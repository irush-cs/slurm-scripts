package cshuji::Slurm;

################################################################################
#
#   cshuji/Slurm.pm
#
#   Copyright (C) 2018-2019 Hebrew University of Jerusalem Israel, see LICENSE
#   file.
#
#   Author: Yair Yarom <irush@cs.huji.ac.il>
#
################################################################################

use List::Util;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse_scontrol_show
                    split_gres
                    nodecmp
                    nodes2array
                  );
our @EXPORT = qw();

our $VERSION = "0.1";

BEGIN {
    # for backward compatibility
    if (eval "use cshuji::Slurm::Local; 1") {
        cshuji::Slurm::Local->export_to_level(1, "cshuji::Slurm::Local", @cshuji::Slurm::Local::EXPORT);
    }
}

=head1 NAME

cshuji::Slurm - Slurm utility functions

=head1 SYNOPSIS

use cshuji::Slurm

=head1 DESCRIPTION

Slurm utility functions. Currently uses the slurm binaries and not the Slurm API.

=head1 FUNCTIONS

=head2 parse_scontrol_show

 $results = parse_scontrol_show($lines)

Converts the lines returned by "scontrol show <something>" to a hash ref.

Any additional data (such as the node resources of jobs), is in the "_DETAILS"
key of the element.

Example:

  parse_scontrol_show([`scontrol show jobs -dd`])
  parse_scontrol_show([`scontrol show nodes -dd`])

=cut

sub parse_scontrol_show {
    my $lines = shift;

    # Reason for show job can be in the middle of the line (?!?!)
    # JobName comes at the end of the line
    my @withspacefirst = qw(Reason Command);
    my @withspace = qw(JobName);

    # this is really annoying...
    my @withspace1711 = qw(OS);

    my %results;
    my %current;
    my $reskey;
    my $indent;
    my $special;

    foreach my $line (@$lines) {
        chomp($line);
        return {} if ($line eq "No jobs in the system");
        next if $line =~ m/^ *$/;

        # new entry
        if ($line =~ m/^[^ ]/) {
            my ($key) = ($line =~ m/^([^=]+)/);

            # first entry
            if ($reskey) {
                if ($reskey ne $key) {
                    print STDERR "Too many keys: $key != $reskey\n";
                }
            } else {
                $reskey = $key;
            }

            # save previous entry
            if (%current) {
                $results{$current{$reskey}} = {%current};
            }
            %current = ();
        } elsif (not $indent) {

            # get indent
            ($indent) = ($line =~ m/^( +)/);
        }

        my %lineparams = ();
        my $detailed = (defined $indent and $line =~ m/^\Q${indent}\E /);
        my $first = 1;

        while ($line) {
            my ($key, $value);
            $line =~ s/^\s*|\s*$//g;
            ($key, $line) = $line =~ m/^([^=]+)=(.*)/;
            if ($line !~ m/=/ or
                ($first and grep {$key eq $_} @withspacefirst) or
                grep {$key eq $_} @withspace or
                ($current{Version} and $current{Version} ge "17.11" and grep {$key eq $_} @withspace1711)) {
                $lineparams{$key} = $line;
                $line = "";
            } else {
                ($value, $line) = $line =~ m/^([^ ]+)(.*)/;
                $lineparams{$key} = $value;
            }
            $first = 0;
        }

        # details array
        if ($detailed) {
            $current{_DETAILS} //= [];
            push @{$current{_DETAILS}}, {%lineparams};
        } else {
            @current{keys %lineparams} = (values %lineparams);
        }
    }

    if (%current and $reskey) {
        $results{$current{$reskey}} = {%current};
    }

    return \%results;
}


=head2 split_gres

 $results = split_gres($gres, [$prev])

Splits a gres string ($gres) to a hash ($results) for gres keys to values.

no_consume and types are currently ignored.

If $prev is specified, the results will contained both gres's
combined. Numerical values will be summed; Memory suffixes will be handled
properly and converted to megabytes; unknown strings will be concatenated with
",".

Tres is also supported, i.e. $gres can have either "key:value" or "key=value".

Examples:

  split_gres("gpu:2,mem:3M")                 -> {gpu => 2, mem => "3M"}
  split_gres("gpu,gpu:2")                    -> {gpu => 3}
  split_gres("gpu:2,mem:2M", "gpu:3,mem:2G") -> {gpu => 5, mem => "2050M"}
  split_gres("gres/gpu=3")                   -> {"gres/gpu" => 3}

=cut

sub split_gres {
    my $input = shift;
    my $gres = shift || {};
    my $sep = ":";

    my $gsep = index($input, ":");
    my $tsep = index($input, "=");
    if ($tsep > 0 and ($tsep < $gsep or $gsep < 0)) {
        $sep = "=";
    }

    $gres = {%$gres};

    foreach my $g (split /,/, $input) {
        $g = "$g${sep}1" if index($g, $sep) < 0 or $g !~ m/${sep}\d/;
        my ($t, $v, $r) = split /\Q${sep}\E/, $g;
        $v = $r if ($v !~ m/^\d/ and $r and $r =~ m/^\d/);
        if ($v =~ m/^\d+$/) {
            $gres->{$t} ||= 0;
        }
        if (defined $gres->{$t} and $gres->{$t} =~ m/^\d+$/ and $v =~ m/^\d+$/) {
            $gres->{$t} += $v;
        } else {
            $gres->{$t} = join(",", $v, $gres->{$t} ? $gres->{$t} : ());

            # memory sum
            if ($gres->{$t} =~ m/^((\d+[MGTP]),)*(\d+[MGTP])$/) {
                my $sum = 0;
                foreach my $sub (split /,/, $gres->{$t}) {
                    my ($sub1, $sub2) = $sub =~ m/^(\d+)([MGTP])$/;
                    if ($sub2 eq "M") {
                        $sub = $sub1;
                    } elsif ($sub2 eq "G") {
                        $sub = $sub1 * 1024;
                    } elsif ($sub2 eq "T") {
                        $sub = $sub1 * 1024 * 1024;
                    } elsif ($sub2 eq "P") {
                        $sub = $sub1 * 1024 * 1024 * 1024;
                    }
                    $sum += $sub;
                }
                $gres->{$t} = "${sum}M";
            }
        }
    }

    return $gres;
}

=head2 nodecmp

 $results = sort nodecmp @nodelist

Sorts node list while taking into account numeric indices inside.

Examples:

  sort nodecmp ('node-10', 'node-9', 'node-90') -> ('node-9', 'node-10', 'node-90')

=cut

sub nodecmp($$) {
    _nodecmp($_[0], $_[1]);
}

sub _nodecmp {
    my $a = shift;
    my $b = shift;

    my ($a1, $a2, $a3) = ($a =~ m/^([^\d]*)(\d*)(.*)$/);
    my ($b1, $b2, $b3) = ($b =~ m/^([^\d]*)(\d*)(.*)$/);

    if ($a1 ne $b1) {
        return $a1 cmp $b1;
    }

    if ($a2 ne $b2) {
        return $a2 <=> $b2;
    }

    if ($a3 =~ m/\d/ or $b3 =~ m/\d/) {
        return _nodecmp($a3, $b3);
    } else {
        return $a3 cmp $b3;
    }
}

=head2 nodes2array

 $results = nodes2array @nodesstrings

Opens up the input strings and returns a complete list of the nodes. The output
is sorted using nodecmp.

Examples:

  nodes2array('node-[01-10]') -> ('node-01', 'node-02', ... , 'node-10')

=cut

sub nodes2array {
    my %nodes;
    my @input = @_;
    while (my $arg = shift @input) {

        # simple, no comma, no bracket
        if ($arg !~ m/[,\[\]]/) {
            $nodes{$arg} = $arg;
            next;
        }

        # comma before bracket
        if ($arg =~ m/^([^[]*),(.*)$/) {
            my $node = $1;
            $arg = $2;
            $nodes{$node} = $node;
            unshift @input, $arg;
            next;
        }

        # brackets
        my @ranges;
        while ($arg =~ m/(.*)\[([\d,-]+)\](.*)/) {
            my ($pref, $range, $suf) = ($1, $2, $3);
            push @ranges, {pref => $pref, range => $range};
            $arg = $suf;
        }
        if ($arg =~ m/(.*),(.*)/) {
            $arg = $1;
            unshift @input, $2;
        }
        # will unshift ${pref}@ranges[0]$ranges[1..-1]$arg
        if (@ranges) {
            my $range = shift @ranges;
            my $pref = $range->{pref};
            $range = $range->{range};
            my @range;
            foreach my $subrange (split /,/, $range) {
                if ($subrange =~ m/^(\d+)-(\d+)$/) {
                    my $first = $1;
                    my $last = $2;
                    my $len = 1;
                    $len = length($first);
                    for (my $i = $first; $i <= $last; $i++) {
                        push @range, sprintf("%0${len}i", $i)
                    }
                } else {
                    push @range, $subrange;
                }
            }
            my $suffix = List::Util::reduce {$a.$b}, map {$_->{pref}."[".$_->{range}."]"} @ranges;
            $suffix .= $arg;
            unshift @input, map {"${pref}${_}$suffix"} @range;
            next;
        }

        $nodes{$arg} = $arg;
    }
    return sort nodecmp grep {$_} keys %nodes;
}

1;
__END__

=head1 AUTHOR

Yair Yarom, E<lt>irush@cs.huji.ac.ilE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2019 Hebrew University Of Jerusalem, Israel See the LICENSE
file.

=cut


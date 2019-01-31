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

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse_scontrol_show);
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

1;
__END__

=head1 AUTHOR

Yair Yarom, E<lt>irush@cs.huji.ac.ilE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2019 Hebrew University Of Jerusalem, Israel See the LICENSE
file.

=cut


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

use Clone;
use List::Util;
use POSIX qw();

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse_scontrol_show
                    parse_list
                    split_gres
                    gres2string
                    nodecmp
                    nodes2array
                    get_config
                    get_jobs
                    get_clusters
                    set_cluster
                    get_nodes
                    get_reservations
                    get_accounts
                    get_associations
                    parse_conf
                    time2sec
                    string2mb
                    mb2string
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

=head2 parse_list

 $results = parse_list($lines)

Converts the lines returned by various slurm utilities to an array ref
(sacctmgr and sacct). The entries are delimited by pipe '|', and the first line
are the headers. Usually the '-p' option should be added to the commands, and
the '-n' should not.

Example:

  parse_list([`sacctmgr list clusters -p`])
  parse_list([`sacctmgr list accounts -s -p`])
  parse_list([`sacct -p -a -o\%all`])

=cut

sub parse_list {
    my $lines = shift;
    my @results;
    my @headers;

    my $header = shift @$lines;
    chomp($header);
    @headers = split /\|/, $header, -1;
    my $pop = length($headers[-1]) == 0;
    pop @headers if $pop;

    foreach my $line (@$lines) {
        chomp($line);
        my @entries = split /\|/, $line, -1;
        pop @entries if $pop;
        my %entry;
        @entry{@headers} = @entries;
        push @results, \%entry;
    }

    return [@results];
}

=head2 split_gres

 $results = split_gres($gres, [$prev])

Splits a gres string ($gres) to a hash ($results) for gres keys to values.

no_consume, types, and socket bindings are currently ignored.

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

    # for now, ignore socket binding
    $input =~ s/\(S:[-\d]+?\)//g;

    my $gsep = index($input, ":");
    my $tsep = index($input, "=");
    if ($tsep > 0 and ($tsep < $gsep or $gsep < 0)) {
        $sep = "=";
    }

    $gres = {%$gres};

    foreach my $g (split /,/, $input) {
        # ignore no_consume
        $g =~ s/:no_consume:/:/;
        $g =~ s/:no_consume$//;

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
                    $sum += string2mb($sub);
                }
                $gres->{$t} = "${sum}M";
            }
        }
    }

    return $gres;
}


=head2 gres2string

 $results = gres2string($gres)

Converts a gres hash (as returned from split_gres) back to string.

Examples:

  gres2string({gpu => 2, mem => "3M"})    -> "gpu:2,mem:3M"
  gres2string({gpu => 3})                 -> "gpu,gpu:2"
  gres2string({gpu => 5, mem => "2050M"}) -> "gpu:2,mem:2M", "gpu:3,mem:2G"
  gres2string({"gres/gpu" => 3})          -> "gres/gpu:3"

=cut

sub gres2string {
    my $input = shift;
    my @outputs;
    my $sep = ":";

    foreach my $key (sort keys %$input) {
        push @outputs, $key.$sep.$input->{$key};
    }

    return join(",", @outputs);
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
        if ($arg =~ m/^([^[]*?),(.*)$/) {
            my $node = $1;
            $arg = $2;
            $nodes{$node} = $node;
            unshift @input, $arg;
            next;
        }

        # comma after balanced brackets
        my $comma = undef;
        my $bcount = 0;
        foreach my $i (0 .. length($arg)-1) {
            my $c = substr($arg, $i, 1);
            if ($c eq '[') {$bcount++}
            elsif ($c eq ']') {$bcount--}
            elsif ($c eq ',') {
                if ($bcount == 0) {
                    unshift @input, substr($arg, $i + 1);
                    $arg = substr($arg, 0, $i);
                    last;
                }
            }
            $bcount = 0 if ($bcount < 0);
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

=head2 get_jobs

 $results = get_jobs()

Get jobs hash ref by calling "scontrol show jobs -dd". Uses the
I<parse_scontrol_show> function so _DETAILS are available with the following items:

=over

=over

=item CPU_IDs

=item GRES_IDX (or GRES after 19.05)

=item Mem

=item Nodes

=back

=back

In addition, the following calculated values are also available per detail:

=over

=over

=item _JobId      - The job's JobId

=item _EndTime    - The job's EndTime

=item _nCPUs      - Totol number of CPUs from CPU_IDs

=item _CPUs       - Array of CPU IDs

=item _GRES       - Hash of GRES from GRES_IDX (or GRES after 19.05)

=item _GRESs      - Hash of GRES with the gres IDX (like _CPUs)

=item _NodeList   - Array of nodes from Nodes

=item _GRES_IDX   - The value of GRES_IDX prior to 19.05, and of GRES otherwise

=back

=back

Also, the job hash contains the following additional values

=over

=over

=item _TRES       - Hash of TRES

=item _NodeList   - Array of nodes from NodeList

=item _UserName   - The login (string part of UserId)

=item _UID        - The uid (\d+ part of UserId)

=back

=back

=cut

sub get_jobs {

    my %args = @_;
    my $jobs;

    local $SIG{CHLD} = 'DEFAULT';
    if ($args{_scontrol_output}) {
        $jobs = parse_scontrol_show($args{_scontrol_output});
    } else {
        $jobs = parse_scontrol_show([`scontrol show jobs -dd`]);
    }

    foreach my $job (values %$jobs) {
        foreach my $detail (@{$job->{_DETAILS}}) {
            $detail->{_JobId} = $job->{JobId};
            $detail->{_EndTime} = $job->{EndTime};

            # cpus per detail
            $detail->{_nCPUs} = 0;
            $detail->{_CPUs} = [];
            foreach my $cr (split /,/, $detail->{CPU_IDs}) {
                if ($cr =~ m/(.*)-(.*)/) {
                    $detail->{_nCPUs} += $2 - $1 + 1;
                    push @{$detail->{_CPUs}}, ($1 .. $2);
                } else {
                    $detail->{_nCPUs}++;
                    push @{$detail->{_CPUs}}, $cr;
                }
            }

            # gres per detail
            $detail->{_GRES} = {};
            $detail->{_GRESs} = {};

            my $greskey = (exists $detail->{GRES} and not exists $detail->{GRES_IDX}) ? "GRES" : "GRES_IDX";
            if (exists $detail->{$greskey}) {
                foreach my $gres ($detail->{$greskey} =~ m/([^(]+?\(IDX:[-\d,]+\),?)/g) {
                    $gres =~ s/,$//;
                    my ($name, $count) = $gres =~ m/^(.+?)(?::.*?)?\(IDX:([\d\-,]+)\)/;
                    $detail->{_GRES}{$name} //= 0;
                    $detail->{_GRESs}{$name} //= [];
                    foreach my $gr (split /,/, $count) {
                        if ($gr =~ m/(.*)-(.*)/) {
                            $detail->{_GRES}{$name} += $2 - $1 + 1;
                            push @{$detail->{_GRESs}{$name}}, ($1 .. $2);
                        } else {
                            $detail->{_GRES}{$name}++;
                            push @{$detail->{_GRESs}{$name}}, $gr;
                        }
                    }
                }
                $detail->{_GRES_IDX} = $detail->{$greskey};
            }

            $detail->{_NodeList} = [nodes2array($detail->{Nodes})];
        }

        $job->{_TRES} = split_gres($job->{TRES}, {});
        if ($job->{NodeList} eq "(null)") {
            $job->{_NodeList} = [];
        } else {
            $job->{_NodeList} = [nodes2array($job->{NodeList})];
        }

        if ($job->{UserId} =~ m/^([^\(]+)\((\d+)\)$/) {
            $job->{_UserName} = $1;
            $job->{_UID} = $2;
        }
    }

    return $jobs;
}


=head2 get_clusters

 $results = get_clusters()

Get clusters hash refs by calling "sacctmgr list clusters". Uses the
I<parse_list> function. Returns a hash of clusters by name.

=cut

sub get_clusters {

    my %args = @_;
    my $clusters;
    my %clusters;

    local $SIG{CHLD} = 'DEFAULT';
    if ($args{_sacctmgr_output}) {
        $clusters = parse_list($args{_sacctmgr_output});
    } else {
        $clusters = parse_list([`sacctmgr list clusters -p`]);
    }

    foreach my $cluster (@$clusters) {
        $clusters{$cluster->{Cluster}} = $cluster;
    }

    return {%clusters};
}

=head2 get_accounts

 $results = get_accounts()

Get array ref of account hash refs by calling "sacctmgr list accounts" and
using the I<parse_list> function. Only the accounts are returned (i.e. where
User is empty).

The returned fields are:

=over

=over

=item Account

=item Description

=item Org

=item Cluster

=item ParentName

=item User

=item Share

=item GrpJobs

=item GrpNodes

=item GrpCPUs

=item GrpMem

=item GrpSubmit

=item GrpWall

=item GrpCPUMins

=item MaxJobs

=item MaxNodes

=item MaxCPUs

=item MaxSubmit

=item MaxWall

=item MaxCPUMins

=item QOS

=item DefaultQOS

=item GrpTRES

=back

=back

=cut

sub get_accounts {

    my %args = @_;
    my $accounts;

    local $SIG{CHLD} = 'DEFAULT';
    if ($args{_sacctmgr_output}) {
        $accounts = parse_list($args{_sacctmgr_output});
    } else {
        $accounts = parse_list([`sacctmgr list accounts -s -p "format=Account,Description,Org,Cluster,ParentName,User,Share,GrpJobs,GrpNodes,GrpCPUs,GrpMem,GrpSubmit,GrpWall,GrpCPUMins,MaxJobs,MaxNodes,MaxCPUs,MaxSubmit,MaxWall,MaxCPUMins,QOS,DefaultQOS,GrpTRES"`]);
    }
    $accounts = [grep {$_->{User} eq ''} @$accounts];

    return $accounts;
}


=head2 get_associations

 $results = get_associations()

Get array ref of association hash refs by calling "sacctmgr list associations"
and using the I<parse_list> function. All associations are returned, including
base ones (with empty user or empty partition).

The returned fields are:

=over

=over

=item Cluster

=item Account

=item User

=item Partition

=item Share

=item GrpJobs

=item GrpTRES

=item GrpSubmit

=item GrpWall

=item GrpTRESMins

=item MaxJobs

=item MaxTRES

=item MaxTRESPerNode

=item MaxSubmit

=item MaxWall

=item MaxTRESMins

=item QOS

=item Def QOS

=item GrpTRESRunMins

=back

=back

=cut

sub get_associations {

    my %args = @_;
    my $associations;

    local $SIG{CHLD} = 'DEFAULT';
    if ($args{_sacctmgr_output}) {
        $associations = parse_list($args{_sacctmgr_output});
    } else {
        $associations = parse_list([`sacctmgr list associations -s -p "format=Cluster,Account,User,Partition,Share,GrpJobs,GrpTRES,GrpSubmit,GrpWall,GrpTRESMins,MaxJobs,MaxTRES,MaxTRESPerNode,MaxSubmit,MaxWall,MaxTRESMins,QOS,DefaultQOS,GrpTRESRunMins"`]);
    }

    return [@$associations];
}

=head2 get_nodes

 $results = get_nodes()

Get nodes hash ref by calling "scontrol show nodes -dd". Uses the
I<parse_scontrol_show>, with the following modifications:

=over

=over

=item Gres - Empty string instead of "(null)".

=back

=back

In addition to the normal values, the following calculated values are also
available:

=over

=over

=item _Gres       - Hash of Gres

=back

=back

=cut

sub get_nodes {

    my %args = @_;
    my $nodes;

    local $SIG{CHLD} = 'DEFAULT';
    if ($args{_scontrol_output}) {
        $nodes = parse_scontrol_show($args{_scontrol_output});
    } else {
        $nodes = parse_scontrol_show([`scontrol show nodes -dd`]);
    }

    foreach my $node (values %$nodes) {
        if ($node->{Gres} and $node->{Gres} eq "(null)") {
            $node->{Gres} = "";
        }
        $node->{_Gres} = split_gres($node->{Gres}, {});
    }

    return $nodes;
}


=head2 get_reservations

 $results = get_reservations()

Get reservations hash ref by calling "scontrol show reservations -dd". Uses the
I<parse_scontrol_show>.

In addition to the normal values, the following calculated values are also
available:

=over

=over

=item _NodeList   - Array of nodes from NodeList

=back

=back

=cut

sub get_reservations {
    my %args = @_;
    my $reservations;

    local $SIG{CHLD} = 'DEFAULT';
    if ($args{_scontrol_output}) {
        $reservations = parse_scontrol_show($args{_scontrol_output});
    } else {
        $reservations = parse_scontrol_show([`scontrol show reservations -dd | grep -v '^No reservations in the system\$'`]);
    }

    foreach my $reservation (values %$reservations) {
        $reservation->{_NodeList} = [nodes2array($reservation->{Nodes})];
    }

    return $reservations;
}

=head2 parse_conf

 $results = parse_conf(<conf file>, [errors => $arrref])

Parses a slurm type conf file. Returns a hash ref of the configuration. On
error, if <errors> is availalbe will contain a list of errors. If file cannot
be read, undef is returned.

Lines that appears multiple times will be converted to hash refs. Each element
will be a hash ref of the values within.

=cut

sub parse_conf {
    my $file = shift;
    my %params = @_;
    my $errors = $params{errors} // [];
    my $conf = {};

    unless (open(CONF, "<$file")) {
        push @$errors, "$!";
        return undef;
    }
    foreach my $line (<CONF>) {
        chomp($line);
        my $origline = $line;
        $line =~ s/#.*//;
        $line =~ s/^\s*|\s*$//g;
        next unless $line;

        if ($line =~ m/^\s*([^=]+?)\s*=\s*(.*?)\s*$/) {
            my ($key, $value) = ($1, $2);
            if (exists $conf->{$key}) {
                if (ref $conf->{$key} ne "ARRAY") {
                    $conf->{$key} = [$conf->{$key}]
                }
                push @{$conf->{$key}}, $value;
            } elsif ($value =~ m/\s/) {
                $conf->{$key} = [$value];
            } else {
                $conf->{$key} = $value;
            }
        } else {
            push @$errors, "Bad line in $file: \"$origline\"";
        }
    }
    close(CONF);

    # lower before ARRAY, so convert ARRAY to HASH properly
    sub _add_lower {
        my $conf = $_[0];

        foreach my $key (keys %$conf) {
            my $lkey = lc($key);
            my $value = $conf->{$key};
            if (exists $conf->{$lkey}) {
                if (ref $value ne "ARRAY") {
                    $value = [$value];
                }
                if (ref $conf->{$lkey} ne "ARRAY") {
                    $conf->{$lkey} = [$conf->{$lkey}];
                }
                $value = [@$value, @{$conf->{$lkey}}];
            }
            $conf->{$lkey} = Clone::clone($value);
            $conf->{$key} = $value;
        }
    }
    _add_lower($conf);

    # go over array values (nodes, partitions, etc.)
    foreach my $key (keys %$conf) {
        if (ref $conf->{$key} eq "ARRAY") {
            my @values = @{$conf->{$key}};
            $conf->{$key} = {};
            foreach my $value (@values) {
                my ($name, $value) = split /\s+/, $value, 2;
                my %values = (map {(split /=/, $_, 2)} split /\s+/, $value);
                $conf->{$key}{$name} = {%values};
                _add_lower($conf->{$key}{$name});
                $conf->{$key}{$name}{$key} = $name;
                $conf->{$key}{$name}{lc($key)} = $name;
            }
        }
    }

    return $conf;
}

=head2 get_config

 $results = get_config([errors => $arrref], [cluster => $cluster])

Calls `scontrol show config` and parses the output into a hash ref. If $cluster
is specified, "-M $cluster" is added.

If I<errors> is given, will contain any errors. Otherwise errors will be printed
to stderr.

If the `scontrol show config` returns the "Cgroup Support Configuration"
section (version 19.05), it is returned in a "_CgroupSupportConfiguration" hash
in the results.

=cut

sub get_config {
    my %args = @_;
    my $errors = $args{errors};
    my $cluster = $args{cluster};
    my $config = {};
    my @lines;
    local $SIG{CHLD} = 'DEFAULT';

    if ($args{_scontrol_output}) {
        @lines = @{$args{_scontrol_output}};
    } else {
        my $cmd = "scontrol show config";
        $cmd = "scontrol -M $cluster show config" if $cluster;
        @lines = `$cmd`;
        if (not @lines or $?) {
            my $err = "Can't run $cmd";
            if ($errors) {
                push @$errors, $err;
            } else {
                print STDERR $err."\n";
            }
            return undef;
        }
    }

    chomp(@lines);
    my $cgroup;
    foreach my $line (@lines) {
        if ($line =~ m/^\s*([^\s]+?)\s*=\s*([^\s].*)?\s*?/) {
            my ($key, $value) = ($1, $2);
            $value //= "";
            if ($cgroup) {
                $cgroup->{$key} = $value;
            } else {
                $config->{$key} = $value;
            }
        } elsif ($line =~ m/^Configuration data as of \d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$/) {
            # ignore
        } elsif ($line =~ m/^\s*$/) {
            # ignore
        } elsif ($line =~ m@^Slurmctld\((?:primary(?:/backup)?|backup)\) at .*? (is|are) (UP|DOWN)(?:/(UP|DOWN))?@) {
            # ignore
        } elsif ($line eq "Cgroup Support Configuration:") {
            $cgroup = {};
        } else {
            if ($errors) {
                push @$errors, "Bad line from show config: $line\n";
            } else {
                print STDERR "Bad line from show config: $line\n";
            }
        }
    }

    if ($cgroup) {
        $config->{_CgroupSupportConfiguration} = $cgroup;
    }

    return $config;
}


=head2 time2sec

 $results = time2sec($interval)

Converts Slurm time interval to seconds. Returns undef on error.

=cut

sub time2sec {
    my $time = shift;
    my $seconds = undef;

    if ($time =~ m/^\d+$/) {
        # "minutes"
        $seconds = $time * 60;
    } elsif ($time =~ m/^(\d+):(\d+)$/) {
        # "minutes:seconds"
        $seconds = $1 * 60 + $2;
    } elsif ($time =~ m/^(\d+):(\d+):(\d+)$/) {
        # "hours:minutes:seconds"
        $seconds = $1 * 60 * 60 + $2 * 60 + $3;
    } elsif ($time =~ m/^(\d+)-(\d+)$/) {
        # "days-hours"
        $seconds = $1 * 24 * 60 * 60 + $2 * 60 * 60;
    } elsif ($time =~ m/^(\d+)-(\d+):(\d+)$/) {
        # "days-hours:minutes"
        $seconds = $1 * 24 * 60 * 60 + $2 * 60 * 60 + $3 * 60;
    } elsif ($time =~ m/^(\d+)-(\d+):(\d+):(\d+)$/) {
        # "days-hours:minutes:seconds".
        $seconds = $1 * 24 * 60 * 60 + $2 * 60 * 60 + $3 * 60 + $4;
    }

    return $seconds;
}

=head2 string2mb

 $results = string2mb($memstring)

Convert memory string to MB integer. I.e. everything that matches the regexp
m/^\d+(\.\d+)?\s*[KMGTP]?B?$/i is converted to megabytes. Without suffix, the
number is assumbed to be in bytes.

Returns undef on error, or integer representing megabytes (floored).

=cut

sub string2mb {
    my $string = shift;
    my $mb = undef;

    if ($string =~ m/^(\d+(?:\.\d+)?)\s*([KMGTP])?B?$/i) {
        my $bytes = $1;
        my $suffix = $2 // 'B';
        $suffix = uc($suffix);
        my @suffixes = qw(B K M G T P);

        for (my $current = shift @suffixes; $current and $current ne $suffix; $current = shift @suffixes) {
            $bytes *= 1024;
        }

        $mb = POSIX::floor($bytes / 1024 / 1024);
    }

    return $mb;
}

=head2 mb2string

 $results = mb2string($memory, [precision => $precision], [space => $space])

Converts memory from MB to general memory. The input B<$memory> should be of
the form m/^\d+(\.\d+)?\s*(M|MB)?$/i and represent memory in MB.

If B<$precision> is given, it is used as the 'f' prefix of printf. The default
value is "2" (i.e. %.2f).

If B<$space> is true, there will be a space before the memory suffix.

Returns string with memory suffix (human readable), or undef on error.

=cut

sub mb2string {
    my $mb = shift;
    my %args = @_;

    $args{precision} //= "2";
    $args{space} //= 0;
    $args{space} = $args{space} ? " " : "";

    return undef unless $args{precision} =~ m/^\d$/;

    if ($mb =~ m/^(\d+(?:\.\d+)?)?\s*(M|MB)?$/i) {
        my $bytes = $1 * 1024 * 1024;

        my @suffixes = qw(B K M G T P);
        my $suffix;
        for ($suffix = shift @suffixes; @suffixes; $suffix = shift@suffixes) {
            # 0.98T is better than 1007.89G
            last if $bytes < 1000;
            $bytes /= 1024;
        }
        my $fmt = "\%.$args{precision}f$args{space}\%s";
        return sprintf $fmt, $bytes, $suffix;
    }

    return undef;
}


=head2 set_cluster

 $result = set_cluster($cluster, [path => \@path], [conf => $conf], [unset => <1|0>])

For multiple clusters, this sets PATH and SLURM_CONF to work with the specified
cluster.

If I<path> is given, they are simply prepended to the PATH environment.

If I<path> is undef, I<get_config> is called for the current cluster name. Then
the location of 'scontrol' and 'slurmctld' is search in PATH. If the path of
scontrol and slurmctld contains the current cluster's name, it is replaced with
the new name and replaced in the PATH (if they exist in the resulting path).

If I<$conf> is given, SLURM_CONF is set appropriately.

If I<$conf> is undef, I<get_config> is called (before PATH is changed). If the
current SLURM_CONF or the SLURM_CONF from get_config contains the current
cluster name, it is replaced with the new cluster name. Otherwise (or if the
new SLURM_CONF doesn't exists), I<get_config> is called with $cluster (with the
new path) and SLURM_CONF is taken from there.

If I<unset> is true, PATH and SLURM_CONF are reset to their original value
before the first call to I<set_cluster>. I<$cluster> is ignored.

A second call to I<set_cluster> will reset both PATH and SLURM_CONF to their
previous states before starting to set the new cluster (like with
I<unset>). This means that if PATH or SLURM_CONF were changed outside
I<set_cluster>, they will be reverted.

The return value is boolean of whether the change worked. This is checked using
I<get_config>, and comparing the result ClusterName with I<$cluster>.

This mechanism lets cshuji::Slurm work with several clusters which might
operate on different versions (and may require different binaries). It is best
to set the paths of the binaries and the slurm.conf files to contain the
cluster names (and make sure the clusters aren't named "usr" or "bin").

For example, the slurm.conf can be in:

=over

=item /etc/slurm/clusterA/slurm.conf

=item /etc/slurm/clusterB/slurm.conf

=back

And the binaries might be:

=over

=item /usr/local/slurm/17.02.1/{bin,sbin,...}

=item /usr/local/slurm/17.11.3/{bin,sbin,...}

=item /usr/local/slurm/clusterA -> /usr/local/slurm/17.02.1

=item /usr/local/slurm/clusterB -> /usr/local/slurm/17.11.3

=back

=cut

my $_old_cluster;
sub set_cluster {
    my $cluster = shift;
    my %args = @_;
    my $unset = $args{unset} // 0;

    # restore previous PATH and SLURM_CONF
    if ($_old_cluster) {
        foreach my $key (keys %$_old_cluster) {
            if (defined $_old_cluster->{$key}) {
                $ENV{$key} = $_old_cluster->{$key};
            } else {
                delete $ENV{$key};
            }
        }
    } else {
        $_old_cluster = {
                         PATH => $ENV{PATH},
                         SLURM_CONF => $ENV{SLURM_CONF},
                        };
    }

    return 1 if $unset;

    my $config = get_config();
    my $oldname = $config->{ClusterName};

    # PATH
    if ($args{path} and ref $args{path} eq "ARRAY") {
        $ENV{PATH} = join(":", (@{$args{path}}, $ENV{PATH}))
    } else {
        my @PATH = ();
        foreach my $path (split /:/, $ENV{PATH}) {
            foreach my $prog (qw(scontrol slurmctld)) {
                if (-x "${path}/${prog}" and $path =~ m/\b$oldname\b/) {
                    my $newpath = $path;
                    $newpath =~ s/\b$oldname\b/$cluster/;
                    if (-x "${newpath}/${prog}") {
                        $path = $newpath;
                        last;
                    }
                }
            }
            push @PATH, $path;
        }
        $ENV{PATH} = join(":", @PATH);
    }

    # SLURM_CONF
    if ($args{conf} and -e $args{conf}) {
        $ENV{SLURM_CONF} = $args{conf};
    } else {
        my $oldconf;

        # try updateding old SLURM_CONF
        if (exists $ENV{SLURM_CONF} and $ENV{SLURM_CONF} =~ m/\b$oldname\b/) {
            $oldconf = $ENV{SLURM_CONF};
            $oldconf =~ s/\b$oldname\b/$cluster/;
        }

        # try updating the SLURM_CONF from the config
        if ((not defined $oldconf or not -e $oldconf) and
            exists $config->{SLURM_CONF} and $config->{SLURM_CONF} =~ m/\b$oldname\b/) {
            $oldconf = $config->{SLURM_CONF};
            $oldconf =~ s/\b$oldname\b/$cluster/;
        }

        # try running get_config($cluster)
        if (not defined $oldconf or not -e $oldconf) {
            my $newconfig = get_config(cluster => $cluster);
            $oldconf = $newconfig->{SLURM_CONF};
        }

        if ($oldconf) {
            $ENV{SLURM_CONF} = $oldconf;
        } else {
            return 0;
        }
    }

    my $newconfig = get_config();
    return ($newconfig and ($newconfig->{ClusterName} eq $cluster)) ? 1 : 0;
}

1;
__END__

=head1 AUTHOR

Yair Yarom, E<lt>irush@cs.huji.ac.ilE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2019 Hebrew University Of Jerusalem, Israel See the LICENSE
file.

=cut


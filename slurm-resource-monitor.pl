#!/usr/bin/env perl

################################################################################
#
#   slurm-resource-monitor.pl
#
#   Copyright (C) 2019 Hebrew University of Jerusalem Israel, see LICENSE file.
#
#   Author: Yair Yarom <irush@cs.huji.ac.il>
#
################################################################################

use strict;
use warnings;

################################################################################
# Some libraries
################################################################################
my $scriptdir;
BEGIN {
    use Cwd;
    use File::Basename;
    $scriptdir = dirname(Cwd::realpath($0));
}
$scriptdir = '.' unless (defined $scriptdir);
use lib "$scriptdir";

use cshuji::Slurm;

use POSIX qw(round);
use File::Find;
use List::Util qw(none any);
use Data::Dumper;
use Getopt::Long;
use Sys::Hostname;
use Time::ParseDate;

$Data::Dumper::Sortkeys = 1;

################################################################################
# Some variables
################################################################################
my $interval = 2;
my $hostname = hostname;
my $havegpus = 0;
my $verbose = 0;
my $debug = 0;
my $minruntime = 60 * 30;
my $shortjobpercent = 15;
my $notifyshortjob = 1;
my %notifyunused = (cpus => 1,
                    gpus => 1);
my $minmonitoredpercent = 75;

# current monitored jobs
# jobid => {uid, login, jobid, state, cpus => {}, gpus => {}}
# cpus, gpus hashes:
#   data => {<id> => {}} - resource specific data
#   usage   - usage historgram (#resources => #samples)
#   gooduse - number of samples with "good" usage (unused <= allowedunused{count})
#   baduse  - number of samples with "bad" usage (unused > allowedunused{count})
#   samples - number of samples
#   count   - number of resources

my %stats; 

# old jobs, already reported
my %oldjobs; 

# count as in-use threshold
my $inusecpupercent = 5;
my $inusegpupercent = 15;

my $minsamples = 5;

# allow unused <count> <resource>s for at most <percent>% of the time.
my %allowedunused = (cpus => {count => 2,
                              percent => 25},
                     gpus => {count => 0,
                              percent => 25});

# states:
#   report  => send mail,
#   sample => sample usage
#   ignore  => don't say you don't know it
#   all     => list of all known
my %states = (report => {"COMPLETED" => 1,
                         "TIMEOUT" => 1,
                         "FAILED" => 1,
                        },
              sample => {"RUNNING" => 1,
                        },
              ignore => {"COMPLETING" => 1,
                         "CANCELLED" => 1,
                        },
              all => {},
             );

foreach my $type (keys %states) {
    foreach my $state (keys %{$states{$type}}) {
        $states{all}{$state} = 1;
    }
}

my $conffile;
my $conf_update_check_interval = 60 * 60;
my $conf_last_update = 0;
my $conf_update_check = 0;
my $config;

my @recipients;

my $temp;

################################################################################
# get options
################################################################################
if (!GetOptions('v|verbose+' => \$verbose,
                'c|conf=s'   => \$conffile,
                'd|debug!'   => \$debug,
               )) {
    print STDERR "usage: slurm-resource-monitor [-v] [-c <conf>]\n";
    print STDERR "  -v        - verbose level\n";
    print STDERR "  -d        - debug\n";
    print STDERR "  -c <conf> - use <conf> as configuration file\n";
    exit 1;
}
$verbose = 1 if $debug;

################################################################################
# get configuration
################################################################################

my $slurm_config = cshuji::Slurm::get_config();
my $cluster = $slurm_config->{ClusterName};
unless ($conffile) {
    $conffile = $slurm_config->{SLURM_CONF};
    $conffile =~ s@/[^/]*$@@;
    $conffile .= "/slurm-resource-monitor.conf";
    unless (-e $conffile) {
        print STDERR "$conffile doesn't exist\n";
        exit 2;
    }
}

sub to_bool {
    my $value = shift;
    my $default = shift;

    return $default unless defined $value;

    if ($value =~ m/^yes|true|1$/i) {
        return 1;
    } elsif ($value =~ m/^no|false|0$/i) {
        return 0;
    }
    return $default;
}

sub read_conf {
    print "Reading configuration: $conffile\n";

    $conf_last_update = (stat $conffile)[9];
    $conf_update_check = time;
    $config = cshuji::Slurm::parse_conf($conffile);

    unless (-x $config->{notificationscript}) {
        print STDERR "NotificationScript: \"$config->{notificationscript}\" isn't executable\n";
        exit 3;
    }

    my $recipients = "*LOGIN*";
    if (exists $config->{notificationrecipients}) {
        $recipients = $config->{notificationrecipients};
    }
    foreach my $recipient (split /,/, $recipients) {
        $recipient =~ s/^\s*|\s*$//g;
        next unless $recipient;
        push @recipients, $recipient;
    }
    unless (@recipients) {
        print STDERR "Warning: No recipients\n";
    }

    if ($config->{confupdatecheckinterval}) {
        $temp = $conf_update_check_interval;
        $conf_update_check_interval = $config->{confupdatecheckinterval};
        if ($conf_update_check_interval !~ m/^\d+$/) {
            print STDERR "Bad configuration: ConfUpdateCheckInterval is not a number ($conf_update_check_interval)\n";
            exit 10;
        }
        print "Updating conf_update_check_interval: $temp -> $conf_update_check_interval\n" if $verbose and $temp != $conf_update_check_interval;
    }

    if ($config->{minruntime}) {
        $temp = $minruntime;
        $minruntime = $config->{minruntime};
        if ($minruntime !~ m/^\d+$/) {
            print STDERR "Bad configuration: MinRunTime is not a number ($minruntime)\n";
            exit 11;
        }
        print "Updating minruntime: $temp -> $minruntime\n" if $verbose and $temp != $minruntime;
    }

    if ($config->{shortjobpercent}) {
        $temp = $shortjobpercent;
        $shortjobpercent = $config->{shortjobpercent};
        if ($shortjobpercent !~ m/^\d+$/ or $shortjobpercent < 0 or $shortjobpercent > 100) {
            print STDERR "Bad configuration: ShortJobPercent is not a percent ($shortjobpercent)\n";
            exit 12;
        }
        print "Updating shortjobpercent: $temp -> $shortjobpercent\n" if $verbose and $temp != $shortjobpercent;
    }

    sub _update_setting {
        my $var = shift;
        my $new = shift;
        my $type = shift;
        my $name = shift;

        if (defined $new) {
            $temp = $$var;
            $$var = $new;
            if ($type eq "bool") {
                if ($$var =~ m/^yes|true|1$/i) {
                    $$var = 1;
                } elsif ($$var =~ m/^no|false|0$/i) {
                    $$var = 0;
                } else {
                    print STDERR "Bad configuration: $name is not boolean ($new)\n";
                    exit 13;
                }
            } elsif ($type eq "percent") {
                if ($new !~ m/^\d+$/ or $new < 0 or $new > 100) {
                    print STDERR "Bad configuration: $name is not a percent ($new)\n";
                    exit 13;
                }
            } elsif ($type eq "int") {
                if ($new !~ m/^\d+$/) {
                    print STDERR "Bad configuration: $name is not a integer ($new)\n";
                    exit 13;
                }
            } else {
                print STDERR "Bad configuration type: \"$type\"\n";
                exit 12;
            }
            print "Updating $name: $temp -> $$var\n" if $verbose and $temp != $$var;
        }
    }

    _update_setting(\$notifyshortjob, $config->{notifyshortjob}, "bool", "NotifyShortJob");
    _update_setting(\$notifyunused{cpus}, $config->{notifyunusedcpus}, "bool", "NotifyUnusedCPUs");
    _update_setting(\$notifyunused{gpus}, $config->{notifyunusedgpus}, "bool", "NotifyUnusedGPUs");

    _update_setting(\$inusecpupercent, $config->{inusecpupercent}, "percent", "InUseCPUPercent");
    _update_setting(\$inusegpupercent, $config->{inusegpupercent}, "percent", "InUseGPUPercent");

    _update_setting(\$allowedunused{cpus}{count}, $config->{allowedunusedcpus}, "int", "AllowedUnusedCPUs");
    _update_setting(\$allowedunused{cpus}{percent}, $config->{allowedunusedcpupercent}, "percent", "AllowedUnusedCPUPercent");
    _update_setting(\$allowedunused{gpus}{count}, $config->{allowedunusedgpus}, "int", "AllowedUnusedGPUs");
    _update_setting(\$allowedunused{gpus}{percent}, $config->{allowedunusedgpupercent}, "percent", "AllowedUnusedGPUPercent");

    _update_setting(\$minmonitoredpercent, $config->{minmonitoredpercent}, "percent", "MinMonitoredPercent");

    # clear stats, parameters might have changed
    %stats = ();
}

read_conf();

################################################################################
# Main loop
################################################################################
while (1) {
    if (time - $conf_update_check > $conf_update_check_interval) {
        my $new_conf_update = (stat $conffile)[9];
        if ($new_conf_update != $conf_last_update) {
            read_conf();
        }
    }
    print "current jobs: ".join(", ", map {"$_/$stats{$_}{state}"} sort keys %stats)."\n" if $verbose;
    get_new_jobs();
    clean_old();
    gpu_utilization() if $havegpus;
    cpu_utilization();

    foreach my $job (values %stats) {
        unless ($states{all}{$job->{state}} ){
            print STDERR "Unknown state $job->{state} for job $job->{jobid}\n";
            exit 4;
        }
    }
    sleep $interval;
}

exit 0;

################################################################################
# get_new_jobs
################################################################################
sub get_new_jobs {
    # clean old state (to capture missing jobs)
    foreach my $old (values %stats) {
        delete $old->{state};
    }
    my $stamp = time;
    my $jobs = cshuji::Slurm::get_jobs();
    foreach my $job (values %$jobs) {
        if (any {$_ eq $hostname} @{$job->{_NodeList}}) {

            # put this just to keep track on something that still in get_jobs()
            if (exists $oldjobs{$job->{JobId}}) {
                $stats{$job->{JobId}} //= {jobid => $job->{JobId}};

             # intizalize structure for new jobs
            } elsif (not exists $stats{$job->{JobId}}) {

                my $cpus = [];
                my $gpus = [];
                foreach my $detail (@{$job->{_DETAILS}}) {
                    next if (none {$hostname eq $_} @{$detail->{_NodeList}});
                    push @$cpus, @{$detail->{_CPUs}};
                    push @$gpus, @{$detail->{_GRESs}{gpu} // []};
                }
                $gpus = {map {$_ => {}} @$gpus};
                $cpus = {map {$_ => {}} @$cpus};
                # slurm has weird cpu mapping, so we'll make it later from cgroup
                my $jobstat = {jobid => $job->{JobId},
                               uid => $job->{UserId} =~ m/\((.*)\)/,
                               login => $job->{UserId} =~ m/^([^(]*)\(/,
                               cpus => {                  samples => 0, count => scalar(keys %$cpus), gooduse => 0, baduse => 0},
                               gpus => {data => {%$gpus}, samples => 0, count => scalar(keys %$gpus), gooduse => 0, baduse => 0}
                              };
                $jobstat->{gpus}{usage} = {map {$_ => 0} (0 .. scalar(keys %$gpus))};
                $jobstat->{cpus}{usage} = {map {$_ => 0} (0 .. scalar(keys %$cpus))};

                my $uconfig = (getpwnam($jobstat->{login}))[7];
                $uconfig .= '/.slurm-resource-monitor';
                if (-r $uconfig) {
                    print "Reading user config $uconfig\n" if $verbose;
                    $uconfig = cshuji::Slurm::parse_conf($uconfig);
                    $uconfig //= {};
                } else {
                    print "No readable user config $uconfig\n" if $verbose;
                    $uconfig = {};
                }
                $uconfig->{notifyshortjob} = to_bool($uconfig->{notifyshortjob}, $notifyshortjob);
                $uconfig->{notifyunusedgpus} = to_bool($uconfig->{notifyunusedgpus}, $notifyunused{gpus});
                $uconfig->{notifyunusedcpus} = to_bool($uconfig->{notifyunusedcpus}, $notifyunused{cpus});

                $jobstat->{notifyshortjob} = $uconfig->{notifyshortjob};
                $jobstat->{gpus}{notifyunused} = $uconfig->{notifyunusedgpus};
                $jobstat->{cpus}{notifyunused} = $uconfig->{notifyunusedcpus};

                $jobstat->{firststamp} = $stamp;

                $stats{$job->{JobId}} = $jobstat;
                unless (exists $oldjobs{$job->{JobId}}) {
                    print "New job $jobstat->{jobid}: cpus: $jobstat->{cpus}{count}, gpus: $jobstat->{gpus}{count}, state: $job->{JobState}\n";
                }
            }
            $stats{$job->{JobId}}{state} = $job->{JobState};
            $stats{$job->{JobId}}{runtime} = $job->{RunTime};
            $stats{$job->{JobId}}{timelimit} = $job->{TimeLimit};
            $stats{$job->{JobId}}{laststamp} = $stamp;
        }
    }

    $havegpus = 0;
    foreach my $job (values %stats) {
        if ($job->{gpus}{count} and $job->{gpus}{count} > 0) {
            $havegpus = 1;
            last;
        }
    }

    # delete missing old jobs
    foreach my $old (keys %oldjobs) {
        delete $oldjobs{$old} unless exists $stats{$old};
    }
}

################################################################################
# clean_old
################################################################################
sub clean_old {
    my @old = map {$_->{jobid}} grep {not exists $_->{state} or $states{report}{$_->{state}}} values %stats;
    foreach my $old (@old) {
        my $job = $stats{$old};
        delete $stats{$old};
        next if exists $oldjobs{$old};
        $oldjobs{$old} = $job;
        my $notify = 0;
        $job->{cluster} = $cluster;
        $job->{node} = $hostname;
        my $runtime = cshuji::Slurm::time2sec($job->{runtime});
        my $timelimit = cshuji::Slurm::time2sec($job->{timelimit});
        if ($runtime >= $minruntime and
            $job->{laststamp} - $job->{firststamp} >= $minruntime and
            (100 * ($job->{laststamp} - $job->{firststamp}) / $runtime) >= $minmonitoredpercent
           ) {
            foreach my $res ("cpus", "gpus") {
                $job->{$res}{baduse} = 0;
                $job->{$res}{gooduse} = 0;
                foreach my $count (keys %{$job->{$res}{usage}}) {
                    if ($job->{$res}{count} - $count > $allowedunused{$res}{count}) {
                        $job->{$res}{baduse} += $job->{$res}{usage}{$count};
                    } else {
                        $job->{$res}{gooduse} += $job->{$res}{usage}{$count};
                    }
                }
                if ($job->{$res}{notifyunused} and $job->{$res}{samples} and $job->{$res}{samples} >= $minsamples) {
                    if ($job->{$res}{samples} * ($allowedunused{$res}{percent} / 100) < $job->{$res}{baduse}) {
                        $job->{$res}{allowedunused} = {%{$allowedunused{$res}}};
                        $job->{$res}{notify} = 1;
                        $notify = 1;
                    }
                }
            }

            my $runtimepercent = (100 * ($runtime / $timelimit));
            if ($job->{state} eq "COMPLETED" and
                $runtimepercent < $shortjobpercent and
                $job->{notifyshortjob}) {
                $notify = 1;
                $job->{runtimepercent} = round($runtimepercent);
                $job->{shortjobpercent} = $shortjobpercent;
                $job->{shortjobnotify} = 1;
            }
        }
        print "old job: ".Dumper($job) if $debug;
        if ($notify) {
            $job->{recipients} = [@recipients];
            if ($config->{notificationreplyto}) {
                $job->{replyto} = $config->{notificationreplyto};
            }
            if ($config->{notificationbcc}) {
                $job->{recipientsbcc} = [map {$_ =~ s/^\s*|\s*$//g; $_} split /,/, $config->{notificationbcc}];
            }
            $ENV{SLURM_RESOURCE_MONITOR_DATA} = Data::Dumper->Dump([$job], [qw(job)]);
            system($config->{notificationscript});
            delete $ENV{SLURM_RESOURCE_MONITOR_DATA};
        }
        print "Removing job $job->{jobid}".($notify ? " (notified)" : "")."\n";
    }
}

################################################################################
# gpu_utilization
################################################################################
sub gpu_utilization {

    # get the load
    my $stamp = time;
    my @load = `nvidia-smi --query-gpu=utilization.gpu --format=csv,nounits,noheader`;
    if ($!) {
        print STDERR "Can't get gpu information\n";
        exit 5;
    }
    chomp(@load);

    foreach my $job (values %stats) {
        next unless $states{sample}{$job->{state}};
        $job->{gpus}{firststamp} = $stamp unless exists $job->{gpus}{firststamp};
        $job->{gpus}{laststamp} = $stamp;

        # calculate and save the load
        my $totalusage = 0;
        my $good = 0;
        foreach my $gpu (keys %{$job->{gpus}{data}}) {
            $job->{gpus}{data}{$gpu}{load} = $load[$gpu];
            $good++ if (100 * $load[$gpu]) > $inusegpupercent;
        }
        $job->{gpus}{usage}{$good}++;
        $job->{gpus}{samples}++;
    }
}

################################################################################
# cpu_load
################################################################################
sub cpu_utilization {
    foreach my $job (values %stats) {
        next unless $states{sample}{$job->{state}};

        # fill cpus data if missing
        unless ($job->{cpus}{data}) {
            my @cpus;
            if (open(CPUS, "</sys/fs/cgroup/cpuset/slurm/uid_$job->{uid}/job_$job->{jobid}/cpuset.cpus")) {
                my $cpus = <CPUS>;
                close(CPUS);
                chomp($cpus);
                foreach my $c (split /,/, $cpus) {
                    if ($c =~ m/(.*)-(.*)/) {
                        push @cpus, ($1 .. $2);
                    } else {
                        push @cpus, $c;
                    }
                }
            } else {
                print STDERR "Can't get cpus for job $job->{jobid}\n";
                next;
            }
            if (@cpus) {
                if (scalar(@cpus) != $job->{cpus}{count}) {
                    print STDERR "Wrong number of CPUs for job $job->{jobid}\n";
                    next;
                }
                $job->{cpus}{data} = {map {$_ => {}} @cpus};
            } else {
                print STDERR "Can't get cpus from cpuset.cpus for job $job->{jobid}\n";
                next;
            }
        }

        # get the utilization
        my @utilization;
        my $stamp = time;
        if (open(USAGE, "</sys/fs/cgroup/cpu,cpuacct/slurm/uid_$job->{uid}/job_$job->{jobid}/cpuacct.usage_percpu")) {
            @utilization = (split / /, <USAGE>);
            close(USAGE);
            $stamp = int(($stamp + time) / 2);
        } else {
            print STDERR "Can't get cpuacct from cpuacct.usage_percpu for job $job->{jobid}\n";
            next;
        }
        $job->{cpus}{firststamp} = $stamp unless exists $job->{cpus}{firststamp};

        # calculate and save the load
        my $totalusage = 0;
        if ($job->{cpus}{laststamp}) {
            my $good = 0;
            foreach my $cpu (keys %{$job->{cpus}{data}}) {
                my $load = ($utilization[$cpu] - $job->{cpus}{data}{$cpu}{lastread});
                $load = $load / ($stamp - $job->{cpus}{laststamp}) / 1000000000;
                $job->{cpus}{data}{$cpu}{load} = $load;
                $good++ if (100 * $load) > $inusecpupercent;
                $totalusage += $load;
            }
            $totalusage = $totalusage / $job->{cpus}{count};
            $job->{cpus}{lastload} = $totalusage;
            $job->{cpus}{usage}{$good}++;
            $job->{cpus}{samples}++;
        }
        foreach my $cpu (keys %{$job->{cpus}{data}}) {
            $job->{cpus}{data}{$cpu}{lastread} = $utilization[$cpu];
        }
        $job->{cpus}{laststamp} = $stamp;
    }
}

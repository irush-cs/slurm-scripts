#!/usr/bin/env perl

################################################################################
#
#   slurm-resource-monitor.pl
#
#   Copyright (C) 2019-2020 Hebrew University of Jerusalem Israel, see LICENSE
#   file.
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

use POSIX qw(round WNOHANG);
use File::Find;
use List::Util qw(none any);
use Data::Dumper;
use Getopt::Long;
use Sys::Hostname;
use Time::ParseDate;
use File::Path qw(make_path remove_tree);
use JSON;

$Data::Dumper::Sortkeys = 1;

################################################################################
# Some variables
################################################################################
my $samplinginterval = 60;
my $hostname = hostname;
my $havegpus = 0;
my $verbose = 0;
my $debug = 0;
my $minruntime = 60 * 30;
my $unusedtimepercent = 15;
my $notifyunusedtime = 1;
my $forcenotify = 0;
my %notifyunused = (cpus => 1,
                    gpus => 1,
                    memory => 1,
                   );
my %notifyhistory = (cpus => 1,
                     gpus => 1,
                     memory => 1,
                    );
my $minmonitoredpercent = 75;
my $runtimedir = $ENV{RUNTIME_DIRECTORY} // "/run/slurm-resource-monitor";
my $notifyinteractive = 0;
my $maxarraytaskid = 10;
my $deletedata = 1;

# current monitored jobs
# jobid => {uid, login, jobid, state, cpus => {}, gpus => {}}
# cpus, gpus hashes:
#   data => {<id> => {}} - resource specific data
#   usage   - usage historgram (#resources => #samples)
#   gooduse - number of samples with "good" usage (unused <= allowedunused{count})
#   baduse  - number of samples with "bad" usage (unused > allowedunused{count})
#   samples - number of samples
#   count   - number of resources
#   history - array of histories [stamp, data]

my %stats; 

# old jobs, already reported
my %oldjobs; 

# count as in-use threshold
my $inusecpupercent = 5;
my $inusegpupercent = 15;

my $minsamples = 10;

# allow unused <count> <resource>s for at most <percent>% of the time.
my %allowedunused = (cpus => {count => 2,
                              percent => 75},
                     gpus => {count => 1,
                              percent => 25},
                     memory => {percent => 25,
                                ignore => 1024,
                               },
                    );

# states:
#   report  => send mail,
#   sample => sample usage
#   ignore  => don't say you don't know it
#   all     => list of all known
my %states = (report => {"COMPLETED" => 1,
                         "TIMEOUT" => 1,
                         "FAILED" => 1,
                         "OUT_OF_MEMORY" => 1,
                        },
              sample => {"RUNNING" => 1,
                        },
              ignore => {"COMPLETING" => 1,
                         "CANCELLED" => 1,
                         "CONFIGURING" => 1,
                         "PREEMPTED" => 1,
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

sub sigCHLD {
    while (waitpid(-1 , WNOHANG) > 0) {};
    $SIG{CHLD} = \&sigCHLD;
}

$SIG{CHLD} = \&sigCHLD;

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
$deletedata = 0 if $debug;

################################################################################
# get configuration
################################################################################

my $slurm_config = cshuji::Slurm::get_config();
unless ($slurm_config) {
    print STDERR "Can't get slurm config\n";
    exit 6;
}
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

if ($conffile !~ m/^\//) {
    $conffile = getcwd."/$conffile";
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

sub to_int {
    my $value = shift;
    my $default = shift;

    return $default unless defined $value;

    if ($value =~ m/^\d+$/) {
        return $value;
    }
    return $default;
}

sub to_percent {
    my $value = shift;
    my $default = shift;

    return $default unless defined $value;

    if ($value =~ m/^\d+$/ and $value >= 0 and $value <= 100) {
        return $value;
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
            } elsif ($type eq "dir") {
                unless (-d "$new") {
                    print STDERR "Bad directory: $name is not a directory ($new)\n";
                    exit 13;
                }
            } else {
                print STDERR "Bad configuration type: \"$type\"\n";
                exit 12;
            }
            print "Updating $name: $temp -> $$var\n" if $verbose and $temp ne $$var;
        }
    }

    _update_setting(\$notifyunusedtime, $config->{notifyunusedtime}, "bool", "NotifyUnusedTime");
    _update_setting(\$notifyunused{cpus}, $config->{notifyunusedcpus}, "bool", "NotifyUnusedCPUs");
    _update_setting(\$notifyunused{gpus}, $config->{notifyunusedgpus}, "bool", "NotifyUnusedGPUs");
    _update_setting(\$notifyunused{memory}, $config->{notifyunusedmemory}, "bool", "NotifyUnusedMemory");
    _update_setting(\$notifyhistory{cpus}, $config->{notifycpugraph}, "bool", "NotifyCPUGraph");
    _update_setting(\$notifyhistory{gpus}, $config->{notifygpugraph}, "bool", "NotifyGPUGraph");
    _update_setting(\$notifyhistory{memory}, $config->{notifymemorygraph}, "bool", "NotifyMemoryGraph");
    _update_setting(\$notifyinteractive, $config->{notifyinteractive}, "bool", "NotifyInteractive");
    _update_setting(\$maxarraytaskid, $config->{maxarraytaskid}, "int", "MaxArrayTaskId");
    _update_setting(\$forcenotify, $config->{forcenotify}, "bool", "ForceNotify");

    _update_setting(\$inusecpupercent, $config->{inusecpupercent}, "percent", "InUseCPUPercent");
    _update_setting(\$inusegpupercent, $config->{inusegpupercent}, "percent", "InUseGPUPercent");

    _update_setting(\$allowedunused{cpus}{count}, $config->{allowedunusedcpus}, "int", "AllowedUnusedCPUs");
    _update_setting(\$allowedunused{cpus}{percent}, $config->{allowedunusedcpupercent}, "percent", "AllowedUnusedCPUPercent");
    _update_setting(\$allowedunused{gpus}{count}, $config->{allowedunusedgpus}, "int", "AllowedUnusedGPUs");
    _update_setting(\$allowedunused{gpus}{percent}, $config->{allowedunusedgpupercent}, "percent", "AllowedUnusedGPUPercent");
    _update_setting(\$allowedunused{memory}{percent}, $config->{allowedunusedmemorypercent}, "percent", "AllowedUnusedMemoryPercent");
    _update_setting(\$allowedunused{memory}{ignore}, $config->{maxignoreunusedmemory}, "int", "MaxIgnoreUnusedMemory");

    _update_setting(\$minmonitoredpercent, $config->{minmonitoredpercent}, "percent", "MinMonitoredPercent");

    _update_setting(\$samplinginterval, $config->{samplinginterval}, "int", "SamplingInterval");
    if ($samplinginterval < 1) {
        print STDERR "Bad configuration: SamplingInterval should be > 0\n";
        exit 14;
    }

    _update_setting(\$minsamples, $config->{minsamples}, "int", "MinSamples");

    _update_setting(\$conf_update_check_interval, $config->{confupdatecheckinterval}, "int", "ConfUpdateCheckInterval");

    _update_setting(\$minruntime, $config->{minruntime}, "int", "MinRunTime");

    _update_setting(\$unusedtimepercent, $config->{unusedtimepercent}, "percent", "UnusedTimePercent");

    _update_setting(\$runtimedir, $config->{runtimedir}, "dir", "RuntimeDir");

    _update_setting(\$deletedata, $config->{deletedata}, "bool", "DeleteData");

    unless (chdir($runtimedir)) {
        print STDERR "Can't chdir to $runtimedir: $!\n";
        exit 14;
    }

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
        if (not $new_conf_update and $!) {
            print STDERR "Can't read configuration from $conffile: $!\n";
            exit 40;
        }
        if ($new_conf_update != $conf_last_update) {
            read_conf();
        }
    }
    print "current jobs: ".join(", ", map {"$_/$stats{$_}{state}"} sort keys %stats)."\n" if $verbose;
    get_new_jobs();
    clean_old();
    gpu_utilization() if $havegpus;
    memory_utilization();
    cpu_utilization();
    runtime_utilization();

    foreach my $job (values %stats) {
        unless ($states{all}{$job->{state}} ){
            print STDERR "Unknown state $job->{state} for job $job->{jobid}\n";
            exit 4;
        }
    }
    sleep $samplinginterval;
}

exit 0;

################################################################################
# get_new_jobs
################################################################################
sub get_new_jobs {
    # mark old jobs to capture missing jobs.
    foreach my $old (values %stats) {
        $old->{old} = 1;
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
                my $mem = 0;
                foreach my $detail (@{$job->{_DETAILS}}) {
                    next if (none {$hostname eq $_} @{$detail->{_NodeList}});
                    push @$cpus, @{$detail->{_CPUs}};
                    push @$gpus, @{$detail->{_GRESs}{gpu} // []};
                    $mem += $detail->{Mem};
                }
                $gpus = {map {$_ => {}} @$gpus};
                $cpus = {map {$_ => {}} @$cpus};
                # slurm has weird cpu mapping, so we'll make it later from cgroup
                my $jobstat = {jobid => $job->{JobId},
                               uid     => $job->{UserId} =~ m/\((.*)\)/,
                               login   => $job->{UserId} =~ m/^([^(]*)\(/,
                               cpus    => {                  samples => 0, count => scalar(keys %$cpus), gooduse => 0, baduse => 0},
                               gpus    => {data => {%$gpus}, samples => 0, count => scalar(keys %$gpus), gooduse => 0, baduse => 0},
                               memory  => {                  samples => 0, count => $mem},
                               running => {                  samples => 0},
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
                $uconfig->{notifyunusedtime} = to_bool($uconfig->{notifyunusedtime}, $notifyunusedtime);
                $uconfig->{notifyunusedgpus} = to_bool($uconfig->{notifyunusedgpus}, $notifyunused{gpus});
                $uconfig->{notifyunusedcpus} = to_bool($uconfig->{notifyunusedcpus}, $notifyunused{cpus});
                $uconfig->{notifyunusedmemory} = to_bool($uconfig->{notifyunusedmemory}, $notifyunused{memory});
                $uconfig->{notifyinteractive} = to_bool($uconfig->{notifyinteractive}, $notifyinteractive);
                $uconfig->{allowedunusedcpus} = to_int($uconfig->{allowedunusedcpus}, $allowedunused{cpus}{count});
                $uconfig->{allowedunusedgpus} = to_int($uconfig->{allowedunusedgpus}, $allowedunused{gpus}{count});
                $uconfig->{allowedunusedcpupercent} = to_percent($uconfig->{allowedunusedcpupercent}, $allowedunused{cpus}{percent});
                $uconfig->{allowedunusedgpupercent} = to_percent($uconfig->{allowedunusedgpupercent}, $allowedunused{gpus}{percent});
                $uconfig->{allowedunusedmemorypercent} = to_percent($uconfig->{allowedunusedmemorypercent}, $allowedunused{memory}{percent});
                $uconfig->{maxarraytaskid} = to_int($uconfig->{maxarraytaskid}, $maxarraytaskid);
                $uconfig->{maxignoreunusedmemory} = to_int($uconfig->{maxignoreunusedmemory}, $allowedunused{memory}{ignore});
                $uconfig->{forcenotify} = to_bool($uconfig->{forcenotify}, $forcenotify);

                $jobstat->{notifyunusedtime} = $uconfig->{notifyunusedtime};
                $jobstat->{gpus}{notifyunused} = $uconfig->{notifyunusedgpus};
                $jobstat->{cpus}{notifyunused} = $uconfig->{notifyunusedcpus};
                $jobstat->{memory}{notifyunused} = $uconfig->{notifyunusedmemory};
                $jobstat->{cpus}{allowedunused} = {count => $uconfig->{allowedunusedcpus}, percent => $uconfig->{allowedunusedcpupercent}};
                $jobstat->{gpus}{allowedunused} = {count => $uconfig->{allowedunusedgpus}, percent => $uconfig->{allowedunusedgpupercent}};
                $jobstat->{memory}{allowedunused} = {percent => $uconfig->{allowedunusedmemorypercent}, ignore => $uconfig->{maxignoreunusedmemory}};
                $jobstat->{cpus}{history} = [] if $notifyhistory{cpus};
                $jobstat->{gpus}{history} = [] if $notifyhistory{gpus};
                $jobstat->{memory}{history} = [] if $notifyhistory{memory};

                $jobstat->{firststamp} = $stamp;
                $jobstat->{runtimedir} = "${runtimedir}/$jobstat->{jobid}/";

                $jobstat->{batch} = $job->{BatchFlag};
                $jobstat->{arraytaskid} = $job->{ArrayTaskId};
                $jobstat->{notifyinteractive} = $uconfig->{notifyinteractive};
                $jobstat->{maxarraytaskid} = $uconfig->{maxarraytaskid};
                $jobstat->{forcenotify} = $uconfig->{forcenotify};

                $stats{$job->{JobId}} = $jobstat;
                unless (exists $oldjobs{$job->{JobId}}) {
                    print "New job $jobstat->{jobid}: cpus: $jobstat->{cpus}{count}, gpus: $jobstat->{gpus}{count}, memory: $jobstat->{memory}{count}, state: $job->{JobState}\n";
                }
            }
            $stats{$job->{JobId}}{state} = $job->{JobState};
            $stats{$job->{JobId}}{runtime} = $job->{RunTime};
            $stats{$job->{JobId}}{timelimit} = $job->{TimeLimit};
            $stats{$job->{JobId}}{laststamp} = $stamp;
            $stats{$job->{JobId}}{starttime} = $job->{StartTime};
            $stats{$job->{JobId}}{endtime} = $job->{EndTime};
            $stats{$job->{JobId}}{submittime} = $job->{SubmitTime};
            $stats{$job->{JobId}}{old} = 0;
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

    # delete requeued jobs (this will drop first sample, but who cares...)
    my @todelete;
    foreach my $job (keys %stats) {
        my $start = parsedate($stats{$job}{starttime});
        my $first = $stats{$job}{firststamp};
        if ($start and $first and $first < $start) {
            push @todelete, $job;
        }
    }
    if (@todelete) {
        delete @stats{@todelete};
        delete @oldjobs{@todelete};
        print "Removing requeued jobs: ".join(", ", @todelete)."\n";
    }
}

################################################################################
# clean_old
################################################################################
sub clean_old {
    my @old = map {$_->{jobid}} grep {$states{report}{$_->{state}}} values %stats;
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
        if ($runtime >= $minruntime
            and $job->{laststamp} - $job->{firststamp} >= $minruntime
            and (100 * ($job->{laststamp} - $job->{firststamp}) / $runtime) >= $minmonitoredpercent
            and ($job->{batch} or $job->{notifyinteractive})
            and (not defined $job->{arraytaskid} or $job->{arraytaskid} <= $job->{maxarraytaskid})
           ) {
            foreach my $res ("cpus", "gpus") {
                $job->{$res}{baduse} = 0;
                $job->{$res}{gooduse} = 0;
                foreach my $count (keys %{$job->{$res}{usage}}) {
                    if ($job->{$res}{count} - $count > $job->{$res}{allowedunused}{count}) {
                        $job->{$res}{baduse} += $job->{$res}{usage}{$count};
                    } else {
                        $job->{$res}{gooduse} += $job->{$res}{usage}{$count};
                    }
                }
                if ($job->{forcenotify} or
                    ($job->{$res}{notifyunused} and $job->{$res}{samples} and $job->{$res}{samples} >= $minsamples)) {
                    if ($job->{forcenotify} or
                        $job->{$res}{samples} * ($job->{$res}{allowedunused}{percent} / 100) < $job->{$res}{baduse}) {
                        $job->{$res}{notify} = 1;
                        $notify = 1;
                        if ($notifyhistory{$res} and @{$job->{$res}{history}}) {
                            make_path("$job->{runtimedir}");
                            unless (-d $job->{runtimedir}) {
                                print STDERR "Can't create $job->{runtimedir}\n";
                                exit 21;
                            }
                            unless (open(RUNTIME, ">$job->{runtimedir}/$res")) {
                                print STDERR "Can't save $res history: $!\n";
                                exit 22;
                            }
                            foreach my $h (@{$job->{$res}{history}}) {
                                print RUNTIME "$h->[0],$h->[1]\n";
                            }
                            close(RUNTIME);
                            $job->{$res}{notifyhistory} = 1;
                        }
                    }
                }
            }

            my $runtimepercent = (100 * ($runtime / $timelimit));
            if ($job->{forcenotify} or
                ($job->{state} and ($job->{state} eq "COMPLETED")
                 and $runtimepercent < $unusedtimepercent
                 and $job->{notifyunusedtime}
                 and $job->{running}{samples} >= $minsamples
                )) {
                $notify = 1;
                $job->{runtimepercent} = round($runtimepercent);
                $job->{unusedtimepercent} = $unusedtimepercent;
                $job->{unusedtimenotify} = 1;
            }

            if ($job->{forcenotify} or
                ($job->{memory}{notifyunused}
                 and $job->{memory}{samples}
                 and $job->{memory}{samples} >= $minsamples
                 and $job->{memory}{count} * ((100 - $job->{memory}{allowedunused}{percent}) / 100) > $job->{memory}{max_usage}
                 and ($job->{memory}{count} - $job->{memory}{max_usage}) > $job->{memory}{allowedunused}{ignore}
                )) {
                $job->{memory}{notify} = 1;
                $notify = 1;
                if ($notifyhistory{memory} and @{$job->{memory}{history}}) {
                    make_path("$job->{runtimedir}");
                    unless (-d $job->{runtimedir}) {
                        print STDERR "Can't create $job->{runtimedir}\n";
                        exit 21;
                    }
                    unless (open(RUNTIME, ">$job->{runtimedir}/memory")) {
                        print STDERR "Can't save memory history: $!\n";
                        exit 22;
                    }
                    foreach my $h (@{$job->{memory}{history}}) {
                        print RUNTIME "$h->[0],$h->[1]\n";
                    }
                    close(RUNTIME);
                    $job->{memory}{notifyhistory} = 1;
                }
            }
        }
        if ($notify) {
            $job->{recipients} = [@recipients];
            if ($config->{notificationreplyto}) {
                $job->{replyto} = $config->{notificationreplyto};
            }
            if ($config->{notificationbcc}) {
                $job->{recipientsbcc} = [map {$_ =~ s/^\s*|\s*$//g; $_} split /,/, $config->{notificationbcc}];
            }

            # save data in json
            delete $job->{cpus}{history};
            delete $job->{gpus}{history};
            delete $job->{memory}{history};
            make_path("$job->{runtimedir}");
            unless (-d $job->{runtimedir}) {
                print STDERR "Can't create $job->{runtimedir}\n";
                exit 23;
            }
            unless (open(RUNTIME, ">$job->{runtimedir}/data")) {
                print STDERR "Can't save job data: $!\n";
                exit 24;
            }
            my $json = JSON->new;
            $json = $json->pretty if $debug;
            print RUNTIME $json->encode($job);
            close(RUNTIME);

            # fork
            my $pid = fork();
            unless (defined $pid) {
                print STDERR "fork() failed: $!\n";
                exit 20;
            }
            unless ($pid) {
                # child
                local $SIG{CHLD} = 'DEFAULT';
                my $exit = system($config->{notificationscript}, "$job->{runtimedir}/data");
                remove_tree("$job->{runtimedir}") if $deletedata;
                exit $exit >> 8;
            }
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

    local $SIG{CHLD} = 'DEFAULT';
    my @load = `nvidia-smi --query-gpu=utilization.gpu --format=csv,nounits,noheader`;
    $SIG{CHLD} = \&sigCHLD;

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
        if ($notifyhistory{gpus}) {
            push @{$job->{gpus}{history}}, [$stamp, $good];
        }
    }
}

################################################################################
# cpu_utilization
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
        if ($job->{cpus}{laststamp} and $job->{cpus}{laststamp} != $stamp) {
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
            if ($notifyhistory{cpus}) {
                push @{$job->{cpus}{history}}, [$stamp, $good];
            }
        }
        foreach my $cpu (keys %{$job->{cpus}{data}}) {
            $job->{cpus}{data}{$cpu}{lastread} = $utilization[$cpu];
        }
        $job->{cpus}{laststamp} = $stamp;
    }
}


################################################################################
# memory_utilization
################################################################################
sub memory_utilization {
    foreach my $job (values %stats) {
        next unless $states{sample}{$job->{state}};

        # get the utilization
        my $usage;
        my $max_usage;
        my $stamp = time;
        if ($notifyhistory{memory}) {
            if (open(USAGE, "</sys/fs/cgroup/memory/slurm/uid_$job->{uid}/job_$job->{jobid}/memory.usage_in_bytes")) {
                $usage = <USAGE>;
                close(USAGE);
                chomp($usage);
            } else {
                print STDERR "Can't get memory.usage_in_bytes from memory cgroup for job $job->{jobid}\n";
                next;
            }
            $usage = round($usage / (1024 * 1024));
        }
        if (open(USAGE, "</sys/fs/cgroup/memory/slurm/uid_$job->{uid}/job_$job->{jobid}/memory.max_usage_in_bytes")) {
            $max_usage = <USAGE>;
            close(USAGE);
            chomp($max_usage);
        } else {
            print STDERR "Can't get memory.max_usage_in_bytes from memory cgroup for job $job->{jobid}\n";
            next;
        }
        $max_usage = round($max_usage / (1024 * 1024));
        $job->{memory}{firststamp} = $stamp unless exists $job->{memory}{firststamp};
        $job->{memory}{laststamp} = $stamp;

        # calculate and save the load
        $job->{memory}{samples}++;
        $job->{memory}{max_usage} = $max_usage;
        if ($notifyhistory{memory}) {
            push @{$job->{memory}{history}}, [$stamp, $usage];
        }
    }
}

################################################################################
# runtime_utilization
################################################################################
sub runtime_utilization {
    # we're only doing this to avoid notify twice about runtime of a job. As
    # reastarting the monitor deamon will show COMPLETED jobs for a while, we
    # want to make sure we've sampled them while RUNNING.
    foreach my $job (values %stats) {
        next unless $states{sample}{$job->{state}};
        next unless $job->{state} eq "RUNNING";
        $job->{running}{samples}++;
    }
}

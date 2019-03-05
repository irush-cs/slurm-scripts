#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp;

use cshuji::Slurm qw(parse_conf);

my $conf = "
# man slurm.conf

ClusterName=phoenix
ControlMachine=slurmctl-01
#ControlAddr=
BackupController=slurmctl-02
#BackupAddr=

SlurmUser=slurm
#SlurmdUser=root
SlurmctldPort=6838
SlurmdPort=6818
AuthType=auth/munge
CryptoType=crypto/munge
StateSaveLocation=/vol/slurm/phoenix/state
SlurmdSpoolDir=/var/spool/slurmd
SwitchType=switch/none
MpiDefault=none
MpiParams=ports=12001-12999
SlurmctldPidFile=/var/run/slurmctld-phoenix.pid
# can have \%h and \%n
SlurmdPidFile=/var/run/slurmd-phoenix.pid
#ProctrackType=proctrack/pgid
ProctrackType=proctrack/cgroup
#PluginDir=/usr/local/slurm/2.5.0.0-rc1/lib/slurm
CacheGroups=0
#FirstJobId=
ReturnToService=2
MaxJobCount=50000
MaxArraySize=5001
PlugStackConfig=/etc/slurm/plugstack.conf
#PropagatePrioProcess=
#PropagateResourceLimits=
PropagateResourceLimitsExcept=ALL
TaskPlugin=task/cgroup
#TaskPluginParam=Cpusets
#TaskPluginParam=Cores
#TrackWCKey=no
#TreeWidth=50
#TmpFs=
# slurm service
UsePAM=yes
#MailProg=/usr/bin/mail
MailProg=/vol/slurm/common/mail.sh
GroupUpdateForce=1
#RebootProgram=\"/sbin/shutdown -r now\"
#VSizeFactor=1
DisableRootJobs=1
JobSubmitPlugins=job_submit/valid_partitions,job_submit/limit_interactive,job_submit/killable

# SCRIPTS
#Prolog=/vol/slurm/phoenix/scripts/Prolog
#Epilog=
#SrunProlog=
#SrunEpilog=
TaskProlog=/etc/slurm/proepilogs/TaskPrologs.sh
#TaskEpilog=
UnkillableStepProgram=/etc/slurm/unkillable-program.sh
HealthCheckInterval=10800
HealthCheckNodeState=CYCLE,ANY
HealthCheckProgram=/etc/slurm/healthcheck.sh

# TIMERS
SlurmctldTimeout=120
SlurmdTimeout=300
# check this
InactiveLimit=0
MinJobAge=300
KillWait=30
Waittime=0
#MessageTimeout=10
MessageTimeout=30
UnkillableStepTimeout=300
BatchStartTimeout=20

# SCHEDULING
SchedulerType=sched/backfill
#SchedulerAuth=
#SchedulerPort=
#SchedulerRootFilter=
SelectType=select/cons_res
#SelectType=select/linear
#SelectTypeParameters=CR_CPU_Memory
SelectTypeParameters=CR_Core_Memory
#SelectTypeParameters=CR_Memory
DefMemPerCPU=50
# 2 peta
MaxMemPerCPU=2097152
#MaxMemPerNode=2097152
FastSchedule=0
PriorityType=priority/multifactor
#PriorityFlags=TICKET_BASED
#PriorityDecayHalfLife=14-0
#PriorityUsageResetPeriod=14-0
PriorityWeightFairshare=1000000
PriorityWeightAge=10000
PriorityWeightQOS=10000000
FairShareDampeningFactor=5
#PriorityWeightPartition=10000
#PriorityWeightJobSize=1000
#PriorityMaxAge=1-0
PreemptMode=REQUEUE
PreemptType=preempt/qos
GresTypes=gpu
JobRequeue=0
SchedulerParameters=bf_window=30300

# LOGGING
#SlurmctldDebug=debug5
SlurmctldDebug=debug
SlurmctldLogFile=/var/log/slurmctld-phoenix.log
#SlurmdDebug=info
#SlurmdDebug=debug5
SlurmdLogFile=/vol/slurm/phoenix/logs/slurmd-\%h.log
SlurmdSyslogDebug=info
SlurmctldSyslogDebug=info

JobCompType=jobcomp/none
#JobCompLoc=


# ACCOUNTING
#JobAcctGatherType=jobacct_gather/linux
JobAcctGatherType=jobacct_gather/cgroup
JobAcctGatherFrequency=30
#
AccountingStorageType=accounting_storage/slurmdbd
#AccountingStorageType=accounting_storage/mysql
AccountingStorageHost=slurm-db
#AccountingStorageBackupHost=slurm-db2
#AccountingStorageLoc=
#AccountingStoragePass=
#AccountingStorageUser=
#
AccountingStorageEnforce=associations,limits,safe,qos
#AccountingStoragePort
#AccountingStoreJobComment
#
#AcctGatherNodeFreq
#AcctGatherEnergyType
AccountingStorageTres=gres/gpu,license/interactive
Licenses=interactive:5000

# COMPUTE NODES
NodeName=DEFAULT State=\"UNKNOWN\" MemSpecLimit=1024

# weight - will take the lower which meet constraints
NodeName=sulfur-[01-16]            Feature=sulfur   Sockets=2 CoresPerSocket=4  ThreadsPerCore=1 RealMemory=63409                      Weight=2
NodeName=cb-[05-20]                Feature=cb       Sockets=2 CoresPerSocket=4  ThreadsPerCore=2 RealMemory=64358                      Weight=3
NodeName=eye-[01-04]               Feature=eye      Sockets=2 CoresPerSocket=8  ThreadsPerCore=1 RealMemory=193391                     Weight=4
NodeName=oxygen-[01-08]            Features=oxygen  Sockets=2 CoresPerSocket=12 ThreadsPerCore=2 RealMemory=257855                     Weight=5
NodeName=cortex-[01-05]            Feature=cortex   Sockets=2 CoresPerSocket=8  ThreadsPerCore=1 RealMemory=257860 Gres=gpu:m60:8      Weight=8
NodeName=dumfries-[001-002]        Feature=dumfries Sockets=2 CoresPerSocket=8  ThreadsPerCore=2 RealMemory=128586 Gres=gpu:rtx2080:4  Weight=9

# State=DRAIN Reason=setup

# PriorityTier - higher is heigher priority
PartitionName=short    Nodes=eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08],cortex-[01-08],dumfries-[001-002] Shared=NO Default=YES MaxTime=2-0  DefaultTime=2:0:0 PriorityTier=2 DenyAccounts=killable-cs
PartitionName=medium   Nodes=eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08],cortex-[03-08],dumfries-[001-002] Shared=NO Default=YES MaxTime=7-0  DefaultTime=2:0:0 PriorityTier=2 DenyAccounts=killable-cs
PartitionName=long     Nodes=eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08]                                   Shared=NO Default=YES MaxTime=21-0 DefaultTime=2:0:0 PriorityTier=2 DenyAccounts=killable-cs
PartitionName=killable Nodes=ALL                                                                                   Shared=NO Default=YES MaxTime=21-0 DefaultTime=2:0:0 PriorityTier=1 AllowAccounts=killable-cs
";

my %conf = (
            'AccountingStorageEnforce' => 'associations,limits,safe,qos',
            'AccountingStorageHost' => 'slurm-db',
            'AccountingStorageTres' => 'gres/gpu,license/interactive',
            'AccountingStorageType' => 'accounting_storage/slurmdbd',
            'AuthType' => 'auth/munge',
            'BackupController' => 'slurmctl-02',
            'BatchStartTimeout' => '20',
            'CacheGroups' => '0',
            'ClusterName' => 'phoenix',
            'ControlMachine' => 'slurmctl-01',
            'CryptoType' => 'crypto/munge',
            'DefMemPerCPU' => '50',
            'DisableRootJobs' => '1',
            'FairShareDampeningFactor' => '5',
            'FastSchedule' => '0',
            'GresTypes' => 'gpu',
            'GroupUpdateForce' => '1',
            'HealthCheckInterval' => '10800',
            'HealthCheckNodeState' => 'CYCLE,ANY',
            'HealthCheckProgram' => '/etc/slurm/healthcheck.sh',
            'InactiveLimit' => '0',
            'JobAcctGatherFrequency' => '30',
            'JobAcctGatherType' => 'jobacct_gather/cgroup',
            'JobCompType' => 'jobcomp/none',
            'JobRequeue' => '0',
            'JobSubmitPlugins' => 'job_submit/valid_partitions,job_submit/limit_interactive,job_submit/killable',
            'KillWait' => '30',
            'Licenses' => 'interactive:5000',
            'MailProg' => '/vol/slurm/common/mail.sh',
            'MaxArraySize' => '5001',
            'MaxJobCount' => '50000',
            'MaxMemPerCPU' => '2097152',
            'MessageTimeout' => '30',
            'MinJobAge' => '300',
            'MpiDefault' => 'none',
            'MpiParams' => 'ports=12001-12999',
            'NodeName' => {
                           'DEFAULT' => {
                                         'MemSpecLimit' => '1024',
                                         'NodeName' => 'DEFAULT',
                                         'State' => '"UNKNOWN"',
                                         'memspeclimit' => '1024',
                                         'nodename' => 'DEFAULT',
                                         'state' => '"UNKNOWN"'
                                        },
                           'cb-[05-20]' => {
                                            'CoresPerSocket' => '4',
                                            'Feature' => 'cb',
                                            'NodeName' => 'cb-[05-20]',
                                            'RealMemory' => '64358',
                                            'Sockets' => '2',
                                            'ThreadsPerCore' => '2',
                                            'Weight' => '3',
                                            'corespersocket' => '4',
                                            'feature' => 'cb',
                                            'nodename' => 'cb-[05-20]',
                                            'realmemory' => '64358',
                                            'sockets' => '2',
                                            'threadspercore' => '2',
                                            'weight' => '3'
                                           },
                           'cortex-[01-05]' => {
                                                'CoresPerSocket' => '8',
                                                'Feature' => 'cortex',
                                                'Gres' => 'gpu:m60:8',
                                                'NodeName' => 'cortex-[01-05]',
                                                'RealMemory' => '257860',
                                                'Sockets' => '2',
                                                'ThreadsPerCore' => '1',
                                                'Weight' => '8',
                                                'corespersocket' => '8',
                                                'feature' => 'cortex',
                                                'gres' => 'gpu:m60:8',
                                                'nodename' => 'cortex-[01-05]',
                                                'realmemory' => '257860',
                                                'sockets' => '2',
                                                'threadspercore' => '1',
                                                'weight' => '8'
                                               },
                           'dumfries-[001-002]' => {
                                                    'CoresPerSocket' => '8',
                                                    'Feature' => 'dumfries',
                                                    'Gres' => 'gpu:rtx2080:4',
                                                    'NodeName' => 'dumfries-[001-002]',
                                                    'RealMemory' => '128586',
                                                    'Sockets' => '2',
                                                    'ThreadsPerCore' => '2',
                                                    'Weight' => '9',
                                                    'corespersocket' => '8',
                                                    'feature' => 'dumfries',
                                                    'gres' => 'gpu:rtx2080:4',
                                                    'nodename' => 'dumfries-[001-002]',
                                                    'realmemory' => '128586',
                                                    'sockets' => '2',
                                                    'threadspercore' => '2',
                                                    'weight' => '9'
                                                   },
                           'eye-[01-04]' => {
                                             'CoresPerSocket' => '8',
                                             'Feature' => 'eye',
                                             'NodeName' => 'eye-[01-04]',
                                             'RealMemory' => '193391',
                                             'Sockets' => '2',
                                             'ThreadsPerCore' => '1',
                                             'Weight' => '4',
                                             'corespersocket' => '8',
                                             'feature' => 'eye',
                                             'nodename' => 'eye-[01-04]',
                                             'realmemory' => '193391',
                                             'sockets' => '2',
                                             'threadspercore' => '1',
                                             'weight' => '4'
                                            },
                           'oxygen-[01-08]' => {
                                                'CoresPerSocket' => '12',
                                                'Features' => 'oxygen',
                                                'NodeName' => 'oxygen-[01-08]',
                                                'RealMemory' => '257855',
                                                'Sockets' => '2',
                                                'ThreadsPerCore' => '2',
                                                'Weight' => '5',
                                                'corespersocket' => '12',
                                                'features' => 'oxygen',
                                                'nodename' => 'oxygen-[01-08]',
                                                'realmemory' => '257855',
                                                'sockets' => '2',
                                                'threadspercore' => '2',
                                                'weight' => '5'
                                               },
                           'sulfur-[01-16]' => {
                                                'CoresPerSocket' => '4',
                                                'Feature' => 'sulfur',
                                                'NodeName' => 'sulfur-[01-16]',
                                                'RealMemory' => '63409',
                                                'Sockets' => '2',
                                                'ThreadsPerCore' => '1',
                                                'Weight' => '2',
                                                'corespersocket' => '4',
                                                'feature' => 'sulfur',
                                                'nodename' => 'sulfur-[01-16]',
                                                'realmemory' => '63409',
                                                'sockets' => '2',
                                                'threadspercore' => '1',
                                                'weight' => '2'
                                               }
                          },
            'PartitionName' => {
                                'killable' => {
                                               'AllowAccounts' => 'killable-cs',
                                               'Default' => 'YES',
                                               'DefaultTime' => '2:0:0',
                                               'MaxTime' => '21-0',
                                               'Nodes' => 'ALL',
                                               'PartitionName' => 'killable',
                                               'PriorityTier' => '1',
                                               'Shared' => 'NO',
                                               'allowaccounts' => 'killable-cs',
                                               'default' => 'YES',
                                               'defaulttime' => '2:0:0',
                                               'maxtime' => '21-0',
                                               'nodes' => 'ALL',
                                               'partitionname' => 'killable',
                                               'prioritytier' => '1',
                                               'shared' => 'NO'
                                              },
                                'long' => {
                                           'Default' => 'YES',
                                           'DefaultTime' => '2:0:0',
                                           'DenyAccounts' => 'killable-cs',
                                           'MaxTime' => '21-0',
                                           'Nodes' => 'eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08]',
                                           'PartitionName' => 'long',
                                           'PriorityTier' => '2',
                                           'Shared' => 'NO',
                                           'default' => 'YES',
                                           'defaulttime' => '2:0:0',
                                           'denyaccounts' => 'killable-cs',
                                           'maxtime' => '21-0',
                                           'nodes' => 'eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08]',
                                           'partitionname' => 'long',
                                           'prioritytier' => '2',
                                           'shared' => 'NO'
                                          },
                                'medium' => {
                                             'Default' => 'YES',
                                             'DefaultTime' => '2:0:0',
                                             'DenyAccounts' => 'killable-cs',
                                             'MaxTime' => '7-0',
                                             'Nodes' => 'eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08],cortex-[03-08],dumfries-[001-002]',
                                             'PartitionName' => 'medium',
                                             'PriorityTier' => '2',
                                             'Shared' => 'NO',
                                             'default' => 'YES',
                                             'defaulttime' => '2:0:0',
                                             'denyaccounts' => 'killable-cs',
                                             'maxtime' => '7-0',
                                             'nodes' => 'eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08],cortex-[03-08],dumfries-[001-002]',
                                             'partitionname' => 'medium',
                                             'prioritytier' => '2',
                                             'shared' => 'NO'
                                            },
                                'short' => {
                                            'Default' => 'YES',
                                            'DefaultTime' => '2:0:0',
                                            'DenyAccounts' => 'killable-cs',
                                            'MaxTime' => '2-0',
                                            'Nodes' => 'eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08],cortex-[01-08],dumfries-[001-002]',
                                            'PartitionName' => 'short',
                                            'PriorityTier' => '2',
                                            'Shared' => 'NO',
                                            'default' => 'YES',
                                            'defaulttime' => '2:0:0',
                                            'denyaccounts' => 'killable-cs',
                                            'maxtime' => '2-0',
                                            'nodes' => 'eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08],cortex-[01-08],dumfries-[001-002]',
                                            'partitionname' => 'short',
                                            'prioritytier' => '2',
                                            'shared' => 'NO'
                                           }
                               },
            'PlugStackConfig' => '/etc/slurm/plugstack.conf',
            'PreemptMode' => 'REQUEUE',
            'PreemptType' => 'preempt/qos',
            'PriorityType' => 'priority/multifactor',
            'PriorityWeightAge' => '10000',
            'PriorityWeightFairshare' => '1000000',
            'PriorityWeightQOS' => '10000000',
            'ProctrackType' => 'proctrack/cgroup',
            'PropagateResourceLimitsExcept' => 'ALL',
            'ReturnToService' => '2',
            'SchedulerParameters' => 'bf_window=30300',
            'SchedulerType' => 'sched/backfill',
            'SelectType' => 'select/cons_res',
            'SelectTypeParameters' => 'CR_Core_Memory',
            'SlurmUser' => 'slurm',
            'SlurmctldDebug' => 'debug',
            'SlurmctldLogFile' => '/var/log/slurmctld-phoenix.log',
            'SlurmctldPidFile' => '/var/run/slurmctld-phoenix.pid',
            'SlurmctldPort' => '6838',
            'SlurmctldSyslogDebug' => 'info',
            'SlurmctldTimeout' => '120',
            'SlurmdLogFile' => '/vol/slurm/phoenix/logs/slurmd-%h.log',
            'SlurmdPidFile' => '/var/run/slurmd-phoenix.pid',
            'SlurmdPort' => '6818',
            'SlurmdSpoolDir' => '/var/spool/slurmd',
            'SlurmdSyslogDebug' => 'info',
            'SlurmdTimeout' => '300',
            'StateSaveLocation' => '/vol/slurm/phoenix/state',
            'SwitchType' => 'switch/none',
            'TaskPlugin' => 'task/cgroup',
            'TaskProlog' => '/etc/slurm/proepilogs/TaskPrologs.sh',
            'UnkillableStepProgram' => '/etc/slurm/unkillable-program.sh',
            'UnkillableStepTimeout' => '300',
            'UsePAM' => 'yes',
            'Waittime' => '0',
            'accountingstorageenforce' => 'associations,limits,safe,qos',
            'accountingstoragehost' => 'slurm-db',
            'accountingstoragetres' => 'gres/gpu,license/interactive',
            'accountingstoragetype' => 'accounting_storage/slurmdbd',
            'authtype' => 'auth/munge',
            'backupcontroller' => 'slurmctl-02',
            'batchstarttimeout' => '20',
            'cachegroups' => '0',
            'clustername' => 'phoenix',
            'controlmachine' => 'slurmctl-01',
            'cryptotype' => 'crypto/munge',
            'defmempercpu' => '50',
            'disablerootjobs' => '1',
            'fairsharedampeningfactor' => '5',
            'fastschedule' => '0',
            'grestypes' => 'gpu',
            'groupupdateforce' => '1',
            'healthcheckinterval' => '10800',
            'healthchecknodestate' => 'CYCLE,ANY',
            'healthcheckprogram' => '/etc/slurm/healthcheck.sh',
            'inactivelimit' => '0',
            'jobacctgatherfrequency' => '30',
            'jobacctgathertype' => 'jobacct_gather/cgroup',
            'jobcomptype' => 'jobcomp/none',
            'jobrequeue' => '0',
            'jobsubmitplugins' => 'job_submit/valid_partitions,job_submit/limit_interactive,job_submit/killable',
            'killwait' => '30',
            'licenses' => 'interactive:5000',
            'mailprog' => '/vol/slurm/common/mail.sh',
            'maxarraysize' => '5001',
            'maxjobcount' => '50000',
            'maxmempercpu' => '2097152',
            'messagetimeout' => '30',
            'minjobage' => '300',
            'mpidefault' => 'none',
            'mpiparams' => 'ports=12001-12999',
            'nodename' => {
                           'DEFAULT' => {
                                         'MemSpecLimit' => '1024',
                                         'State' => '"UNKNOWN"',
                                         'memspeclimit' => '1024',
                                         'nodename' => 'DEFAULT',
                                         'state' => '"UNKNOWN"'
                                        },
                           'cb-[05-20]' => {
                                            'CoresPerSocket' => '4',
                                            'Feature' => 'cb',
                                            'RealMemory' => '64358',
                                            'Sockets' => '2',
                                            'ThreadsPerCore' => '2',
                                            'Weight' => '3',
                                            'corespersocket' => '4',
                                            'feature' => 'cb',
                                            'nodename' => 'cb-[05-20]',
                                            'realmemory' => '64358',
                                            'sockets' => '2',
                                            'threadspercore' => '2',
                                            'weight' => '3'
                                           },
                           'cortex-[01-05]' => {
                                                'CoresPerSocket' => '8',
                                                'Feature' => 'cortex',
                                                'Gres' => 'gpu:m60:8',
                                                'RealMemory' => '257860',
                                                'Sockets' => '2',
                                                'ThreadsPerCore' => '1',
                                                'Weight' => '8',
                                                'corespersocket' => '8',
                                                'feature' => 'cortex',
                                                'gres' => 'gpu:m60:8',
                                                'nodename' => 'cortex-[01-05]',
                                                'realmemory' => '257860',
                                                'sockets' => '2',
                                                'threadspercore' => '1',
                                                'weight' => '8'
                                               },
                           'dumfries-[001-002]' => {
                                                    'CoresPerSocket' => '8',
                                                    'Feature' => 'dumfries',
                                                    'Gres' => 'gpu:rtx2080:4',
                                                    'RealMemory' => '128586',
                                                    'Sockets' => '2',
                                                    'ThreadsPerCore' => '2',
                                                    'Weight' => '9',
                                                    'corespersocket' => '8',
                                                    'feature' => 'dumfries',
                                                    'gres' => 'gpu:rtx2080:4',
                                                    'nodename' => 'dumfries-[001-002]',
                                                    'realmemory' => '128586',
                                                    'sockets' => '2',
                                                    'threadspercore' => '2',
                                                    'weight' => '9'
                                                   },
                           'eye-[01-04]' => {
                                             'CoresPerSocket' => '8',
                                             'Feature' => 'eye',
                                             'RealMemory' => '193391',
                                             'Sockets' => '2',
                                             'ThreadsPerCore' => '1',
                                             'Weight' => '4',
                                             'corespersocket' => '8',
                                             'feature' => 'eye',
                                             'nodename' => 'eye-[01-04]',
                                             'realmemory' => '193391',
                                             'sockets' => '2',
                                             'threadspercore' => '1',
                                             'weight' => '4'
                                            },
                           'oxygen-[01-08]' => {
                                                'CoresPerSocket' => '12',
                                                'Features' => 'oxygen',
                                                'RealMemory' => '257855',
                                                'Sockets' => '2',
                                                'ThreadsPerCore' => '2',
                                                'Weight' => '5',
                                                'corespersocket' => '12',
                                                'features' => 'oxygen',
                                                'nodename' => 'oxygen-[01-08]',
                                                'realmemory' => '257855',
                                                'sockets' => '2',
                                                'threadspercore' => '2',
                                                'weight' => '5'
                                               },
                           'sulfur-[01-16]' => {
                                                'CoresPerSocket' => '4',
                                                'Feature' => 'sulfur',
                                                'RealMemory' => '63409',
                                                'Sockets' => '2',
                                                'ThreadsPerCore' => '1',
                                                'Weight' => '2',
                                                'corespersocket' => '4',
                                                'feature' => 'sulfur',
                                                'nodename' => 'sulfur-[01-16]',
                                                'realmemory' => '63409',
                                                'sockets' => '2',
                                                'threadspercore' => '1',
                                                'weight' => '2'
                                               }
                          },
            'partitionname' => {
                                'killable' => {
                                               'AllowAccounts' => 'killable-cs',
                                               'Default' => 'YES',
                                               'DefaultTime' => '2:0:0',
                                               'MaxTime' => '21-0',
                                               'Nodes' => 'ALL',
                                               'PriorityTier' => '1',
                                               'Shared' => 'NO',
                                               'allowaccounts' => 'killable-cs',
                                               'default' => 'YES',
                                               'defaulttime' => '2:0:0',
                                               'maxtime' => '21-0',
                                               'nodes' => 'ALL',
                                               'partitionname' => 'killable',
                                               'prioritytier' => '1',
                                               'shared' => 'NO'
                                              },
                                'long' => {
                                           'Default' => 'YES',
                                           'DefaultTime' => '2:0:0',
                                           'DenyAccounts' => 'killable-cs',
                                           'MaxTime' => '21-0',
                                           'Nodes' => 'eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08]',
                                           'PriorityTier' => '2',
                                           'Shared' => 'NO',
                                           'default' => 'YES',
                                           'defaulttime' => '2:0:0',
                                           'denyaccounts' => 'killable-cs',
                                           'maxtime' => '21-0',
                                           'nodes' => 'eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08]',
                                           'partitionname' => 'long',
                                           'prioritytier' => '2',
                                           'shared' => 'NO'
                                          },
                                'medium' => {
                                             'Default' => 'YES',
                                             'DefaultTime' => '2:0:0',
                                             'DenyAccounts' => 'killable-cs',
                                             'MaxTime' => '7-0',
                                             'Nodes' => 'eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08],cortex-[03-08],dumfries-[001-002]',
                                             'PriorityTier' => '2',
                                             'Shared' => 'NO',
                                             'default' => 'YES',
                                             'defaulttime' => '2:0:0',
                                             'denyaccounts' => 'killable-cs',
                                             'maxtime' => '7-0',
                                             'nodes' => 'eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08],cortex-[03-08],dumfries-[001-002]',
                                             'partitionname' => 'medium',
                                             'prioritytier' => '2',
                                             'shared' => 'NO'
                                            },
                                'short' => {
                                            'Default' => 'YES',
                                            'DefaultTime' => '2:0:0',
                                            'DenyAccounts' => 'killable-cs',
                                            'MaxTime' => '2-0',
                                            'Nodes' => 'eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08],cortex-[01-08],dumfries-[001-002]',
                                            'PriorityTier' => '2',
                                            'Shared' => 'NO',
                                            'default' => 'YES',
                                            'defaulttime' => '2:0:0',
                                            'denyaccounts' => 'killable-cs',
                                            'maxtime' => '2-0',
                                            'nodes' => 'eye-[01-04],sulfur-[01-16],cb-[05-20],oxygen-[01-08],cortex-[01-08],dumfries-[001-002]',
                                            'partitionname' => 'short',
                                            'prioritytier' => '2',
                                            'shared' => 'NO'
                                           }
                               },
            'plugstackconfig' => '/etc/slurm/plugstack.conf',
            'preemptmode' => 'REQUEUE',
            'preempttype' => 'preempt/qos',
            'prioritytype' => 'priority/multifactor',
            'priorityweightage' => '10000',
            'priorityweightfairshare' => '1000000',
            'priorityweightqos' => '10000000',
            'proctracktype' => 'proctrack/cgroup',
            'propagateresourcelimitsexcept' => 'ALL',
            'returntoservice' => '2',
            'schedulerparameters' => 'bf_window=30300',
            'schedulertype' => 'sched/backfill',
            'selecttype' => 'select/cons_res',
            'selecttypeparameters' => 'CR_Core_Memory',
            'slurmctlddebug' => 'debug',
            'slurmctldlogfile' => '/var/log/slurmctld-phoenix.log',
            'slurmctldpidfile' => '/var/run/slurmctld-phoenix.pid',
            'slurmctldport' => '6838',
            'slurmctldsyslogdebug' => 'info',
            'slurmctldtimeout' => '120',
            'slurmdlogfile' => '/vol/slurm/phoenix/logs/slurmd-%h.log',
            'slurmdpidfile' => '/var/run/slurmd-phoenix.pid',
            'slurmdport' => '6818',
            'slurmdspooldir' => '/var/spool/slurmd',
            'slurmdsyslogdebug' => 'info',
            'slurmdtimeout' => '300',
            'slurmuser' => 'slurm',
            'statesavelocation' => '/vol/slurm/phoenix/state',
            'switchtype' => 'switch/none',
            'taskplugin' => 'task/cgroup',
            'taskprolog' => '/etc/slurm/proepilogs/TaskPrologs.sh',
            'unkillablestepprogram' => '/etc/slurm/unkillable-program.sh',
            'unkillablesteptimeout' => '300',
            'usepam' => 'yes',
            'waittime' => '0'
           );

my $errors = [];
my ($fh, $filename) = File::Temp::tempfile();
print $fh $conf;
close($fh);

my $results = parse_conf($filename, errors => $errors);
is_deeply($results, \%conf);
is_deeply($errors, []);

unlink $filename;
$results = parse_conf($filename, errors => $errors);
ok(not defined $results);
ok(@$errors == 1); # No such file or directory

done_testing();

#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(get_jobs);

my $jobs = "JobId=1 JobName=name1
   UserId=user1(100) GroupId=group1(200) MCS_label=N/A
   Priority=105969 Nice=0 Account=account1 QOS=normal
   JobState=RUNNING Reason=None Dependency=(null)
   Requeue=0 Restarts=0 BatchFlag=1 Reboot=0 ExitCode=0:0
   DerivedExitCode=0:0
   RunTime=05:46:31 TimeLimit=1-00:00:00 TimeMin=N/A
   SubmitTime=2019-01-31T10:35:35 EligibleTime=2019-01-31T10:35:35
   StartTime=2019-01-31T10:35:53 EndTime=2019-02-01T10:35:54 Deadline=N/A
   PreemptTime=None SuspendTime=None SecsPreSuspend=0
   LastSchedEval=2019-01-31T10:35:53
   Partition=long AllocNode:Sid=node-04:3428
   ReqNodeList=(null) ExcNodeList=(null)
   NodeList=node-[63-65]
   BatchHost=node-63
   NumNodes=3 NumCPUs=8 NumTasks=8 CPUs/Task=1 ReqB:S:C:T=0:0:*:*
   TRES=cpu=8,mem=4000M,node=3,billing=8
   Socks/Node=* NtasksPerN:B:S:C=0:0:*:* CoreSpec=*
     Nodes=node-63 CPU_IDs=22-23 Mem=1000 GRES_IDX=
     Nodes=node-64 CPU_IDs=0,4-7 Mem=2000 GRES_IDX=
     Nodes=node-65 CPU_IDs=20-21 Mem=1000 GRES_IDX=
   MinCPUsNode=1 MinMemoryCPU=500M MinTmpDiskNode=0
   Features=(null) DelayBoot=00:00:00
   Gres=(null) Reservation=(null)
   OverSubscribe=OK Contiguous=0 Licenses=(null) Network=(null)
   Command=/location/with/command.sh
   WorkDir=/location/with
   StdErr=/location/with/err.txt
   StdIn=/dev/null
   StdOut=/location/with/out.txt
   Power=

JobId=2398617 ArrayJobId=2398463 ArrayTaskId=150 JobName=parallel.sh
   UserId=user2(200) GroupId=group1(200) MCS_label=N/A
   Priority=100021 Nice=0 Account=account1 QOS=normal
   JobState=COMPLETED Reason=None Dependency=(null)
   Requeue=0 Restarts=0 BatchFlag=1 Reboot=0 ExitCode=0:0
   DerivedExitCode=0:0
   RunTime=03:53:12 TimeLimit=15-00:00:00 TimeMin=N/A
   SubmitTime=2019-01-31T12:15:53 EligibleTime=2019-01-31T12:15:53
   StartTime=2019-01-31T12:26:08 EndTime=2019-01-31T16:19:20 Deadline=N/A
   PreemptTime=None SuspendTime=None SecsPreSuspend=0
   LastSchedEval=2019-01-31T12:26:08
   Partition=long AllocNode:Sid=node-01:115559
   ReqNodeList=(null) ExcNodeList=(null)
   NodeList=node-44
   BatchHost=node-44
   NumNodes=1 NumCPUs=2 NumTasks=0 CPUs/Task=1 ReqB:S:C:T=0:0:*:*
   TRES=cpu=2,mem=16000M,node=1,billing=2
   Socks/Node=* NtasksPerN:B:S:C=0:0:*:* CoreSpec=*
     Nodes=node-44 CPU_IDs=2-3 Mem=16000 GRES_IDX=
   MinCPUsNode=1 MinMemoryCPU=8000M MinTmpDiskNode=0
   Features=(null) DelayBoot=00:00:00
   Gres=(null) Reservation=(null)
   OverSubscribe=OK Contiguous=0 Licenses=(null) Network=(null)
   Command=/location/with/other/command.pl
   WorkDir=/location/with/other/dir
   StdErr=/location/with/other/dir/a.out
   StdIn=/dev/null
   StdOut=/location/with/other/dir/a.out
   Power=

JobId=153291 JobName=name3
   UserId=user3(300) GroupId=group3(300) MCS_label=N/A
   Priority=1660779 Nice=0 Account=oabend QOS=normal
   JobState=RUNNING Reason=None Dependency=(null)
   Requeue=0 Restarts=0 BatchFlag=1 Reboot=0 ExitCode=0:0
   DerivedExitCode=0:0
   RunTime=01:22:30 TimeLimit=7-00:00:00 TimeMin=N/A
   SubmitTime=2019-02-07T16:05:08 EligibleTime=2019-02-07T16:05:08
   StartTime=2019-02-07T16:05:09 EndTime=2019-02-14T16:05:09 Deadline=N/A
   PreemptTime=None SuspendTime=None SecsPreSuspend=0
   LastSchedEval=2019-02-07T16:05:09
   Partition=medium AllocNode:Sid=node-3:19166
   ReqNodeList=(null) ExcNodeList=(null)
   NodeList=node-06
   BatchHost=node-06
   NumNodes=1 NumCPUs=4 NumTasks=1 CPUs/Task=4 ReqB:S:C:T=0:0:*:*
   TRES=cpu=4,mem=80G,node=1,billing=4,gres/gpu=4
   Socks/Node=* NtasksPerN:B:S:C=0:0:*:* CoreSpec=*
     Nodes=node-06 CPU_IDs=10-11,15,21 Mem=81920 GRES_IDX=gpu(IDX:0,2-3,5)
   MinCPUsNode=4 MinMemoryNode=80G MinTmpDiskNode=0
   Features=(null) DelayBoot=00:00:00
   Gres=gpu:4 Reservation=(null)
   OverSubscribe=OK Contiguous=0 Licenses=(null) Network=(null)
   Command=/some/location/script
   WorkDir=/some/location
   StdErr=/some/location/err
   StdIn=/dev/null
   StdOut=/some/location/out
   Power=

JobId=134238037 JobName=wrap
   UserId=user3(300) GroupId=group3(300) MCS_label=N/A
   Priority=101461 Nice=0 Account=irush QOS=normal
   JobState=PENDING Reason=AssocGrpCpuLimit Dependency=(null)
   Requeue=0 Restarts=0 BatchFlag=1 Reboot=0 ExitCode=0:0
   RunTime=00:00:00 TimeLimit=1-00:00:00 TimeMin=N/A
   SubmitTime=2019-02-17T15:52:28 EligibleTime=2019-02-17T15:52:28
   StartTime=Unknown EndTime=Unknown Deadline=N/A
   PreemptTime=None SuspendTime=None SecsPreSuspend=0
   LastSchedEval=2019-02-17T15:52:30
   Partition=long,other AllocNode:Sid=newt:13247
   ReqNodeList=(null) ExcNodeList=(null)
   NodeList=(null)
   FedOrigin=debug FedViableSiblings=debug FedActiveSiblings=debug
   NumNodes=1 NumCPUs=4 NumTasks=1 CPUs/Task=4 ReqB:S:C:T=0:0:*:*
   TRES=cpu=4,mem=200M,node=1
   Socks/Node=* NtasksPerN:B:S:C=0:0:*:* CoreSpec=*
   MinCPUsNode=4 MinMemoryCPU=50M MinTmpDiskNode=0
   Features=(null) DelayBoot=00:00:00
   ClusterFeatures=c-f1
   Gres=(null) Reservation=(null)
   OverSubscribe=OK Contiguous=0 Licenses=(null) Network=(null)
   Command=(null)
   WorkDir=/some/location
   StdErr=/some/location/err
   StdIn=/dev/null
   StdOut=/some/location/out
   Power=

";

my %jobs = (1 => {"JobId" => "1",
                  "JobName" => "name1",
                  "UserId" => "user1(100)",
                  "GroupId" => "group1(200)",
                  "MCS_label" => "N/A",
                  "Priority" => "105969",
                  "Nice" => "0",
                  "Account" => "account1",
                  "QOS" => "normal",
                  "JobState" => "RUNNING",
                  "Reason" => "None",
                  "Dependency" => "(null)",
                  "Requeue" => "0",
                  "Restarts" => "0",
                  "BatchFlag" => "1",
                  "Reboot" => "0",
                  "ExitCode" => "0:0",
                  "DerivedExitCode" => "0:0",
                  "RunTime" => "05:46:31",
                  "TimeLimit" => "1-00:00:00",
                  "TimeMin" => "N/A",
                  "SubmitTime" => "2019-01-31T10:35:35",
                  "EligibleTime" => "2019-01-31T10:35:35",
                  "StartTime" => "2019-01-31T10:35:53",
                  "EndTime" => "2019-02-01T10:35:54",
                  "Deadline" => "N/A",
                  "PreemptTime" => "None",
                  "SuspendTime" => "None",
                  "SecsPreSuspend" => "0",
                  "LastSchedEval" => "2019-01-31T10:35:53",
                  "Partition" => "long",
                  "AllocNode:Sid" => "node-04:3428",
                  "ReqNodeList" => "(null)",
                  "ExcNodeList" => "(null)",
                  "NodeList" => "node-[63-65]",
                  "_NodeList" => ["node-63", "node-64", "node-65"],
                  "BatchHost" => "node-63",
                  "NumNodes" => "3",
                  "NumCPUs" => "8",
                  "NumTasks" => "8",
                  "CPUs/Task" => "1",
                  "ReqB:S:C:T" => "0:0:*:*",
                  "TRES" => "cpu=8,mem=4000M,node=3,billing=8",
                  "Socks/Node" => "*",
                  "NtasksPerN:B:S:C" => "0:0:*:*",
                  "CoreSpec" => "*",
                  "_DETAILS" => [{"Nodes" => "node-63", "CPU_IDs" => "22-23", "Mem" => "1000", "GRES_IDX" => "",   "_GRES" => {}, "_GRESs" => {}, "_JobId" => 1, "_nCPUs" => 2, "_CPUs" => [22, 23],  "_EndTime" => "2019-02-01T10:35:54", "_NodeList" => ['node-63']},
                                 {"Nodes" => "node-64", "CPU_IDs" => "0,4-7",   "Mem" => "2000", "GRES_IDX" => "", "_GRES" => {}, "_GRESs" => {}, "_JobId" => 1, "_nCPUs" => 5, "_CPUs" => [0,4,5,6,7], "_EndTime" => "2019-02-01T10:35:54", "_NodeList" => ['node-64']},
                                 {"Nodes" => "node-65", "CPU_IDs" => "20-21", "Mem" => "1000", "GRES_IDX" => "",   "_GRES" => {}, "_GRESs" => {}, "_JobId" => 1, "_nCPUs" => 2, "_CPUs" => [20, 21],  "_EndTime" => "2019-02-01T10:35:54", "_NodeList" => ['node-65']},
                                ],
                  "MinCPUsNode" => "1",
                  "MinMemoryCPU" => "500M",
                  "MinTmpDiskNode" => "0",
                  "Features" => "(null)",
                  "DelayBoot" => "00:00:00",
                  "Gres" => "(null)",
                  "Reservation" => "(null)",
                  "OverSubscribe" => "OK",
                  "Contiguous" => "0",
                  "Licenses" => "(null)",
                  "Network" => "(null)",
                  "Command" => "/location/with/command.sh",
                  "WorkDir" => "/location/with",
                  "StdErr" => "/location/with/err.txt",
                  "StdIn" => "/dev/null",
                  "StdOut" => "/location/with/out.txt",
                  "Power" => "",
                  "_TRES" => {"cpu" => 8, "mem" => "4000M" , "node" => 3, "billing" => 8},
                 },

            2398617 => {
                        "JobId" => "2398617",
                        "ArrayJobId" => "2398463",
                        "ArrayTaskId" => "150",
                        "JobName" => "parallel.sh",
                        "UserId" => "user2(200)",
                        "GroupId" => "group1(200)",
                        "MCS_label" => "N/A",
                        "Priority" => "100021",
                        "Nice" => "0",
                        "Account" => "account1",
                        "QOS" => "normal",
                        "JobState" => "COMPLETED",
                        "Reason" => "None",
                        "Dependency" => "(null)",
                        "Requeue" => "0",
                        "Restarts" => "0",
                        "BatchFlag" => "1",
                        "Reboot" => "0",
                        "ExitCode" => "0:0",
                        "DerivedExitCode" => "0:0",
                        "RunTime" => "03:53:12",
                        "TimeLimit" => "15-00:00:00",
                        "TimeMin" => "N/A",
                        "SubmitTime" => "2019-01-31T12:15:53",
                        "EligibleTime" => "2019-01-31T12:15:53",
                        "StartTime" => "2019-01-31T12:26:08",
                        "EndTime" => "2019-01-31T16:19:20",
                        "Deadline" => "N/A",
                        "PreemptTime" => "None",
                        "SuspendTime" => "None",
                        "SecsPreSuspend" => "0",
                        "LastSchedEval" => "2019-01-31T12:26:08",
                        "Partition" => "long",
                        "AllocNode:Sid" => "node-01:115559",
                        "ReqNodeList" => "(null)",
                        "ExcNodeList" => "(null)",
                        "NodeList" => "node-44",
                        "_NodeList" => ["node-44"],
                        "BatchHost" => "node-44",
                        "NumNodes" => "1",
                        "NumCPUs" => "2",
                        "NumTasks" => "0",
                        "CPUs/Task" => "1",
                        "ReqB:S:C:T" => "0:0:*:*",
                        "TRES" => "cpu=2,mem=16000M,node=1,billing=2",
                        "Socks/Node" => "*",
                        "NtasksPerN:B:S:C" => "0:0:*:*",
                        "CoreSpec" => "*",
                        "_DETAILS" => [{"Nodes" => "node-44", "CPU_IDs" => "2-3", "Mem" => "16000", "GRES_IDX" => "", "_JobId" => "2398617", "_NodeList" => ["node-44"], "_EndTime" => "2019-01-31T16:19:20", "_GRES" => {}, "_GRESs" => {}, "_nCPUs" => 2, "_CPUs" => [2,3], "_NodeList" => ["node-44"]}],
                        "MinCPUsNode" => "1",
                        "MinMemoryCPU" => "8000M",
                        "MinTmpDiskNode" => "0",
                        "Features" => "(null)",
                        "DelayBoot" => "00:00:00",
                        "Gres" => "(null)",
                        "Reservation" => "(null)",
                        "OverSubscribe" => "OK",
                        "Contiguous" => "0",
                        "Licenses" => "(null)",
                        "Network" => "(null)",
                        "Command" => "/location/with/other/command.pl",
                        "WorkDir" => "/location/with/other/dir",
                        "StdErr" => "/location/with/other/dir/a.out",
                        "StdIn" => "/dev/null",
                        "StdOut" => "/location/with/other/dir/a.out",
                        "Power" => "",
                        "_TRES" => {"cpu" => 2, "mem" => "16000M", "node" => 1, "billing" => 2},
                       },

            153291 => {
                       "JobId" => "153291",
                       "JobName" => "name3",
                       "UserId" => "user3(300)",
                       "GroupId" => "group3(300)",
                       "MCS_label" => "N/A",
                       "Priority" => "1660779",
                       "Nice" => "0",
                       "Account" => "oabend",
                       "QOS" => "normal",
                       "JobState" => "RUNNING",
                       "Reason" => "None",
                       "Dependency" => "(null)",
                       "Requeue" => "0",
                       "Restarts" => "0",
                       "BatchFlag" => "1",
                       "Reboot" => "0",
                       "ExitCode" => "0:0",
                       "DerivedExitCode" => "0:0",
                       "RunTime" => "01:22:30",
                       "TimeLimit" => "7-00:00:00",
                       "TimeMin" => "N/A",
                       "SubmitTime" => "2019-02-07T16:05:08",
                       "EligibleTime" => "2019-02-07T16:05:08",
                       "StartTime" => "2019-02-07T16:05:09",
                       "EndTime" => "2019-02-14T16:05:09",
                       "Deadline" => "N/A",
                       "PreemptTime" => "None",
                       "SuspendTime" => "None",
                       "SecsPreSuspend" => "0",
                       "LastSchedEval" => "2019-02-07T16:05:09",
                       "Partition" => "medium",
                       "AllocNode:Sid" => "node-3:19166",
                       "ReqNodeList" => "(null)",
                       "ExcNodeList" => "(null)",
                       "NodeList" => "node-06",
                       "_NodeList" => ["node-06"],
                       "BatchHost" => "node-06",
                       "NumNodes" => "1",
                       "NumCPUs" => "4",
                       "NumTasks" => "1",
                       "CPUs/Task" => "4",
                       "ReqB:S:C:T" => "0:0:*:*",
                       "TRES" => "cpu=4,mem=80G,node=1,billing=4,gres/gpu=4",
                       "Socks/Node" => "*",
                       "NtasksPerN:B:S:C" => "0:0:*:*",
                       "CoreSpec" => "*",
                       "_DETAILS" => [{"Nodes" => "node-06", "CPU_IDs" => "10-11,15,21", "Mem" => "81920", "GRES_IDX" => "gpu(IDX:0,2-3,5)", "_JobId" => 153291, "_GRES" => {gpu => 4}, "_GRESs" => {gpu => [0,2,3,5]}, "_EndTime" => "2019-02-14T16:05:09", "_nCPUs" => 4, "_CPUs" => [10,11,15,21], "_NodeList" => ["node-06"]}],
                       "MinCPUsNode" => "4",
                       "MinMemoryNode" => "80G",
                       "MinTmpDiskNode" => "0",
                       "Features" => "(null)",
                       "DelayBoot" => "00:00:00",
                       "Gres" => "gpu:4",
                       "Reservation" => "(null)",
                       "OverSubscribe" => "OK",
                       "Contiguous" => "0",
                       "Licenses" => "(null)",
                       "Network" => "(null)",
                       "Command" => "/some/location/script",
                       "WorkDir" => "/some/location",
                       "StdErr" => "/some/location/err",
                       "StdIn" => "/dev/null",
                       "StdOut" => "/some/location/out",
                       "Power" => "",
                       "_TRES" => {"cpu" => 4, mem => "81920M", node => 1, billing => 4, "gres/gpu" => 4},
                      },

            "134238037" => {
                            "JobId" => "134238037",
                            "JobName" => "wrap",
                            "UserId" => "user3(300)",
                            "GroupId" => "group3(300)",
                            "MCS_label" => "N/A",
                            "Priority" => "101461",
                            "Nice" => "0",
                            "Account" => "irush",
                            "QOS" => "normal",
                            "JobState" => "PENDING",
                            "Reason" => "AssocGrpCpuLimit",
                            "Dependency" => "(null)",
                            "Requeue" => "0",
                            "Restarts" => "0",
                            "BatchFlag" => "1",
                            "Reboot" => "0",
                            "ExitCode" => "0:0",
                            "RunTime" => "00:00:00",
                            "TimeLimit" => "1-00:00:00",
                            "TimeMin" => "N/A",
                            "SubmitTime" => "2019-02-17T15:52:28",
                            "EligibleTime" => "2019-02-17T15:52:28",
                            "StartTime" => "Unknown",
                            "EndTime" => "Unknown",
                            "Deadline" => "N/A",
                            "PreemptTime" => "None",
                            "SuspendTime" => "None",
                            "SecsPreSuspend" => "0",
                            "LastSchedEval" => "2019-02-17T15:52:30",
                            "Partition" => "long,other",
                            "AllocNode:Sid" => "newt:13247",
                            "ReqNodeList" => "(null)",
                            "ExcNodeList" => "(null)",
                            "NodeList" => "(null)",
                            "_NodeList" => [],
                            "FedOrigin" => "debug",
                            "FedViableSiblings" => "debug",
                            "FedActiveSiblings" => "debug",
                            "NumNodes" => "1",
                            "NumCPUs" => "4",
                            "NumTasks" => "1",
                            "CPUs/Task" => "4",
                            "ReqB:S:C:T" => "0:0:*:*",
                            "TRES" => "cpu=4,mem=200M,node=1",
                            "_TRES" => {cpu => "4", mem => "200M", "node" => 1},
                            "Socks/Node" => "*",
                            "NtasksPerN:B:S:C" => "0:0:*:*",
                            "CoreSpec" => "*",
                            "MinCPUsNode" => "4",
                            "MinMemoryCPU" => "50M",
                            "MinTmpDiskNode" => "0",
                            "Features" => "(null)",
                            "DelayBoot" => "00:00:00",
                            "ClusterFeatures" => "c-f1",
                            "Gres" => "(null)",
                            "Reservation" => "(null)",
                            "OverSubscribe" => "OK",
                            "Contiguous" => "0",
                            "Licenses" => "(null)",
                            "Network" => "(null)",
                            "Command" => "(null)",
                            "WorkDir" => "/some/location",
                            "StdErr" => "/some/location/err",
                            "StdIn" => "/dev/null",
                            "StdOut" => "/some/location/out",
                            "Power" => "",
                            "_DETAILS" => [],
                           },

           );

my $results = get_jobs(_scontrol_output => [split /\n/, $jobs]);
is_deeply($results, \%jobs);

done_testing();

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

JobId=2423559 ArrayJobId=2423430 ArrayTaskId=72 ArrayTaskThrottle=20 JobName=tsn
   UserId=user4(400) GroupId=group4(404) MCS_label=N/A
   Priority=1409292 Nice=0 Account=account4 QOS=normal
   JobState=RUNNING Reason=None Dependency=(null)
   Requeue=0 Restarts=0 BatchFlag=1 Reboot=0 ExitCode=0:0
   DerivedExitCode=0:0
   RunTime=00:02:29 TimeLimit=2-00:00:00 TimeMin=N/A
   SubmitTime=2019-12-02T14:47:13 EligibleTime=2019-12-02T15:28:10
   AccrueTime=Unknown
   StartTime=2019-12-02T15:28:10 EndTime=2019-12-04T15:28:10 Deadline=N/A
   PreemptEligibleTime=2019-12-02T15:28:10 PreemptTime=None
   SuspendTime=None SecsPreSuspend=0 LastSchedEval=2019-12-02T15:28:10
   Partition=short AllocNode:Sid=e-phoenix-gw.cs.huji.ac.il:21453
   ReqNodeList=(null) ExcNodeList=(null)
   NodeList=cortex-08
   BatchHost=cortex-08
   NumNodes=1 NumCPUs=1 NumTasks=1 CPUs/Task=1 ReqB:S:C:T=0:0:*:*
   TRES=cpu=1,mem=8G,node=1,billing=1,gres/gpu=1
   Socks/Node=* NtasksPerN:B:S:C=0:0:*:* CoreSpec=*
     Nodes=cortex-08 CPU_IDs=20 Mem=8192 GRES=gpu(IDX:5)
   MinCPUsNode=1 MinMemoryNode=8G MinTmpDiskNode=0
   Features=(null) DelayBoot=00:00:00
   OverSubscribe=OK Contiguous=0 Licenses=(null) Network=(null)
   Command=tsn
   WorkDir=/tsn/logs
   StdErr=/tsn/logs/out
   StdIn=/dev/null
   StdOut=/tsn/logs/out
   Power=
   TresPerNode=gpu:1

JobId=20547 JobName=test
   UserId=user5(500) GroupId=group5(505) MCS_label=N/A
   Priority=105882 Nice=0 Account=account5 QOS=normal
   JobState=PENDING Reason=PartitionConfig Dependency=(null)
   Requeue=0 Restarts=0 BatchFlag=1 Reboot=0 ExitCode=0:0
   DerivedExitCode=0:0
   RunTime=00:00:00 TimeLimit=00:10:00 TimeMin=N/A
   SubmitTime=2020-01-21T12:12:46 EligibleTime=2020-01-21T12:12:46
   AccrueTime=2020-01-21T12:12:46
   StartTime=2020-01-21T12:22:42 EndTime=2020-01-21T12:32:42 Deadline=N/A
   SuspendTime=None SecsPreSuspend=0 LastSchedEval=2020-01-21T12:15:09
   Partition=short,long,other AllocNode:Sid=newt.cs.huji.ac.il:25104
   ReqNodeList=(null) ExcNodeList=(null)
   NodeList=(null) SchedNodeList=doppelganger,dune3
   NumNodes=2-2 NumCPUs=2 NumTasks=2 CPUs/Task=1 ReqB:S:C:T=0:0:*:*
   TRES=cpu=2,mem=100M,node=2,billing=2
   Socks/Node=* NtasksPerN:B:S:C=0:0:*:* CoreSpec=*
   MinCPUsNode=1 MinMemoryCPU=50M MinTmpDiskNode=0
   Features=(null) DelayBoot=00:00:00
   ClusterFeatures=c-f1
   OverSubscribe=OK Contiguous=0 Licenses=(null) Network=(null)
   Command=(null)
   WorkDir=/work/dir/1
   StdErr=/std/err2
   StdIn=/dev/null
   StdOut=/std/out3
   Power=

";

my %jobs = (1 => {"JobId" => "1",
                  "JobName" => "name1",
                  "UserId" => "user1(100)",
                  "_UserName" => "user1",
                  "_UID" => "100",
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
                  "_DETAILS" => [{"Nodes" => "node-63", "CPU_IDs" => "22-23", "Mem" => "1000", "GRES_IDX" => "",   "_GRES_IDX" => "", "_GRES" => {}, "_GRESs" => {}, "_JobId" => 1, "_nCPUs" => 2, "_CPUs" => [22, 23],  "_EndTime" => "2019-02-01T10:35:54", "_NodeList" => ['node-63']},
                                 {"Nodes" => "node-64", "CPU_IDs" => "0,4-7",   "Mem" => "2000", "GRES_IDX" => "", "_GRES_IDX" => "", "_GRES" => {}, "_GRESs" => {}, "_JobId" => 1, "_nCPUs" => 5, "_CPUs" => [0,4,5,6,7], "_EndTime" => "2019-02-01T10:35:54", "_NodeList" => ['node-64']},
                                 {"Nodes" => "node-65", "CPU_IDs" => "20-21", "Mem" => "1000", "GRES_IDX" => "",   "_GRES_IDX" => "", "_GRES" => {}, "_GRESs" => {}, "_JobId" => 1, "_nCPUs" => 2, "_CPUs" => [20, 21],  "_EndTime" => "2019-02-01T10:35:54", "_NodeList" => ['node-65']},
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
                        "_UserName" => "user2",
                        "_UID" => "200",
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
                        "_DETAILS" => [{"Nodes" => "node-44", "CPU_IDs" => "2-3", "Mem" => "16000", "GRES_IDX" => "", "_GRES_IDX" => "", "_JobId" => "2398617", "_NodeList" => ["node-44"], "_EndTime" => "2019-01-31T16:19:20", "_GRES" => {}, "_GRESs" => {}, "_nCPUs" => 2, "_CPUs" => [2,3], "_NodeList" => ["node-44"]}],
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
                       "_UserName" => "user3",
                       "_UID" => "300",
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
                       "_DETAILS" => [{"Nodes" => "node-06", "CPU_IDs" => "10-11,15,21", "Mem" => "81920", "GRES_IDX" => "gpu(IDX:0,2-3,5)", "_GRES_IDX" => "gpu(IDX:0,2-3,5)", "_JobId" => 153291, "_GRES" => {gpu => 4}, "_GRESs" => {gpu => [0,2,3,5]}, "_EndTime" => "2019-02-14T16:05:09", "_nCPUs" => 4, "_CPUs" => [10,11,15,21], "_NodeList" => ["node-06"]}],
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
                            "_UserName" => "user3",
                            "_UID" => "300",
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

            "2423559" => {
                          "JobId" => "2423559",
                          "ArrayJobId" => "2423430",
                          "ArrayTaskId" => "72",
                          "ArrayTaskThrottle" => "20",
                          "JobName" => "tsn",
                          "UserId" => "user4(400)",
                          "_UserName" => "user4",
                          "_UID" => "400",
                          "GroupId" => "group4(404)",
                          "MCS_label" => "N/A",
                          "Priority" => "1409292",
                          "Nice" => "0",
                          "Account" => "account4",
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
                          "RunTime" => "00:02:29",
                          "TimeLimit" => "2-00:00:00",
                          "TimeMin" => "N/A",
                          "SubmitTime" => "2019-12-02T14:47:13",
                          "EligibleTime" => "2019-12-02T15:28:10",
                          "AccrueTime" => "Unknown",
                          "StartTime" => "2019-12-02T15:28:10",
                          "EndTime" => "2019-12-04T15:28:10",
                          "Deadline" => "N/A",
                          "PreemptEligibleTime" => "2019-12-02T15:28:10",
                          "PreemptTime" => "None",
                          "SuspendTime" => "None",
                          "SecsPreSuspend" => "0",
                          "LastSchedEval" => "2019-12-02T15:28:10",
                          "Partition" => "short",
                          "AllocNode:Sid" => "e-phoenix-gw.cs.huji.ac.il:21453",
                          "ReqNodeList" => "(null)",
                          "ExcNodeList" => "(null)",
                          "NodeList" => "cortex-08",
                          "_NodeList" => ["cortex-08"],
                          "BatchHost" => "cortex-08",
                          "NumNodes" => "1",
                          "NumCPUs" => "1",
                          "NumTasks" => "1",
                          "CPUs/Task" => "1",
                          "ReqB:S:C:T" => "0:0:*:*",
                          "TRES" => "cpu=1,mem=8G,node=1,billing=1,gres/gpu=1",
                          "_TRES" => {"cpu" => 1, node => "1", "billing" => 1, "gres/gpu" => 1, mem => "8192M"},
                          "Socks/Node" => "*",
                          "NtasksPerN:B:S:C" => "0:0:*:*",
                          "CoreSpec" => "*",
                          "MinCPUsNode" => "1",
                          "MinMemoryNode" => "8G",
                          "MinTmpDiskNode" => "0",
                          "Features" => "(null)",
                          "DelayBoot" => "00:00:00",
                          "OverSubscribe" => "OK",
                          "Contiguous" => "0",
                          "Licenses" => "(null)",
                          "Network" => "(null)",
                          "Command" => "tsn",
                          "WorkDir" => "/tsn/logs",
                          "StdErr" => "/tsn/logs/out",
                          "StdIn" => "/dev/null",
                          "StdOut" => "/tsn/logs/out",
                          "Power" => "",
                          "TresPerNode" => "gpu:1",
                          "_DETAILS" => [{_JobId => 2423559, _NodeList => ["cortex-08"], _CPUs => [20], GRES => "gpu(IDX:5)", _GRES_IDX => "gpu(IDX:5)", CPU_IDs => 20, _nCPUs => 1, "Nodes" => "cortex-08", "Mem" => 8192, _EndTime => "2019-12-04T15:28:10", _GRES => {gpu => 1}, _GRESs => {gpu => [5]}}],
                         },

            "20547" => {
                        "JobId" => "20547",
                        "JobName" => "test",
                        "UserId" => "user5(500)",
                        "_UID" => "500",
                        "_UserName" => "user5",
                        "GroupId" => "group5(505)",
                        "MCS_label" => "N/A",
                        "Priority" => "105882",
                        "Nice" => "0",
                        "Account" => "account5",
                        "QOS" => "normal",
                        "JobState" => "PENDING",
                        "Reason" => "PartitionConfig",
                        "Dependency" => "(null)",
                        "Requeue" => "0",
                        "Restarts" => "0",
                        "BatchFlag" => "1",
                        "Reboot" => "0",
                        "ExitCode" => "0:0",
                        "DerivedExitCode" => "0:0",
                        "RunTime" => "00:00:00",
                        "TimeLimit" => "00:10:00",
                        "TimeMin" => "N/A",
                        "SubmitTime" => "2020-01-21T12:12:46",
                        "EligibleTime" => "2020-01-21T12:12:46",
                        "AccrueTime" => "2020-01-21T12:12:46",
                        "StartTime" => "2020-01-21T12:22:42",
                        "EndTime" => "2020-01-21T12:32:42",
                        "Deadline" => "N/A",
                        "SuspendTime" => "None",
                        "SecsPreSuspend" => "0",
                        "LastSchedEval" => "2020-01-21T12:15:09",
                        "Partition" => "short,long,other",
                        "AllocNode:Sid" => "newt.cs.huji.ac.il:25104",
                        "ReqNodeList" => "(null)",
                        "ExcNodeList" => "(null)",
                        "NodeList" => "(null)",
                        "_NodeList" => [],
                        "SchedNodeList" => "doppelganger,dune3",
                        "_SchedNodeList" => ["doppelganger", "dune3"],
                        "NumNodes" => "2-2",
                        "NumCPUs" => "2",
                        "NumTasks" => "2",
                        "CPUs/Task" => "1",
                        "ReqB:S:C:T" => "0:0:*:*",
                        "TRES" => "cpu=2,mem=100M,node=2,billing=2",
                        "_TRES" => {cpu => 2, mem => "100M", node => 2, billing => 2},
                        "Socks/Node" => "*",
                        "NtasksPerN:B:S:C" => "0:0:*:*",
                        "CoreSpec" => "*",
                        "MinCPUsNode" => "1",
                        "MinMemoryCPU" => "50M",
                        "MinTmpDiskNode" => "0",
                        "Features" => "(null)",
                        "DelayBoot" => "00:00:00",
                        "ClusterFeatures" => "c-f1",
                        "OverSubscribe" => "OK",
                        "Contiguous" => "0",
                        "Licenses" => "(null)",
                        "Network" => "(null)",
                        "Command" => "(null)",
                        "WorkDir" => "/work/dir/1",
                        "StdErr" => "/std/err2",
                        "StdIn" => "/dev/null",
                        "StdOut" => "/std/out3",
                        "Power" => "",
                        "_DETAILS" => [],
                       }
           );

my $results = get_jobs(_scontrol_output => [split /\n/, $jobs]);
is_deeply($results, \%jobs);

done_testing();

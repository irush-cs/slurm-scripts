#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(parse_scontrol_show);

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
     Nodes=node-64 CPU_IDs=4-7 Mem=2000 GRES_IDX=
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
                  "_DETAILS" => [{"Nodes" => "node-63", "CPU_IDs" => "22-23", "Mem" => "1000", "GRES_IDX" => ""},
                                 {"Nodes" => "node-64", "CPU_IDs" => "4-7", "Mem" => "2000", "GRES_IDX" => ""},
                                 {"Nodes" => "node-65", "CPU_IDs" => "20-21", "Mem" => "1000", "GRES_IDX" => ""},
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
                        "_DETAILS" => [{"Nodes" => "node-44", "CPU_IDs" => "2-3", "Mem" => "16000", "GRES_IDX" => ""}],
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
                       },
           );

my $nodes = "NodeName=cortex-01 Arch=x86_64 CoresPerSocket=8
   CPUAlloc=16 CPUErr=0 CPUTot=16 CPULoad=6.98
   AvailableFeatures=cortex
   ActiveFeatures=cortex
   Gres=gpu:m60:8
   GresDrain=N/A
   GresUsed=gpu:m60:8(IDX:0-7)
   NodeAddr=cortex-01 NodeHostName=cortex-01 Version=17.11
   OS=Linux 4.14.61-aufs-1 #1 SMP Tue Aug 7 18:13:22 IDT 2018 
   RealMemory=257860 AllocMem=196608 FreeMem=231242 Sockets=2 Boards=1
   MemSpecLimit=1024
   State=ALLOCATED ThreadsPerCore=1 TmpDisk=95995 Weight=8 Owner=N/A MCS_label=N/A
   Partitions=short,killable 
   BootTime=2018-12-24T14:09:28 SlurmdStartTime=2019-01-27T00:08:52
   CfgTRES=cpu=16,mem=257860M,billing=16,gres/gpu=8
   AllocTRES=cpu=16,mem=192G,gres/gpu=8
   CapWatts=n/a
   CurrentWatts=0 LowestJoules=0 ConsumedJoules=0
   ExtSensorsJoules=n/s ExtSensorsWatts=0 ExtSensorsTemp=n/s
   

NodeName=dumfries-002 Arch=x86_64 CoresPerSocket=8
   CPUAlloc=32 CPUErr=0 CPUTot=32 CPULoad=24.95
   AvailableFeatures=dumfries
   ActiveFeatures=dumfries
   Gres=gpu:rtx2080:4
   GresDrain=N/A
   GresUsed=gpu:rtx2080:4(IDX:0-3)
   NodeAddr=dumfries-002 NodeHostName=dumfries-002 Version=17.11
   OS=Linux 4.14.61-aufs-1 #1 SMP Tue Aug 7 18:13:22 IDT 2018 
   RealMemory=128586 AllocMem=69632 FreeMem=105418 Sockets=2 Boards=1
   MemSpecLimit=1024
   State=ALLOCATED ThreadsPerCore=2 TmpDisk=95611 Weight=9 Owner=N/A MCS_label=N/A
   Partitions=short,medium,killable 
   BootTime=2019-01-28T15:51:33 SlurmdStartTime=2019-01-28T15:57:24
   CfgTRES=cpu=32,mem=128586M,billing=32,gres/gpu=4
   AllocTRES=cpu=32,mem=68G,gres/gpu=4
   CapWatts=n/a
   CurrentWatts=0 LowestJoules=0 ConsumedJoules=0
   ExtSensorsJoules=n/s ExtSensorsWatts=0 ExtSensorsTemp=n/s
   

NodeName=oxygen-04 Arch=x86_64 CoresPerSocket=12
   CPUAlloc=0 CPUErr=0 CPUTot=48 CPULoad=0.00
   AvailableFeatures=oxygen
   ActiveFeatures=oxygen
   Gres=(null)
   GresDrain=N/A
   GresUsed=gpu:0
   NodeAddr=oxygen-04 NodeHostName=oxygen-04 Version=17.11
   OS=Linux 4.14.61-aufs-1 #1 SMP Tue Aug 7 18:13:22 IDT 2018 
   RealMemory=257855 AllocMem=0 FreeMem=257040 Sockets=2 Boards=1
   MemSpecLimit=1024
   State=IDLE+DRAIN ThreadsPerCore=2 TmpDisk=47932 Weight=5 Owner=N/A MCS_label=N/A
   Partitions=short,medium,long,killable 
   BootTime=2019-01-29T10:46:30 SlurmdStartTime=2019-01-29T10:47:34
   CfgTRES=cpu=48,mem=257855M,billing=48
   AllocTRES=
   CapWatts=n/a
   CurrentWatts=0 LowestJoules=0 ConsumedJoules=0
   ExtSensorsJoules=n/s ExtSensorsWatts=0 ExtSensorsTemp=n/s
   Reason=memory issues? [root@2019-01-29T10:42:12]
";

my %nodes = ("cortex-01" => {"NodeName" => "cortex-01",
                             "Arch" => "x86_64",
                             "CoresPerSocket" => "8",
                             "CPUAlloc" => "16",
                             "CPUErr" => "0",
                             "CPUTot" => "16",
                             "CPULoad" => "6.98",
                             "AvailableFeatures" => "cortex",
                             "ActiveFeatures" => "cortex",
                             "Gres" => "gpu:m60:8",
                             "GresDrain" => "N/A",
                             "GresUsed" => "gpu:m60:8(IDX:0-7)",
                             "NodeAddr" => "cortex-01",
                             "NodeHostName" => "cortex-01",
                             "Version" => "17.11",
                             "OS" => "Linux 4.14.61-aufs-1 #1 SMP Tue Aug 7 18:13:22 IDT 2018",
                             "RealMemory" => "257860",
                             "AllocMem" => "196608",
                             "FreeMem" => "231242",
                             "Sockets" => "2",
                             "Boards" => "1",
                             "MemSpecLimit" => "1024",
                             "State" => "ALLOCATED",
                             "ThreadsPerCore" => "1",
                             "TmpDisk" => "95995",
                             "Weight" => "8",
                             "Owner" => "N/A",
                             "MCS_label" => "N/A",
                             "Partitions" => "short,killable",
                             "BootTime" => "2018-12-24T14:09:28",
                             "SlurmdStartTime" => "2019-01-27T00:08:52",
                             "CfgTRES" => "cpu=16,mem=257860M,billing=16,gres/gpu=8",
                             "AllocTRES" => "cpu=16,mem=192G,gres/gpu=8",
                             "CapWatts" => "n/a",
                             "CurrentWatts" => "0",
                             "LowestJoules" => "0",
                             "ConsumedJoules" => "0",
                             "ExtSensorsJoules" => "n/s",
                             "ExtSensorsWatts" => "0",
                             "ExtSensorsTemp" => "n/s",
                            },
             
             "dumfries-002" => {"NodeName" => "dumfries-002",
                                "Arch" => "x86_64",
                                "CoresPerSocket" => "8",
                                "CPUAlloc" => "32",
                                "CPUErr" => "0",
                                "CPUTot" => "32",
                                "CPULoad" => "24.95",
                                "AvailableFeatures" => "dumfries",
                                "ActiveFeatures" => "dumfries",
                                "Gres" => "gpu:rtx2080:4",
                                "GresDrain" => "N/A",
                                "GresUsed" => "gpu:rtx2080:4(IDX:0-3)",
                                "NodeAddr" => "dumfries-002",
                                "NodeHostName" => "dumfries-002",
                                "Version" => "17.11",
                                "OS" => "Linux 4.14.61-aufs-1 #1 SMP Tue Aug 7 18:13:22 IDT 2018",
                                "RealMemory" => "128586",
                                "AllocMem" => "69632",
                                "FreeMem" => "105418",
                                "Sockets" => "2",
                                "Boards" => "1",
                                "MemSpecLimit" => "1024",
                                "State" => "ALLOCATED",
                                "ThreadsPerCore" => "2",
                                "TmpDisk" => "95611",
                                "Weight" => "9",
                                "Owner" => "N/A",
                                "MCS_label" => "N/A",
                                "Partitions" => "short,medium,killable",
                                "BootTime" => "2019-01-28T15:51:33",
                                "SlurmdStartTime" => "2019-01-28T15:57:24",
                                "CfgTRES" => "cpu=32,mem=128586M,billing=32,gres/gpu=4",
                                "AllocTRES" => "cpu=32,mem=68G,gres/gpu=4",
                                "CapWatts" => "n/a",
                                "CurrentWatts" => "0",
                                "LowestJoules" => "0",
                                "ConsumedJoules" => "0",
                                "ExtSensorsJoules" => "n/s",
                                "ExtSensorsWatts" => "0",
                                "ExtSensorsTemp" => "n/s",
                               },

             "oxygen-04" => {"NodeName" => "oxygen-04",
                             "Arch" => "x86_64",
                             "CoresPerSocket" => "12",
                             "CPUAlloc" => "0",
                             "CPUErr" => "0",
                             "CPUTot" => "48",
                             "CPULoad" => "0.00",
                             "AvailableFeatures" => "oxygen",
                             "ActiveFeatures" => "oxygen",
                             "Gres" => "(null)",
                             "GresDrain" => "N/A",
                             "GresUsed" => "gpu:0",
                             "NodeAddr" => "oxygen-04",
                             "NodeHostName" => "oxygen-04",
                             "Version" => "17.11",
                             "OS" => "Linux 4.14.61-aufs-1 #1 SMP Tue Aug 7 18:13:22 IDT 2018",
                             "RealMemory" => "257855",
                             "AllocMem" => "0",
                             "FreeMem" => "257040",
                             "Sockets" => "2",
                             "Boards" => "1",
                             "MemSpecLimit" => "1024",
                             "State" => "IDLE+DRAIN",
                             "ThreadsPerCore" => "2",
                             "TmpDisk" => "47932",
                             "Weight" => "5",
                             "Owner" => "N/A",
                             "MCS_label" => "N/A",
                             "Partitions" => "short,medium,long,killable",
                             "BootTime" => "2019-01-29T10:46:30",
                             "SlurmdStartTime" => "2019-01-29T10:47:34",
                             "CfgTRES" => "cpu=48,mem=257855M,billing=48",
                             "AllocTRES" => "",
                             "CapWatts" => "n/a",
                             "CurrentWatts" => "0",
                             "LowestJoules" => "0",
                             "ConsumedJoules" => "0",
                             "ExtSensorsJoules" => "n/s",
                             "ExtSensorsWatts" => "0",
                             "ExtSensorsTemp" => "n/s",
                             "Reason" => "memory issues? [root@2019-01-29T10:42:12]",
                            },
            );

my $partitions = "PartitionName=long
   AllowGroups=ALL DenyAccounts=killable-cs AllowQos=ALL
   AllocNodes=ALL Default=NO QoS=N/A
   DefaultTime=02:00:00 DisableRootJobs=YES ExclusiveUser=NO GraceTime=0 Hidden=NO
   MaxNodes=UNLIMITED MaxTime=21-00:00:00 MinNodes=1 LLN=NO MaxCPUsPerNode=UNLIMITED
   Nodes=eye-[01-04],sulfur-[01-16],sm-[01-04,07-08,15-20],cb-[05-20],oxygen-[01-08]
   PriorityJobFactor=1 PriorityTier=2 RootOnly=NO ReqResv=NO OverSubscribe=NO
   OverTimeLimit=NONE PreemptMode=REQUEUE
   State=UP TotalCPUs=1056 TotalNodes=56 SelectTypeParameters=NONE
   DefMemPerNode=UNLIMITED MaxMemPerNode=UNLIMITED

PartitionName=killable
   AllowGroups=ALL AllowAccounts=killable-cs AllowQos=ALL
   AllocNodes=ALL Default=YES QoS=N/A
   DefaultTime=02:00:00 DisableRootJobs=YES ExclusiveUser=NO GraceTime=0 Hidden=NO
   MaxNodes=UNLIMITED MaxTime=21-00:00:00 MinNodes=1 LLN=NO MaxCPUsPerNode=UNLIMITED
   Nodes=cb-[05-20],cortex-[01-08],dumfries-[001-002],eye-[01-04],gsm-[01-04],lucy-[01-03],oxygen-[01-08],sm-[01-04,07-08,15-20],sulfur-[01-16]
   PriorityJobFactor=1 PriorityTier=1 RootOnly=NO ReqResv=NO OverSubscribe=NO
   OverTimeLimit=NONE PreemptMode=REQUEUE
   State=UP TotalCPUs=1544 TotalNodes=73 SelectTypeParameters=NONE
   DefMemPerNode=UNLIMITED MaxMemPerNode=UNLIMITED
";

my $assoc_mgr = "Current Association Manager state

Association Records

ClusterName=cluster1 Account=root UserName= Partition= Priority=0 ID=1
    SharesRaw/Norm/Level/Factor=1/0.00/1/0.00
    UsageRaw/Norm/Efctv=1646501252.24/1.00/1.00
    ParentAccount= Lft=1 DefAssoc=No
    GrpJobs=N(700) GrpJobsAccrue=N(0)
    GrpSubmitJobs=N(700) GrpWall=N(10556027.97)
    GrpTRES=cpu=N(1434),mem=N(2709980),energy=N(0),node=N(66),billing=N(1434),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(80),license/interactive=N(6)
    GrpTRESMins=cpu=N(27642627),mem=N(49493614890),energy=N(0),node=N(10586614),billing=N(27441687),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(1093678),license/interactive=N(78325)
    GrpTRESRunMins=cpu=N(3413840),mem=N(13010318176),energy=N(0),node=N(1195517),billing=N(3413840),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(383525),license/interactive=N(7705)
    MaxJobs= MaxJobsAccrue= MaxSubmitJobs= MaxWallPJ=
    MaxTRESPJ=
    MaxTRESPN=
    MaxTRESMinsPJ=
    MinPrioThresh=
ClusterName=cluster1 Account=guests UserName= Partition= Priority=0 ID=10
    SharesRaw/Norm/Level/Factor=1/0.17/6/0.00
    UsageRaw/Norm/Efctv=112387028.16/0.07/0.07
    ParentAccount=root(1) Lft=1620 DefAssoc=No
    GrpJobs=N(60) GrpJobsAccrue=N(0)
    GrpSubmitJobs=N(60) GrpWall=N(304980.53)
    GrpTRES=cpu=554(230),mem=3007203(673828),energy=N(0),node=N(17),billing=N(230),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=33(12),license/interactive=N(1)
    GrpTRESMins=cpu=N(1873117),mem=N(7858589396),energy=N(0),node=N(334291),billing=N(1873117),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(114222),license/interactive=N(4871)
    GrpTRESRunMins=cpu=N(1714124),mem=N(4605810015),energy=N(0),node=N(409492),billing=N(1714124),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(42851),license/interactive=N(1263)
    MaxJobs= MaxJobsAccrue= MaxSubmitJobs= MaxWallPJ=
    MaxTRESPJ=
    MaxTRESPN=
    MaxTRESMinsPJ=
    MinPrioThresh=
ClusterName=cluster1 Account=account1 UserName= Partition= Priority=0 ID=11
    SharesRaw/Norm/Level/Factor=1/0.03/30/0.00
    UsageRaw/Norm/Efctv=6.58/0.00/0.00
    ParentAccount=guests(10) Lft=2743 DefAssoc=No
    GrpJobs=N(0) GrpJobsAccrue=N(0)
    GrpSubmitJobs=N(0) GrpWall=N(0.04)
    GrpTRES=cpu=194(0),mem=1052521(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=12(0),license/interactive=N(0)
    GrpTRESMins=cpu=N(0),mem=N(50),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=N(0)
    GrpTRESRunMins=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=N(0)
    MaxJobs= MaxJobsAccrue= MaxSubmitJobs= MaxWallPJ=
    MaxTRESPJ=
    MaxTRESPN=
    MaxTRESMinsPJ=
    MinPrioThresh=
ClusterName=cluster1 Account=account1 UserName=user1(1000) Partition= Priority=0 ID=22
    SharesRaw/Norm/Level/Factor=1/0.33/3/0.61
    UsageRaw/Norm/Efctv=5.88/0.00/0.89
    ParentAccount= Lft=2746 DefAssoc=No
    GrpJobs=N(0) GrpJobsAccrue=N(0)
    GrpSubmitJobs=N(0) GrpWall=N(0.04)
    GrpTRES=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=2(0)
    GrpTRESMins=cpu=N(0),mem=N(50),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=N(0)
    GrpTRESRunMins=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=N(0)
    MaxJobs= MaxJobsAccrue= MaxSubmitJobs= MaxWallPJ=
    MaxTRESPJ=
    MaxTRESPN=
    MaxTRESMinsPJ=
    MinPrioThresh=
ClusterName=cluster1 Account=account1 UserName=user2(2000) Partition= Priority=0 ID=12
    SharesRaw/Norm/Level/Factor=1/0.33/3/0.61
    UsageRaw/Norm/Efctv=0.00/0.00/0.00
    ParentAccount= Lft=2748 DefAssoc=No
    GrpJobs=N(0) GrpJobsAccrue=N(0)
    GrpSubmitJobs=N(0) GrpWall=N(0.00)
    GrpTRES=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=2(0)
    GrpTRESMins=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=N(0)
    GrpTRESRunMins=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=N(0)
    MaxJobs= MaxJobsAccrue= MaxSubmitJobs= MaxWallPJ=
    MaxTRESPJ=
    MaxTRESPN=
    MaxTRESMinsPJ=
    MinPrioThresh=
";

my %partitions = ("long" => {"PartitionName" => "long",
                             "AllowGroups" => "ALL",
                             "DenyAccounts" => "killable-cs",
                             "AllowQos" => "ALL",
                             "AllocNodes" => "ALL",
                             "Default" => "NO",
                             "QoS" => "N/A",
                             "DefaultTime" => "02:00:00",
                             "DisableRootJobs" => "YES",
                             "ExclusiveUser" => "NO",
                             "GraceTime" => "0",
                             "Hidden" => "NO",
                             "MaxNodes" => "UNLIMITED",
                             "MaxTime" => "21-00:00:00",
                             "MinNodes" => "1",
                             "LLN" => "NO",
                             "MaxCPUsPerNode" => "UNLIMITED",
                             "Nodes" => "eye-[01-04],sulfur-[01-16],sm-[01-04,07-08,15-20],cb-[05-20],oxygen-[01-08]",
                             "PriorityJobFactor" => "1",
                             "PriorityTier" => "2",
                             "RootOnly" => "NO",
                             "ReqResv" => "NO",
                             "OverSubscribe" => "NO",
                             "OverTimeLimit" => "NONE",
                             "PreemptMode" => "REQUEUE",
                             "State" => "UP",
                             "TotalCPUs" => "1056",
                             "TotalNodes" => "56",
                             "SelectTypeParameters" => "NONE",
                             "DefMemPerNode" => "UNLIMITED",
                             "MaxMemPerNode" => "UNLIMITED",
                            }, 
                  "killable" => {"PartitionName" => "killable",
                                 "AllowGroups" => "ALL",
                                 "AllowAccounts" => "killable-cs",
                                 "AllowQos" => "ALL",
                                 "AllocNodes" => "ALL",
                                 "Default" => "YES",
                                 "QoS" => "N/A",
                                 "DefaultTime" => "02:00:00",
                                 "DisableRootJobs" => "YES",
                                 "ExclusiveUser" => "NO",
                                 "GraceTime" => "0",
                                 "Hidden" => "NO",
                                 "MaxNodes" => "UNLIMITED",
                                 "MaxTime" => "21-00:00:00",
                                 "MinNodes" => "1",
                                 "LLN" => "NO",
                                 "MaxCPUsPerNode" => "UNLIMITED",
                                 "Nodes" => "cb-[05-20],cortex-[01-08],dumfries-[001-002],eye-[01-04],gsm-[01-04],lucy-[01-03],oxygen-[01-08],sm-[01-04,07-08,15-20],sulfur-[01-16]",
                                 "PriorityJobFactor" => "1",
                                 "PriorityTier" => "1",
                                 "RootOnly" => "NO",
                                 "ReqResv" => "NO",
                                 "OverSubscribe" => "NO",
                                 "OverTimeLimit" => "NONE",
                                 "PreemptMode" => "REQUEUE",
                                 "State" => "UP",
                                 "TotalCPUs" => "1544",
                                 "TotalNodes" => "73",
                                 "SelectTypeParameters" => "NONE",
                                 "DefMemPerNode" => "UNLIMITED",
                                 "MaxMemPerNode" => "UNLIMITED",
                                },                  
                 );

my @assoc_mgr = ({
                  "ClusterName" => "cluster1",
                  "Account" => "root",
                  "UserName" => "",
                  "Partition" => "",
                  "Priority" => "0",
                  "ID" => "1",
                  "SharesRaw/Norm/Level/Factor" => "1/0.00/1/0.00",
                  "UsageRaw/Norm/Efctv" => "1646501252.24/1.00/1.00",
                  "ParentAccount" => "",
                  "Lft" => "1",
                  "DefAssoc" => "No",
                  "GrpJobs" => "N(700)",
                  "GrpJobsAccrue" => "N(0)",
                  "GrpSubmitJobs" => "N(700)",
                  "GrpWall" => "N(10556027.97)",
                  "GrpTRES" => "cpu=N(1434),mem=N(2709980),energy=N(0),node=N(66),billing=N(1434),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(80),license/interactive=N(6)",
                  "GrpTRESMins" => "cpu=N(27642627),mem=N(49493614890),energy=N(0),node=N(10586614),billing=N(27441687),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(1093678),license/interactive=N(78325)",
                  "GrpTRESRunMins" => "cpu=N(3413840),mem=N(13010318176),energy=N(0),node=N(1195517),billing=N(3413840),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(383525),license/interactive=N(7705)",
                  "MaxJobs" => "",
                  "MaxJobsAccrue" => "",
                  "MaxSubmitJobs" => "",
                  "MaxWallPJ" => "",
                  "MaxTRESPJ" => "",
                  "MaxTRESPN" => "",
                  "MaxTRESMinsPJ" => "",
                  "MinPrioThresh" => "",
                 },
                 {
                  "ClusterName" => "cluster1",
                  "Account" => "guests",
                  "UserName" => "",
                  "Partition" => "",
                  "Priority" => "0",
                  "ID" => "10",
                  "SharesRaw/Norm/Level/Factor" => "1/0.17/6/0.00",
                  "UsageRaw/Norm/Efctv" => "112387028.16/0.07/0.07",
                  "ParentAccount" => "root(1)",
                  "Lft" => "1620",
                  "DefAssoc" => "No",
                  "GrpJobs" => "N(60)",
                  "GrpJobsAccrue" => "N(0)",
                  "GrpSubmitJobs" => "N(60)",
                  "GrpWall" => "N(304980.53)",
                  "GrpTRES" => "cpu=554(230),mem=3007203(673828),energy=N(0),node=N(17),billing=N(230),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=33(12),license/interactive=N(1)",
                  "GrpTRESMins" => "cpu=N(1873117),mem=N(7858589396),energy=N(0),node=N(334291),billing=N(1873117),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(114222),license/interactive=N(4871)",
                  "GrpTRESRunMins" => "cpu=N(1714124),mem=N(4605810015),energy=N(0),node=N(409492),billing=N(1714124),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(42851),license/interactive=N(1263)",
                  "MaxJobs" => "",
                  "MaxJobsAccrue" => "",
                  "MaxSubmitJobs" => "",
                  "MaxWallPJ" => "",
                  "MaxTRESPJ" => "",
                  "MaxTRESPN" => "",
                  "MaxTRESMinsPJ" => "",
                  "MinPrioThresh" => "",
                 },
                 {
                  "ClusterName" => "cluster1",
                  "Account" => "account1",
                  "UserName" => "",
                  "Partition" => "",
                  "Priority" => "0",
                  "ID" => "11",
                  "SharesRaw/Norm/Level/Factor" => "1/0.03/30/0.00",
                  "UsageRaw/Norm/Efctv" => "6.58/0.00/0.00",
                  "ParentAccount" => "guests(10)",
                  "Lft" => "2743",
                  "DefAssoc" => "No",
                  "GrpJobs" => "N(0)",
                  "GrpJobsAccrue" => "N(0)",
                  "GrpSubmitJobs" => "N(0)",
                  "GrpWall" => "N(0.04)",
                  "GrpTRES" => "cpu=194(0),mem=1052521(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=12(0),license/interactive=N(0)",
                  "GrpTRESMins" => "cpu=N(0),mem=N(50),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=N(0)",
                  "GrpTRESRunMins" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=N(0)",
                  "MaxJobs" => "",
                  "MaxJobsAccrue" => "",
                  "MaxSubmitJobs" => "",
                  "MaxWallPJ" => "",
                  "MaxTRESPJ" => "",
                  "MaxTRESPN" => "",
                  "MaxTRESMinsPJ" => "",
                  "MinPrioThresh" => "",
                 },
                 {
                  "ClusterName" => "cluster1",
                  "Account" => "account1",
                  "UserName" => "user1(1000)",
                  "Partition" => "",
                  "Priority" => "0",
                  "ID" => "22",
                  "SharesRaw/Norm/Level/Factor" => "1/0.33/3/0.61",
                  "UsageRaw/Norm/Efctv" => "5.88/0.00/0.89",
                  "ParentAccount" => "",
                  "Lft" => "2746",
                  "DefAssoc" => "No",
                  "GrpJobs" => "N(0)",
                  "GrpJobsAccrue" => "N(0)",
                  "GrpSubmitJobs" => "N(0)",
                  "GrpWall" => "N(0.04)",
                  "GrpTRES" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=2(0)",
                  "GrpTRESMins" => "cpu=N(0),mem=N(50),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=N(0)",
                  "GrpTRESRunMins" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=N(0)",
                  "MaxJobs" => "",
                  "MaxJobsAccrue" => "",
                  "MaxSubmitJobs" => "",
                  "MaxWallPJ" => "",
                  "MaxTRESPJ" => "",
                  "MaxTRESPN" => "",
                  "MaxTRESMinsPJ" => "",
                  "MinPrioThresh" => "",
                 },
                 {
                  "ClusterName" => "cluster1",
                  "Account" => "account1",
                  "UserName" => "user2(2000)",
                  "Partition" => "",
                  "Priority" => "0",
                  "ID" => "12",
                  "SharesRaw/Norm/Level/Factor" => "1/0.33/3/0.61",
                  "UsageRaw/Norm/Efctv" => "0.00/0.00/0.00",
                  "ParentAccount" => "",
                  "Lft" => "2748",
                  "DefAssoc" => "No",
                  "GrpJobs" => "N(0)",
                  "GrpJobsAccrue" => "N(0)",
                  "GrpSubmitJobs" => "N(0)",
                  "GrpWall" => "N(0.00)",
                  "GrpTRES" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=2(0)",
                  "GrpTRESMins" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=N(0)",
                  "GrpTRESRunMins" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0),license/interactive=N(0)",
                  "MaxJobs" => "",
                  "MaxJobsAccrue" => "",
                  "MaxSubmitJobs" => "",
                  "MaxWallPJ" => "",
                  "MaxTRESPJ" => "",
                  "MaxTRESPN" => "",
                  "MaxTRESMinsPJ" => "",
                  "MinPrioThresh" => "",
                 },
);

my $results = parse_scontrol_show([split /\n/, $jobs]);
is_deeply($results, \%jobs);

$results = parse_scontrol_show([split /\n/, $nodes]);
is_deeply($results, \%nodes);

$results = parse_scontrol_show([split /\n/, $partitions]);
is_deeply($results, \%partitions);

$results = parse_scontrol_show([split /\n/, $assoc_mgr], type => "list");
is_deeply($results, \@assoc_mgr);

done_testing();

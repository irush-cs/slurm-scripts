#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(get_nodes);

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

NodeName=cricket Arch=x86_64 CoresPerSocket=4 
   CPUAlloc=0 CPUTot=8 CPULoad=0.02
   AvailableFeatures=cricket
   ActiveFeatures=cricket
   Gres=gpu:quadro:1(S:0),vmem:2G
   GresDrain=N/A
   GresUsed=gpu:quadro:0(IDX:N/A),vmem:0
   NodeAddr=cricket NodeHostName=cricket 
   OS=Linux 4.14.138-aufs-1 #1 SMP Tue Aug 13 16:21:39 IDT 2019 
   RealMemory=7907 AllocMem=0 FreeMem=4608 Sockets=1 Boards=1
   MemSpecLimit=1024
   State=IDLE ThreadsPerCore=2 TmpDisk=47932 Weight=3 Owner=N/A MCS_label=N/A
   Partitions=short,long,debug,other,allowed,deny 
   BootTime=2019-11-06T16:17:37 SlurmdStartTime=2019-11-17T07:39:50
   CfgTRES=cpu=8,mem=7907M,billing=8,gres/gpu=1
   AllocTRES=
   CapWatts=n/a
   CurrentWatts=0 AveWatts=0
   ExtSensorsJoules=n/s ExtSensorsWatts=0 ExtSensorsTemp=n/s
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
                             "_Gres" => {"gpu" => 8},
                             "_GresType" => {"gpu:m60" => 8},
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
                                "_Gres" => {gpu => 4},
                                "_GresType" => {"gpu:rtx2080" => 4},
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
                             "Gres" => "",
                             "_Gres" => {},
                             "_GresType" => {},
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

             "cricket" => {"NodeName" => "cricket",
                           "Arch" => "x86_64",
                           "CoresPerSocket" => "4",
                           "CPUAlloc" => "0",
                           "CPUTot" => "8",
                           "CPULoad" => "0.02",
                           "AvailableFeatures" => "cricket",
                           "ActiveFeatures" => "cricket",
                           "Gres" => "gpu:quadro:1(S:0),vmem:2G",
                           "_Gres" => {"vmem" => "2048M", gpu => "1"},
                           "_GresType" => {"vmem" => "2048M", "gpu:quadro" => "1"},
                           "GresDrain" => "N/A",
                           "GresUsed" => "gpu:quadro:0(IDX:N/A),vmem:0",
                           "NodeAddr" => "cricket",
                           "NodeHostName" => "cricket",
                           "OS" => "Linux 4.14.138-aufs-1 #1 SMP Tue Aug 13 16:21:39 IDT 2019",
                           "RealMemory" => "7907",
                           "AllocMem" => "0",
                           "FreeMem" => "4608",
                           "Sockets" => "1",
                           "Boards" => "1",
                           "MemSpecLimit" => "1024",
                           "State" => "IDLE",
                           "ThreadsPerCore" => "2",
                           "TmpDisk" => "47932",
                           "Weight" => "3",
                           "Owner" => "N/A",
                           "MCS_label" => "N/A",
                           "Partitions" => "short,long,debug,other,allowed,deny",
                           "BootTime" => "2019-11-06T16:17:37",
                           "SlurmdStartTime" => "2019-11-17T07:39:50",
                           "CfgTRES" => "cpu=8,mem=7907M,billing=8,gres/gpu=1",
                           "AllocTRES" => "",
                           "CapWatts" => "n/a",
                           "CurrentWatts" => "0",
                           "AveWatts" => "0",
                           "ExtSensorsJoules" => "n/s",
                           "ExtSensorsWatts" => "0",
                           "ExtSensorsTemp" => "n/s",
                          },
            );

my $results = get_nodes(_scontrol_output => [split /\n/, $nodes]);
is_deeply($results, \%nodes);

done_testing();

#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(get_partitions);

my $partitions = "PartitionName=short
   AllowGroups=ALL DenyAccounts=account1,account2 AllowQos=ALL
   AllocNodes=ALL Default=NO QoS=N/A
   DefaultTime=00:10:00 DisableRootJobs=YES ExclusiveUser=NO GraceTime=0 Hidden=NO
   MaxNodes=UNLIMITED MaxTime=2-00:00:00 MinNodes=0 LLN=NO MaxCPUsPerNode=UNLIMITED
   Nodes=node[1-7]
   PriorityJobFactor=1 PriorityTier=2 RootOnly=NO ReqResv=NO OverSubscribe=NO
   OverTimeLimit=NONE PreemptMode=REQUEUE
   State=UP TotalCPUs=38 TotalNodes=7 SelectTypeParameters=NONE
   JobDefaults=(null)
   DefMemPerNode=UNLIMITED MaxMemPerNode=UNLIMITED

PartitionName=long
   AllowGroups=ALL DenyAccounts=account1,account2 AllowQos=ALL
   AllocNodes=ALL Default=YES QoS=N/A
   DefaultTime=02:00:00 DisableRootJobs=YES ExclusiveUser=NO GraceTime=0 Hidden=NO
   MaxNodes=UNLIMITED MaxTime=21-00:00:00 MinNodes=0 LLN=NO MaxCPUsPerNode=UNLIMITED
   Nodes=node[3-7]
   PriorityJobFactor=1 PriorityTier=2 RootOnly=NO ReqResv=NO OverSubscribe=NO
   OverTimeLimit=NONE PreemptMode=REQUEUE
   State=UP TotalCPUs=38 TotalNodes=7 SelectTypeParameters=NONE
   JobDefaults=(null)
   DefMemPerNode=UNLIMITED MaxMemPerNode=UNLIMITED

PartitionName=irush
   AllowGroups=ALL AllowAccounts=account3 AllowQos=ALL
   AllocNodes=ALL Default=NO QoS=N/A
   DefaultTime=02:00:00 DisableRootJobs=YES ExclusiveUser=NO GraceTime=0 Hidden=NO
   MaxNodes=UNLIMITED MaxTime=21-00:00:00 MinNodes=0 LLN=NO MaxCPUsPerNode=UNLIMITED
   Nodes=node3
   PriorityJobFactor=1 PriorityTier=3 RootOnly=NO ReqResv=NO OverSubscribe=NO
   OverTimeLimit=NONE PreemptMode=REQUEUE
   State=UP TotalCPUs=4 TotalNodes=1 SelectTypeParameters=NONE
   JobDefaults=(null)
   DefMemPerNode=UNLIMITED MaxMemPerNode=UNLIMITED

PartitionName=killable
   AllowGroups=ALL AllowAccounts=account1,account2 AllowQos=ALL
   AllocNodes=ALL Default=NO QoS=N/A
   DefaultTime=02:00:00 DisableRootJobs=YES ExclusiveUser=NO GraceTime=0 Hidden=NO
   MaxNodes=UNLIMITED MaxTime=21-00:00:00 MinNodes=0 LLN=NO MaxCPUsPerNode=UNLIMITED
   Nodes=node[2,4,7]
   PriorityJobFactor=1 PriorityTier=1 RootOnly=NO ReqResv=NO OverSubscribe=NO
   OverTimeLimit=NONE PreemptMode=REQUEUE
   State=UP TotalCPUs=38 TotalNodes=7 SelectTypeParameters=NONE
   JobDefaults=(null)
   DefMemPerNode=UNLIMITED MaxMemPerNode=UNLIMITED

PartitionName=interactive
   AllowGroups=ALL DenyAccounts=account1,account2 AllowQos=ALL
   AllocNodes=ALL Default=NO QoS=interactive-partition-qos
   DefaultTime=00:10:00 DisableRootJobs=YES ExclusiveUser=NO GraceTime=0 Hidden=NO
   MaxNodes=UNLIMITED MaxTime=2-00:00:00 MinNodes=0 LLN=NO MaxCPUsPerNode=UNLIMITED
   Nodes=node[1-4]
   PriorityJobFactor=1 PriorityTier=3 RootOnly=NO ReqResv=NO OverSubscribe=NO
   OverTimeLimit=NONE PreemptMode=REQUEUE
   State=UP TotalCPUs=38 TotalNodes=7 SelectTypeParameters=NONE
   JobDefaults=(null)
   DefMemPerNode=UNLIMITED MaxMemPerNode=UNLIMITED

";

my %partitions = (
                  "short" => {"PartitionName" => "short",
                              "AllowGroups" => "ALL",
                              "DenyAccounts" => "account1,account2",
                              "AllowQos" => "ALL",
                              "AllocNodes" => "ALL",
                              "Default" => "NO",
                              "QoS" => "N/A",
                              "DefaultTime" => "00:10:00",
                              "DisableRootJobs" => "YES",
                              "ExclusiveUser" => "NO",
                              "GraceTime" => "0",
                              "Hidden" => "NO",
                              "MaxNodes" => "UNLIMITED",
                              "MaxTime" => "2-00:00:00",
                              "MinNodes" => "0",
                              "LLN" => "NO",
                              "MaxCPUsPerNode" => "UNLIMITED",
                              "Nodes" => "node[1-7]",
                              "_NodeList" => ["node1", "node2", "node3", "node4", "node5", "node6", "node7"],
                              "PriorityJobFactor" => "1",
                              "PriorityTier" => "2",
                              "RootOnly" => "NO",
                              "ReqResv" => "NO",
                              "OverSubscribe" => "NO",
                              "OverTimeLimit" => "NONE",
                              "PreemptMode" => "REQUEUE",
                              "State" => "UP",
                              "TotalCPUs" => "38",
                              "TotalNodes" => "7",
                              "SelectTypeParameters" => "NONE",
                              "JobDefaults" => "(null)",
                              "DefMemPerNode" => "UNLIMITED",
                              "MaxMemPerNode" => "UNLIMITED",
                             },

                  "long" => {"PartitionName" => "long",
                             "AllowGroups" => "ALL",
                             "DenyAccounts" => "account1,account2",
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
                             "MinNodes" => "0",
                             "LLN" => "NO",
                             "MaxCPUsPerNode" => "UNLIMITED",
                             "Nodes" => "node[3-7]",
                             "_NodeList" => ["node3", "node4", "node5", "node6", "node7"],
                             "PriorityJobFactor" => "1",
                             "PriorityTier" => "2",
                             "RootOnly" => "NO",
                             "ReqResv" => "NO",
                             "OverSubscribe" => "NO",
                             "OverTimeLimit" => "NONE",
                             "PreemptMode" => "REQUEUE",
                             "State" => "UP",
                             "TotalCPUs" => "38",
                             "TotalNodes" => "7",
                             "SelectTypeParameters" => "NONE",
                             "JobDefaults" => "(null)",
                             "DefMemPerNode" => "UNLIMITED",
                             "MaxMemPerNode" => "UNLIMITED",
                            },

                  "irush" => {"PartitionName" => "irush",
                              "AllowGroups" => "ALL",
                              "AllowAccounts" => "account3",
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
                              "MinNodes" => "0",
                              "LLN" => "NO",
                              "MaxCPUsPerNode" => "UNLIMITED",
                              "Nodes" => "node3",
                              "_NodeList" => ["node3"],
                              "PriorityJobFactor" => "1",
                              "PriorityTier" => "3",
                              "RootOnly" => "NO",
                              "ReqResv" => "NO",
                              "OverSubscribe" => "NO",
                              "OverTimeLimit" => "NONE",
                              "PreemptMode" => "REQUEUE",
                              "State" => "UP",
                              "TotalCPUs" => "4",
                              "TotalNodes" => "1",
                              "SelectTypeParameters" => "NONE",
                              "JobDefaults" => "(null)",
                              "DefMemPerNode" => "UNLIMITED",
                              "MaxMemPerNode" => "UNLIMITED",
                             },

                  "killable" => {"PartitionName" => "killable",
                                 "AllowGroups" => "ALL",
                                 "AllowAccounts" => "account1,account2",
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
                                 "MinNodes" => "0",
                                 "LLN" => "NO",
                                 "MaxCPUsPerNode" => "UNLIMITED",
                                 "Nodes" => "node[2,4,7]",
                                 "_NodeList" => ["node2", "node4", "node7"],
                                 "PriorityJobFactor" => "1",
                                 "PriorityTier" => "1",
                                 "RootOnly" => "NO",
                                 "ReqResv" => "NO",
                                 "OverSubscribe" => "NO",
                                 "OverTimeLimit" => "NONE",
                                 "PreemptMode" => "REQUEUE",
                                 "State" => "UP",
                                 "TotalCPUs" => "38",
                                 "TotalNodes" => "7",
                                 "SelectTypeParameters" => "NONE",
                                 "JobDefaults" => "(null)",
                                 "DefMemPerNode" => "UNLIMITED",
                                 "MaxMemPerNode" => "UNLIMITED",
                                },

                  "interactive" => {"PartitionName" => "interactive",
                                    "AllowGroups" => "ALL",
                                    "DenyAccounts" => "account1,account2",
                                    "AllowQos" => "ALL",
                                    "AllocNodes" => "ALL",
                                    "Default" => "NO",
                                    "QoS" => "interactive-partition-qos",
                                    "DefaultTime" => "00:10:00",
                                    "DisableRootJobs" => "YES",
                                    "ExclusiveUser" => "NO",
                                    "GraceTime" => "0",
                                    "Hidden" => "NO",
                                    "MaxNodes" => "UNLIMITED",
                                    "MaxTime" => "2-00:00:00",
                                    "MinNodes" => "0",
                                    "LLN" => "NO",
                                    "MaxCPUsPerNode" => "UNLIMITED",
                                    "Nodes" => "node[1-4]",
                                    "_NodeList" => ["node1", "node2", "node3", "node4"],
                                    "PriorityJobFactor" => "1",
                                    "PriorityTier" => "3",
                                    "RootOnly" => "NO",
                                    "ReqResv" => "NO",
                                    "OverSubscribe" => "NO",
                                    "OverTimeLimit" => "NONE",
                                    "PreemptMode" => "REQUEUE",
                                    "State" => "UP",
                                    "TotalCPUs" => "38",
                                    "TotalNodes" => "7",
                                    "SelectTypeParameters" => "NONE",
                                    "JobDefaults" => "(null)",
                                    "DefMemPerNode" => "UNLIMITED",
                                    "MaxMemPerNode" => "UNLIMITED",
                                   },

                 );

my $results = get_partitions(_scontrol_output => [split /\n/, $partitions]);
is_deeply($results, \%partitions);

done_testing();

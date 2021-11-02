#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(get_qos);

my $sacct_qos = "Name|Priority|GraceTime|Preempt|PreemptExemptTime|PreemptMode|Flags|UsageThres|UsageFactor|GrpTRES|GrpTRESMins|GrpTRESRunMins|GrpJobs|GrpSubmit|GrpWall|MaxTRES|MaxTRESPerNode|MaxTRESMins|MaxWall|MaxTRESPU|MaxJobsPU|MaxSubmitPU|MaxTRESPA|MaxJobsPA|MaxSubmitPA|MinTRES|
normal|1000|00:00:00|gutter||cluster|||1.000000|||||||||||||||||cpu=1|
gutter|0|00:00:00|||cluster|||1.000000||||||||||||||||||
rebug-accounta|1000|00:00:00|||cluster|DenyOnLimit,NoDecay||1.000000||billing=2000||||||||||||||||
";

my $scontrol_qos = "Current Association Manager state

QOS Records

QOS=normal(1)
    UsageRaw=0.000000
    GrpJobs=N(0) GrpJobsAccrue=N(0) GrpSubmitJobs=N(0) GrpWall=N(0.00)
    GrpTRES=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)
    GrpTRESMins=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)
    GrpTRESRunMins=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)
    MaxWallPJ=
    MaxTRESPJ=
    MaxTRESPN=
    MaxTRESMinsPJ=
    MinPrioThresh= 
    MinTRESPJ=cpu=1
    PreemptMode=OFF
    Priority=1000
    Account Limits
        No Accounts
    User Limits
        No Users
QOS=gutter(16)
    UsageRaw=0.000000
    GrpJobs=N(0) GrpJobsAccrue=N(0) GrpSubmitJobs=N(0) GrpWall=N(0.00)
    GrpTRES=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)
    GrpTRESMins=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)
    GrpTRESRunMins=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)
    MaxWallPJ=
    MaxTRESPJ=
    MaxTRESPN=
    MaxTRESMinsPJ=
    MinPrioThresh= 
    MinTRESPJ=
    PreemptMode=OFF
    Priority=0
    Account Limits
        No Accounts
    User Limits
        No Users
QOS=rebug-accounta(38)
    UsageRaw=32.000000
    GrpJobs=N(0) GrpJobsAccrue=N(0) GrpSubmitJobs=N(0) GrpWall=N(0.53)
    GrpTRES=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)
    GrpTRESMins=cpu=N(0),mem=N(26),energy=N(0),node=N(0),billing=1000(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)
    GrpTRESRunMins=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)
    MaxWallPJ=
    MaxTRESPJ=
    MaxTRESPN=
    MaxTRESMinsPJ=
    MinPrioThresh= 
    MinTRESPJ=
    PreemptMode=OFF
    Priority=1000
    Account Limits
      accounta
        MaxJobsPA=N(0) MaxJobsAccruePA=N(0) MaxSubmitJobsPA=N(0)
        MaxTRESPA=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)
    User Limits
      1234
        MaxJobsPU=N(0) MaxJobsAccruePU=N(0) MaxSubmitJobsPU=N(0)
        MaxTRESPU=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)
      5678
        MaxJobsPU=N(0) MaxJobsAccruePU=N(0) MaxSubmitJobsPU=N(0)
        MaxTRESPU=cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)
";

my %qos = (
           "normal" => {
                        "Name" => "normal",
                        "Priority" => "1000",
                        "GraceTime" => "00:00:00",
                        "Preempt" => "gutter",
                        "PreemptExemptTime" => "",
                        "PreemptMode" => "cluster",
                        "Flags" => "",
                        "_Flags" => [],
                        "UsageThres" => "",
                        "UsageFactor" => "1.000000",
                        "GrpTRES" => "",
                        "GrpTRESMins" => "",
                        "_GrpTRESMins" => {},
                        "GrpTRESRunMins" => "",
                        "GrpJobs" => "",
                        "GrpSubmit" => "",
                        "GrpWall" => "",
                        "MaxTRES" => "",
                        "MaxTRESPerNode" => "",
                        "MaxTRESMins" => "",
                        "MaxWall" => "",
                        "MaxTRESPU" => "",
                        "MaxJobsPU" => "",
                        "MaxSubmitPU" => "",
                        "MaxTRESPA" => "",
                        "MaxJobsPA" => "",
                        "MaxSubmitPA" => "",
                        "MinTRES" => "cpu=1",
                        "_current" => {
                                       "QOS" => "normal(1)",
                                       "UsageRaw" => "0.000000",
                                       "GrpJobs" => "N(0)",
                                       "GrpJobsAccrue" => "N(0)",
                                       "GrpSubmitJobs" => "N(0)",
                                       "GrpWall" => "N(0.00)",
                                       "GrpTRES" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)",
                                       "GrpTRESMins" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)",
                                       "_GrpTRESMins" => {cpu => "N(0)", mem => "N(0)", energy => "N(0)", node => "N(0)", billing => "N(0)", "fs/disk" => "N(0)", vmem => "N(0)", pages => "N(0)", "gres/gpu" => "N(0)"},
                                       "GrpTRESRunMins" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)",
                                       "MaxWallPJ" => "",
                                       "MaxTRESPJ" => "",
                                       "MaxTRESPN" => "",
                                       "MaxTRESMinsPJ" => "",
                                       "MinPrioThresh" => "",
                                       "MinTRESPJ" => "cpu=1",
                                       "PreemptMode" => "OFF",
                                       "Priority" => "1000",
                                       "Account Limits" => {},
                                       "User Limits" => {},
                                      },
                       },

           "gutter" => {
                        "Name" => "gutter",
                        "Priority" => "0",
                        "GraceTime" => "00:00:00",
                        "Preempt" => "",
                        "PreemptExemptTime" => "",
                        "PreemptMode" => "cluster",
                        "Flags" => "",
                        "_Flags" => [],
                        "UsageThres" => "",
                        "UsageFactor" => "1.000000",
                        "GrpTRES" => "",
                        "GrpTRESMins" => "",
                        "_GrpTRESMins" => {},
                        "GrpTRESRunMins" => "",
                        "GrpJobs" => "",
                        "GrpSubmit" => "",
                        "GrpWall" => "",
                        "MaxTRES" => "",
                        "MaxTRESPerNode" => "",
                        "MaxTRESMins" => "",
                        "MaxWall" => "",
                        "MaxTRESPU" => "",
                        "MaxJobsPU" => "",
                        "MaxSubmitPU" => "",
                        "MaxTRESPA" => "",
                        "MaxJobsPA" => "",
                        "MaxSubmitPA" => "",
                        "MinTRES" => "",
                        "_current" => {
                                       "QOS" => "gutter(16)",
                                       "UsageRaw" => "0.000000",
                                       "GrpJobs" => "N(0)",
                                       "GrpJobsAccrue" => "N(0)",
                                       "GrpSubmitJobs" => "N(0)",
                                       "GrpWall" => "N(0.00)",
                                       "GrpTRES" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)",
                                       "GrpTRESMins" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)",
                                       "_GrpTRESMins" => {"cpu" => "N(0)", mem => "N(0)", energy => "N(0)", node => "N(0)", billing => "N(0)","fs/disk" => "N(0)", vmem => "N(0)", pages => "N(0)", "gres/gpu" => "N(0)"},
                                       "GrpTRESRunMins" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)",
                                       "MaxWallPJ" => "",
                                       "MaxTRESPJ" => "",
                                       "MaxTRESPN" => "",
                                       "MaxTRESMinsPJ" => "",
                                       "MinPrioThresh" => "",
                                       "MinTRESPJ" => "",
                                       "PreemptMode" => "OFF",
                                       "Priority" => "0",
                                       "Account Limits" => {},
                                       "User Limits" => {},
                                      },
                       },

           "rebug-accounta" => {
                                "Name" => "rebug-accounta",
                                "Priority" => "1000",
                                "GraceTime" => "00:00:00",
                                "Preempt" => "",
                                "PreemptExemptTime" => "",
                                "PreemptMode" => "cluster",
                                "Flags" => "DenyOnLimit,NoDecay",
                                "_Flags" => [qw(DenyOnLimit NoDecay)],
                                "UsageThres" => "",
                                "UsageFactor" => "1.000000",
                                "GrpTRES" => "",
                                "GrpTRESMins" => "billing=2000",
                                "_GrpTRESMins" => {billing => 2000},
                                "GrpTRESRunMins" => "",
                                "GrpJobs" => "",
                                "GrpSubmit" => "",
                                "GrpWall" => "",
                                "MaxTRES" => "",
                                "MaxTRESPerNode" => "",
                                "MaxTRESMins" => "",
                                "MaxWall" => "",
                                "MaxTRESPU" => "",
                                "MaxJobsPU" => "",
                                "MaxSubmitPU" => "",
                                "MaxTRESPA" => "",
                                "MaxJobsPA" => "",
                                "MaxSubmitPA" => "",
                                "MinTRES" => "",
                                "_current" => {
                                               "QOS" => "rebug-accounta(38)",
                                               "UsageRaw" => "32.000000",
                                               "GrpJobs" => "N(0)",
                                               "GrpJobsAccrue" => "N(0)",
                                               "GrpSubmitJobs" => "N(0)",
                                               "GrpWall" => "N(0.53)",
                                               "GrpTRES" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)",
                                               "GrpTRESMins" => "cpu=N(0),mem=N(26),energy=N(0),node=N(0),billing=1000(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)",
                                               "_GrpTRESMins" => {cpu => "N(0)", mem => "N(26)", energy => "N(0)", node => "N(0)", billing => "1000(0)", "fs/disk" => "N(0)", vmem => "N(0)", pages => "N(0)", "gres/gpu" => "N(0)"},
                                               "GrpTRESRunMins" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)",
                                               "MaxWallPJ" => "",
                                               "MaxTRESPJ" => "",
                                               "MaxTRESPN" => "",
                                               "MaxTRESMinsPJ" => "",
                                               "MinPrioThresh" => "",
                                               "MinTRESPJ" => "",
                                               "PreemptMode" => "OFF",
                                               "Priority" => "1000",
                                               "Account Limits" => {
                                                                    "accounta" => {
                                                                                   "MaxJobsPA" => "N(0)",
                                                                                   "MaxJobsAccruePA" => "N(0)",
                                                                                   "MaxSubmitJobsPA" => "N(0)",
                                                                                   "MaxTRESPA" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)",
                                                                                  },
                                                                   },
                                               "User Limits" => {"1234" => {
                                                                            "MaxJobsPU" => "N(0)",
                                                                            "MaxJobsAccruePU" => "N(0)",
                                                                            "MaxSubmitJobsPU" => "N(0)",
                                                                            "MaxTRESPU" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)",
                                                                           },
                                                                 "5678" => {
                                                                            "MaxJobsPU" => "N(0)",
                                                                            "MaxJobsAccruePU" => "N(0)",
                                                                            "MaxSubmitJobsPU" => "N(0)",
                                                                            "MaxTRESPU" => "cpu=N(0),mem=N(0),energy=N(0),node=N(0),billing=N(0),fs/disk=N(0),vmem=N(0),pages=N(0),gres/gpu=N(0)",
                                                                           },
                                                                },

                                              },
                               },
);

my $results = get_qos(_sacctmgr_output => [split /\n/, $sacct_qos], _scontrol_output => [split /\n/, $scontrol_qos]);
is_deeply($results, \%qos);

done_testing();

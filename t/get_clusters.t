#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(get_clusters);

my $clusters = "Cluster|ControlHost|ControlPort|RPC|Share|GrpJobs|GrpTRES|GrpSubmit|MaxJobs|MaxTRES|MaxSubmit|MaxWall|QOS|Def QOS|
c1|10.0.0.1|6834|8192|1||||||||high,normal,requeue|normal|
c2|10.0.0.2|6833|8192|1||||||||high,low,normal,requeue|normal|
c3|10.0.0.2|6822|8192|2||||||||high,low,normal|normal|
";

my %clusters = (c1 => {
                       "Cluster"     => "c1",
                       "ControlHost" => "10.0.0.1",
                       "ControlPort" => "6834",
                       "RPC"         => "8192",
                       "Share"       => "1",
                       "GrpJobs"     => "",
                       "GrpTRES"     => "",
                       "GrpSubmit"   => "",
                       "MaxJobs"     => "",
                       "MaxTRES"     => "",
                       "MaxSubmit"   => "",
                       "MaxWall"     => "",
                       "QOS"         => "high,normal,requeue",
                       "Def QOS"     => "normal",
                      },
                "c2" => {
                         "Cluster"     => "c2",
                         "ControlHost" => "10.0.0.2",
                         "ControlPort" => "6833",
                         "RPC"         => "8192",
                         "Share"       => "1",
                         "GrpJobs"     => "",
                         "GrpTRES"     => "",
                         "GrpSubmit"   => "",
                         "MaxJobs"     => "",
                         "MaxTRES"     => "",
                         "MaxSubmit"   => "",
                         "MaxWall"     => "",
                         "QOS"         => "high,low,normal,requeue",
                         "Def QOS"     => "normal",
                        },
                "c3" => {
                         "Cluster"     => "c3",
                         "ControlHost" => "10.0.0.2",
                         "ControlPort" => "6822",
                         "RPC"         => "8192",
                         "Share"       => "2",
                         "GrpJobs"     => "",
                         "GrpTRES"     => "",
                         "GrpSubmit"   => "",
                         "MaxJobs"     => "",
                         "MaxTRES"     => "",
                         "MaxSubmit"   => "",
                         "MaxWall"     => "",
                         "QOS"         => "high,low,normal",
                         "Def QOS"     => "normal",
                        },
               );

my $results = get_clusters(_sacctmgr_output => [split /\n/, $clusters]);
is_deeply($results, \%clusters);

done_testing();

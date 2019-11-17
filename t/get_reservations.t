#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(get_reservations);

my $reservations = "
ReservationName=res1 StartTime=2019-12-01T11:00:00 EndTime=2019-12-03T11:00:00 Duration=2-00:00:00
   Nodes=cb-05,cortex-[01-03],eye-[01-04] NodeCnt=8 CoreCnt=100 Features=(null) PartitionName=(null) Flags=OVERLAP,SPEC_NODES,ALL_NODES
   TRES=cpu=75
   Users=user1 Accounts=(null) Licenses=(null) State=INACTIVE BurstBuffer=(null) Watts=n/a

ReservationName=res2 StartTime=2019-11-13T14:28:26 EndTime=2019-12-03T12:00:00 Duration=19-21:31:34
   Nodes=cb-11,cortex-03,eye-04,sulfur-05 NodeCnt=4 CoreCnt=50 Features=(null) PartitionName=(null) Flags=SPEC_NODES
   TRES=cpu=60
   Users=-user2 Accounts=(null) Licenses=(null) State=ACTIVE BurstBuffer=(null) Watts=n/a
";


my %reservations = ("res1" => {
                               "ReservationName" => "res1",
                               "StartTime" => "2019-12-01T11:00:00",
                               "EndTime" => "2019-12-03T11:00:00",
                               "Duration" => "2-00:00:00",
                               "Nodes" => "cb-05,cortex-[01-03],eye-[01-04]",
                               "_NodeList" => ["cb-05", "cortex-01", "cortex-02", "cortex-03", "eye-01", "eye-02", "eye-03", "eye-04"],
                               "NodeCnt" => "8",
                               "CoreCnt" => "100",
                               "Features" => "(null)",
                               "PartitionName" => "(null)",
                               "Flags" => "OVERLAP,SPEC_NODES,ALL_NODES",
                               "TRES" => "cpu=75",
                               "Users" => "user1",
                               "Accounts" => "(null)",
                               "Licenses" => "(null)",
                               "State" => "INACTIVE",
                               "BurstBuffer" => "(null)",
                               "Watts" => "n/a",
                              },
                    "res2" => {
                               "ReservationName" => "res2",
                               "StartTime" => "2019-11-13T14:28:26",
                               "EndTime" => "2019-12-03T12:00:00",
                               "Duration" => "19-21:31:34",
                               "Nodes" => "cb-11,cortex-03,eye-04,sulfur-05",
                               "_NodeList" => ["cb-11", "cortex-03", "eye-04", "sulfur-05"],
                               "NodeCnt" => "4",
                               "CoreCnt" => "50",
                               "Features" => "(null)",
                               "PartitionName" => "(null)",
                               "Flags" => "SPEC_NODES",
                               "TRES" => "cpu=60",
                               "Users" => "-user2",
                               "Accounts" => "(null)",
                               "Licenses" => "(null)",
                               "State" => "ACTIVE",
                               "BurstBuffer" => "(null)",
                               "Watts" => "n/a",
                              },
                   );

my $results = get_reservations(_scontrol_output => [split /\n/, $reservations]);
is_deeply($results, \%reservations);

done_testing();

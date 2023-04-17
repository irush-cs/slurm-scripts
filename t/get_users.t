#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(get_users);

my $users = "User|Cluster|Def Acct|Account|Def QOS|Admin|
user1|cluster1|account1|account1|normal|Administrator|
user2|cluster1|account1|account1|normal|None|
user3|cluster1|account1|account1|normal|None|
user3|cluster2|account2|killable-bio|killable|None|
user3|cluster2|account2|default|killable|None|
user3|cluster2|account2|account2|normal|None|
user3|cluster3|account2|account2|normal|None|
user5|cluster2|account3|killable-bio|killable|None|
user5|cluster2|account3|default|killable|None|
user5|cluster2|account3|account3|normal|None|
user5|cluster3|account3|account3|normal|None|
user6|cluster1|account1|account1|normal|Administrator|
user7|cluster1|account1|account1|normal|None|
user7|cluster1|account1|account1|normal|None|
user7|cluster4|account4|killable-cs|killable|None|
user7|cluster4|account4|account4|normal|None|
user7|cluster4|account4|default|killable|None|
user8|cluster5|account5|account5|normal|None|
user8|cluster5|account5|killable-astro|killable|None|
";

my @users = (
             {
              "User" => "user1",
              "Cluster" => "cluster1",
              "Def Acct" => "account1",
              "Account" => "account1",
              "Def QOS" => "normal",
              "Admin" => "Administrator",
             },
             {
              "User" => "user2",
              "Cluster" => "cluster1",
              "Def Acct" => "account1",
              "Account" => "account1",
              "Def QOS" => "normal",
              "Admin" => "None",
             },
             {
              "User" => "user3",
              "Cluster" => "cluster1",
              "Def Acct" => "account1",
              "Account" => "account1",
              "Def QOS" => "normal",
              "Admin" => "None",
             },
             {
              "User" => "user3",
              "Cluster" => "cluster2",
              "Def Acct" => "account2",
              "Account" => "killable-bio",
              "Def QOS" => "killable",
              "Admin" => "None",
             },
             {
              "User" => "user3",
              "Cluster" => "cluster2",
              "Def Acct" => "account2",
              "Account" => "default",
              "Def QOS" => "killable",
              "Admin" => "None",
             },
             {
              "User" => "user3",
              "Cluster" => "cluster2",
              "Def Acct" => "account2",
              "Account" => "account2",
              "Def QOS" => "normal",
              "Admin" => "None",
             },
             {
              "User" => "user3",
              "Cluster" => "cluster3",
              "Def Acct" => "account2",
              "Account" => "account2",
              "Def QOS" => "normal",
              "Admin" => "None",
             },
             {
              "User" => "user5",
              "Cluster" => "cluster2",
              "Def Acct" => "account3",
              "Account" => "killable-bio",
              "Def QOS" => "killable",
              "Admin" => "None",
             },
             {
              "User" => "user5",
              "Cluster" => "cluster2",
              "Def Acct" => "account3",
              "Account" => "default",
              "Def QOS" => "killable",
              "Admin" => "None",
             },
             {
              "User" => "user5",
              "Cluster" => "cluster2",
              "Def Acct" => "account3",
              "Account" => "account3",
              "Def QOS" => "normal",
              "Admin" => "None",
             },
             {
              "User" => "user5",
              "Cluster" => "cluster3",
              "Def Acct" => "account3",
              "Account" => "account3",
              "Def QOS" => "normal",
              "Admin" => "None",
             },
             {
              "User" => "user6",
              "Cluster" => "cluster1",
              "Def Acct" => "account1",
              "Account" => "account1",
              "Def QOS" => "normal",
              "Admin" => "Administrator",
             },
             {
              "User" => "user7",
              "Cluster" => "cluster1",
              "Def Acct" => "account1",
              "Account" => "account1",
              "Def QOS" => "normal",
              "Admin" => "None",
             },
             {
              "User" => "user7",
              "Cluster" => "cluster1",
              "Def Acct" => "account1",
              "Account" => "account1",
              "Def QOS" => "normal",
              "Admin" => "None",
             },
             {
              "User" => "user7",
              "Cluster" => "cluster4",
              "Def Acct" => "account4",
              "Account" => "killable-cs",
              "Def QOS" => "killable",
              "Admin" => "None",
             },
             {
              "User" => "user7",
              "Cluster" => "cluster4",
              "Def Acct" => "account4",
              "Account" => "account4",
              "Def QOS" => "normal",
              "Admin" => "None",
             },
             {
              "User" => "user7",
              "Cluster" => "cluster4",
              "Def Acct" => "account4",
              "Account" => "default",
              "Def QOS" => "killable",
              "Admin" => "None",
             },
             {
              "User" => "user8",
              "Cluster" => "cluster5",
              "Def Acct" => "account5",
              "Account" => "account5",
              "Def QOS" => "normal",
              "Admin" => "None",
             },
             {
              "User" => "user8",
              "Cluster" => "cluster5",
              "Def Acct" => "account5",
              "Account" => "killable-astro",
              "Def QOS" => "killable",
              "Admin" => "None",
             },
            );


my $results = get_users(_sacctmgr_output => [split /\n/, $users]);
is_deeply($results, \@users);

done_testing();

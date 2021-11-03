#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(get_users);

my $users = "User|Cluster|Def Acct|Account|Def QOS|
user1|cluster1|account1|account1|normal|
user2|cluster1|account1|account1|normal|
user3|cluster1|account1|account1|normal|
user3|cluster2|account2|killable-bio|killable|
user3|cluster2|account2|default|killable|
user3|cluster2|account2|account2|normal|
user3|cluster3|account2|account2|normal|
user5|cluster2|account3|killable-bio|killable|
user5|cluster2|account3|default|killable|
user5|cluster2|account3|account3|normal|
user5|cluster3|account3|account3|normal|
user6|cluster1|account1|account1|normal|
user7|cluster1|account1|account1|normal|
user7|cluster1|account1|account1|normal|
user7|cluster4|account4|killable-cs|killable|
user7|cluster4|account4|account4|normal|
user7|cluster4|account4|default|killable|
user8|cluster5|account5|account5|normal|
user8|cluster5|account5|killable-astro|killable|
";

my @users = (
             {
              "User" => "user1",
              "Cluster" => "cluster1",
              "Def Acct" => "account1",
              "Account" => "account1",
              "Def QOS" => "normal",
             },
             {
              "User" => "user2",
              "Cluster" => "cluster1",
              "Def Acct" => "account1",
              "Account" => "account1",
              "Def QOS" => "normal",
             },
             {
              "User" => "user3",
              "Cluster" => "cluster1",
              "Def Acct" => "account1",
              "Account" => "account1",
              "Def QOS" => "normal",
             },
             {
              "User" => "user3",
              "Cluster" => "cluster2",
              "Def Acct" => "account2",
              "Account" => "killable-bio",
              "Def QOS" => "killable",
             },
             {
              "User" => "user3",
              "Cluster" => "cluster2",
              "Def Acct" => "account2",
              "Account" => "default",
              "Def QOS" => "killable",
             },
             {
              "User" => "user3",
              "Cluster" => "cluster2",
              "Def Acct" => "account2",
              "Account" => "account2",
              "Def QOS" => "normal",
             },
             {
              "User" => "user3",
              "Cluster" => "cluster3",
              "Def Acct" => "account2",
              "Account" => "account2",
              "Def QOS" => "normal",
             },
             {
              "User" => "user5",
              "Cluster" => "cluster2",
              "Def Acct" => "account3",
              "Account" => "killable-bio",
              "Def QOS" => "killable",
             },
             {
              "User" => "user5",
              "Cluster" => "cluster2",
              "Def Acct" => "account3",
              "Account" => "default",
              "Def QOS" => "killable",
             },
             {
              "User" => "user5",
              "Cluster" => "cluster2",
              "Def Acct" => "account3",
              "Account" => "account3",
              "Def QOS" => "normal",
             },
             {
              "User" => "user5",
              "Cluster" => "cluster3",
              "Def Acct" => "account3",
              "Account" => "account3",
              "Def QOS" => "normal",
             },
             {
              "User" => "user6",
              "Cluster" => "cluster1",
              "Def Acct" => "account1",
              "Account" => "account1",
              "Def QOS" => "normal",
             },
             {
              "User" => "user7",
              "Cluster" => "cluster1",
              "Def Acct" => "account1",
              "Account" => "account1",
              "Def QOS" => "normal",
             },
             {
              "User" => "user7",
              "Cluster" => "cluster1",
              "Def Acct" => "account1",
              "Account" => "account1",
              "Def QOS" => "normal",
             },
             {
              "User" => "user7",
              "Cluster" => "cluster4",
              "Def Acct" => "account4",
              "Account" => "killable-cs",
              "Def QOS" => "killable",
             },
             {
              "User" => "user7",
              "Cluster" => "cluster4",
              "Def Acct" => "account4",
              "Account" => "account4",
              "Def QOS" => "normal",
             },
             {
              "User" => "user7",
              "Cluster" => "cluster4",
              "Def Acct" => "account4",
              "Account" => "default",
              "Def QOS" => "killable",
             },
             {
              "User" => "user8",
              "Cluster" => "cluster5",
              "Def Acct" => "account5",
              "Account" => "account5",
              "Def QOS" => "normal",
             },
             {
              "User" => "user8",
              "Cluster" => "cluster5",
              "Def Acct" => "account5",
              "Account" => "killable-astro",
              "Def QOS" => "killable",
             },
            );


my $results = get_users(_sacctmgr_output => [split /\n/, $users]);
is_deeply($results, \@users);

done_testing();

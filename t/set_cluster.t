#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(set_cluster get_clusters get_config);

my @clusters = keys %{get_clusters()};

diag("Setting ".scalar(@clusters)." clusters");

my $orig_config = get_config();

foreach my $cluster (@clusters) {
    ok(set_cluster($cluster));
    is(get_config()->{ClusterName}, $cluster, "Can't set_cluster($cluster)");
}

set_cluster("something", unset => 1);
my $config = get_config();
is($config->{ClusterName}, $orig_config->{ClusterName});

# close STDERR as set_cluster/get_config will complain for bad clusters
open(PREVERR, ">&STDERR");
open(STDERR, ">/dev/null");
ok(not set_cluster(join(".", @clusters)."K"));
open(STDERR, ">&PREVERR");
close(PREVERR);

done_testing();

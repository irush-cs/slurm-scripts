#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(nodecmp);

my @tests = ([['b','a'], ['a', 'b']],
             [['a2', 'a1'], ['a1', 'a2']],
             [['a9', 'a10'], ['a9', 'a10']],
             [['a9b1', 'a10b1', 'a10b2', 'a9b2'], ['a9b1', 'a9b2', 'a10b1', 'a10b2']],
             [['3a', 'a3', '3b', 'a4'], ['3a', '3b', 'a3', 'a4']],
            );

foreach my $test (@tests) {
    my $results = [sort nodecmp @{$test->[0]}];
    is_deeply($results, $test->[1], "node sorting: [".join(",", $test->[0])."]");
}

done_testing();

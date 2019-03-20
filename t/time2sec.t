#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(time2sec);

my %times = ("3" => 180,
             "3:3" => 183,
             "3:3:3" => 10983,
             "2-3" => 183600,
             "3-4:5" => 273900,
             "4-5:4:3" => 363843,
             "fhdsjka" => undef,
             "1:2:3:4" => undef,
             "2-3-4" => undef,
             "0" => 0,
             "" => undef,
            );

foreach my $time (keys %times) {
    my $results = time2sec($time);
    ok(defined ($times{$time}) ? ($results == $times{$time}) : (not defined $results), "time2sec(\"$time\") = ".($results//"undef")." != ".($times{$time}//"undef"));
}

done_testing();

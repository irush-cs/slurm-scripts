#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(mb2string);

my @mb = (
          ["1", "1.00M"],
          ["hello", undef],
          ["1k", undef],
          ["1mb", "1.00M"],
          ["1 M", "1.00M"],
          ["0.003M", "3.07K"],
          ["0.00003", "31.46B"],
          ["900", "900.00M"],
          ["1000", "0.98G"],
          ["2000", "1.95G"],
          ["1000000", "976.56G"],
          ["1100000", "1.05T"],
          ["1000000000", "953.67T"],
          ["1000000000000", "931.32P"],
          ["1000000000000000", "931322.57P"],

          ["2000", "precision", "0", "2G"],
          ["1000000000000", "precision", "0", "931P"],
          ["2000", "precision", "6", "1.953125G"],
          ["2000", "precision", ".3", undef],
          ["2000", "precision", "hello", undef],

          ["0.003M", "space", "1", "3.07 K"],
          ["0.00003", "space", "1", "31.46 B"],
          ["900", "space", "1", "900.00 M"],
          ["1000", "space", "1", "0.98 G"],
          ["2050", "space", "1", "precision", "3", "2.002 G"],
          ["1000000000000", "precision", "0", "space", "1", "931 P"],
         );

foreach my $mb (@mb) {
    my $should = pop @$mb;
    my $results = mb2string(@$mb);
    ok(defined ($should) ? ($results eq $should) : (not defined $results), "mb2string(\"".join('", "', @$mb)."\") = \"".($results//"undef")."\" != \"".($should//"undef")."\"");
}

done_testing();

#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(string2mb);

# m/^\d+(\.\d+)?\s*[KMGTP]?B?$/i
my @mb = (
          ["1", "0"],
          ["hello", undef],
          ["1k", "0"],
          ["1mb", "1"],
          ["2 M", "2"],
          ["1024k", "1"],
          ["1000000", "0"],
          ["1048575", "0"],
          ["1048576", "1"],
          ["900.13 mb", "900"],
          ["0.98G", "1003"],
          ["976.56G", "999997"],
          ["1.05T", "1101004"],
          ["931.32P", "999997235527"],
         );

foreach my $mb (@mb) {
    my $should = pop @$mb;
    my $results = string2mb(@$mb);
    ok(defined $should ? (defined $results and $results eq $should) : (not defined $results), "string2mb(\"".join('", "', @$mb)."\") = \"".($results//"undef")."\" != \"".($should//"undef")."\"");
}

done_testing();

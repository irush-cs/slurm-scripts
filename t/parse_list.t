#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(parse_list);

my $list = "A|B|C D|E|
a|b|c|d|
b||||
|d|e f|g|
";

my $list2 = "A|B|C D|E
a|b|c|d
b|||
|d|e f|g
";

my @list = ({
             "A" => "a",
             "B" => "b",
             "C D" => "c",
             "E" => "d",
            },
            {
             "A" => "b",
             "B" => "",
             "C D" => "",
             "E" => "",
            },             
            {
             "A" => "",
             "B" => "d",
             "C D" => "e f",
             "E" => "g",
            },             
           );

my @list2 = @list;

my $results = parse_list([split /\n/, $list]);
is_deeply($results, \@list);

$results = parse_list([split /\n/, $list2]);
is_deeply($results, \@list2);

done_testing();

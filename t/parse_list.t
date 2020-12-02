#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(parse_list);

my $list = 'A|B|C D|E|
a|b|c|d|
b||||
|d|e f|g|
a\\\\aa\\\\|\\\\bbb\\||\\||d\\|\\\\dd|
';

my $list2 = $list =~ s/\|$//mgr;

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
             {
              "A" => 'a\\\\aa\\\\',
              "B" => '\\\\bbb\\',
              "C D" => '',
              "E" => '\\',
             },
            );

my @elist = ({
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
             {
              "A" => 'a\\aa\\',
              "B" => '\\bbb|',
              "C D" => '|',
              "E" => 'd|\\dd',
             },
            );

my @list2 = @list;
my @elist2 = @elist;

my $results = parse_list([split /\n/, $list]);
is_deeply($results, \@list);

$results = parse_list([split /\n/, $list2]);
is_deeply($results, \@list2);

$cshuji::Slurm::escaped_delimiter = 1;

$results = parse_list([split /\n/, $list]);
is_deeply($results, \@elist);

$results = parse_list([split /\n/, $list2]);
is_deeply($results, \@elist2);

done_testing();

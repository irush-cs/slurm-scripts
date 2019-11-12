#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(nodes2array);

my %input = ('a' => ['a'],
             'a,b' => ['a', 'b'],
             'a,b,c' => ['a', 'b', 'c'],
             'a-[0-3]' => ['a-0', 'a-1', 'a-2', 'a-3'],
             'a-[01-4]-b' => ['a-01-b', 'a-02-b', 'a-03-b', 'a-04-b'],
             'a-[8-11]-b' => ['a-8-b', 'a-9-b', 'a-10-b', 'a-11-b'],
             'a-[1-3]-b-[4-5]-c-[9-10]-d' => [
                                              'a-1-b-4-c-9-d',
                                              'a-1-b-4-c-10-d',
                                              'a-1-b-5-c-9-d',
                                              'a-1-b-5-c-10-d',
                                              'a-2-b-4-c-9-d',
                                              'a-2-b-4-c-10-d',
                                              'a-2-b-5-c-9-d',
                                              'a-2-b-5-c-10-d',
                                              'a-3-b-4-c-9-d',
                                              'a-3-b-4-c-10-d',
                                              'a-3-b-5-c-9-d',
                                              'a-3-b-5-c-10-d',
                                             ],
             'a-[1]' => ['a-1'],
             'a-[1,2]' => ['a-1', 'a-2'],
             'a-[1,03-005,9]' => ['a-1', 'a-03', 'a-04', 'a-05', 'a-9'],
             'b[2],a[]' => ['a[]', 'b2'],
             'a[' => ['a['],
             ',' => [],
             'a,' => ['a'],
             'a,[' => ['[', 'a'],
             ']a,a[3' => [']a', 'a[3'],
            );

foreach my $input (keys %input) {
    my $results = [nodes2array($input)];
    is_deeply($results, $input{$input}, "nodes: \"$input\"");
}

done_testing();

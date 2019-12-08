#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(gres2string);


my %gres = ("gpu:3" => {gpu => 3},
            "gpu:2" => {gpu => 2},
            "gpu:2,mem:3M" => {gpu => 2, mem => "3M"},
            "mem:15360M" => {mem => "15360M"},
            "gpu:1" => {gpu => 1},
            "gpu:3" => {gpu => 3},
            "gpu:1" => {gpu => 1},
            "gpu:8" => {gpu => 8},
            "vmem:2048M" => {vmem => "2048M"},
            "gpu:2" => {gpu => 2},
            "billing:1,cpu:1,gres/gpu:1,mem:2048M,node:1" => {cpu => 1, mem => "2048M", node => 1, billing => 1, "gres/gpu" => 1},
            "billing:2,cpu:1,mem:300M,node:1" => {cpu => 1, mem => "300M", node => 1, billing => 2},
            "billing:16,cpu:16,gres/gpu:2,license/interactive:1,mem:16384M,node:2" => {cpu => 16, mem => "16384M", node => 2, billing => 16, "gres/gpu" => 2, "license/interactive" => 1},
           );

foreach my $gres (keys %gres) {
    my $results = gres2string($gres{$gres});
    is_deeply($results, $gres, "GRES: \"$gres\"");
}

done_testing();

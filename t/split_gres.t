#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use cshuji::Slurm qw(split_gres);


my %gres = ("gpu,gpu:2" => {gpu => 3},
            "gpu:2" => {gpu => 2},
            "gpu:2,mem:3M" => {gpu => 2, mem => "3M"},
            "mem:15G" => {mem => "15360M"},
            "gpu" => {gpu => 1},
            "gpu:black:3" => {gpu => 3},
            "gpu:m60" => {gpu => 1},
            "gpu:m60:8" => {gpu => 8},
            "vmem:no_consume:2G" => {vmem => "2048M"},
            "gpu:m60:no_consume:2" => {gpu => 2},
           );
my $allgres = {gpu => 22, mem => "15363M", vmem => "2048M"};

my %tres = (
            "cpu=1,mem=2G,node=1,billing=1,gres/gpu=1" => {cpu => 1, mem => "2048M", node => 1, billing => 1, "gres/gpu" => 1},
            "cpu=1,mem=300M,node=1,billing=2" => {cpu => 1, mem => "300M", node => 1, billing => 2},
            "cpu=16,mem=16G,node=2,billing=16,gres/gpu=2,license/interactive=1" => {cpu => 16, mem => "16384M", node => 2, billing => 16, "gres/gpu" => 2, "license/interactive" => 1},
           );
my $alltres = {cpu => 18, mem => "18732M", node => 4, "gres/gpu" => 3, billing => 19, "license/interactive" => 1},

my $all = {};
foreach my $gres (keys %gres) {
    my $results = split_gres($gres);
    $all = split_gres($gres, $all);
    is_deeply($results, $gres{$gres}, "GRES: \"$gres\"");
}
is_deeply($all, $allgres, "All GRES combined");

$all = {};
foreach my $tres (keys %tres) {
    my $results = split_gres($tres);
    $all = split_gres($tres, $all);
    is_deeply($results, $tres{$tres}, "TRES: \"$tres\"");
}
is_deeply($all, $alltres, "All TRES combined");

done_testing();

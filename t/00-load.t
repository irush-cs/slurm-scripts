#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'cshuji::Slurm' ) || print "Bail out!\n";
}

diag( "Testing cshuji::Slurm $cshuji::Slurm::VERSION, Perl $], $^X" );

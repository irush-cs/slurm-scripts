#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Builder;

#unless ( $ENV{RELEASE_TESTING} ) {
#    plan( skip_all => "Author tests not required for installation" );
#}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

my $ok = 1;
my $Test = Test::Builder->new;
my @modules = map {"cshuji::$_"} Test::Pod::Coverage::all_modules("cshuji");
if ( @modules ) {
    $Test->plan( tests => scalar @modules );

    for my $module ( @modules ) {
        my $thismsg = "Pod coverage on $module";

        my $thisok = pod_coverage_ok( $module, {}, $thismsg );
        $ok = 0 unless $thisok;
    }
} else {
    $Test->plan( tests => 1 );
    $Test->ok( 0, "No modules found." );
}

#return $ok;

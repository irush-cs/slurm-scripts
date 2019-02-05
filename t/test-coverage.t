#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Builder;
use Cwd;
use Package::Stash;
use cshuji::Slurm;

my $scriptdir;
BEGIN {
    use Cwd;
    use File::Basename;
    $scriptdir = dirname(Cwd::realpath($0));
}
$scriptdir = "." unless $scriptdir;

my $Test = Test::Builder->new;
my $ps = Package::Stash->new("cshuji::Slurm");
my @funcs = $ps->list_all_symbols('CODE');
$Test->plan(tests => scalar @funcs);
foreach my $func (@funcs) {
    my $ok = -e "$scriptdir/${func}.t";
    $Test->ok($ok, "available test for $func");
    unless ($ok) {
        $Test->diag("Missing t/${func}.t test file");
    }
}

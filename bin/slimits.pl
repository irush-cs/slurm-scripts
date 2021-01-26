#!/usr/bin/env perl

use strict;
use warnings;

use List::Util qw(max);
use Text::Table;
use Getopt::Long;

Getopt::Long::Configure("bundling");

my $scriptdir;
BEGIN {
    use Cwd;
    use File::Basename;
    $scriptdir = dirname(Cwd::realpath($0));
}
$scriptdir = '.' unless (defined $scriptdir);
use lib "$scriptdir/..";

use cshuji::Slurm qw(split_gres);

my $user = getpwuid($<);
my $all = 0;
unless (GetOptions("u|user=s" => \$user,
                   "a|all+"   => \$all,
                  )) {
    print STDERR "slimits [options]\n";
    print STDERR "Options:\n";
    print STDERR "  -u <user> - check for <user> instead of current user\n";
    print STDERR "  -a        - show all accounts instead of just default\n";
    print STDERR "  -aa       - show all accounts including which can't run\n";
    exit 1;
}
my $uid = getpwnam($user);
my %trestorun = (cpu => 1,
                );

my %tres;
my @assocs = @{cshuji::Slurm::parse_scontrol_show([`scontrol show assoc_mgr flags=assoc user=$user`], type => "list")};
foreach my $assoc (@assocs) {
    $assoc->{_ParentAccount} = $assoc->{ParentAccount} =~ s/\(.*\)$//r;
    $assoc->{_UserName} = $assoc->{UserName} =~ s/\(.*\)$//r;
    my $grptres = split_gres($assoc->{GrpTRES}, type => "string");
    $assoc->{_GrpTRES} = {Limit => {},
                          Usage => {},
                         };
    foreach my $tres (keys %{$grptres}) {
        if ($grptres->{$tres} =~ m/(.*)\((.*)\)/) {
            $assoc->{_GrpTRES}{Usage}{$tres} = $2;
            $assoc->{_GrpTRES}{Limit}{$tres} = $1;
        } else {
            print STDERR "Warning: Don't know how to handle \"$tres\" limit of $grptres->{$tres}\n";
            next;
        }
        $tres{$tres} = $tres;
    }
}

# get direct accounts
my @accounts = grep {$_->{UserName} eq "$user($uid)"} @assocs;

# default first
@accounts = sort {$a->{DefAssoc} ne $b->{DefAssoc} ? $b->{DefAssoc} eq "Yes" : $a->{Account} cmp $b->{Account}} @accounts;

my @rrows;
ACCOUNT:
foreach my $assoc (@accounts) {
    my @rows;
    my %tlength;
    do {
        my %entry;
        $entry{User} = $assoc->{_UserName};
        $entry{Account} = $assoc->{Account};
        foreach my $tres (sort keys %tres) {
            $entry{$tres} = [$assoc->{_GrpTRES}{Usage}{$tres}, $assoc->{_GrpTRES}{Limit}{$tres}];
            $tlength{$tres} = max($tlength{$tres} // 0, length($entry{$tres}[1]));
            next ACCOUNT if ($all < 2 and exists $trestorun{$tres} and $entry{$tres}[1] eq "0");
        }
        push @rows, {%entry};

        # if user, get generic account, otherwise get parent account (with or without user)
        if ($assoc->{UserName}) {
            ($assoc) = grep {$_->{Account} eq $assoc->{Account} and not $_->{UserName}} @assocs;
        } elsif ($assoc->{_ParentAccount}) {
            my ($assoc1) = grep {$_->{Account} eq $assoc->{_ParentAccount} and $_->{UserName}} @assocs;
            if ($assoc1) {
                $assoc = $assoc1;
            } else {
                ($assoc) = grep {$_->{Account} eq $assoc->{_ParentAccount} and not $_->{UserName}} @assocs;
            }
        } else {
            $assoc = undef;
        }
    } while $assoc;

    push @rrows, [];
    foreach my $row (@rows) {
        my @data = ($row->{User}, $row->{Account});
        foreach my $tres (sort keys %tres) {
            push @data, sprintf "\%i / \%$tlength{$tres}s", @{$row->{$tres}}
        }
        push @{$rrows[-1]}, [@data]
    }
    last unless $all;
}

my $table = Text::Table->new("User", \" | ", "Account", \" | ",
                             map {{title => "$_", align => "right", align_title => "right"}, \" | "} sort keys %tres,
                            );

my @seps = 0;
foreach my $row (@rrows) {
    $table->load(@$row);
    push @seps, scalar(@$row);
}
print $table->title;
my $current = 0;
foreach my $sep (@seps) {
    print $table->body($current, $sep);
    print $table->rule("-", "+");
    $current += $sep;
}

exit 0;

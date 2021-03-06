#!/usr/bin/env perl

use strict;
use warnings;

use List::Util qw(max min);
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

use cshuji::Slurm qw(split_gres mb2string);

@ARGV = map {s/^-M([^=].*)/--cluster=$1/r} @ARGV;

my $user = getpwuid($<);
my $in_user;
my $all = 0;
my $long;
my $avail;
my $account;
my $cluster;
unless (GetOptions("u|user=s"    => \$in_user,
                   "a|all+"      => \$all,
                   "l|long!"     => \$long,
                   "avail!"      => \$avail,
                   "A|account=s" => \$account,
                   "M|cluster=s" => \$cluster,
                  )) {
    print STDERR "slimits [options]\n";
    print STDERR "Options:\n";
    print STDERR "  -u <user>    - check for <user> instead of current user\n";
    print STDERR "  -A <account> - show limits of all users in <account>\n";
    print STDERR "  -M <cluster> - show limits on cluster <cluster>\n";
    print STDERR "  -a           - show all accounts instead of just default\n";
    print STDERR "  -l           - show all attributes, even without limits\n";
    print STDERR "  -aa          - show all accounts including which can't run\n";
    print STDERR "  --avail      - show calculated availability\n";
    print STDERR "

Each \"fat\" row is a single account with all its parents. An account might not
have reached a limit but its parent might have. Each line shows the specific
limits of a user and/or an account.

Each column shows the limits of a particular resource. Some rows have two
numbers in the format '<used> / <limit>'. If the limit it 'N', there is no
limit (but there could be a limit on a parent account). If the limit is '0',
this resource cannot be used.

Resources:

cpu, mem, gres/gpu          - The used and limits of CPUs, memory and GPUs.
license/interactive         - Number of allowed interactive sessions
cpu pj, mem pj, gres/gpu pj - Limits of CPUs, memory and GPUs per job.
GrpSubmitJobs               - Total number of jobs (pending and running)
                              allowed by the account and its children.
MaxSubmitJobs               - Maximum number of jobs (pending and runnig).
MaxJobs                     - Maximum number of running jobs.
";

    exit 1;
}
$user = $in_user if $in_user;
my $uid = getpwnam($user);
$avail = 0 if $account;
my %trestorun = (cpu => 1,
                 MaxSubmitJobs => 1,
                 mem => 1,
                 MaxJobs => 1,
                 GrpSubmitJobs => 1,
                );
my %memtres = (mem => 1,
              );

if ($cluster) {
    cshuji::Slurm::set_cluster($cluster);
}

my %tres;
my %trespj;
my %nontres = (MaxSubmitJobs => 1,
               MaxJobs => 1,
               GrpSubmitJobs => 1,
              );
my %useronlytres = (MaxSubmitJobs => 1,
                    MaxJobs => 1,
                   );
my @assocs = @{cshuji::Slurm::parse_scontrol_show([`scontrol show assoc_mgr flags=assoc user=$user`], type => "list")};
if ($account) {
    $all = 2 if $all < 2;
    if ($in_user) {
        # account and user, just grep the proper account
        @assocs = grep {not $_->{UserName} or $_->{Account} eq $account} @assocs;
        $account = undef;
    } else {
        # with account, needs the non user accounts from the basic user account (any user will do)
        @assocs = grep {not $_->{UserName}} @assocs;
        push @assocs, @{cshuji::Slurm::parse_scontrol_show([`scontrol show assoc_mgr flags=assoc account=$account`], type => "list")};
    }
}
foreach my $assoc (@assocs) {
    $assoc->{_ParentAccount} = $assoc->{ParentAccount} =~ s/\(.*\)$//r;
    $assoc->{_UserName} = $assoc->{UserName} =~ s/\(.*\)$//r;

    # GrpTRES
    my $grptres = split_gres($assoc->{GrpTRES}, type => "string");
    $assoc->{_GrpTRES} = {Limit => {},
                          Usage => {},
                         };
    foreach my $tres (keys %{$grptres}) {
        if ($grptres->{$tres} =~ m/(.*)\((.*)\)/) {
            $assoc->{_GrpTRES}{Usage}{$tres} = $2;
            $assoc->{_GrpTRES}{Limit}{$tres} = $1;
            if ($memtres{$tres} and not $avail) {
                foreach my $t (qw(Usage Limit)) {
                    if ($assoc->{_GrpTRES}{$t}{$tres} =~ m/^\d+$/) {
                        $assoc->{_GrpTRES}{$t}{$tres} = mb2string($assoc->{_GrpTRES}{$t}{$tres});
                    }
                }
            }
        } else {
            print STDERR "Warning: Don't know how to handle \"$tres\" limit of $grptres->{$tres}\n";
            next;
        }
        $tres{$tres} = $tres;
    }
    $assoc->{_nontres} = {Limit => {},
                          Usage => {},
                         };

    # MaxTRESPJ
    $assoc->{_MaxTRESPJ} = split_gres($assoc->{MaxTRESPJ});
    @trespj{keys %{$assoc->{_MaxTRESPJ}}} = keys %{$assoc->{_MaxTRESPJ}};
    foreach my $tres (keys %trespj) {
        $assoc->{_MaxTRESPJ}{$tres} = mb2string($assoc->{_MaxTRESPJ}{$tres}) if $assoc->{_MaxTRESPJ}{$tres} and $memtres{$tres};
    }

    # non tres
    foreach my $nontres (keys %nontres) {
        if (($assoc->{$nontres} or "N(N)") =~ m/(.*)\((.*)\)/) {
            $assoc->{_nontres}{Usage}{$nontres} = $2;
            $assoc->{_nontres}{Limit}{$nontres} = $1;
        } else {
            print STDERR "Warning: Don't know how to handle \"$nontres\" limit of \"$assoc->{$nontres}\"\n";
        }
    }
}

# get direct accounts
my @accounts;
if ($account) {
    @accounts = grep {$_->{UserName}} @assocs;

    # sort by users
    @accounts = sort {$a->{UserName} cmp $b->{UserName}} @accounts;
} else {
    @accounts = grep {$_->{UserName} eq "$user($uid)"} @assocs;

    # default first
    @accounts = sort {$a->{DefAssoc} ne $b->{DefAssoc} ? $b->{DefAssoc} eq "Yes" : $a->{Account} cmp $b->{Account}} @accounts;
}

# build table
# haslimits - if tres has limit anywhere (will be deleted otherwise unless $long)
# entries - list of list hashes (list ref per account), internal list - hashes of rows
my %haslimits;
my @entries;
my %tlength;
ACCOUNT:
while (my $assoc = shift @accounts) {
    my @rows;
    do {
        my %entry;
        $entry{User} = $assoc->{_UserName};
        $entry{Account} = $assoc->{Account};
        foreach my $tres (sort keys %tres) {
            $entry{$tres} = [$assoc->{_GrpTRES}{Usage}{$tres}, $assoc->{_GrpTRES}{Limit}{$tres}];
            $tlength{$tres} = max($tlength{$tres} // 0, length($entry{$tres}[1]));
            next ACCOUNT if ($all < 2 and exists $trestorun{$tres} and $entry{$tres}[1] eq "0");
            $haslimits{$tres} ||= $entry{$tres}[1] ne "N";
        }
        foreach my $tres (sort keys %trespj) {
            $entry{"${tres}pj"} = $assoc->{_MaxTRESPJ}{$tres} // "N";
            $haslimits{"${tres}pj"} ||= $entry{"${tres}pj"} ne "N";
        }
        foreach my $nontres (sort keys %nontres) {
            $entry{$nontres} = [$assoc->{_nontres}{Usage}{$nontres}, $assoc->{_nontres}{Limit}{$nontres}];
            $tlength{$nontres} = max($tlength{$nontres} // 0, length($entry{$nontres}[1]));
            next ACCOUNT if ($all < 2 and exists $trestorun{$nontres} and $entry{$nontres}[1] eq "0");
            $haslimits{$nontres} ||= $entry{$nontres}[1] ne "N";
        }
        push @rows, {%entry};

        # find next row in this account
        # if user, get generic account, otherwise get parent account (with or without user)
        if ($assoc->{UserName}) {
            if ($account and @accounts) {
                $assoc = shift @accounts;
            } else {
                ($assoc) = grep {$_->{Account} eq $assoc->{Account} and not $_->{UserName}} @assocs;
            }
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

    push @entries, [@rows];
    last unless $all;
}

unless ($long) {
    delete @tres{grep {not $haslimits{$_}} keys %haslimits};
    delete @trespj{map {s/pj$//r} grep {not $haslimits{$_}} keys %haslimits};
    delete @nontres{grep {not $haslimits{$_}} keys %haslimits};
}

# rows - the actual final rows, list of list ref (per account like entries)
# Calculate available resources (if needed)
my @rows;
foreach my $entries (@entries) {
    push @rows, [];
    if ($avail) {
        foreach my $tres (sort keys %tres, sort keys %nontres) {
            my $limit = "N";
            foreach my $row (reverse @$entries) {
                if ($row->{$tres}[1] ne "N") {
                    my $limit2 = $row->{$tres}[1] - $row->{$tres}[0];
                    $limit = min(($limit eq "N" ? $limit2 : $limit), $limit2);
                }
                $limit = "N" if ($useronlytres{$tres} and not $row->{User});
                $row->{"${tres}-avail"} = ($memtres{$tres} and $limit =~ m/^\d+$/) ? mb2string($limit) : $limit;
            }
        }
    }
    foreach my $row (@$entries) {
        my @data = ($row->{User}, $row->{Account});
        foreach my $tres (sort keys %tres) {
            push @data, $avail ? $row->{"${tres}-avail"} : sprintf "\%s / \%$tlength{$tres}s", @{$row->{$tres}};
        }
        foreach my $tres (sort keys %trespj) {
            push @data, $row->{"${tres}pj"};
        }
        foreach my $tres (sort keys %nontres) {
            if ($useronlytres{$tres} and not $row->{User}) {
                push @data, "";
            } else {
                push @data, $avail ? $row->{"${tres}-avail"} : sprintf "\%s / \%$tlength{$tres}s", @{$row->{$tres}};
            }
        }
        push @{$rows[-1]}, [@data]
    }
}

my $table = Text::Table->new("User", \" | ", "Account", \" | ",
                             (map {{title => "$_", align => "right", align_title => "right"}, \" | "} sort keys %tres),
                             (map {{title => "$_ pj", align => "right", align_title => "right"}, \" | "} sort keys %trespj),
                             (map {{title => "$_", align => "right", align_title => "right"}, \" | "} sort keys %nontres),
                            );

my @seps = 0;
foreach my $row (@rows) {
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

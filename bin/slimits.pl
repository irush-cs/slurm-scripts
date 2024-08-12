#!/usr/bin/env perl

use strict;
use warnings;

use Clone;
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
my $in_account;
my $cluster;
my $in_qos;
unless (GetOptions("u|user=s"    => \$in_user,
                   "a|all+"      => \$all,
                   "l|long!"     => \$long,
                   "avail!"      => \$avail,
                   "A|account=s" => \$in_account,
                   "M|cluster=s" => \$cluster,
                   "qos!"        => \$in_qos,
                  )) {
    print STDERR "slimits [options]\n";
    print STDERR "Options:\n";
    print STDERR "  -u <user>    - check for <user> instead of current user\n";
    print STDERR "  -A <account> - show limits of all users in <account>\n";
    print STDERR "  -M <cluster> - show limits on cluster <cluster>\n";
    print STDERR "  --qos        - show QoS limits instead of current live usage\n";
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
cpu pu, mem pu, gres/gpu pu - Limits of CPUs, memory and GPUs per user.
GrpSubmitJobs               - Total number of jobs (pending and running)
                              allowed by the account and its children.
MaxSubmitJobs               - Maximum number of jobs (pending and runnig).
MaxJobs                     - Maximum number of running jobs.
";

    exit 1;
}

$user = $in_user if $in_user;
my $uid = getpwnam($user);
$avail = 0 if $in_account;
my %trestorun = (cpu => 1,
                 MaxSubmitJobs => 1,
                 mem => 1,
                 MaxJobs => 1,
                 GrpSubmitJobs => 1,
                );
my %memtres = (mem => 1,
              );

if ($cluster) {
    unless (cshuji::Slurm::set_cluster($cluster)) {
        print STDERR "Can't access cluster $cluster\n";
        exit 2;
    }
} else {
    $cluster = cshuji::Slurm::get_config()->{ClusterName};
}

my %tres;
my %trespj;
my %trespu;
my %tresmin;
my %nontres = (MaxSubmitJobs => 1,
               MaxJobs => 1,
               GrpSubmitJobs => 1,
              );
my %useronlytres = (MaxSubmitJobs => 1,
                    MaxJobs => 1,
                   );

my @assocs;
if ($in_qos) {
    my $qos = cshuji::Slurm::get_qos();
    my $assocs = cshuji::Slurm::get_associations();
    my $users = cshuji::Slurm::get_users();
    my @acct_assocs = grep {$_->{Cluster} eq $cluster} @$assocs;
    my @users = grep {$_->{User} eq $user and $_->{Cluster} eq $cluster} @$users;
    my $defaccount = $users[0]{"Def Acct"};
    my @accounts = ($defaccount);

    if ($in_account) {
        @accounts = ($in_account);
        @users = map {$_->{User}} grep {$_->{Cluster} eq $cluster and $_->{Account} eq $in_account} @$users;
    } elsif ($all > 1) {
        # -aa - all accounts, keep default first;
        my %accounts;
        @accounts = map {$_->{Account}} @users;
        @accounts{@accounts} = @accounts;
        delete $accounts{$defaccount};
        @accounts = ($defaccount, sort keys %accounts);
        @users = ($user);
    } else {
        @users = ($user);
    }
    foreach my $account (@accounts) {
        foreach my $user (@users) {
            my @acct_assocs2 = grep {$_->{User} eq $user and $_->{Account} eq $account} @acct_assocs;
            my $defqos = $acct_assocs2[0]->{"Def QOS"};
            my @qos;
            foreach my $assoc (@acct_assocs2) {
                push @qos, (split /,/, $assoc->{QOS});
            }
            my %qos;
            foreach my $q (@qos) {
                # we'll clone because we pair them with user/account
                $qos{$q} = Clone::clone($qos->{$q});
                $qos{$q}{_UserName} = $user;
                $qos{$q}{Account} = $account;
                # this overrides the data...
                $qos{$q}{GrpTRESMins} = $qos{$q}{_current}{GrpTRESMins};
                $qos{$q}{MaxTRESPU} = $qos{$q}{_current}{"User Limits"}{getpwnam($user)} ?
                  $qos{$q}{_current}{"User Limits"}{getpwnam($user)}{MaxTRESPU} :
                  $qos{$q}{MaxTRESPU};
            }

            # we'll sort them here, because we're per account
            my @assocs2 = values %qos;
            @assocs2 = sort {($a->{Name} eq $defqos) ? -1 : ($b->{Name} eq $defqos) ? 1 : ($a->{Name} cmp $b->{Name})} @assocs2;
            push @assocs, @assocs2;
        }
    }

} else {
    @assocs = @{cshuji::Slurm::parse_scontrol_show([`scontrol show assoc_mgr flags=assoc user=$user`], type => "list")};
    if ($in_account) {
        # probably not a good idea...
        $all = 3 if $all;
        $all = 2 if $all < 2;
        if ($in_user) {
            # account and user, just grep the proper account
            @assocs = grep {not $_->{UserName} or $_->{Account} eq $in_account} @assocs;
            $in_account = undef;
        } else {
            # with account, needs the non user accounts from the basic user account (any user will do)
            @assocs = grep {not $_->{UserName}} @assocs;
            my $accounts = $in_account;
            if ($all > 2) {
                my $all_accounts = cshuji::Slurm::get_accounts();
                my %done;
                my @parents = $in_account;
                while (my $parent = shift @parents) {
                    next if $done{$parent};
                    push @parents, map {$_->{Account}} grep {$_->{"Par Name"} eq "$parent" and $_->{Cluster} eq $cluster} @$all_accounts;
                    $done{$parent} = 1;
                }
                $accounts = join(",", keys %done);
            }
            push @assocs, @{cshuji::Slurm::parse_scontrol_show([`scontrol show assoc_mgr flags=assoc account=$accounts`], type => "list")};
        }
    }
}

foreach my $assoc (@assocs) {
    unless ($in_qos) {
        $assoc->{_ParentAccount} = $assoc->{ParentAccount} =~ s/\(.*\)$//r;
        $assoc->{_UserName} = $assoc->{UserName} =~ s/\(.*\)$//r;
    }

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

    # MaxTRESPU
    my $maxtrespu = split_gres($assoc->{MaxTRESPU}, type => "string");
    $assoc->{_MaxTRESPU} = {Limit => {},
                            Usage => {},
                           };
    foreach my $trespu (keys %{$maxtrespu}) {
        if ($maxtrespu->{$trespu} =~ m/(.*)\((.*)\)/) {
            $assoc->{_MaxTRESPU}{Usage}{$trespu} = $2;
            $assoc->{_MaxTRESPU}{Limit}{$trespu} = $1;
        } else {
            $assoc->{_MaxTRESPU}{Limit}{$trespu} = $maxtrespu->{$trespu};
            $assoc->{_MaxTRESPU}{Usage}{$trespu} = 0;
        }
        $trespu{$trespu} = $trespu;
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

    # GrpTRESMins
    my $grptresmin = split_gres($assoc->{GrpTRESMins}, type => "string");
    $assoc->{_GrpTRESMins} = {Limit => {},
                              Usage => {},
                             };
    foreach my $tresmin (keys %{$grptresmin}) {
        if ($grptresmin->{$tresmin} =~ m/(.*)\((.*)\)/) {
            $assoc->{_GrpTRESMins}{Usage}{$tresmin} = $2;
            $assoc->{_GrpTRESMins}{Limit}{$tresmin} = $1;
        } else {
            print STDERR "Warning: Don't know how to handle \"$tresmin\" GrpTRESMins limit of $grptresmin->{$tresmin}\n";
            next;
        }
        $tresmin{$tresmin} = $tresmin;
    }

}

# get direct accounts
my @accounts;
if ($in_qos) {
    @accounts = @assocs;
} elsif ($in_account) {
    @accounts = grep {$_->{UserName}} @assocs;

    # sort by accounts or users
    if ($all > 2) {
        @accounts = sort {$a->{Account} cmp $b->{Account} or $a->{UserName} cmp $b->{UserName}} @accounts;
    } else {
        @accounts = sort {$a->{UserName} cmp $b->{UserName}} @accounts;
    }
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
    my $prevuser;
    my $prevaccount;
    do {
        my %entry;
        $entry{User} = $assoc->{_UserName};
        $entry{Account} = $assoc->{Account};
        $prevuser //= $entry{User};
        $prevaccount //= $entry{Account};
        if ($in_qos) {
            $entry{QOS} = $assoc->{Name};
        }
        foreach my $tres (sort keys %tres) {
            $entry{$tres} = [$assoc->{_GrpTRES}{Usage}{$tres}, $assoc->{_GrpTRES}{Limit}{$tres}];
            $tlength{$tres} = max($tlength{$tres} // 0, length($entry{$tres}[1]));
            next ACCOUNT if ($all < 2 and exists $trestorun{$tres} and $entry{$tres}[1] eq "0");
            $haslimits{$tres} ||= $entry{$tres}[1] ne "N";
        }
        foreach my $tres (sort keys %tresmin) {
            $entry{"${tres}min"} = [$assoc->{_GrpTRESMins}{Usage}{$tres}, $assoc->{_GrpTRESMins}{Limit}{$tres}];
            $tlength{"${tres}min"} = max($tlength{"${tres}min"} // 0, length($entry{"${tres}min"}[1]));
            $haslimits{"${tres}min"} ||= $entry{"${tres}min"}[1] ne "N";
        }
        foreach my $tres (sort keys %trespj) {
            $entry{"${tres}pj"} = $assoc->{_MaxTRESPJ}{$tres} // "N";
            $haslimits{"${tres}pj"} ||= $entry{"${tres}pj"} ne "N";
        }
        foreach my $tres (sort keys %trespu) {
            $entry{"${tres}pu"} = [$assoc->{_MaxTRESPU}{Usage}{$tres} // "0", $assoc->{_MaxTRESPU}{Limit}{$tres} // "N"];
            $tlength{"${tres}pu"} = max($tlength{"${tres}pu"} // 0, length($entry{"${tres}pu"}[1]));
            $haslimits{"${tres}pu"} ||= $entry{"${tres}pu"}[1] ne "N";
        }
        foreach my $nontres (sort keys %nontres) {
            $entry{$nontres} = [$assoc->{_nontres}{Usage}{$nontres}, $assoc->{_nontres}{Limit}{$nontres}];
            $tlength{$nontres} = max($tlength{$nontres} // 0, length($entry{$nontres}[1]));
            next ACCOUNT if ($all < 2 and exists $trestorun{$nontres} and $entry{$nontres}[1] eq "0");
            $haslimits{$nontres} ||= $entry{$nontres}[1] ne "N";
        }
        push @rows, {%entry};

        # find next row in this account/qos
        if ($in_qos) {
            if ($in_account) {
                $assoc = shift @accounts;
            } elsif ($all) {
                if (@accounts
                    and $accounts[0]{_UserName} eq $prevuser
                    and $accounts[0]{Account} eq $prevaccount
                   ) {
                    $assoc = shift @accounts;
                    $assoc->{_UserName} = "";
                    $assoc->{Account} = "";
                } else {
                    $assoc = undef;
                }
            } else {
                $assoc = undef;
            }
        } else {
            # if user, get generic account, otherwise get parent account (with or without user)
            if ($assoc->{UserName}) {
                if ($in_account and @accounts) {
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
        }
    } while $assoc;

    push @entries, [@rows];
    last if ((not $in_qos and not $all)
             or ($in_qos and $all <= 1));
}

unless ($long) {
    delete @tres{grep {not $haslimits{$_}} keys %haslimits};
    delete @tresmin{map {s/min$//r} grep {not $haslimits{$_}} keys %haslimits};
    delete @trespj{map {s/pj$//r} grep {not $haslimits{$_}} keys %haslimits};
    delete @trespu{map {s/pu$//r} grep {not $haslimits{$_}} keys %haslimits};
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
        if ($in_qos) {
            push @data, $row->{QOS};
        }
        foreach my $tres (sort keys %tres) {
            push @data, $avail ? $row->{"${tres}-avail"} : sprintf "\%s / \%$tlength{$tres}s", @{$row->{$tres}};
        }
        foreach my $tres (sort keys %tresmin) {
            push @data, sprintf "\%s / \%".$tlength{"${tres}min"}."s", @{$row->{"${tres}min"}};
        }
        foreach my $tres (sort keys %trespj) {
            push @data, $row->{"${tres}pj"};
        }
        foreach my $tres (sort keys %trespu) {
            push @data, sprintf "\%s / \%".$tlength{"${tres}pu"}."s", @{$row->{"${tres}pu"}};
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
                             ($in_qos ? ("QOS", \" | ") : ()),
                             (map {{title => "$_", align => "right", align_title => "right"}, \" | "} sort keys %tres),
                             (map {{title => "$_ min", align => "right", align_title => "right"}, \" | "} sort keys %tresmin),
                             (map {{title => "$_ pj", align => "right", align_title => "right"}, \" | "} sort keys %trespj),
                             (map {{title => "$_ pu", align => "right", align_title => "right"}, \" | "} sort keys %trespu),
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

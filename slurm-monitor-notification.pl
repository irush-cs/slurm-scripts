#!/usr/bin/env perl

################################################################################
#
#   slurm-monitor-notification.pl
#
#   Copyright (C) 2019 Hebrew University of Jerusalem Israel, see LICENSE file.
#
#   Author: Yair Yarom <irush@cs.huji.ac.il>
#
################################################################################

use strict;
use warnings;

use Email::Stuffer;
use Net::Domain qw(hostdomain);
use Text::Table;
use POSIX qw(round);

my $domain = hostdomain;

unless (exists $ENV{SLURM_RESOURCE_MONITOR_DATA}) {
    exit 1;
}
my $job;
eval $ENV{SLURM_RESOURCE_MONITOR_DATA};

my $body = "";

if (not exists $job->{recipients} or not @{$job->{recipients}}) {
    print STDERR "No recipients\n";
    exit 1;
}

foreach my $res (qw(cpus gpus)) {
    if ($job->{$res}{notify}) {
        my $badpercent = round(100 * $job->{$res}{baduse} / $job->{$res}{samples});
        my $baduse = $job->{$res}{count} - $job->{$res}{allowedunused}{count};
        $body .= "You have requested $job->{$res}{count} $res, but at least ${badpercent}\% of the time you used less than $baduse $res\n";
        $body .= "\n";
        $body .= "$res usage:\n";

        my $table = Text::Table->new({title => "# $res", align => "right", align_title => "right"}, \" | ", {title => "% of time used", align => "right", align_title => "left"});
        foreach my $count (reverse sort {$a cmp $b} keys %{$job->{$res}{usage}}) {
            $table->add($count, round(100 * $job->{$res}{usage}{$count} / $job->{$res}{samples}).'%');
        }
        $body .= $table->title();
        $body .= $table->rule("-", "+");
        $body .= $table->body();
        $body .= "\n";
    }
}

if ($body) {
    $body = "Dear $job->{login}

Your job $job->{jobid} on $job->{node} ($job->{cluster}) was allocated more resources than it needed.

".$body;
    $body .= "
Please adjust your future jobs parameters to ensure better utilization of the
cluster and faster starting time of your and other's jobs.

Regards,
Slurm Resource Monitor
";
    my $html_body = "<html><body><div><pre style=\"font-family:monospace;\">\n$body\n</pre></div></body></html>\n";

    my @recipients;
    foreach my $recipient (@{$job->{recipients}}) {
        push @recipients, address_of($recipient);
    }

    my $replyto = "slurm";
    if ($job->{replyto}) {
        $replyto = $job->{replyto};
    }
    $replyto = address_of($replyto);

    my $email = Email::Stuffer
      ->from("Slurm Resource Monitor <slurm\@${domain}>")
      ->to(@recipients)
      ->subject("Unused resources for job $job->{jobid} (on $job->{cluster})")
      ->text_body($body)
      ->html_body($html_body)
      ->reply_to("$replyto");

    $email->send();

    if ($job->{recipientsbcc} and @{$job->{recipientsbcc}}) {
        $email->send({to => [map {address_of($_)} @{$job->{recipientsbcc}}]});
    }

}

sub address_of {
    my $recipient = shift;
    if ($recipient =~ m/\@/) {
        return $recipient;
    } elsif ($recipient eq "*LOGIN*") {
        return $job->{login}."\@${domain}";
    } else {
        return "$recipient\@${domain}";
    }
    exit 1;
}

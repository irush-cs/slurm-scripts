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
use Time::Local;

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

my %attachments;

my @time = localtime(time);
my $tzoffset = timegm(@time) - timelocal(@time);

sub plot {
    my $job = shift;
    my $res = shift;

    my $ytics = 1;
    if ($job->{$res}{count} > 10)  {
        $ytics = $job->{$res}{count} / 6;
    }
    if ($job->{$res}{notifyhistory} and -r "$job->{runtimedir}/$res") {
        if (open(GP, ">$job->{runtimedir}/$res.gp")) {
            print GP "#!/usr/bin/env gnuplot\n";
            print GP "\n";
            print GP "data = \"$job->{runtimedir}/$res\"\n";
            print GP "unset key\n";
            print GP "set datafile separator \",\"\n";
            print GP "set style fill solid\n";
            print GP "set terminal gif size 800,200\n";
            print GP "set output \"$job->{runtimedir}/$res.gif\"\n";

            print GP "set xdata time\n";
            print GP "set xlabel \"time\"\n";
            print GP "set xrange [($job->{$res}{firststamp} + $tzoffset):($job->{$res}{laststamp} + $tzoffset)]\n";

            print GP "set ylabel \"$res\"\n";
            print GP "set ytics $ytics\n";
            print GP "set yrange [0:$job->{$res}{count}]\n";
            print GP "set format y \"\%.f\"\n";
            print GP "set timefmt \"\%s\"\n";

            print GP "plot data using (\$1 + $tzoffset):(\$2) with filledcurves x1 fillcolor rgb \"blue\" title \"$res\"\n";
            close(GP);
            chmod 0755, "$job->{runtimedir}/$res.gp";
            if (system("gnuplot $job->{runtimedir}/$res.gp") == 0) {
                $attachments{"$res.gif"} = "$job->{runtimedir}/$res.gif";
                $body .= "__IMAGE_$res.gif__\n";
            } else {
                print STDERR "Can't run gnuplot: $!\n";
            }
        } else {
            print STDERR "Can't create a gnuplot file: $!\n";
        }
    }
}

foreach my $res (qw(cpus gpus)) {
    if ($job->{$res}{notify}) {
        my $badpercent = round(100 * $job->{$res}{baduse} / $job->{$res}{samples});
        my $baduse = $job->{$res}{count} - $job->{$res}{allowedunused}{count} + 1;
        $body .= "You have requested $job->{$res}{count} $res, but at least ${badpercent}\% of the time you used less than $baduse $res\n";
        $body .= "\n";
        $body .= "$res usage:\n";

        my $table = Text::Table->new({title => "# $res", align => "right", align_title => "right"}, \" | ", {title => "% of time used", align => "right", align_title => "left"});
        foreach my $count (reverse sort {$a <=> $b} keys %{$job->{$res}{usage}}) {
            $table->add($count, round(100 * $job->{$res}{usage}{$count} / $job->{$res}{samples}).'%');
        }
        $body .= $table->title();
        $body .= $table->rule("-", "+");
        $body .= $table->body();
        $body .= "\n";

        plot($job, $res);
    }
}

if ($job->{memory}{notify}) {
    my $badpercent = round(100 * $job->{memory}{max_usage} / $job->{memory}{count});
    $body .= "You have requested $job->{memory}{count} MB RAM, but your max usage was only $job->{memory}{max_usage} MB (${badpercent}\%)\n";
    $body .= "\n";
    plot($job, "memory");
}

if ($job->{shortjobnotify}) {
    $body .= "You have requested a time limit of $job->{timelimit} but the run time was $job->{runtime}, which is only $job->{runtimepercent}% of the requested time.\n";
}

if ($body) {
    my $name = (getpwnam($job->{login}))[6] // $job->{login};
    $body = "Dear $name,

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

    my @attachments;
    foreach my $file (keys %attachments) {
        if (-r $attachments{$file}) {
            my $email = Email::Stuffer->attach_file($attachments{$file});
            $email->{parts}->[-1]->header_str_set("Content-ID", "<${file}>");
            push @attachments, $email->{parts}->[-1];
            $body =~ s/__IMAGE_\Q${file}\E__/See attached $file\n/sg;
            $html_body =~ s,__IMAGE_\Q${file}\E__,<img src="cid:$file" alt="See attached $file"><br>,sg;
        }
    }

    my $text_part = Email::MIME->create(
                                        attributes => {
                                                       content_type => 'text/plain',
                                                       charset => 'utf-8',
                                                       encoding     => 'quoted-printable',
                                                      },
                                        body => $body);

    my $html_part = Email::MIME->create(
                                        attributes => {
                                                       content_type => 'text/html',
                                                       charset => 'utf-8',
                                                       encoding => 'quoted-printable',
                                                      },
                                        body => $html_body);

    $html_part = Email::MIME->create(parts => [$html_part, @attachments]);
    $html_part->content_type_set("multipart/related");

    my $email = Email::MIME->create(
                                 header_str => [
                                                'Content-Type' => "multipart/alternative",
                                                'From' => "Slurm Resource Monitor <slurm\@${domain}>",
                                                'To' => [@recipients],
                                                'Subject' => "Unused resources for job $job->{jobid} (on $job->{cluster})",
                                                'Reply-To' => "$replyto",
                                               ],
                                 parts => [$text_part, $html_part],
                                );

    #print $email->as_string;
    unless (Email::Sender::Simple->try_to_send($email)) {
        print STDERR "Error sending mail\n";
    }

    if ($job->{recipientsbcc} and @{$job->{recipientsbcc}}) {
        unless (Email::Sender::Simple->try_to_send($email, {to => [map {address_of($_)} @{$job->{recipientsbcc}}]})) {
            print STDERR "Error sending bcc mail\n";
        }
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

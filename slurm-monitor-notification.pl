#!/usr/bin/env perl

################################################################################
#
#   slurm-monitor-notification.pl
#
#   Copyright (C) 2019-2020 Hebrew University of Jerusalem Israel, see LICENSE
#   file.
#
#   Author: Yair Yarom <irush@cs.huji.ac.il>
#
################################################################################

use strict;
use warnings;

my $scriptdir;
BEGIN {
    use Cwd;
    use File::Basename;
    $scriptdir = dirname(Cwd::realpath($0));
}
$scriptdir = '.' unless (defined $scriptdir);
use lib "$scriptdir";
use cshuji::Slurm qw(mb2string);

use Email::Stuffer;
use Net::Domain qw(hostdomain);
use Text::Table;
use POSIX qw(round);
use Time::Local;
use JSON;

my $domain = hostdomain;

my $job;
if ($ARGV[0] and -r $ARGV[0]) {
    open(DATA, "$ARGV[0]") or exit 2;
    my $data = join "", <DATA>;
    close(DATA);
    $job = JSON->new->decode($data);
} elsif (exists $ENV{SLURM_RESOURCE_MONITOR_DATA}) {
    eval $ENV{SLURM_RESOURCE_MONITOR_DATA};
}
exit 1 unless $job;

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
        my $baduse = $job->{$res}{count} - $job->{$res}{allowedunused}{count};
        my $betterpercent = 0.66 * $job->{$res}{allowedunused}{percent};
        my $betteruse = 0;
        my $psum = 0;

        my $table = Text::Table->new({title => "# $res", align => "right", align_title => "right"}, \" | ", {title => "% of time used", align => "right", align_title => "left"});
        foreach my $count (reverse sort {$a <=> $b} keys %{$job->{$res}{usage}}) {
            my $percent = round(100 * $job->{$res}{usage}{$count} / $job->{$res}{samples});
            $psum += $percent;
            $betteruse = $count if $psum <= $betterpercent;
            $table->add($count, "${percent}\%");
        }

        $body .= "<title>$res</title>\n";
        my $atleast = $badpercent eq "100" ? "the entire" : "${badpercent}\% of the";
        $body .= "You have requested $job->{$res}{count} $res, but ${atleast} time you used less than $baduse $res.\n";
        if ($betteruse > 0 and $betteruse < $job->{$res}{count}) {
            $body .= "You might get better timing if you request $betteruse $res.\n";
        }
        $body .= "\n";

        $body .= "$res usage:\n";
        $body .= $table->title();
        $body .= $table->rule("-", "+");
        $body .= $table->body();
        $body .= "\n";

        plot($job, $res);

    }
}

if ($job->{memory}{notify}) {
    my $badpercent = round(100 * $job->{memory}{max_usage} / $job->{memory}{count});

    my $betterpercent = (0.66 * $job->{memory}{allowedunused}{percent}) / 100;
    my $betteruse = int($job->{memory}{max_usage} + ($betterpercent * $job->{memory}{max_usage}) / (1 - $betterpercent));

    $body .= "<title>memory</title>\n";
    $body .= "You have requested ".mb2string($job->{memory}{count}, space => 1)."B RAM, but your max usage was ".mb2string($job->{memory}{max_usage}, space => 1)."B (${badpercent}\%)\n";
    if ($betteruse > 10 and $betteruse < $job->{memory}{count} and $betteruse > $job->{memory}{max_usage}) {
        $body .= "You might get better timing if you request ".mb2string($betteruse, space => 1)."B.\n";
    }
    $body .= "\n";
    plot($job, "memory");
}

if ($job->{unusedtimenotify}) {
    $body .= "<title>time</title>\n";
    $body .= "You have requested a time limit of $job->{timelimit} but the run time was $job->{runtime}, which is $job->{runtimepercent}% of the requested time.
Requesting more time than needed can drastically delay the starting time of your and others jobs.
";
}

if ($body) {
    my $name = (getpwnam($job->{login}))[6] // $job->{login};
    $body = "Dear $name,

Your job $job->{jobid} on $job->{node} ($job->{cluster}) was allocated more resources than it needed.

".$body;
    $body .= "
<title>options</title>
Please adjust your future jobs parameters to ensure better utilization of the
cluster and faster starting time of your and other's jobs.

If you want to stop receiving these mails but continue wasting resources and
time, you can add one or more of the following lines into
~/.slurm-resource-monitor:

NotifyUnusedTime=No
NotifyUnusedCPUs=No
NotifyUnusedGPUs=No
NotifyUnusedMemory=No
ForceNotify=No

If you want to fine tune the reported parameters, please look at:
https://github.com/irush-cs/slurm-scripts/blob/master/slurm-resource-monitor.md

Job data (on $job->{node}):
  CPUs:       $job->{cpus}{count}
  GPUs:       $job->{gpus}{count}
  Memory:     ".mb2string($job->{memory}{count}, space => 1)."B
  SubmitTime: $job->{submittime}
  StartTime:  $job->{starttime}
  EndTime:    $job->{endtime}
  RunTime:    $job->{runtime}
  State:      $job->{state}

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

    my %title_map = (cpus => "CPUs", gpus => "GPUs", memory => "Memory", time => "Time", options => "Options");
    foreach my $title ($body =~ m/<title>([^_]*?)<\/title>/g) {
        my $html_title = '</pre><hr><h4>'.($title_map{$title} // $title).'</h4><pre style="font-family:monospace;">';
        $html_body =~ s,<title>${title}</title>,$html_title,;
        my $text_title = ("-" x 75)."\n".($title_map{$title} // $title)."\n".("-"x length($title));
        $body =~ s,<title>${title}</title>,${text_title},ms;
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

    if (@attachments) {
        $html_part = Email::MIME->create(parts => [$html_part, @attachments]);
        $html_part->content_type_set("multipart/related");
    }

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

    #print $email->as_string; exit 3;
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

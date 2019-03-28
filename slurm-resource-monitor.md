# Slurm-Resource-Monitor

The slurm-resource-monitor is a stand-alone daemon that monitors the resources
used by slurm jobs and reports back to the users if they've requested too much
resources. Currently monitored are: CPU, GPU, and time limit.

# Table of Contents

* [slurm-resource-monitor.pl](#slurm-resource-monitorpl)
* [etc/slurm-resource-monitor.service](#etcslurm-resource-monitorservice)
* [slurm-monitor-notification.pl](#slurm-monitor-notificationpl)
* [slurm-resource-monitor.conf](#slurm-resource-monitorconf)

## slurm-resource-monitor.pl

This is the main daemon. It should run by user who has access to the slurm data
(i.e. can get response from `scontrol show jobs`), and `scontrol` should be in
it's `PATH`.

The daemon periodically checks the current utilization of the job's resources
and saves the data in memory. When a job finishes, it runs another script that
can send mail to the user with the utilization status. The daemon will only
report jobs that it properly monitored for at least `MinRunTime` seconds, and
at least `MinMonitoredPercent` percent of the total job's runtime.

The daemon is configured using a configuration file
[slurm-resource-monitor.conf](#slurm-resource-monitorconf), which should either
be placed in the same directory as `slurm.conf`, or supplied using the `-c`
argument.

When a job finishes, if a notification needs to be sent and external script
`NotificationScript` is run with the `SLURM_RESOURCE_MONITOR_DATA` environment
variable set to a perl hash with job's data.

### CPU

In order to check the utilization of the CPUs, slurm should be configured to
use the `proctrack/cgroup`, and the daemon needs read access to the cpuset and
the cpuacct cgroups of the jobs. I.e. to
```
/sys/fs/cgroup/cpuset/slurm/uid_<uid>/job-<jobid>/cpuset.cpus
/sys/fs/cgroup/cpu,cpuacct/slurm/uid_<uid>/job_<jobid>/cpuacct.usage_percpu
```

The number of currently used CPUs is counted and saved in a histogram table
(how many times X CPUs were used). A CPU is considered "in use" if its
utilization since the last sample is above `InUseCPUPercent`.

When the job finishes, the number of "good" and "bad" cpu usages is counted. A
"bad" usage is if the number of unused CPUs is below `AllowedUnusedCPUs`. If
the percent of "bad" usages is above `AllowedUnusedCPUPercent`, a notification
is sent.

For example, if a process requested 5 CPUs, and 
```
AllowedUnusedCPUs = 2
AllowedUnusedCPUPercent = 30
```

And the usage histogram is

| # cpus | % of time used |
|--------|----------------|
|      5 |  10%           |
|      4 |  10%           |
|      3 |  10%           |
|      2 |  10%           |
|      1 |  50%           |
|      0 |  10%           |

A "good" usage is 4 or 5 CPUs, which was 20% of the time. "bad" usage is 0 - 3
CPUs, which is 80%. A notification will be sent as 80 > 30.

### GPU

The GPU utilization checks is very similar to the CPU checks. From the slurm's
job information, the daemon knows which GPUs are assigned to the job, and uses
`nvidia-smi` to check the current load (so nvidia-smi should be in the PATH,
and usable by the deamons' user).

Like with the CPUs, "good" and "bad" usages are counted using `InUseGPUPercent`
and `AllowedUnusedGPUs`. And a notification is sent depending on
`AllowedUnusedGPUPercent`.

Unlike CPUs, the `nvidia-smi` utility reports the current usage of the GPU
instead of the usage in the past time interval. So for sparse GPU usages with
long sampling intervals, the report might be inaccurate.

### Timelimit

When a job finishes with a `COMPLETED` state, if it uses less than
`ShortJobPercent`, a notification is sent.

## etc/slurm-resource-monitor.service

An example systemd service file that can be used to start the daemon. Needs to
be copied to `/etc/systemd/system/slurm-resource-monitor.service`, and run:
```
systemctl daemon-reload
systemctl enable slurm-resource-monitor
systemctl start slurm-resource-monitor
```

## slurm-monitor-notification.pl

The basic notification script the daemon will call. The script will parse the
`SLURM_RESOURCE_MONITOR_DATA` environment variable and send mail accordingly.

The `NotificationScript` configuration should point to the installation
location of this script.

## slurm-resource-monitor.conf

This is the configuration file for the daemon. See
[slurm-resource-monitor.conf.sample](slurm-resource-monitor.conf.sample) for
example file with the default parameters.

The `NotificationScript` is mandatory, the rest are optional with default
values.

Some options can be set per user in `~/.slurm-resource-monitor`. This file is
consulted at the start of each job (so changes to it will only effect new
jobs).

### NotificationScript

The script to run when a notification needs to be sent. The job's data is
supplied via the `SLURM_RESOURCE_MONITOR_DATA` environment variable.

### NotificationRecipients

A comma separated list of recipients. The default value `*LOGIN*` is used to
send to the job's user.

### NotificationBcc

A comma separated list of additional recipients to send a blind carbon copy.

### NotificationReplyto

The `ReplyTo` header to be used in the mail.

### ConfUpdateCheckInterval

The deamon will stat the configuration file every `ConfUpdateCheckInterval`
seconds. If the file was modified since last read, it will reload the
configuration file and reset the daemon's data.

### MinRunTime

Jobs who's runtime is less than `MinRunTime` will not be reported. Also, jobs
which were monitored less than `MinRunTime` will not be reported.

### ShortJobPercent

If a job was successfully finished after only `ShortJobPercent` of the time
which was allocated, a notification will be sent.

### NotifyShortJob

Whether to notify on short jobs or not (boolean value). This can be set per
user in `~/.slurm-resource-monitor`.

### NotifyUnusedCPUs

Whether to notify on low CPU usage or not (boolean value). This can be set per
user in `~/.slurm-resource-monitor`.

### NotifyUnusedGPUs

Whether to notify on low GPU usage or not (boolean value). This can be set per
user in `~/.slurm-resource-monitor`.

### InUseCPUPercent, InUseGPUPercent

The minimum utilization of the CPU or GPU (in percentage) to consider the
resource "in-use".

### AllowedUnusedCPUs, AllowedUnusedGPUs

Number of CPUs or GPUs to allow to be unused.

### AllowedUnusedCPUPercent, AllowedUnusedGPUPercent

If the percentage of sampling that didn't use more than that allowed unused
resource is higher than the AllowedUnusedCPUPercent (or
AllowedUnusedGPUPercent), a notification is sent.

### MinMonitoredPercent

If the job is monitored less than this percent of the total runtime, no
notification will be sent.

### SamplingInterval

The sleep duration between each sample. To low will load the node, to high will
give inaccurate results.

### MinSamples

The minimum number of samples for reporting. This will be apply separately for
the CPU and GPU sampling.

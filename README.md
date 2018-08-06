# SLURM Scripts

A collection of SLURM scripts used at the Hebrew University of Jerusalem,
School of Computer Science and Engineering.

# Table of Contents

* [pam_slurm_save_cgroups](#pam_slurm_save_cgroupssh)
* [healthcheck.sh](#healthchecksh)
* [cluster.conf](#clusterconf)

## pam\_slurm\_save\_cgroups\.sh

A script to use with pam\_exec that saves and restores the current slurm's
cgroups. Useful when pam\_systemd is required, but when the slurm cgroups needs
to be saves (e.g. the devices cgroup).

On the slurm nodes, `/etc/pam.d/slurm` should contain (perhaps in addition to
other things):
```
session		required	pam_exec.so seteuid /etc/security/pam_slurm_save_cgroups.sh save
session		optional	pam_loginuid.so
session		optional	pam_systemd.so
session		required	pam_exec.so seteuid /etc/security/pam_slurm_save_cgroups.sh restore
```

`pam_slurm_save_cgroups.sh` should be saved in `/etc/security`, and
`/run/slurm-saved-cgroups/` should be created (on boot) owned by root\:root
with permissions mode `0700`.

## healthcheck\.sh

A script to run as the `HealthCheckProgram` (as set in `slurm.conf`) used to
drain and resume nodes automatically. This script goes through a
`healthcheck.d` directory and runs all the scripts there. The `healthcheck.d`
should reside in the same directory as `slurm.conf`.

If any of the programs in `healthcheck.d` produce a single line and exit with
status != 0, the node will be drained with Reason containing the line with
additional "HC: " prefix.

If all program passes and the node is drained with reason prefixed with "HC: ",
the node will be resumed automatically and mail will be sent to the maintainers
as set in [cluster.conf](#clusterconf)

If the programs take more than 50 seconds to run, or if the `healthcheck.d`
directory is missing, the node will be drained with the appropriate message.

## cluster\.conf

An ini type configuration file, used by some of the scripts. The file should be
named after the cluster (the `ClusterName` in `slurm.conf`), and reside in the
same directory as `slurm.conf` or one directory above it.

### [general]

|Option|Value|
|-|-|
|maintainers| comma separated list of mails (or users) to send mails regarding draining and resuming nodes.|

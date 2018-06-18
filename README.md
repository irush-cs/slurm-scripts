# SLURM Scripts

A collection of SLURM scripts used at the Hebrew University of Jerusalem,
School of Computer Science and Engineering.

# Table of Contents

* [pam_slurm_save_cgroups](#pam_slurm_save_cgroupssh)

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

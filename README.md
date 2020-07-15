# SLURM Scripts

A collection of SLURM scripts used at the Hebrew University of Jerusalem,
School of Computer Science and Engineering.

# Table of Contents

* [pam_slurm_save_cgroups](#pam_slurm_save_cgroupssh)
* [healthcheck.sh](#healthchecksh)
* [healthcheck.d/netspeed.sh](#healthcheckdnetspeedsh)
* [healthcheck.d/highload.sh](#healthcheckdhighloadsh)
* [healthcheck.d/needs-reboot.sh](#healthcheckdneeds-rebootsh)
* [cluster.conf](#clusterconf)
* [functions.bash](#functionsbash)
* [cshuji/Slurm.pm](#cshujislurmpm)
* [Makefile](#makefile)
* [slurm-resource-monitor](#slurm-resource-monitor)

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

Instead of the `restore` parameter, `slurm` can be used to force all cgroups to
be moved to a /slurm/ subtree, regardless of whether slurm uses them or
not. This is useful when pam\_systemd.so is not used, but the user processes
still shouldn't be in the system-slurmd.slice cgroup. This only affects non
root cgroups, if the task is in the root (`/`), it won't be moved.

## healthcheck\.sh

A script to run as the `HealthCheckProgram` (as set in `slurm.conf`) used to
drain and resume nodes automatically. This script goes through a
`healthcheck.d` directory and runs all the scripts there. The `healthcheck.d`
should reside in the same directory as `slurm.conf`.

If any of the programs in `healthcheck.d` produce a single line and exit with
status != 0, the node will be drained with Reason containing the line with
additional "HC: " prefix. Mail will be sent to the maintainers as set in
[cluster.conf](#clusterconf).

If all program passes and the node is drained with reason prefixed with "HC: ",
the node will be resumed automatically and mail will be sent to the
maintainers.

If the programs take more than 50 seconds to run, or if the `healthcheck.d`
directory is missing, the node will be drained with the appropriate message.

## healthcheck.d/netspeed.sh

A healthcheck script to verify that the default route interface speed is not
less then 1000Mb/s.

## healthcheck.d/highload.sh

A healthcheck script to check if the load is below 10 * CPUs.

## healthcheck.d/needs-reboot.sh

A healthcheck script that reboots a node if the node is IDLE+DRAIN and drained
because of 'HC: needs reboot'. The node is kept drained until it's idle, then
rebooted, then resumed (by the `healthcheck.sh` script).

## cluster\.conf

An ini type configuration file, used by some of the scripts. The file should be
named after the cluster (the `ClusterName` in `slurm.conf`), and reside in the
same directory as `slurm.conf` or one directory above it.

### [general]

|Option|Value|
|-|-|
|maintainers| comma separated list of mails (or users) to send mails regarding draining and resuming nodes.|

## functions.bash

A bash file that can be source'ed by bash scripts with various functions. To
use, it's best to create the `cshuji` directory where slurm.conf resides and
run:
```
slurmdir=`dirname \`scontrol show config | awk '$1=="SLURM_CONF" {print $3}'\``
. $slurmdir/cshuji/functions.bash
```
### slurm\_get\_config

Retrieves SLURM's configuration by calling `scontrol show config` and storing
the data in `_slurm_config` array.

Should be called when `slurm.conf` changes, or when a different cluster is
wanted.

### slurm\_config <conf>

Returns a specific configuration, e.g.:
```
slurm_config MaxArraySize
```

Will call `slurm_get_config` if needed.

### slurm\_get\_node <node>

Retrieves the `node`s status from `scontrol show node` and saves the data in
`_slurm_nodes` array.

### slurm\_node <node> <key>

Returns a specific element from the node status (from `scontrol show node`)
```
slurm_node node-01 State
slurm_node node-01 BootTime
```

Will call `slurm_get_node` if needed.

### slurm\_maintainers

Returns the maintainers list from `cluster.conf`

## cshuji/Slurm.pm

A perl module with slurm utility functions (mostly parsing slurm commands
output).

To install, the cshuji directory needs to be in the standard perl package paths
(such as `/usr/local/lib/site_perl`), or the `PERL5LIB` environment variable
needs to be set appropriately.

### parse\_scontrol\_show

Parses some of the `scontrol show` commands into a perl hash.
```
$results = parse_scontrol_show([`scontrol show job -dd`])
```

### parse\_list

Parses some of the lists returned by various slurm utilities into a perl array
ref. E.g:
```
$results = parse_list([`sacctmgr list users -s -p`])
```

### split\_gres

Splits a GRES or TRES string to a perl hash. Can combine the has with previous
hash values
```
my $prev = {gpu => 1}
split_gres("gpu:2,mem:1M", $prev) # {gpu => 3, mem => "1M"}
```

### nodecmp

A compare function for `sort` to sort nodes. This takes into account numeric
indices inside the node names.
```
print join("\n", sort nodecmp ('node-10', 'node-9', 'node-90'))
node-9
node-10
node-90
```

### nodes2array

Opens up the input string(s) (slurm node notation) and returns a complete list
of the nodes. The output is sorted using nodecmp.

### get_jobs

Get jobs hash ref by calling `scontrol show jobs -dd`. Uses the
`parse_scontrol_show` function so \_DETAILS are available with the following
items:
* CPU_IDs
* GRES_IDX
* Mem
* Nodes

In addition, the following calculated values are also available per detail:

* _JobId      - The job's JobId
* _EndTime    - The job's EndTime
* _nCPUs      - Totol number of CPUs from CPU_IDs
* _GRES       - Hash of GRES from GRES_IDX
* _NodeList   - Array of nodes from Nodes

Also, the job hash contains the following additional values:
* _TRES       - Hash of TRES

### get\_clusters

Get clusters hash refs by calling `sacctmgr list clusters`. Uses the
`parse_list` function. Returns a hash of clusters by name.

### set\_ cluster

For multiple clusters, this sets `PATH` and `SLURM_CONF` to work with the
specified cluster.

```
set_cluster($cluster, [path => \@path], [conf => $conf], [unset => <1|0>])
```

If `path` is given, they are simply prepended to the `PATH` environment.

If `path` is undef, `get_config` is called for the current cluster name. Then
the location of 'scontrol' and 'slurmctld' is search in `PATH`. If the path of
'scontrol' and 'slurmctld' contains the current cluster's name, it is replaced
with the new name and replaced in the `PATH` (if they exist in the resulting
path).

If `conf` is given, `SLURM_CONF` is set appropriately.

If `conf` is undef, `get_config` is called (before `PATH` is changed). If the
current `SLURM_CONF` or the `SLURM_CONF` from `get_config` contains the current
cluster name, it is replaced with the new cluster name. Otherwise (or if the
new `SLURM_CONF` doesn't exists), `get_config` is called with `$cluster` (with
the new path) and `SLURM_CONF` is taken from there.

If `unset` is true, `PATH` and `SLURM_CONF` are reset to their original value
before the first call to `set_cluster`. `$cluster` is ignored.

A second call to `set_cluster` will reset both `PATH` and `SLURM_CONF` to their
previous states before starting to set the new cluster (like with
`unset`). This means that if `PATH` or `SLURM_CONF` were changed outside
`set_cluster`, they will be reverted.

The return value is boolean of whether the change worked. This is checked using
`get_config`, and comparing the result ClusterName with `$cluster`.

This mechanism lets cshuji::Slurm work with several clusters which might
operate on different versions (and may require different binaries). It is best
to set the paths of the binaries and the slurm.conf files to contain the
cluster names (and make sure the clusters aren't named "usr" or "bin").

For example, the slurm.conf can be in:
* /etc/slurm/clusterA/slurm.conf
* /etc/slurm/clusterB/slurm.conf

And the binaries might be:
* /usr/local/slurm/17.02.1/{bin,sbin,...}
* /usr/local/slurm/17.11.3/{bin,sbin,...}
* /usr/local/slurm/clusterA -> /usr/local/slurm/17.02.1
* /usr/local/slurm/clusterB -> /usr/local/slurm/17.11.3

### get\_accounts

Get array ref of account hash refs by calling `sacctmgr list accounts` and
using the `parse_list` function. Only the accounts are returned (i.e. where
`User` is empty).

The returned fields are:

* Description
* Org
* Cluster
* ParentName
* User
* Share
* GrpJobs
* GrpNodes
* GrpCPUs
* GrpMem
* GrpSubmit
* GrpWall
* GrpCPUMins
* MaxJobs
* MaxNodes
* MaxCPUs
* MaxSubmit
* MaxWall
* MaxCPUMins
* QOS
* DefaultQOS
* GrpTRES


### get\_associations

Get array ref of association hash refs by calling `sacctmgr list associations`
and using the `parse_list` function. All associations are returned, including
base ones (with empty user or empty partition).

The returned fields are:

* Cluster
* Account
* User
* Partition
* Share
* GrpJobs
* GrpTRES
* GrpSubmit
* GrpWall
* GrpTRESMins
* MaxJobs
* MaxTRES
* MaxTRESPerNode
* MaxSubmit
* MaxWall
* MaxTRESMins
* QOS
* Def QOS
* GrpTRESRunMins

### get_nodes

Get nodes hash ref by calling `scontrol show nodes -dd`. Uses the
 `parse_scontrol_show` function with the following updates:
 * GRES   - Empty strin ginstead of "(null)".
 * \_Gres - Computed `GRES` hash

### cshuji/Slurm/Local.pm

This file, if exists, is loaded and exported automatically. It is used mainly
for backward compatibility, but in the future may be used to override functions
in cshuji/Slurm.pm

## Makefile

This is currently only used to run the perl module tests:
```
make test
```

## slurm-resource-monitor

See [slurm-resource-monitor.md](slurm-resource-monitor.md)

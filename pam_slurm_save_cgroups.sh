#!/bin/bash

################################################################################
#
#   pam_slurm_save_cgroups.sh
#
#   Copyright (C) 2018-2019 Hebrew University of Jerusalem Israel, see LICENSE
#   file.
#
#   Author: Yair Yarom <irush@cs.huji.ac.il>
#
################################################################################

set -e

_savedir="/run/slurm-saved-cgroups/"
if [[ ! -e "$_savedir" ]]; then
    mkdir "$_savedir"
    chown 0:0 "$_savedir"
    chmod 700 "$_savedir"
fi

if [[ ( ! -d "$_savedir" ) || ( `stat --format '%F/%a/%u/%g' "$_savedir"` != 'directory/700/0/0' ) ]]; then
    echo "bad permissions for $_savedir" 1>&2
    exit 3
fi

_ppid=`awk '$1=="PPid:"{print $2}' /proc/$$/status`
if [[ -z "$_ppid" ]]; then
   echo "Don't know my PPID" 1>&2
   exit 1
fi
_savefile="$_savedir/${PAM_SERVICE}.${PAM_TYPE}.${PAM_USER}.${_ppid}"

case "$1" in
    save)
        cat /proc/$_ppid/cgroup > $_savefile
    ;;
    restore)
        for cgroup in `awk -F: '$2&&$3~/^\/slurm\// {printf "/sys/fs/cgroup/%s%s/tasks\n", $2, $3}' ${_savefile}`; do
            echo $_ppid >> $cgroup
        done

        # systemd uses the unified cgroup-v2. If we keep it, "systemctl
        # daemon-reload" will trash our work and reset the v1 cgroups.
        if [[ -d "/sys/fs/cgroup/unified/" ]]; then
            jobdir=`awk -F: '$3~/\/job_/{print $3}' ${_savefile} | head -n 1 | tr / '\n' | grep ^job_`
            uiddir=`awk -F: '$3~/\/uid_/{print $3}' ${_savefile} | head -n 1 | tr / '\n' | grep ^uid_`
            mkdir -p /sys/fs/cgroup/unified/slurm/$uiddir/$jobdir
            echo $_ppid >> /sys/fs/cgroup/unified/slurm/$uiddir/$jobdir/cgroup.procs
        fi

        rm "${_savefile}"
    ;;
    *)
        echo "Either save or restore" 1>&2
        exit 2
esac

exit 0


#!/bin/bash

################################################################################
#
#   pam_slurm_save_cgroups.sh
#
#   Copyright (C) 2018-2022 Hebrew University of Jerusalem Israel, see LICENSE
#   file.
#
#   Author: Yair Yarom <irush@cs.huji.ac.il>
#
################################################################################

set -e
set -u

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

action=
as_type=${PAM_TYPE}
delete_only_on_close=
while [[ "$#" -gt 0 ]]; do
    arg=$1
    shift;
    case $arg in
        as_type=*)
            as_type=`echo $arg | cut -d= -f2-`
            ;;
        save|restore|slurm)
            action=$arg
            ;;
        delete_only_on_close)
            delete_only_on_close=1
            ;;
        *)
            echo "Bad argument: $arg" 1>&2
            exit 3;
    esac
done


_ppid=`awk '$1=="PPid:"{print $2}' /proc/$$/status`
if [[ -z "$_ppid" ]]; then
   echo "Don't know my PPID" 1>&2
   exit 1
fi
_savefile="$_savedir/${PAM_SERVICE}.${as_type}.${PAM_USER}.${SLURM_JOB_ID:-$_ppid}"

case "$action" in
    save)
        cat /proc/$_ppid/cgroup > $_savefile
    ;;

    restore)
        for cgroup in `awk -F: '$2&&$3~/^\/slurm\//&&$2!~/name=systemd/ {printf "/sys/fs/cgroup/%s%s/tasks\n", $2, $3}' ${_savefile}`; do
            echo $_ppid >> $cgroup
        done

        # systemd uses the unified cgroup-v2. If we keep it, "systemctl
        # daemon-reload" will trash our work and reset the v1 cgroups.
        unified=`mount | awk '$4=="type"&&$5=="cgroup2"{print $3}' | tail -n 1`
        jobdir=`awk -F: '$3~/\/job_/{print $3}' ${_savefile} | head -n 1 | tr / '\n' | grep ^job_`
        uiddir=`awk -F: '$3~/\/uid_/{print $3}' ${_savefile} | head -n 1 | tr / '\n' | grep ^uid_`
        if [[ -n "${unified}" && -d "${unified}" ]]; then
            mkdir -p "${unified}"/slurm/$uiddir/$jobdir
            echo $_ppid >> "${unified}"/slurm/$uiddir/$jobdir/cgroup.procs
        fi
        # without cgroup-v2, it uses the name=systemd to mess things up.
        systemdcg=`mount | awk '$4=="type"&&$5=="cgroup"&&$6~/\Wname=systemd\W/{print $3}'`
        if [[ -n "${systemdcg}" && -d "${systemdcg}" ]]; then
            # can't use the slurm service, as then can't restart
            # it. We'll make a slurm dir and hope systemd doesn't complain
            #tasks=`awk -F: '$2=="name=systemd"{printf "'"${systemdcg}"'/%s/tasks\n", $3}' ${_savefile}`
            #tasks=${systemdcg}/tasks
            mkdir -p "${systemdcg}"/slurm/$uiddir/$jobdir
            echo $_ppid >> "${systemdcg}"/slurm/$uiddir/$jobdir/tasks
        fi

        rm "${_savefile}"
    ;;

    slurm)
        if [[ ! -e ${_savefile} ]]; then
            exit 200
        fi

        # first lets restore
        for cgroup in `awk -F: '$2&&$3~/^\/slurm\//&&$2!~/name=systemd/ {printf "/sys/fs/cgroup/%s%s/tasks\n", $2, $3}' ${_savefile}`; do
            echo $_ppid >> $cgroup
        done

        # get some data
        unified=`mount | awk '$4=="type"&&$5=="cgroup2"{print $3}' | tail -n 1`
        jobdir=`awk -F: '$3~/\/job_/{print $3}' ${_savefile} | head -n 1 | tr / '\n' | grep ^job_`
        uiddir=`awk -F: '$3~/\/uid_/{print $3}' ${_savefile} | head -n 1 | tr / '\n' | grep ^uid_`

        # go over cgroups
        for cgroup in `awk -F: '{print $2}' ${_savefile}` ""; do

            # name=systemd isn't mounted on name=systemd...
            if echo $cgroup | grep -q name=; then
                cgroup=`echo $cgroup | sed -e 's/^name=//'`
            fi

            # get full path, special unified case
            current=`awk -F: '$2=="'${cgroup}'"{print $3}' ${_savefile}`
            if [[ -n "$cgroup" ]]; then
                fullcgroup=/sys/fs/cgroup/${cgroup}
            else
                fullcgroup=${unified}
                if [[ -z "${unified}" ]]; then
                    continue
                fi
            fi

            # update if something other than /slurm/ or /
            # and special unified case...
            case "${current}" in
                */slurm/*|/)
                ;;
                *)
                    if [[ -e "${fullcgroup}" ]]; then
                        path=/${fullcgroup}/slurm/$uiddir/$jobdir
                        mkdir -p $path
                        if [[ -e $path/cgroup.procs ]]; then
                            echo $_ppid >> $path/cgroup.procs
                        else
                            echo $_ppid >> $path/tasks
                        fi
                    fi
                ;;
            esac

        done

        if [[ "${PAM_TYPE}" = close_session || "x${delete_only_on_close}" = "x" ]]; then
            rm "${_savefile}"
        fi
    ;;
    *)
        echo "Unknown action \"${action}\"" 1>&2
        exit 2
esac

exit 0


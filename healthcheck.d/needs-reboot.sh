#!/bin/bash

set -u
set -e

node=`hostname`

slurmdir=`dirname \`scontrol show config | awk '$1=="SLURM_CONF" {print $3}'\``
. $slurmdir/cshuji/functions.bash

function reboot_reason {
    reason="$1"

    reason=`echo $reason | sed -e 's/ *\[[^ ]\+@[0-9T:-]\+\]$//'`

    # simple reboot reason
    if echo "$reason" | grep -q '^HC: needs reboot$'; then
        return 0
    fi

    # regex file
    if [[ -e $slurmdir/reboot-reasons ]]; then
        while read line; do
            if echo "$reason" | grep -qx "$line"; then
                return 0
            fi
        done < $slurmdir/reboot-reasons
    fi

    return 1
}

state="`slurm_node $node State`"
case "${state}" in
    *DRAIN*)
        reason="`slurm_node $node Reason`"
        if ! echo "$reason" | grep -q '@'; then
            exit 0;
        fi
        draintime=`echo $reason | sed -e 's/.*\[[^@]\+@//' -e 's/\]$//'`
        draintime=`date -d \`echo $draintime\` +%s`
        if reboot_reason "$reason"; then
            boottime=`awk '$1=="btime"{print $2}' /proc/stat`

            # if idle or down, check if before or after reboot
            if [[ "$state" = "IDLE+DRAIN" \
                      || "$state" = "RESERVED+DRAIN" \
                      || "$state" = "MAINT+DRAIN" \
                      || "$state" = "DOWN*+DRAIN" \
                      || "$state" = "IDLE+COMPLETING+DRAIN" \
                      || "$state" = "IDLE*+COMPLETING+DRAIN" \
                ]]; then
                # special case when stuck on completing, check for how long
                # it's like this, more than an hour - reboot
                if [[ "$state" = "IDLE+COMPLETING+DRAIN" || "$state" = "IDLE*+COMPLETING+DRAIN" ]]; then
                    endtime=`squeue -w "${node}" -h -Oendtime | sort | tail -n 1`
                    endtime=`date -d $endtime +%s`
                    lastcomp=$((`date +%s` - endtime))
                    if [[ $lastcomp -lt $((60 * 60)) ]]; then
                        echo 'needs reboot'
                        exit 1;
                    fi
                fi
                if [[ $draintime -lt $boottime ]]; then
                    # drain before reboot, can resume
                    exit 0
                else
                    # drain after reboot, can reboot
                    shutdown -r now 'slurm healthcheck reboot'
                    exit 1
                fi
            else
                # not idle, keep drained
                echo 'needs reboot'
                exit 1;
            fi
        fi
        exit 0;
        ;;
    *)
        exit 0;
        ;;
esac

exit 0

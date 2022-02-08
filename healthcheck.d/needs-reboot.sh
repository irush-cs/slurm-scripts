#!/bin/bash

set -u
set -e

node=`hostname`

slurmdir=`dirname \`scontrol show config | awk '$1=="SLURM_CONF" {print $3}'\``
. $slurmdir/cshuji/functions.bash

state="`slurm_node $node State`"
case "${state}" in
    *DRAIN*)
        reason="`slurm_node $node Reason`"
        if echo $reason | grep -q '^HC: needs reboot \['; then
            draintime=`echo $reason | sed -e 's/^HC: needs reboot \[[^@]*@//' -e 's/\]$//'`
            draintime=`date -d \`echo $draintime\` +%s`
            boottime=`awk '$1=="btime"{print $2}' /proc/stat`

            # if idle, check if before or after reboot
            if [[ "$state" = "IDLE+DRAIN" || "$state" = "RESERVED+DRAIN" || "$state" = "MAINT+DRAIN" ]]; then
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

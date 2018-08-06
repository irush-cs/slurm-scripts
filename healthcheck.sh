#!/bin/bash

################################################################################
#
#   healthcheck.sh
#
#   Copyright (C) 2018 Hebrew University of Jerusalem Israel, see
#   LICENSE file.
#
#   Author: Yair Yarom <irush@cs.huji.ac.il>
#
################################################################################

set -e
set -u

PATH=${PATH}:/etc/alternatives/slurm/bin
export PATH

slurmdir=`dirname \`scontrol show config | awk '$1=="SLURM_CONF" {print $3}'\``
hcdir="${slurmdir}/healthcheck.d"

node=`hostname`
cluster=`scontrol show config | awk -F= '$1~/ClusterName/{print $2}' | sed -e 's/ //g'`

clusterconf=
if [[ -e "${slurmdir}/${cluster}.conf" ]]; then
    clusterconf="${slurmdir}/${cluster}.conf"
elif [[ -e "`dirname ${slurmdir}`/${cluster}.conf" ]]; then
    clusterconf="`dirname ${slurmdir}`/${cluster}.conf"
fi

maintainers=root
if [[ -n "$clusterconf" && -e "${clusterconf}" ]]; then
    maintainers=`awk 'BEGIN{general=0} $1=="[general]"{general=1} general==1&&$1=="maintainers:"{print $2} $1!="[general]"&&$1~/\[/{general=0}' ${clusterconf}`
fi
if [[ -z "$maintainers" ]]; then
    maintainers=root
fi

time1=`date +%s`
out=`timeout -k 1 50s run-parts --exit-on-error --regex '[^~]$' ${hcdir} 2>/dev/null || true`
time2=`date +%s`
if [[ -z "$out" && $((time2 - time1)) -ge 50 ]]; then
    out="healthcheck timeout"
fi
if [[ -z "$out" && ! -d ${hcdir} ]]; then
    out="healthcheck.d is missing"
fi

state=`scontrol show node $node | tr ' ' '\n' | awk -F= '$1=="State" {print $2}'`
if [[ $? != 0 || -n "$out" ]]; then
    if [[ -z $out ]]; then
        out="health check program failed"
    fi
    case "$state" in
        *DRAIN*)
            # if drained, check if because of healthcheck, otherwise keep drained
            if [[ `scontrol show node $node | awk -F= '$1~/^\s*Reason/&&$2~/^HC: /{print "yes"}'` = "yes" ]]; then
                scontrol update nodename=$node state=drain reason="HC: $out"
            fi
            ;;
        *)
            # if not drained, drain it
            scontrol update nodename=$node state=drain reason="HC: $out"
            ;;
    esac

    # on startup, will run this until passes
    exit 1;
else
    case "$state" in
        *DRAIN*)
            reason=`scontrol show node $node | awk -F= '$1~/^\s*Reason/{print $2}'`
            if echo $reason | grep -q ^HC:\ ; then
                scontrol show node $node | mail -s "Resuming node $node" ${maintainers} > /dev/null 2>&1
                scontrol update nodename=$node state=resume
            fi
            ;;
    esac
fi

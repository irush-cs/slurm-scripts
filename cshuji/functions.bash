
################################################################################
#
#   cshuji/functions.bash
#
#   Copyright (C) 2018 Hebrew University of Jerusalem Israel, see
#   LICENSE file.
#
#   Author: Yair Yarom <irush@cs.huji.ac.il>
#
################################################################################

################################################################################
#
# To install, place in a cshuji directory where slurm.conf is in.
#
# To include in a script:
# slurmdir=`dirname \`scontrol show config | awk '$1=="SLURM_CONF" {print $3}'\``
# . $slurmdir/cshuji/functions.bash
#
# functions:
#   slurm_config <conf>
#   slurm_get_config
#   slurm_maintainers
################################################################################

################################################################################
# gets the config and stores in _slurm_config. Needs to be called if SLURM_CONF
# has changed.
################################################################################
declare -A _slurm_config
function slurm_get_config {
    #echo "**slurm_get_config**"
    declare -gA _slurm_config=()
    eval `scontrol show config | grep ' = ' | awk '{printf "_slurm_config[%s]=\"%s\"; ", $1, $3}'`
}

################################################################################
# show specific slurm config. Calls slurm_get_config if needed
################################################################################
function slurm_config {
    conf=${1:-}
    if [[ -z "${_slurm_config[*]}" ]]; then
        slurm_get_config
    fi

    if [[ -n "$conf" ]]; then
        echo ${_slurm_config[$conf]}
    fi
}

################################################################################
# returns a list of maintainers (from <cluster>.conf)
################################################################################
function slurm_maintainers {
    slurm_config
    slurmdir=`dirname \`slurm_config SLURM_CONF\``
    cluster=`slurm_config ClusterName`

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

    echo $maintainers
}

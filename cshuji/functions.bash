
################################################################################
#
#   cshuji/functions.bash
#
#   Copyright (C) 2018-2020 Hebrew University of Jerusalem Israel, see LICENSE
#   file.
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
#   slurm_get_node <node>
#   slurm_node <node> <key>
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

################################################################################
# gets a node data and stores in _slurm_nodes.
################################################################################
declare -A _slurm_nodes
function slurm_get_node {
    #echo "**slurm_get_node**"
    if [[ $# -lt 1 ]]; then
        node=`hostname`
    else
        node=$1
    fi
    scontrol show node $node > /dev/null 2>&1 || return

    # two calls to scontrol for multi simple values and multi-word values (OS and Reason)
    eval `scontrol show node $node | grep -v '^ *OS' | grep -v '^ *Reason' | sed -e 's/^ *//g' -e 's/ /\n/g' | grep -v '^$' | sed -e 's/=/ /' | awk '{printf "_slurm_nodes['$node',%s]=\"%s\"; ", $1, $2}'`

    eval `scontrol show node $node | grep -E '^ *(OS|Reason)=' | sed -e 's/^ *//g' -e 's/\\\\/\\\\\\\\/g' -e 's/"/\"/g' -e 's/=/]="/' -e 's/^/_slurm_nodes['$node,'/' -e 's/$/"/'`
}

################################################################################
# Returns specific node info. Calls slurm_get_node if needed. Requires two
# parameters: node and keys
# example: slurm_node node-001 State
################################################################################
function slurm_node {
    node=${1:-}
    key=${2:-}
    if [[ -z "$node" || -z "$key" ]]; then
        return
    fi
    declare -gA _slurm_nodes
    if [[ -z "${_slurm_nodes[$node,NodeName]:+isset}" ]]; then
        slurm_get_node $node
    fi

    if [[ -n "$key" ]]; then
        echo ${_slurm_nodes[$node,$key]}
    fi
}

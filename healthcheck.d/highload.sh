#!/bin/bash

################################################################################
#
#   healthcheck.d/highload.sh
#
#   Copyright (C) 2020 Hebrew University of Jerusalem Israel, see LICENSE file.
#
#   Author: Yair Yarom <irush@cs.huji.ac.il>
#
################################################################################


load=`cut -d' ' -f2 /proc/loadavg | cut -d. -f1`
cpus=`cat /proc/cpuinfo | awk '$1=="processor"' | wc -l`
if [[ $load -gt $((10 * cpus)) ]]; then
    echo "High load: $load on $cpus CPUs"
    exit 1
fi

exit 0

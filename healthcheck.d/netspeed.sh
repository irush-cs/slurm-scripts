#!/bin/bash

################################################################################
#
#   healthcheck.d/netspeed.sh
#
#   Copyright (C) 2018-2020 Hebrew University of Jerusalem Israel, see LICENSE
#   file.
#
#   Author: Yair Yarom <irush@cs.huji.ac.il>
#
################################################################################

eth=`route -4 | awk '$1=="default"{print $NF}' | head -n 1`
speed=`ethtool $eth | awk '$1=="Speed:" {print $2}'`
speed2=`echo $speed | grep -E -o '[[:digit:]]*'`

if [[ "$speed2" -lt 1000 ]]; then
    echo "network speed less than 1000Mb/s ($speed)"
    exit 1
fi

exit 0

#!/bin/bash
# (C) 2017 Operant Solar
# All rights reserved
#
# @author: Walter Coole <walter.coole@operantsolar.com>
#
devices=(SN402 SN404 SN405 SN406 SN407) # SN403
echo starting logging for: "${devices[*]}"
for device in ${devices[*]}
do
    make $device.log &
    pids[${#pids[*]}]=$!
done
make load
sleep 20
echo kill "${pids[*]}"
wait

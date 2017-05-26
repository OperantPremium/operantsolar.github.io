#!/bin/sh
# (C) 2017 Operant Solar
# All rights reserved
#
# @author: Walter Coole <walter.coole@operantsolar.com>
#
macAddresses=(56dd18 56dc4c 56ddb2 56ddc8 56ddde) # 56dd24
paths=('CyPoe3l9E5Od' 'oHMQMg_lcxsT' 'QGO7JQAzyiev' 'VifAbahCX8ux' 'hxsSiYETEEpd') # 'wXqOLIl3KiLB'
# Record lockup time
while true
do
    let moffset=$RANDOM%${#macAddresses[*]}
    let poffset=$RANDOM%${#paths[*]}
    date
    node ImpConnect.js deviceid=${macAddresses[$moffset]} path="/${paths[$poffset]}"
    sleep 20
done
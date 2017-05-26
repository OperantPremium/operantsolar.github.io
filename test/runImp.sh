#
# (C) 2017 Operant Solar
# All rights reserved
#
# @author: Rama Nadendla <rama.nadendla@operantsolar.com>

# Device ID hashes as reference for TARGET
#SN402 = D85F6461EB91
#SN403 = 018C268ECB5B
#SN404 = 2BF6EF3EFD90
#SN405 = 718A34D8423A
#SN406 = C5F6371C8A03
#SN407 = 4CA33E88EDAA
#SN506 (Blue) = C3B996B9F76C
#SN508 (Orange) = 730D72A6E22F
#SN509 (Green) = 16240A06C1FC
#SN513 (Black) = DF04146F1DF0
#SN514 (Yellow) = 00E329B56259
#SN515 = 4E44238D7110


# Agent URLs as reference for GATEWAY
#SN402 = /oHMQMg_lcxsT
#SN403 = /wXqOLIl3KiLB
#SN404 = /QGO7JQAzyiev
#SN405 = /CyPoe3l9E5Od
#SN406 = /hxsSiYETEEpd
#SN407 = /VifAbahCX8ux
#SN506 (Blue) = /oGQ_PBSAUppO
#SN508 (Orange) = /2866vQYBgUpC
#SN509 (Green) = /D1PRYwJmmHAi
#SN513 (Black) = /ZT8GBL-7RrgD
#SN514 (Yellow) = /609atPXTxkX7
#SN515 = /VRa-gimZfDGJ



# Target 404 Agent 406
node ImpConnect.js  usng="28475668" deviceIdHash="2BF6EF3EFD90"  rw="read" category="wiFi" task="scan" parameters="Operant"  gatewayURL='/oHMQMg_lcxsT' ;
#node ImpConnect.js  usng="28475668" deviceIdHash="2BF6EF3EFD90"  rw="read" category="modbus" task="fc03" parameters="01_00240002_9600_8_1"  gatewayURL='/CyPoe3l9E5Od' ;


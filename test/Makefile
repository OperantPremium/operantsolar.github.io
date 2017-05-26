.PHONY: test testB all_logs analysis load
devices := SN402 SN404 SN405 SN406 SN407 #  SN403
SRC := ../application
DST := ../dist
NDN := ../../ndn-squirrel
BASE := ../../operantBase/src

load: $(DST)/impAgent.nut $(DST)/impDevice.nut FORCE
	@imp push

test:
	node impConnect.js

testB:
	node impConnect.js deviceid=56ddc8 path="/CyPoe3l9E5Od"

$(DST)/impAgent.nut: $(BASE)/rockyHeader.nut $(NDN)/ndn-squirrel.nut $(NDN)/contrib/kisi-inc/aes-squirrel/aes.class.nut $(NDN)/contrib/vukicevic/crunch/crunch.nut $(BASE)/ImpUtilities.nut $(BASE)/applicationBase.nut $(SRC)/fleetLinkApp.nut $(BASE)/agentHandler.nut
	cat $^ > $@

$(DST)/impDevice.nut:$(NDN)/ndn-squirrel.nut $(NDN)/contrib/kisi-inc/aes-squirrel/aes.class.nut $(NDN)/contrib/vukicevic/crunch/crunch.nut $(NDN)/tools/micro-forwarder.nut $(BASE)/ImpUtilities.nut $(BASE)/LoRa.nut $(SRC)/modbus.nut $(BASE)/applicationBase.nut $(SRC)/fleetLinkApp.nut $(BASE)/deviceHandler.nut
	cat $^ > $@

%.log: FORCE
	imp log -t $(basename $@F) > ~/Google\ Drive/Operant\ Engineering/FleetLink/Network\ Test/Network\ Monitor\ Logs/$(basename $@F)_$(shell date +"%Y:%m:%d:%H:%M").log

FORCE:

all_logs:
	./multilog.sh

analysis:
	./analyze -s'$(shell date -j -v-1H +"%Y/%m/%d %H:%M:%S")' -f'$(shell date -j +"%Y/%m/%d %H:%M:%S")' $(foreach dev, $(devices), "$(shell ls ~/Google\ Drive/Operant\ Engineering/FleetLink/Network\ Test/Network\ Monitor\ Logs/$(dev)* | tail -1)" ) >~/Google\ Drive/Operant\ Engineering/FleetLink/Network\ Test/Network\ Monitor\ Analysis/analysis$(shell date +"%Y:%m:%d:%H:%M").csv
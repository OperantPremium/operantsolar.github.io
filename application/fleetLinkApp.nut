/**                                                                            
 * (C) 2017 Operant Solar
 * All rights reserved
 *
 * @author: Rama Nadendla <rama.nadendla@operantsolar.com>
 * 
 */

/* fleetLinkApplication
 * The purpose of this class is to handle the request body, parse it
 * and generate a NDN Name from the body. Handles the interests of this
 * Application, and returns the results for the supported names.
 */
class impApplication extends applicationBase {
    _usng = 28475668;

    /*
    * Base method override to provide the Agent the wait time after which it would return an error
    */
    function getInterestLifetime() {
        return 12000;
    }

    function getNamePrefix()
    {
        return "/FL/" + _usng + "/" + getDeviceIdHash("operant", "fleetLink", hardware.getdeviceid());
    }    

    /*
     * private method to add the NDN names that this application supports
     * Build Name: FL|usng|deviceIdHash|rw|category|function|parameters
     */
    function addSupportedNames() {
        local nameColl = getSupportedNames();
        local name = "";

        // fleetLink internal commands
        local deviceId = getDeviceIdHash("operant", "fleetLink", hardware.getdeviceid());
 
        name = getNameforPath("FL|28475668|" + deviceId + "|read|wiFi|scan");
        nameColl.append(name);
        
        name = getNameforPath("FL|28475668|" + deviceId + "|read|modbus|fc03");
        nameColl.append(name);

        // SunSpec commands
        deviceId = getDeviceIdHash("MeasurLogic", "DTS SKT2-92-NN-SM-N-2S-200", "DSKT201505001");
        name = getNameforPath("FL|28475668|" + deviceId + "|read|power|MC_AC_Power_A");
        nameColl.append(name);
    }

    function nameMatchesSupportedNames(name) {
        local nameColl = getSupportedNames();
        for(local i = 0; i < nameColl.len(); i++) {
            if (nameColl[i].match(name)) return true;
        }
        return false;
    }

    /*
     * Base method override that handles the incoming interest and returns the result of handling the interest
     */
    function handleInterest (interest) {
        local result = "";
        local name = interest.getName();

        //get the names that are registered.. we are not registering, but using them to
        //compare the name associated with the interest..
        local nameColl = getSupportedNames();
        if (nameColl.len() == 0) {
            addSupportedNames();
        }
        for(local i =0; i < nameColl.len(); i++) {
	    if (debugEnable) consoleLog("<DBUG>matching name " + nameColl[i] + " </DBUG>");
            // if we have a matching name
            if (nameColl[i].match(name)) {                
                //check to see if it is read or write
                if (name.get(nameComponentIndex.rw).toEscapedString() == "read") {
                    if (name.get(nameComponentIndex.category).toEscapedString() == "wiFi") {
                        result = scanWiFi(name.get(nameComponentIndex.task).toEscapedString(), name.get(nameComponentIndex.parameters).getValue().toRawStr());
                        break;
                    }
                    if (name.get(nameComponentIndex.category).toEscapedString() == "modbus") {
                        result = getmodbus(name.get(nameComponentIndex.task).toEscapedString(), name.get(nameComponentIndex.parameters).toEscapedString());
                        break;
                    }
                }
                
                else if (name.get(5).toEscapedString() == "write") {
                    if (name.get(3).toEscapedString() == "wiFi") {
                        //add code for writing something to WIFI
                        break;
                    }
                }
            }          
        }
        if (debugEnable) consoleLog("<DBUG> handleInterest result: " + result + "</DBUG>");
        return result;
    }

    /*
     * private method to handle the interest coming in the args. Appropriate
     * result associated with the args are returned if the contents of the
     * args match the supported entries.
     */
    function getmodbus(task, parameters) {
        local modbusCmd = getModbusCmd(task, parameters); // interest.getName().get(impNameElements.ModbusCmd).toEscapedString(); 
        if (debugEnable) consoleLog("<DBUG> Sending modbus cmd: " + modbusCmd + " </DBUG>");

        // Extract the Baud Rate from the parameters field and set Modbus driver accordingly
        // TODO: change Modbus constructor to take data and stop bits in similar fashion to Baud rate <<<<<<<<
        local requestedBaudRate = getModbusBaudRate(parameters);
        
        local modb = Modbus(requestedBaudRate);
        modb.writeCommand(modbusCmd);
        return modb.readResult();
    }

    // Construct the Modbus command form both Function and Parameters as required by standard
    function getModbusCmd (task, parameters) {
        local paramArray = split(parameters, "_");
        local modbusCmd = "";
        local i = 0;
        if (paramArray.len() >= 2) {
            modbusCmd += paramArray[0];
            modbusCmd += task.slice(2);
            modbusCmd += paramArray[1];
        }
        return modbusCmd;
    }

    // The requested Baud rate is the third component in the parameters field
    // Return as Integer
    function getModbusBaudRate (parameters) {
        local paramArray = split(parameters, "_");
        local modbusBaudRate = paramArray[2].tointeger();
        return modbusBaudRate;
    }

    /*
     * private method to handle the interest coming in the args. Appropriate
     * result associated with the args are returned if the contents of the
     * args match the supported entries.
     */
    function scanWiFi(task, parameters) {
        if (debugEnable) consoleLog("<DBUG>in getwifi, parameters = " + parameters + " </DBUG>")
        local requestedData = "";
        local wlans = imp.scanwifinetworks();
        local i = 1;
        
        if(task == "scan") {
            // If possible return only the specified network's SSID, RSSI. and channel 
            foreach (hotspot in wlans) {
                if(hotspot.ssid == parameters){
                    requestedData = hotspot.ssid;
                    requestedData += "|RSSI";
                    requestedData += format("%i", hotspot.rssi);
                    requestedData += "|Ch";
                    requestedData += hotspot.channel;
                }
            } 
            
            // If not specified or not found, return the SSID, RSSI. and channel for a random network
            if(requestedData == "") {     
                // Choose a network at random
                local numberNetworksFound = wlans.len();
                local networkIndex = (1.0 * math.rand() / RAND_MAX) * numberNetworksFound;
                networkIndex = networkIndex.tointeger();
                // if (debugEnable) consoleLog("<DBUG>Network " +  networkIndex + " chosen of " + numberNetworksFound + " found </DBUG>");
                requestedData = wlans[networkIndex].ssid;
                requestedData += "|RSSI";
                requestedData += format("%i", wlans[networkIndex].rssi);
                requestedData += "|Ch";
                requestedData += wlans[networkIndex].channel;
                requestedData += "|";
                requestedData += networkIndex + "of" + numberNetworksFound;
            }
        }

        return requestedData;
    } 
}

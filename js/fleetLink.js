// FleetLink Mobirise Javascript 
//Randy King 5/25/2017
// default Interest with reasonable values

var gateway = "SN517";
var target = "SN528";
var sunSpecReg = 0; // as a decimal number, like SunSpec standards
var sunSpecLength = 1; // as a decimal number, like SunSpec standards
var wiFiSSID = "";
var mapFleetLink;
var nodePath =  null;


var fleetLink = { 
    //dev
    "SN402":{"network":"dev", "locName":"Shirlie", "deviceIdHash":"D85F6461EB91", "deviceID":"5000d8c46a56dc4c", "usng":"21016306", "latitude":38.5157472, "longitude":-122.7589444, "agentUrl": "/oHMQMg_lcxsT", "baseAddress":49999, "modbusAddress": 100, "marker": null, "online":false},
 //   "SN403":{"network":"dev", "locName":"Sugiyama Outside", "deviceIdHash":"2BF6EF3EFD90", "deviceID":"5000d8c46a56ddc8", "usng":"21236282", "latitude":38.5134, "longitude":-122.75655, "agentUrl": "/wXqOLIl3KiLB", "baseAddress":49999, "modbusAddress": 100, "marker": null, "online":false},
    "SN404":{"network":"dev", "locName":"Kiva", "deviceIdHash":"018C268ECB5B", "deviceID":"5000d8c46a56dd24", "usng":"20916258", "latitude":38.5113556, "longitude":-122.7601444, "agentUrl": "/QGO7JQAzyiev", "baseAddress":49999, "modbusAddress": 100, "marker": null, "online":false},
    "SN405":{"network":"dev", "locName":"Gibson", "deviceIdHash":"718A34D8423A", "deviceID":"5000d8c46a56ddb2", "usng":"21426258", "latitude":38.5113889, "longitude":-122.7542667, "agentUrl": "/CyPoe3l9E5Od", "baseAddress":49999, "modbusAddress": 100, "marker": null, "online":false},
    "SN406":{"network":"dev", "locName":"Beckman", "deviceIdHash":"C5F6371C8A03", "deviceID":"5000d8c46a56dd18", "usng":"21896255", "latitude":38.5110833, "longitude":-122.7488806, "agentUrl": "/hxsSiYETEEpd", "baseAddress":49999, "modbusAddress": 100, "marker": null, "online":false},
    "SN407":{"network":"dev", "locName":"Sugiyama Inside", "deviceIdHash":"4CA33E88EDAA", "deviceID":"5000d8c46a56ddde", "usng":"21226282", "latitude":38.5135, "longitude":-122.75653, "agentUrl": "/VifAbahCX8ux", "baseAddress":49999, "modbusAddress": 100, "marker": null, "online":false},
    //vivint
    "SN506":{"network":"vivint", "locName":"Vivint 1", "deviceIdHash":"C3B996B9F76C", "deviceID":"5000d8c46a572880", "usng":"15795063", "latitude":38.4038333, "longitude":-122.8190833, "agentUrl": "/oGQ_PBSAUppO", "baseAddress":39999, "modbusAddress": 1, "marker": null, "online":false},
    "SN511":{"network":"vivint", "locName":"Vivint 2 ", "deviceIdHash":"C1B16ADC8E57", "deviceID":"5000d8c46a5728f6", "usng":"15815066", "latitude":38.4041111, "longitude":-122.8189167, "agentUrl": "/4R2NSeUUtys8", "baseAddress":39999, "modbusAddress": 1, "marker": null, "online":false},
    "SN513":{"network":"vivint", "locName":"SolarEdge Inverter", "deviceIdHash":"DF04146F1DF0", "deviceID":"5000d8c46a57285e", "usng":"15795070", "latitude":38.40443, "longitude":-122.8190967, "agentUrl": "/ZT8GBL-7RrgD", "baseAddress":39999, "modbusAddress": 1, "marker": null, "online":false},
    "SN514":{"network":"vivint", "locName":"Vivint 3", "deviceIdHash":"00E329B56259", "deviceID":"5000d8c46a572872", "usng":"15705066", "latitude":38.4040556, "longitude":-122.8201667, "agentUrl": "/609atPXTxkX7", "baseAddress":39999, "modbusAddress": 1, "marker": null, "online":false},
    // larkfield
    //
    //"SN503":{"network":"larkfield", "locName":"Shirlie", "deviceIdHash":"4E562573DBA0", "deviceID":"5000d8c46a572868", "usng":"21016306", "latitude":38.515786, "longitude":-122.759001, "agentUrl": "/tRNE2WbS2CGw", "baseAddress":0, "modbusAddress": 1, "marker": null, "online":false},
    //"SN512":{"network":"larkfield", "locName":"Beckman", "deviceIdHash":"6917511534FD", "deviceID":"5000d8c46a5721ea", "usng":"21886253", "latitude":38.510951, "longitude": -122.748958, "agentUrl": "/kRQMPFuKmzDM", "baseAddress":0, "modbusAddress": 1, "marker": null, "online":false},
    "SN508":{"network":"larkfield", "locName":"Foster", "deviceIdHash":"730D72A6E22F", "deviceID":"5000d8c46a572874", "usng":"17776661", "latitude":38.547754, "longitude":-122.796043, "agentUrl": "/2866vQYBgUpC", "baseAddress":0, "modbusAddress": 1, "marker": null, "online":true},
    "SN517":{"network":"larkfield", "locName":"Sugiyama", "deviceIdHash":"73210C7C7368", "deviceID":"5000d8c46a572a40", "usng":"21226281", "latitude":38.513469, "longitude":-122.756491, "agentUrl": "/lfonbmovX8Ak", "baseAddress":0, "modbusAddress": 1, "marker": null, "online":true},
    "SN522":{"network":"larkfield", "locName":"Van Grouw", "deviceIdHash":"9CBABDD00BD5", "deviceID":"5000d8c46a572a68", "usng":"17286817", "latitude":38.561889, "longitude":-122.801555, "agentUrl": "/QCxFKECTRdBH", "baseAddress":0, "modbusAddress": 1, "marker": null, "online":true},
    "SN523":{"network":"larkfield", "locName":"Buffo", "deviceIdHash":"BB2A0BFDC8FC", "deviceID":"5000d8c46a5729e6", "usng":"16386739", "latitude":38.554853, "longitude":-122.811906, "agentUrl": "/jYthi-aNvlv6", "baseAddress":0, "modbusAddress": 1, "marker": null, "online":true},
    "SN524":{"network":"larkfield", "locName":"Yamasaki", "deviceIdHash":"022676CEA2C8", "deviceID":"5000d8c46a572a70", "usng":"16426752", "latitude":38.555988, "longitude":-122.811517, "agentUrl": "/NTLnl40ofe9Y", "baseAddress":0, "modbusAddress": 1, "marker": null, "online":true},
    "SN527":{"network":"larkfield", "locName":"Galli", "deviceIdHash":"E18F79FBF4D0", "deviceID":"5000d8c46a572a38", "usng":"18166731", "latitude":38.554040, "longitude":-122.791538, "agentUrl": "/t02E8X0S0Kl6", "baseAddress":0, "modbusAddress": 1, "marker": null, "online":true},
    "SN528":{"network":"larkfield", "locName":"Gibson", "deviceIdHash":"F5ED514678B2", "deviceID":"5000d8c46a572a58", "usng":"21416258", "latitude":38.511400, "longitude":-122.754315, "agentUrl": "/aQTyLRwIHjYn", "baseAddress":0, "modbusAddress": 1, "marker": null, "online":true},
    "SN530":{"network":"larkfield", "locName":"Nadendla", "deviceIdHash":"2EB55A0B48F4", "deviceID":"5000d8c46a572a12", "usng":"17616705", "latitude":38.551712, "longitude":-122.79779, "agentUrl": "/r7-wVnF8nV9b", "baseAddress":0, "modbusAddress": 1, "marker": null, "online":true},
    "SN531":{"network":"larkfield", "locName":"Ferrara", "deviceIdHash":"A9D4A224043D", "deviceID":"5000d8c46a572a4c", "usng":"21246285", "latitude":38.513862, "longitude":-122.756289, "agentUrl": "/lgWdhq_T9EsC", "baseAddress":0, "modbusAddress": 1, "marker": null, "online":true}
    //
    //
};

var interest = {
    'usng': fleetLink[target].usng,
    'deviceIdHash' : fleetLink[target].deviceIdHash,
    'rw': 'read',
    'category': 'modbus',
    'task': 'fc03',
    'parameters': decimalToHex(fleetLink[target].modbusAddress, 2) + '_' + decimalToHex(fleetLink[target].baseAddress + sunSpecReg, 4) + decimalToHex(sunSpecLength, 4) + '_9600_8_1',
    'url' : "https://agent.electricimp.com" + fleetLink[gateway].agentUrl
}

var displayFactors = {
    // the following parameters are used to pretty up data returns, particularly from modbus
    'firstDataChar' : 6, // position of the FIRST data character in whatever the interest returns (0 based)
    'lastDataChar' : 9,  // position of the LAST data character in whatever the interest returns (0 based)
    'dataFormat' : 'hex', // defines format of returned data (can be hex | dec | ascii | string)
    'scaleFactor' : 0.529, // Scale numeric data when necessary
    'offsetFactor' : 0, // similarly apply any numeric offset
    'unitString' : "W/m^2", // append units string to communicate result better
    'displayName' : "Irradiance" // nice human readble display name for user
}


    // Choose target unit
    function setTarget(requestedTarget) {
        //console.log("Target= " + requestedTarget)
        target = requestedTarget;
        interest.deviceIdHash = fleetLink[target].deviceIdHash;
        interest.usng = fleetLink[target].usng;
        updateParamTable(target,interest,displayFactors,gateway);
        reDrawMap();     
        
        if (fleetLink[target].network == "larkfield"){
            document.getElementById("inverterCommands").style.visibility = 'hidden'; // hide inverter commands
            document.getElementById("meterCommands").style.visibility = 'visible'; // reveal meter commands
        } else if (fleetLink[target].network == "vivint"){
            document.getElementById("inverterCommands").style.visibility = 'visible'; // reveal inverter commands
            document.getElementById("meterCommands").style.visibility = 'hidden'; // hide meter commands
        } else {
            document.getElementById("inverterCommands").style.visibility = 'visible'; // reveal inverter commands
            document.getElementById("meterCommands").style.visibility = 'visible'; // reveal meter commands
        }
    }

    // Choose gateway unit
    function setGateway(requestedGateway) {
    //console.log("Gateway= " + requestedGateway)
    gateway = requestedGateway;
    interest.url = "https://agent.electricimp.com" + fleetLink[gateway].agentUrl
    updateParamTable(target,interest,displayFactors,gateway);
    reDrawMap();    
    }

    // Change network
    function changeNetwork(rb){
        if(rb.value == "vivint"){ 
            setTarget('SN513');
            setGateway('SN513');      
            readSunSpec('Mn');  
        } else if (rb.value == "larkfield"){
            setTarget('SN523');
            setGateway('SN523');    
            readSunSpec('Mn');  
        } else {
            setTarget('SN402');
            setGateway('SN402');        
            readSunSpec('Mn');  
        }
    }

    // Set Development Mode
    function setDevMode(cb){
        if (cb.checked != true){
            document.getElementById("serviceMenu").style.visibility = 'hidden';
            document.getElementById("devRadio").style.visibility = 'hidden';
            document.getElementById("sunSpecModels").style.visibility = 'hidden';
        } else {
            document.getElementById("serviceMenu").style.visibility = 'visible';
            document.getElementById("devRadio").style.visibility = 'visible';      
            document.getElementById("sunSpecModels").style.visibility = 'visible';
             
        }
    }

//================================================================================
// MAPPING 
//================================================================================

function initMap() {
    var locations = [];
    var iconColor = "white";
    var iconScale = 4;
    var iconType = "CIRCLE";
    //var infowindow = new google.maps.InfoWindow();
    var bounds = new google.maps.LatLngBounds();
    var myLatLng = {lat: 38.491, lng: -122.717};

    
    // Draw default map
        mapFleetLink = new google.maps.Map(document.getElementById('map'), {
        zoom: 1,
        mapTypeId: google.maps.MapTypeId.SATELLITE,
        center: myLatLng
        });

        
    for (var key in fleetLink) {
        if (fleetLink.hasOwnProperty(key)) {
            // if this unit is a member of the network which includes the target unit, then add to list to plot
            if (fleetLink[key]["network"] == fleetLink[target]["network"] ){
                if (key == target){ 
                    if(key == gateway){
                        icon =  {path: google.maps.SymbolPath["CIRCLE"], strokeColor: "#ff6600", strokeWeight: 2, scale: 7, fillColor: '#ff0066', fillOpacity: 0.3};
                    } else {
                        icon =  {path: google.maps.SymbolPath["CIRCLE"], strokeColor: "gold", strokeWeight: 2, scale: 7, fillColor: 'gold', fillOpacity: 0.3};
                    }
                }
                else if (key == gateway && key != target){
                    icon =  {path: google.maps.SymbolPath["CIRCLE"], strokeColor: "#ff0066", strokeWeight: 2, scale: 7, fillColor: '#ff0066', fillOpacity: 0.3};
                } 
                else {
                    icon =  {path: google.maps.SymbolPath["CIRCLE"], strokeColor: "#0099cc", strokeWeight: 2, scale: 7, fillColor: '#0099cc', fillOpacity: 0.3};
                }
                marker = new google.maps.Marker({
                    position: new google.maps.LatLng(fleetLink[key]["latitude"], fleetLink[key]["longitude"]),
                    icon: icon,
                    map: mapFleetLink
                });
                bounds.extend(marker.position);
                fleetLink[key]["marker"] = marker;

                /*
                google.maps.event.addListener(marker, 'click', (function (marker, i) {
                    return function () {
                        setGateway(locations[i][0]);
                        console.log(locations[i][0]);
                    }
                })(marker, i));
                */
            }
        }
    }

    mapFleetLink.fitBounds(bounds);

    var listener = google.maps.event.addListener(mapFleetLink, "idle", function () {
        google.maps.event.removeListener(listener);
    });

}


function reDrawMap(){
    // remove any node paths
    if (nodePath != null){
        nodePath.setMap(null);
    }
    // redraw the icons to match the targets andgateways
    for (var key in fleetLink) {
        if (fleetLink.hasOwnProperty(key)) {
            // if this unit is a member of the network which includes the target unit, then add to list to plot
            if (fleetLink[key]["network"] == fleetLink[target]["network"] ){
                if (key == target){ 
                    if(key == gateway){
                        icon =  {path: google.maps.SymbolPath["CIRCLE"], strokeColor: "#ff6600", strokeWeight: 3, scale: 7, fillColor: '#ff0066', fillOpacity: 0.3};
                    } else {
                        icon =  {path: google.maps.SymbolPath["CIRCLE"], strokeColor: "gold", strokeWeight: 3, scale: 7, fillColor: 'gold', fillOpacity: 0.3};
                    }
                }
                else if (key == gateway && key != target){
                    icon =  {path: google.maps.SymbolPath["CIRCLE"], strokeColor: "#ff0066", strokeWeight: 3, scale: 7, fillColor: '#ff0066', fillOpacity: 0.3};
                } 
                else {
                    icon =  {path: google.maps.SymbolPath["CIRCLE"], strokeColor: "#0099cc", strokeWeight: 3, scale: 7, fillColor: '#0099cc', fillOpacity: 0.3};
                }
                fleetLink[key]["marker"].setIcon(icon) ;        
            }
        }
    }
}


function drawNodePath(unitId1,unitId2){
    var nodePlanCoordinates = [
              {lat: fleetLink[unitId1].latitude, lng: fleetLink[unitId1].longitude},
              {lat: fleetLink[unitId2].latitude, lng: fleetLink[unitId2].longitude}
            ];
    nodePath = new google.maps.Polyline({
              path: nodePlanCoordinates,
              geodesic: true,
              strokeColor: '#00ff00',
              strokeOpacity: 1.0,
              strokeWeight: 4
            });
    nodePath.setMap(mapFleetLink);
    }



// Format the data for pretty display
function formatData(rawData, interest){
    var returnDataString = "";

    // remove any leading or trailing numbers (esp Modbus)    
    var cleanData = rawData.substring(displayFactors.firstDataChar, displayFactors.lastDataChar + 1);
    // convert to decimal if hex
    switch(displayFactors.dataFormat){
        case 'hex':
            var numericData = 0;
            numericData = parseInt(cleanData, 16); 
            if (cleanData != 'FFFF' && cleanData != '8000'){ 
                numericData = numericData * displayFactors.scaleFactor + displayFactors.offsetFactor;
                // Add units string at end of data, display two decimal places
                returnDataString = numericData.toFixed(2) + " " + displayFactors.unitString;                
            }
            else {
                returnDataString = "Not Available";
            }
            // apply scale factor and offset

        break;
        case 'ascii':
            var asciiCode = 0;
            for (i = 0; i < cleanData.length; i+=2) { 
                asciiCode = parseInt(cleanData.substring(i,i+2), 16);
                returnDataString += String.fromCharCode(asciiCode);
            }
        break;
        case 'binary':
            returnDataString = cleanData;
        break;

        default:
            returnDataString = rawData;
        }

return returnDataString
}



function updateParamTable(target, interest, displayFactors, gatewayID){
    var x = document.getElementById("paramTable").rows[0].cells;
    x[0].innerHTML = displayFactors.displayName;    
    x[2].innerHTML = "";
    x[2].style.backgroundColor = null;  
}



function redrawGoButton(){
    document.getElementById("goButton").style.visibility = 'visible';
}


// read the web UI to determine the unit that is being targeted
function expressInterest(buttonID) {
    var x = document.getElementById("paramTable").rows[0].cells;
// Trap the special case of write the geolocation to a unit, which uses fixed predefined geolocation in the Interest
// Until you write a unit's geolocation into flash, you wouldn;t know what usng to use to address it, otherwise
var tempUSNG = interest.usng; // First save the unit's expected geolocation temporarily (will put back after Express Interest below)
if (interest.rw == 'write'&& interest.category == 'flash' && interest.task == 'geoSelf'){
    interest.usng = '45898592'; // predefined geolocation used for writing actual geolocation to flash
}

    console.log(interest);

    updateParamTable(target,interest,displayFactors,gateway);    
    reDrawMap();

    var waitResultDisplay = "";
    if (target == gateway){
        waitResultDisplay = "Direct WiFi..."
        x[2].innerHTML = waitResultDisplay;
        buttonID.style.background='#1474BF';
    } 
    else  {
        waitResultDisplay = "Accessing LoRa Mesh..."
        x[2].innerHTML = waitResultDisplay;
        buttonID.style.background='#9999ff';
    }
    document.getElementById("goButton").style.visibility = 'hidden';

    // actual web POST
    $.ajax({
        url: interest.url,
        timeout: 15000,
        data: JSON.stringify(interest), // convert interest string to JSON
        type: 'POST',
            success : function(response) {
                var successDisplay = formatData(response, interest);
                x[2].style.background = '#1474BF';
                x[2].innerHTML = successDisplay;
                setTimeout(redrawGoButton, 3000, buttonID);
                drawNodePath(gateway,target);
            },
            error : function(jqXHR, textStatus, err) {
                var errorResponse = err ;
                console.log(errorResponse);
                x[2].innerHTML = errorResponse;
                document.getElementById("goButton").style.visibility = 'hidden';
                setTimeout(redrawGoButton, 3000, buttonID);
            }
        
    });
    interest.usng = tempUSNG ; // Return the unit's expected geolocation 
    buttonID.innerHTML = "GO";
    buttonID.style.background='#90A878';
}


function autoOnlines() {
    for (var key in fleetLink) {
        if (fleetLink.hasOwnProperty(key)) {
            // if this unit is a member of the network which includes the target unit, then add to list to plot
            if (fleetLink[key]["network"] == fleetLink[target]["network"] ){
                if(fleetLink[key]["online"] == true){
                    setGateway(key);
                    setTarget(key);
                    // actual web POST direct to unit
                 $.ajax({
                        url: interest.url,
                        context:{requestedTargetKey:key},
                        timeout: 15000,
                        data: JSON.stringify(interest), // convert interest string to JSON
                        type: 'POST',
                            success : function(response) {
                                console.log(this.requestedTargetKey);
                                console.log(formatData(response, interest));
                            },
                            error : function(jqXHR, textStatus, err) {
                                var errorResponse = err ;
                                console.log(errorResponse);
                            }
                    });
                }
            }
        }
    }
}

//================================================================================
// COMMAND LANGUAGE
//================================================================================

// Set a specific unit's geolocation
function writeGeoSelf(){
    geoSelf = prompt("Desired GeoLocation to Write?", "21706200");
    interest.rw = 'write';
    interest.category = 'flash';
    interest.task = 'geoSelf';
    interest.parameters = geoSelf;
    displayFactors.dataFormat = 'string';
    displayFactors.displayName = "Set Geolocation to " + interest.parameters;
    updateParamTable(target,interest,displayFactors,gateway);
}

// Read a specific unit's geolocation
function readGeoSelf(){
    interest.rw = 'read';
    interest.category = 'flash';
    interest.task = 'geoSelf';
    interest.parameters = "";
    displayFactors.dataFormat = 'string';
    displayFactors.displayName = "Read Geolocation" + interest.parameters;
    updateParamTable(target,interest,displayFactors,gateway);
}

// Scan the WiFi environment, optionally choose the SSID of the network to scane
function scanWiFi(){
    wiFiSSID = prompt("Desired SSID?", "Operant");
    interest.rw = 'read';
    interest.category = 'wiFi';
    interest.task = 'scan';
    interest.parameters = wiFiSSID;
    displayFactors.dataFormat = 'string';
    displayFactors.displayName = "Scan WiFi for SSID " + interest.parameters;
    updateParamTable(target,interest,displayFactors,gateway);

}

// Read the Modbus,must know detailed Modbus command
function readModbus(){
    modbusCommand = prompt("Modbus Read Command?", "01_00000001_9600_8_1");
    interest.rw = 'read';
    interest.category = 'modbus';
    interest.task = 'fc03';
    interest.parameters = modbusCommand;
    displayFactors.dataFormat = 'string';
    displayFactors.displayName = "Read Modbus: " + interest.parameters;
    updateParamTable(target,interest,displayFactors,gateway);
 
}

//================================================================================
// SUNSPEC LANGUAGE
//================================================================================
function readSunSpec(sunSpecName){

    switch(sunSpecName) {
    //================================================================================
    // METER COMMON
    //================================================================================
        case "Mn":
            sunSpecReg = 5;
            sunSpecLength = 16;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 37;
            displayFactors.dataFormat = 'ascii';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Manufacturer";
            break;
        case "Md":
            sunSpecReg = 21;
            sunSpecLength = 16;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 37;
            displayFactors.dataFormat = 'ascii';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Model";
            break;
        case "Opt":
            sunSpecReg = 37;
            sunSpecLength = 8;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 21;
            displayFactors.dataFormat = 'ascii';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Option";
            break;    
        case "Vr":
            sunSpecReg = 45;
            sunSpecLength = 8;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 21;
            displayFactors.dataFormat = 'ascii';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Version";
            break;    
        case "SN":
            sunSpecReg = 53;
            sunSpecLength = 16;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 37;
            displayFactors.dataFormat = 'ascii';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Serial Number";
            break;    
        case "DA":
            sunSpecReg = 69;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Device Address";
            break;  

    //================================================================================
    // METER COMMANDS BELOW
    //================================================================================            
    //================================================================================
    // METER CURRENT
    //================================================================================
        case "M_AC_Current":
            sunSpecReg = 69 + 3;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "AC Current (sum of active phases)";
            break;
        case "M_AC_Current_A":
            sunSpecReg = 69 + 4;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "Phase A AC Current";
            break;
        case "M_AC_Current_B":
            sunSpecReg = 69 + 5;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "Phase B AC Current";
            break;            
        case "M_AC_Current_C":
            sunSpecReg = 69 + 6;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "Phase C AC Current";
            break;                
    //================================================================================
    // METER VOLTAGE
    //================================================================================
    // LINE TO NEUTRAL
    //================================================================================        
        case "M_AC_Voltage_LN":
            sunSpecReg = 69 + 8;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Line to Neutral AC Voltage (average of active phases)";
            break;
        case "M_AC_Voltage_AN":
            sunSpecReg = 69 + 9;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Phase A to Neutral AC Voltage";
            break;
        case "M_AC_Voltage_BN":
            sunSpecReg = 69 + 10;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Phase B to Neutral AC Voltage";
            break;                        
        case "M_AC_Voltage_CN":
            sunSpecReg = 69 + 11;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Phase C to Neutral AC Voltage";
            break;
//================================================================================
// VOLTAGE
//================================================================================
// LINE TO LINE
//================================================================================               
        case "M_AC_Voltage_LL":
            sunSpecReg = 69 + 12;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Line to Line AC Voltage (average of active phases)";
            break;
        case "M_AC_Voltage_AB":
            sunSpecReg = 69 + 13;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Phase A to Phase B AC Voltage";
            break;
        case "M_AC_Voltage_BC":
            sunSpecReg = 69 + 14;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Phase B to Phase C AC Voltage";
            break;     
        case "M_AC_Voltage_CA":
            sunSpecReg = 69 + 15;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Phase C to Phase A AC Voltage";
            break;                                                         
    //================================================================================
    // METER FREQUENCY
    //================================================================================
        case "M_AC_Freq":
            sunSpecReg = 69 + 17;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Hz';
            displayFactors.displayName = "AC Frequency";
            break;
    //================================================================================
    // METER POWER
    //================================================================================
    // REAL
    //================================================================================             
        case "M_AC_Power":
            sunSpecReg = 69 + 19;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'W';
            displayFactors.displayName = "Total Real Power(sum of active phases)";
            break;
        case "M_AC_Power_A":
            sunSpecReg = 69 + 20;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'W';
            displayFactors.displayName = "Phase A AC Real Power";
            break;
        case "M_AC_Power_B":
            sunSpecReg = 69 + 21;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'W';
            displayFactors.displayName = "Phase B AC Real Power";
            break;
        case "M_AC_Power_C":
            sunSpecReg = 69 + 22;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'W';
            displayFactors.displayName = "Phase C AC Real Power";
            break;
    //================================================================================
    // METER POWER
    //================================================================================
    // APPARENT
    //================================================================================  
        case "M_AC_VA":
            sunSpecReg = 69 + 24;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VA';
            displayFactors.displayName = "Total AC Apparent Power(sum of active phases)";
            break;
        case "M_AC_VA_A":
            sunSpecReg = 69 + 25;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VA';
            displayFactors.displayName = "Phase A AC Apparent Power";
            break;
        case "M_AC_VA_B":
            sunSpecReg = 69 + 26;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VA';
            displayFactors.displayName = "Phase B AC Apparent Power";
            break;
        case "M_AC_VA_C":
            sunSpecReg = 69 + 27;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VA';
            displayFactors.displayName = "Phase C AC Apparent Power";
            break;
    //================================================================================
    // METER POWER
    //================================================================================
    // REACTIVE
    //================================================================================     
        case "M_AC_VAR":
            sunSpecReg = 69 + 29;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAR';
            displayFactors.displayName = "Total AC Reactive Power(sum of active phases)";
            break;
        case "M_AC_VAR_A":
            sunSpecReg = 69 + 30;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAR';
            displayFactors.displayName = "Phase A AC Reactive Power";
            break;
        case "M_AC_VAR_B":
            sunSpecReg = 69 + 31;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAR';
            displayFactors.displayName = "Phase B AC Reactive Power";
            break;
        case "M_AC_VAR_C":
            sunSpecReg = 69 + 32;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAR';
            displayFactors.displayName = "Phase C AC Reactive Power";
            break;
    //================================================================================
    // METER POWER FACTOR
    //================================================================================
        case "M_AC_PF":
            sunSpecReg = 69 + 34;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Average Power Factor(average of active phases)";
            break;
        case "M_AC_PF_A":
            sunSpecReg = 69 + 35;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Phase A Power Factor";
            break;
        case "M_AC_PF_B":
            sunSpecReg = 69 + 36;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Phase B Power Factor";
            break;
        case "M_AC_PF_C":
            sunSpecReg = 69 + 37;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Phase C Power Factor";
            break;
    //================================================================================
    // METER ACCUMULATED REAL ENERGY
    //================================================================================
    // EXPORTED
    //================================================================================ 
        case "M_Exported":
            sunSpecReg = 69 + 39;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Total Exported Real Energy";
            break;
        case "M_Exported_A":
            sunSpecReg = 69 + 41;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Phase A Exported Real Energy";
            break;
        case "M_Exported_B":
            sunSpecReg = 69 + 43;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Phase B Exported Real Energy";
            break;
        case "M_Exported_C":
            sunSpecReg = 69 + 45;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Phase C Exported Real Energyy";
            break; 
    //================================================================================
    // METER ACCUMULATED REAL ENERGY
    //================================================================================
    // IMPORTED
    //================================================================================     
        case "M_Imported":
            sunSpecReg = 69 + 47;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Total Imported Real Energy";
            break;
        case "M_Imported_A":
            sunSpecReg = 69 + 49;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Phase A Imported Real Energy";
            break;
        case "M_Imported_B":
            sunSpecReg = 69 + 51;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Phase B Imported Real Energy";
            break;
        case "M_Imported_C":
            sunSpecReg = 69 + 53;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Phase C Imported Real Energy";
            break;  
    //================================================================================
    // METER ACCUMULATED APPARENT ENERGY
    //================================================================================
    // EXPORTED
    //================================================================================      
        case "M_Exported_VA":
            sunSpecReg = 69 + 56;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Total Imported Real Energy";
            break;
        case "M_Exported_VA_A":
            sunSpecReg = 69 + 58;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Phase A Exported Apparent Energy";
            break;
        case "M_Exported_VA_B":
            sunSpecReg = 69 + 60;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Phase B Exported Apparent Energy";
            break;
        case "M_Exported_VA_C":
            sunSpecReg = 69 + 62;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Phase C Exported Apparent Energy";
            break;                                   
    //================================================================================
    // METER ACCUMULATED APPARENT ENERGY
    //================================================================================
    // IMPORTED
    //================================================================================      
        case "M_Imported_VA":
            sunSpecReg = 69 + 64;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Total Imported Apparent Energy";
            break;
        case "M_Imported_VA_A":
            sunSpecReg = 69 + 66;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Phase A Imported Apparent Energy";
            break;
        case "M_Imported_VA_B":
            sunSpecReg = 69 + 68;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Phase B Imported Apparent Energy";
            break;
        case "M_Imported_VA_C":
            sunSpecReg = 69 + 70;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Phase C Imported Apparent Energy";
            break; 

    //================================================================================
    // METER ACCUMULATED REACTIVE ENERGY
    //================================================================================
    // IMPORTED
    //================================================================================      
        case "M_Import_VARh_Q1":
            sunSpecReg = 69 + 73;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Quadrant 1: Total Imported Reactive Energyy";
            break;
        case "M_Import_VARh_Q1A":
            sunSpecReg = 69 + 75;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase A - Quadrant 1: Imported Reactive Energy";
            break;
        case "M_Import_VARh_Q1B":
            sunSpecReg = 69 + 77;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase B - Quadrant 1: Imported Reactive Energyy";
            break;
        case "M_Import_VARh_Q1C":
            sunSpecReg = 69 + 79;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase C - Quadrant 1: Imported Reactive Energy";
            break; 
        case "M_Import_VARh_Q2":
            sunSpecReg = 69 + 81;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Quadrant 2: Total Imported Reactive Energy";
            break;
        case "M_Import_VARh_Q2A":
            sunSpecReg = 69 + 83;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase A - Quadrant 2: Imported Reactive Energy";
            break;
        case "M_Import_VARh_Q2B":
            sunSpecReg = 69 + 85;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase B - Quadrant 2: Imported Reactive Energy";
            break;
        case "M_Import_VARh_Q2C":
            sunSpecReg = 69 + 87;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase C - Quadrant 2: Imported Reactive Energy";
            break;             
    //================================================================================
    // METER ACCUMULATED REACTIVE ENERGY
    //================================================================================
    // EXPORTED
    //================================================================================   
        case "M_Export_VARh_Q3":
            sunSpecReg = 69 + 89;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Quadrant 3: Total Exported Reactive Energy";
            break;
        case "M_Export_VARh_Q3A":
            sunSpecReg = 69 + 91;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase A - Quadrant 3: Exported Reactive Energy";
            break;
        case "M_Export_VARh_Q3B":
            sunSpecReg = 69 + 93;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase B - Quadrant 3: Exported Reactive Energy";
            break;
        case "M_Export_VARh_Q3C":
            sunSpecReg = 69 + 95;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase C - Quadrant 3: Exported Reactive Energy";
            break; 
            case "M_Export_VARh_Q4":
            sunSpecReg = 69 + 97;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Quadrant 4: Total Exported Reactive Energyy";
            break;
        case "M_Export_VARh_Q4A":
            sunSpecReg = 69 + 99;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase A - Quadrant 4: Exported Reactive Energy";
            break;
        case "M_Export_VARh_Q4B":
            sunSpecReg = 69 + 101;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase B - Quadrant 4: Exported Reactive Energy";
            break;
        case "M_Export_VARh_Q4C":
            sunSpecReg = 69 + 103;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'VARh';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase C - Quadrant 4: Exported Reactive Energy";
            break; 
    //================================================================================
    // METER EVENTS
    //================================================================================       
        case "M_Events":
            sunSpecReg = 69 + 106;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'binary';
            displayFactors.scaleFactor =  1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = 'M_EVENT_ flags';
            break; 
    //================================================================================
    // INVERTER COMMANDS BELOW
    //================================================================================

    //================================================================================
    // INVERTER CURRENT
    //================================================================================
        case "I_AC_Current":
            sunSpecReg = 69 + 3;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "AC Total Current value";
            break;
        case "I_AC_CurrentA":
            sunSpecReg = 69 + 4;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "AC Phase-A Current value";
            break;
        case "I_AC_CurrentB":
            sunSpecReg = 69 + 5;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "AC Phase-B Current value";
            break;
        case "I_AC_CurrentC":
            sunSpecReg = 69 + 6;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "AC Phase-C Current value";
            break;
    //================================================================================
    // INVERTER VOLTAGE
    //================================================================================
        case "I_AC_VoltageAB":
            sunSpecReg = 69 + 8;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "AC Voltage Phase-AB value";
            break;
        case "I_AC_VoltageBC":
            sunSpecReg = 69 + 9;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "AC Voltage Phase-BC value";
            break;
        case "I_AC_VoltageCA":
            sunSpecReg = 69 + 10;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "AC Voltage Phase-CA value";
            break;        
        case "I_AC_VoltageAN":
            sunSpecReg = 69 + 11;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "AC Voltage Phase-A-to-neutral value";
            break;
        case "I_AC_VoltageBN":
            sunSpecReg = 69 + 12;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "AC Voltage Phase-B-to-neutral value";
            break;
        case "I_AC_VoltageCN":
            sunSpecReg = 69 + 13;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "AC Voltage Phase-C-to-neutral value";
            break;
    //================================================================================
    // INVERTER POWER
    //================================================================================
        case "I_AC_Power":
            sunSpecReg = 69 + 15;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'W';
            displayFactors.displayName = "AC Power value";
            break;
    //================================================================================
    // INVERTER FREQUENCY
    //================================================================================
        case "I_AC_Frequency":
            sunSpecReg = 69 + 17;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Hz';
            displayFactors.displayName = "AC Frequency value";
            break;
    //================================================================================
    // INVERTER POWER
    //================================================================================
        case "I_AC_VA":
            sunSpecReg = 69 + 19;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VA';
            displayFactors.displayName = "Apparent Power";
            break;
        case "I_AC_VAR":
            sunSpecReg = 69 + 21;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAR';
            displayFactors.displayName = "Reactive Power";
            break;
        case "I_AC_PF":
            sunSpecReg = 69 + 23;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.0001;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Power Factor";
            break;
    //================================================================================
    // INVERTER ENERGY
    //================================================================================
        case "I_AC_Energy_WH":
            sunSpecReg = 69 + 25;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "AC Lifetime Energy production";
            break;
    //================================================================================
    // INVERTER DC
    //================================================================================
        case "I_DC_Current":
            sunSpecReg = 69 + 28;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.0001;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "DC Current value";
            break;
        case "I_DC_Voltage":
            sunSpecReg = 69 + 30;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "DC Voltage value";
            break;
        case "I_DC_Power":
            sunSpecReg = 69 + 32;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'W';
            displayFactors.displayName = "DC Power value";
            break;
    //================================================================================
    // INVERTER TEMPERATURE
    //================================================================================
        case "I_Temp_Cab":
            sunSpecReg = 69 + 34;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'C';
            displayFactors.displayName = "Cabinet Temperature";
            break;
        case "I_Temp_Sink":
            sunSpecReg = 69 + 35;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'C';
            displayFactors.displayName = "Coolant or Heat Sink Temperature";
            break;
        case "I_Temp_Trans":
            sunSpecReg = 69 + 36;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'C';
            displayFactors.displayName = "Transformer Temperature";
            break;
        case "I_Temp_Other":
            sunSpecReg = 69 + 37;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'C';
            displayFactors.displayName = "Other Temperature";
            break;
    //================================================================================
    // INVERTER STATUS/EVENTS
    //================================================================================
        case "I_Status":
            sunSpecReg = 69 + 39;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'binary';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Operating State";
            break;
        case "I_Status_Vendor":
            sunSpecReg = 69 + 40;
            sunSpecLength = 1;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'binary';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Vendor Defined Operating State";
            break;
        case "I_Event_1":
            sunSpecReg = 69 + 41;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'binary';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Event Flags (bits 0-31)";
            break;
        case "I_Event_2":
            sunSpecReg = 69 + 43;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'binary';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Event Flags (bits 32-63)";
            break;
        case "I_Event_1_Vendor":
            sunSpecReg = 69 + 45;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'binary';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Vendor Defined Event Flags (bits 0-31)";
            break;
        case "I_Event_2_Vendor":
            sunSpecReg = 69 + 47;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'binary';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Vendor Defined Event Flags (bits 32-63)";
            break;
        case "I_Event_3_Vendor":
            sunSpecReg = 69 + 49;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'binary';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Vendor Defined Event Flags (bits 64-95)";
            break;
        case "I_Event_4_Vendor":
            sunSpecReg = 69 + 51;
            sunSpecLength = 2;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'binary';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Vendor Defined Event Flags (bits 96- 127)";
            break;


    //================================================================================
    // If command not implemented, display requested name but return Manufacturer's name
    // This is something any SunSpec equipment can do
    //================================================================================   
        default:
            sunSpecReg = 5;
            sunSpecLength = 16;
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 37;
            displayFactors.dataFormat = 'ascii';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = sunSpecName;    } 

    interest.rw = 'read';
    interest.category = 'modbus';
    interest.task = 'fc03';
    interest.parameters = decimalToHex(fleetLink[target].modbusAddress, 2) + '_' + decimalToHex(fleetLink[target].baseAddress + sunSpecReg, 4) + decimalToHex(sunSpecLength, 4) + '_9600_8_1';
    updateParamTable(target,interest,displayFactors,gateway);
    initMap();
}


function decimalToHex(decimal, chars) {
    return (decimal + Math.pow(16, chars)).toString(16).slice(-chars).toUpperCase();
}




      $( window ).on( "load", function() {
        initMap();
        updateParamTable(target,interest,displayFactors,gateway);
        document.getElementById("serviceMenu").style.visibility = 'hidden'; // hide service commands on start up
        document.getElementById("inverterCommands").style.visibility = 'hidden'; // hide inverter commnads on startup
        document.getElementById("devRadio").style.visibility = 'hidden'; // hide development network on startup
        document.getElementById("sunSpecModels").style.visibility = 'hidden';
    });
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
    "SN404":{"network":"dev", "locName":"Kiva", "deviceIdHash":"018C268ECB5B", "deviceID":"5000d8c46a56dd24", "usng":"20916258", "latitude":38.5113556, "longitude":-122.7601444, "agentUrl": "/QGO7JQAzyiev", "baseAddress":49999, "modbusAddress": 100, "marker": null, "nodePath":null, "online":false},
    "SN405":{"network":"dev", "locName":"Gibson", "deviceIdHash":"718A34D8423A", "deviceID":"5000d8c46a56ddb2", "usng":"21426258", "latitude":38.5113889, "longitude":-122.7542667, "agentUrl": "/CyPoe3l9E5Od", "baseAddress":49999, "modbusAddress": 100, "marker": null, "nodePath":null, "online":false},
    "SN406":{"network":"dev", "locName":"Beckman", "deviceIdHash":"C5F6371C8A03", "deviceID":"5000d8c46a56dd18", "usng":"21896255", "latitude":38.5110833, "longitude":-122.7488806, "agentUrl": "/hxsSiYETEEpd", "baseAddress":49999, "modbusAddress": 100, "marker": null, "nodePath":null, "online":false},
    "SN407":{"network":"dev", "locName":"Sugiyama Inside", "deviceIdHash":"4CA33E88EDAA", "deviceID":"5000d8c46a56ddde", "usng":"21226282", "latitude":38.5135, "longitude":-122.75653, "agentUrl": "/VifAbahCX8ux", "baseAddress":49999, "modbusAddress": 100, "marker": null, "nodePath":null, "online":false},
    //vivint
    "SN506":{"network":"vivint", "locName":"Vivint 1", "deviceIdHash":"C3B996B9F76C", "deviceID":"5000d8c46a572880", "usng":"15795063", "latitude":38.4038333, "longitude":-122.8190833, "agentUrl": "/oGQ_PBSAUppO", "baseAddress":39999, "modbusAddress": 1, "marker": null, "nodePath":null, "online":false},
    "SN511":{"network":"vivint", "locName":"Vivint 2 ", "deviceIdHash":"C1B16ADC8E57", "deviceID":"5000d8c46a5728f6", "usng":"15815066", "latitude":38.4041111, "longitude":-122.8189167, "agentUrl": "/4R2NSeUUtys8", "baseAddress":39999, "modbusAddress": 1, "marker": null, "nodePath":null, "online":false},
    "SN513":{"network":"vivint", "locName":"SolarEdge Inverter", "deviceIdHash":"DF04146F1DF0", "deviceID":"5000d8c46a57285e", "usng":"15795070", "latitude":38.40443, "longitude":-122.8190967, "agentUrl": "/ZT8GBL-7RrgD", "baseAddress":39999, "modbusAddress": 1, "marker": null, "nodePath":null, "online":false},
    "SN514":{"network":"vivint", "locName":"Vivint 3", "deviceIdHash":"00E329B56259", "deviceID":"5000d8c46a572872", "usng":"15705066", "latitude":38.4040556, "longitude":-122.8201667, "agentUrl": "/609atPXTxkX7", "baseAddress":39999, "modbusAddress": 1, "marker": null, "nodePath":null, "online":false},
    // larkfield
    //"SN402":{"network":"larkfield", "locName":"Opalitliga", "deviceIdHash":"D85F6461EB91", "deviceID":"5000d8c46a56dc4c", "usng":"14776690", "latitude":38.550429, "longitude":-122.830439, "agentUrl": "/oHMQMg_lcxsT", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN503":{"network":"larkfield", "locName":"Henry", "deviceIdHash":"4E562573DBA0", "deviceID":"5000d8c46a572868", "usng":"18166719", "latitude":38.552979, "longitude":-122.791571, "agentUrl": "/tRNE2WbS2CGw", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN504":{"network":"larkfield", "locName":"Piero", "deviceIdHash":"QB930FA057CB6", "deviceID":"5000d8c46a5728d2", "usng":"17136785", "latitude":38.558938, "longitude":-122.8033373, "agentUrl": "/w8Bdk3n0iWt3", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN505":{"network":"larkfield", "locName":"Sugiyama2", "deviceIdHash":"BA48D077C2A8", "deviceID":"5000d8c46a57286a", "usng":"21236281", "latitude":38.513395, "longitude":-122.756469, "agentUrl": "/RVKEMRdCLmKj", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN508":{"network":"larkfield", "locName":"Foster", "deviceIdHash":"730D72A6E22F", "deviceID":"5000d8c46a572874", "usng":"17776661", "latitude":38.547754, "longitude":-122.796043, "agentUrl": "/2866vQYBgUpC", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN512":{"network":"larkfield", "locName":"Beckman", "deviceIdHash":"6917511534FD", "deviceID":"5000d8c46a5721ea", "usng":"21886253", "latitude":38.510951, "longitude": -122.748958, "agentUrl": "/kRQMPFuKmzDM", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN516":{"network":"larkfield", "locName":"Sugiyama", "deviceIdHash":"364935E144C5", "deviceID":"5000d8c46a572a5a", "usng":"21226281", "latitude":38.513559, "longitude":-122.756549, "agentUrl": "/m6fnIP8Xwcbx", "baseAddress":50070, "modbusAddress": 100, "marker": null, "nodePath":null, "online":true},
    "SN517":{"network":"larkfield", "locName":"Shirlie", "deviceIdHash":"73210C7C7368", "deviceID":"5000d8c46a572a40", "usng":"21016306", "latitude":38.515786, "longitude":-122.759001, "agentUrl": "/lfonbmovX8Ak", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN518":{"network":"larkfield", "locName":"Hermosillo", "deviceIdHash":"45BB2C5D3151", "deviceID":"5000d8c46a5729fa", "usng":"16106798", "latitude":38.560186, "longitude":-122.815174, "agentUrl": "/JPTE9uGlCGQL", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN519":{"network":"larkfield", "locName":"Kempker", "deviceIdHash":"035E6124319B", "deviceID":"5000d8c46a572a04", "usng":"17996657", "latitude":38.547460, "longitude":-122.793545, "agentUrl": "/sv3PuN3lquKO", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN520":{"network":"larkfield", "locName":"Buren", "deviceIdHash":"8C41DCBC3DF2", "deviceID":"5000d8c46a572a84", "usng":"14576664", "latitude":38.548154, "longitude":-122.832752, "agentUrl": "/2IauvU30NdQH", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN521":{"network":"larkfield", "locName":"Palmer", "deviceIdHash":"35DFD2657C41", "deviceID":"5000d8c46a572a74", "usng":"17756732", "latitude":38.554163, "longitude":-122.796195, "agentUrl": "/LYmDkTTVsD1E", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN522":{"network":"larkfield", "locName":"Van Grouw", "deviceIdHash":"9CBABDD00BD5", "deviceID":"5000d8c46a572a68", "usng":"17286817", "latitude":38.561889, "longitude":-122.801555, "agentUrl": "/QCxFKECTRdBH", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN523":{"network":"larkfield", "locName":"Buffo", "deviceIdHash":"BB2A0BFDC8FC", "deviceID":"5000d8c46a5729e6", "usng":"16386739", "latitude":38.554853, "longitude":-122.811906, "agentUrl": "/jYthi-aNvlv6", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN524":{"network":"larkfield", "locName":"Yamasaki", "deviceIdHash":"022676CEA2C8", "deviceID":"5000d8c46a572a70", "usng":"16426752", "latitude":38.555988, "longitude":-122.811517, "agentUrl": "/NTLnl40ofe9Y", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN526":{"network":"larkfield", "locName":"Opalitliga", "deviceIdHash":"4B816CB75142", "deviceID":"5000d8c46a572868", "usng":"14776690", "latitude":38.550429, "longitude":-122.830439, "agentUrl": "/_ERhHgIiqjx0", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN527":{"network":"larkfield", "locName":"Galli", "deviceIdHash":"E18F79FBF4D0", "deviceID":"5000d8c46a572a38", "usng":"18166731", "latitude":38.554040, "longitude":-122.791538, "agentUrl": "/t02E8X0S0Kl6", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN528":{"network":"larkfield", "locName":"Gibson", "deviceIdHash":"F5ED514678B2", "deviceID":"5000d8c46a572a58", "usng":"21416258", "latitude":38.511400, "longitude":-122.754315, "agentUrl": "/aQTyLRwIHjYn", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN529":{"network":"larkfield", "locName":"Clapper", "deviceIdHash":"BC4AD7B8D7B2", "deviceID":"5000d8c46a572a7a", "usng":"16576784", "latitude":38.558927, "longitude": -122.809762, "agentUrl": "/TjIP9SXEzEGb", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},    
    "SN530":{"network":"larkfield", "locName":"Nadendla", "deviceIdHash":"2EB55A0B48F4", "deviceID":"5000d8c46a572a12", "usng":"17616705", "latitude":38.551712, "longitude":-122.79779, "agentUrl": "/r7-wVnF8nV9b", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true},
    "SN531":{"network":"larkfield", "locName":"Ferrara", "deviceIdHash":"A9D4A224043D", "deviceID":"5000d8c46a572a4c", "usng":"21246285", "latitude":38.513862, "longitude":-122.756289, "agentUrl": "/lgWdhq_T9EsC", "baseAddress":0, "modbusAddress": 1, "marker": null, "nodePath":null, "online":true}
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
    'unitString' : "W", // append units string to communicate result better
    'displayName' : "Irradiance" // nice human readble display name for user
}


    // Choose target unit
    function setTarget(requestedTarget) {
        //console.log("Target= " + requestedTarget)
        target = requestedTarget;
        interest.deviceIdHash = fleetLink[target].deviceIdHash;
        interest.usng = fleetLink[target].usng;
        fleetLink[target]["online"] = false;
        var continuousMode = document.getElementById("continuousGo").checked;
        if (continuousMode == false){        
            redrawMap();
            drawMarker(target, "#ff8080", "#ff4d4d", 0);
            drawNodePath(target,gateway, "white", 1);
        }
      }


    // Choose gateway unit
    function setGateway(requestedGateway) {
        //console.log("Gateway= " + requestedGateway)
        gateway = requestedGateway;
        interest.url = "https://agent.electricimp.com" + fleetLink[gateway].agentUrl
        fleetLink[gateway]["online"] = true;
        var continuousMode = document.getElementById("continuousGo").checked;
        if (continuousMode == false){               
            redrawMap();
            drawMarker(gateway, "white", "white", 0);
            drawNodePath(target,gateway, "white", 1);
        }
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
            document.getElementById("meterCommands").style.visibility = 'hidden';
            document.getElementById("inverterCommands").style.visibility = 'hidden';
            
        } else {
            document.getElementById("serviceMenu").style.visibility = 'visible';
            document.getElementById("devRadio").style.visibility = 'visible';      
            document.getElementById("sunSpecModels").style.visibility = 'visible';
            document.getElementById("meterCommands").style.visibility = 'visible';
            document.getElementById("inverterCommands").style.visibility = 'visible';
            
         }
    }

     // Set Run Mode
     function setRunMode(cb){
        if (cb.checked == true){
            document.getElementById("gatewayMenu").style.visibility = 'hidden';
            document.getElementById("targetMenu").style.visibility = 'hidden';
         } else {
            document.getElementById("gatewayMenu").style.visibility = 'visible';
            document.getElementById("targetMenu").style.visibility = 'visible';
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
                if (fleetLink[key]["online"] == true ){
                    icon =  {path: google.maps.SymbolPath["CIRCLE"], strokeColor: "white", strokeWeight: 2, scale: 6, fillColor: 'white', fillOpacity: 0.0};
                } else {
                    icon =  {path: google.maps.SymbolPath["CIRCLE"], strokeColor: "#ff8080", strokeWeight: 2, scale: 6, fillColor: '#ff4d4d', fillOpacity: 0.0};
                }
                
        marker = new google.maps.Marker({
            position: new google.maps.LatLng(fleetLink[key]["latitude"], fleetLink[key]["longitude"]),
            icon: icon,
            title: key + " " + fleetLink[key]["locName"],
            map: mapFleetLink
        });
        bounds.extend(marker.position);

        fleetLink[key]["marker"] = marker; // store this marker in the fleetlink JSON object
        
        // add a lsitener to change online status by clicking on marker
        google.maps.event.addListener(marker, 'click', (function (marker,key) {
            return function () {
                if(fleetLink[key]["online"] == true){
                    fleetLink[key]["online"] = false;
                    drawMarker(key, '#ff8080', '#ff4d4d', '0.0');                    
                } else {
                    fleetLink[key]["online"] = true;
                    drawMarker(key, 'white', 'white', '0.0');
                }
            }
        })(marker, key));
        
        }
    }
}
    // size the map to include all units
    mapFleetLink.fitBounds(bounds);

    var listener = google.maps.event.addListener(mapFleetLink, "idle", function () {
        google.maps.event.removeListener(listener);
    });
}


function drawMarker(unitID, reqStrokeColor, reqFillColor, reqFillOpacity){
    var icon =  {path: google.maps.SymbolPath["CIRCLE"], strokeColor: reqStrokeColor, strokeWeight: 2, scale: 6, fillColor: reqFillColor, fillOpacity: Number(reqFillOpacity)};
    fleetLink[unitID]["marker"].setIcon(icon) ;   
}

function clearNodePath(targetId){
    if (fleetLink[targetId]["nodePath"] != null) {
        // if this unit has an existing node path, remove it
        fleetLink[targetId]["nodePath"].setMap(null);
    }
    }

function drawNodePath(unitId1,unitId2, color, opacity){
    var nodePlanCoordinates = [
              {lat: fleetLink[unitId1].latitude, lng: fleetLink[unitId1].longitude},
              {lat: fleetLink[unitId2].latitude, lng: fleetLink[unitId2].longitude}
            ];

    if (fleetLink[unitId1]["nodePath"] != null) {
        // if this unit has an existing node path, remove it
        fleetLink[unitId1]["nodePath"].setMap(null);
    }
    // then draw the new one  
    nodePath = new google.maps.Polyline({
        path: nodePlanCoordinates,
        geodesic: true,
        strokeColor: color,
        strokeOpacity: opacity,
        strokeWeight: 3
        });
        nodePath.setMap(mapFleetLink);

    fleetLink[unitId1]["nodePath"] = nodePath;
    }


    // reset all the merkers and node paths to blank without reinitializing map
    function redrawMap(){
        for (var key in fleetLink) {
            if (fleetLink.hasOwnProperty(key)) {
                // if this unit is a member of the network which includes the target unit, then add to list to plot
                if (fleetLink[key]["network"] == fleetLink[target]["network"] ){
                    if (fleetLink[key]["online"] == true ){
                        drawMarker(key, 'white', 'white', '0.0');
                    } else {
                        drawMarker(key, '#ff8080', '#ff4d4d', '0.0');                    
                    }          
                    if (fleetLink[key]["nodePath"] != null){
                        fleetLink[key]["nodePath"].setOptions({strokeOpacity: 0.0});
                    }
                clearNodePath(key);
                }        
            }
        }   
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
                returnDataString = numericData.toFixed(0) + " " + displayFactors.unitString;                
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



function getAllData() {
    console.log("----------------------------------------");
    redrawMap();

    // if in continous mode, randomize the offline units and do this every X seconds
    var continuousMode = document.getElementById("continuousGo").checked;
    if (continuousMode == true){
        setTimeout(getAllData,120000);
        // set all units as online to start
        for (var key in fleetLink) {
                // if this unit is a member of the network which includes the target unit, then process it
                if (fleetLink[key]["network"] == fleetLink[target]["network"] ){
                    fleetLink[key]["online"] = true;                                                                         
                }
            }
        redrawMap();
        // get data from online units and find out if any are unexpectedly offline
        setTimeout(getOnlineData,2000);
        // now get all the offlines, must be sequential to avoid overloading LoRa network
        // Wait a bit to allow return of online unit data
        setTimeout(getAllOfflineData, 8000);
    } else {
        // maybe you're in single measurement mode
        getOneOfflineData();
    }
}



function getOneOfflineData(){
    // assumes you've already set target and gateway units
    var thisDistance = 0;
    var clockTime = "";

    // set all units as online to start
    for (var key in fleetLink) {
        // if this unit is a member of the network which includes the target unit, then process it
        if (fleetLink[key]["network"] == fleetLink[target]["network"] ){
            fleetLink[key]["online"] = true;        
        }
    }
    redrawMap();

    thisDistance = findDistance(target, gateway);
    // Draw a white line to indicate activity
    drawNodePath(target,gateway,"white", 1);
    // Web POST to nearby agent for LoRa request
    $.ajax({
            url: interest.url,
            context:{requestedTargetKey:target, requestedGatewayKey:gateway, requestedDistance:thisDistance},
            timeout: 15000,
            data: JSON.stringify(interest), // convert interest string to JSON
            type: 'POST',
                success : function(response) {
                    drawMarker(this.requestedTargetKey, 'white', '#2eb82e', '1.0');                                                            
                    drawNodePath(this.requestedTargetKey,this.requestedGatewayKey, '#4db8ff', 1);
                    clockTime = getClock();
                    console.log(clockTime + " LoRa PASS, " + this.requestedTargetKey + " " + fleetLink[this.requestedTargetKey]["locName"] + ", " + this.requestedGatewayKey + " " + fleetLink[this.requestedGatewayKey]["locName"] + ", " + this.requestedDistance + " m, " + formatData(response, interest));
                },
                error : function(jqXHR, textStatus, err) {
                    var errorResponse = err ;
                    clockTime = getClock();
                    drawMarker(this.requestedTargetKey, '#ff0066', '#ff4d4d', '1.0');                                                                                        
                    drawNodePath(this.requestedTargetKey,this.requestedGatewayKey, '#ff4d4d', 1);
                    console.log(clockTime + " LoRa FAIL, " + this.requestedTargetKey + " " + fleetLink[this.requestedTargetKey]["locName"] + ", " + this.requestedGatewayKey + " " + fleetLink[this.requestedGatewayKey]["locName"] + ", " + this.requestedDistance + " m");
                }
        });
}

function getOnlineData(){
        // Request all the online units' data asynchronously
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
                            timeout: 5000,
                            data: JSON.stringify(interest), // convert interest string to JSON
                            type: 'POST',
                                success : function(response) {
                                    drawMarker(this.requestedTargetKey, 'white', '#2eb82e', '1.0');      
                                    fleetLink[this.requestedTargetKey]["online"] = true;                                      
                                    clockTime = getClock();
                                    console.log(clockTime + " WiFi PASS, " + this.requestedTargetKey + " " + fleetLink[this.requestedTargetKey]["locName"] + ", " + formatData(response, interest));
                                },
                                error : function(jqXHR, textStatus, err) {
                                    var errorResponse = err ;
                                    drawMarker(this.requestedTargetKey, '#ff0066', '#ff4d4d', '0.0');       
                                    fleetLink[this.requestedTargetKey]["online"] = false;                                                         
                                    clockTime = getClock();
                                    console.log(clockTime + " WiFi FAIL, " + this.requestedTargetKey + " " + fleetLink[this.requestedTargetKey]["locName"] + " WiFi is offline");
                                }
                        });
                    }
                }
            }
        }
}


function getAllOfflineData(){
    var nearestOnlineUnit = '';
    var thisDistance = 0;
    var clockTime = "";
    var retryFlag = false;

    // set the desired number of units offline
    setOfflineRandom();

    (function($) {
        // This is a way to queue  Ajax POST queries so that they run sequentially
        // Got it here: http://jsfiddle.net/1337/9TG8t/86/
        // Can't claim I understand it!
        // jQuery on an empty object, we are going to use this as our Queue
        var ajaxQueue = $({});
        
        $.ajaxQueue = function( ajaxOpts ) {
            var jqXHR,
                dfd = $.Deferred(),
                promise = dfd.promise();
            // queue our ajax request
            ajaxQueue.delay(5000).queue( doRequest );
            // add the abort method
            promise.abort = function( statusText ) {
                // proxy abort to the jqXHR if it is active
                if ( jqXHR ) {
                    return jqXHR.abort( statusText );
                }
                // if there wasn't already a jqXHR we need to remove from queue
                var queue = ajaxQueue.queue(),
                    index = $.inArray( doRequest, queue );
                if ( index > -1 ) {
                    queue.splice( index, 1 );
                }
                // and then reject the deferred
                dfd.rejectWith( ajaxOpts.context || ajaxOpts,
                    [ promise, statusText, "" ] );
                return promise;
            };
            // run the actual query
            function doRequest( next ) {
                jqXHR = $.ajax( ajaxOpts )
                .then( next, next )
                .done( dfd.resolve )
                .fail( dfd.reject );
            }

            return promise;
        };
        })(jQuery);


    // This is the application specific Ajax query to get offline units' data    
    for (var key in fleetLink) {
        trialNumber = 0;
        if (fleetLink.hasOwnProperty(key)) {
            // if this unit is a member of the network which includes the target unit, then process it as potentially offline
            if (fleetLink[key]["network"] == fleetLink[target]["network"] ){
                if(fleetLink[key]["online"] == false){  // if it's offline, we have query via LoRa
                setTarget(key); 
                nearestOnlineUnit = findNearestOnline(key);
                thisDistance = findDistance(key, nearestOnlineUnit);
                setGateway(nearestOnlineUnit); 
                // Draw a white line to indicate activity
                drawNodePath(target,gateway,"white", 1);
                trialNumber = addToAjaxQueue(key, nearestOnlineUnit, thisDistance, retryFlag);
                }
            }
        }
    }
}

function addToAjaxQueue(key, nearestOnlineUnit, thisDistance, retryFlag){
    // Web POST to nearby agent for LoRa request
    $.ajaxQueue({
        url: interest.url,
        context:{requestedTargetKey:key, requestedGatewayKey:nearestOnlineUnit, requestedDistance:thisDistance, requestedRetryFlag:retryFlag},
        timeout: 8000,
        data: JSON.stringify(interest), // convert interest string to JSON
        type: 'POST',
            success : function(response) {                
                drawMarker(this.requestedTargetKey, 'white', '#2eb82e', '1.0');                                                            
                drawNodePath(this.requestedTargetKey,this.requestedGatewayKey, '#4db8ff', 1);
                clockTime = getClock();
                console.log(clockTime + " LoRa PASS, " + this.requestedTargetKey + " " + fleetLink[this.requestedTargetKey]["locName"] + ", " + this.requestedGatewayKey + " " + fleetLink[this.requestedGatewayKey]["locName"] + ", " + this.requestedDistance + " m, " + formatData(response, interest));
            },
            error : function(jqXHR, textStatus, err) {
                var errorResponse = err ;
                // retry (currently set to only one retry)
                if (this.requestedRetryFlag == false){
                    setTarget(this.requestedTargetKey); 
                    nearestOnlineUnit = findNearestOnline(key);
                    thisDistance = findDistance(key, nearestOnlineUnit);
                    setGateway(nearestOnlineUnit); 
                    addToAjaxQueue(this.requestedTargetKey, this.requestedGatewayKey, this.requestedDistance, true);
                    trialNumber++;
                    clockTime = getClock();
                    drawMarker(this.requestedTargetKey, '#ffffb3', '#cccc00', '1.0');                                                                                        
                    drawNodePath(this.requestedTargetKey,this.requestedGatewayKey, '#ffffb3', 1);
                    console.log(clockTime + " LoRa RETRY, " + this.requestedTargetKey + " " + fleetLink[this.requestedTargetKey]["locName"] + ", " + this.requestedGatewayKey + " " + fleetLink[this.requestedGatewayKey]["locName"] + ", " + this.requestedDistance + " m");    
                } else {
                    clockTime = getClock();
                    drawMarker(this.requestedTargetKey, '#ff0066', '#ff4d4d', '1.0');                                                                                        
                    drawNodePath(this.requestedTargetKey,this.requestedGatewayKey, '#ff4d4d', 1);
                    console.log(clockTime + " LoRa FAIL, " + this.requestedTargetKey + " " + fleetLink[this.requestedTargetKey]["locName"] + ", " + this.requestedGatewayKey + " " + fleetLink[this.requestedGatewayKey]["locName"] + ", " + this.requestedDistance + " m");
                }
            }
    });
    return trialNumber;
}

function setOfflineRandom(){
    var randomKey = "";
    var fleetLinkKeys = Object.keys(fleetLink);
    do {
            randomNumber = Math.floor(Math.random() * fleetLinkKeys.length);
            randomKey = fleetLinkKeys[randomNumber];
            // if this unit is a member of the network which includes the target unit, then process it
            if (fleetLink[randomKey]["network"] == fleetLink[target]["network"] ){
                // if this unit is online, set it offline
                if (fleetLink[randomKey]["online"] == true){
                    fleetLink[randomKey]["online"] = false;
                    drawMarker(randomKey, '#ff0066', '#ff4d4d', '0.0');                                                                            
                    clockTime = getClock();
                    console.log(clockTime + " forcing unit " + randomKey + " " + fleetLink[randomKey]["locName"] + " WiFi offline")
                }

            }
        // count offline units
        var numberOfflineUnits = 0;
        for (var key in fleetLink) {
            if (fleetLink.hasOwnProperty(key)) {
                // if this unit is a member of the network which includes the target unit, then process it
                if (fleetLink[key]["network"] == fleetLink[target]["network"] ){
                    if (fleetLink[key]["online"] == false){
                        numberOfflineUnits++;
                    }
                }
            }
        }
    }
    while (numberOfflineUnits < 4);

}


function findNearestOnline(offlineUnit){
    var nearestOnline = '';
    var distanceToNearestOnline = 99999;
    var thisDistance = 99999;

    for (var key in fleetLink) {
        if (fleetLink.hasOwnProperty(key)) {
            // if this unit is a member of the network which includes the target unit, then process it as potentially online
            if (fleetLink[key]["network"] == fleetLink[offlineUnit]["network"] ){
                if(fleetLink[key]["online"] == true){  // if its online, check if its closest unit
                    thisDistance = findDistance(offlineUnit, key);
                    if(Number(thisDistance) < Number(distanceToNearestOnline)){
                        nearestOnline = key;
                        distanceToNearestOnline = thisDistance;
                    }
                }
            }
        }

    }


    return nearestOnline;
    
}


function findDistance(unit1, unit2){
    var x1 = 10 * fleetLink[unit1]["usng"].substring(0,4);
    var y1 = 10 * fleetLink[unit1]["usng"].substring(4,8);
    var x2 = 10 * fleetLink[unit2]["usng"].substring(0,4);
    var y2 = 10 * fleetLink[unit2]["usng"].substring(4,8);
    var distance = Math.pow((Math.pow((x2 - x1),2) + Math.pow((y2 - y1),2)),0.5).toFixed(0);
    return distance;
}


function getClock(){
    var d=new Date();
    year = d.getFullYear();
    month = d.getMonth();
    date = d.getDate();
    h=d.getHours();
    m=d.getMinutes();
    s=d.getSeconds();
    if (m<10) { m = "0" + m; }
    if (s<10) { s = "0" + s; }
    var clockTime = month + "/" + date + "/" + year + " " + h + ":" + m + ":" + s;
    return clockTime;
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
    //updateParamTable(target,interest,displayFactors,gateway);
}

// Read a specific unit's geolocation
function readGeoSelf(){
    interest.rw = 'read';
    interest.category = 'flash';
    interest.task = 'geoSelf';
    interest.parameters = "";
    displayFactors.dataFormat = 'string';
    displayFactors.displayName = "Read Geolocation" + interest.parameters;
    //updateParamTable(target,interest,displayFactors,gateway);
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
    //updateParamTable(target,interest,displayFactors,gateway);

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
    //updateParamTable(target,interest,displayFactors,gateway);
 
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
    //(target,interest,displayFactors,gateway);
    initMap();
}


function decimalToHex(decimal, chars) {
    return (decimal + Math.pow(16, chars)).toString(16).slice(-chars).toUpperCase();
}




      $( window ).on( "load", function() {
        initMap();
        //updateParamTable(target,interest,displayFactors,gateway);
        document.getElementById("serviceMenu").style.visibility = 'hidden'; // hide service commands on start up
        document.getElementById("inverterCommands").style.visibility = 'hidden'; // hide inverter commnads on startup
        document.getElementById("devRadio").style.visibility = 'hidden'; // hide development network on startup
        document.getElementById("sunSpecModels").style.visibility = 'hidden';
        //document.getElementById("gatewayMenu").style.visibility = 'hidden';
        //document.getElementById("targetMenu").style.visibility = 'hidden';
        document.getElementById("meterCommands").style.visibility = 'hidden';
        
    });
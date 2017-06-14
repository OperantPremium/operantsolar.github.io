// FleetLink Mobirise Javascript 
//Randy King 5/25/2017
// default Interest with reasonable values for SN404
var target = "SN403";
var gateway = "SN403";
var wiFiSSID = "";

var interest = {
    'usng': "28475668",
    'deviceIdHash' : "018C268ECB5B",
    'rw': 'read',
    'category': 'modbus',
    'task': 'fc03',
    'parameters': '64_C3A50001_9600_8_1',
    'url' : "https://agent.electricimp.com/wXqOLIl3KiLB",
    // the following parameters are used to pretty up data returns, particularly from modbus
    'firstDataChar' : 6, // position of the FIRST data character in whatever the interest returns (0 based)
    'lastDataChar' : 9,  // position of the LAST data character in whatever the interest returns (0 based)
    'dataFormat' : 'hex', // defines format of returned data (can be hex | dec | ascii | string)
    'scaleFactor' : 0.01, // Scale numeric data when necessary
    'offsetFactor' : 0, // similarly apply any numeric offset
    'unitString' : "Hz", // append units string to communicate result better
    'displayName' : "AC Frequency" // nice human readble display name for user
}


// Device ID hashes as reference for TARGET
// Agent URLs as reference for GATEWAY
//----------------------------------------------------


// R&D development units - 918.5 MHz
//----------------------------------------------------
//SN402                  D85F6461EB91    /oHMQMg_lcxsT
//SN403                  018C268ECB5B    /wXqOLIl3KiLB
//SN404                  2BF6EF3EFD90    /QGO7JQAzyiev
//SN405                  718A34D8423A    /CyPoe3l9E5Od
//SN406                  C5F6371C8A03    /hxsSiYETEEpd
//SN407                  4CA33E88EDAA    /VifAbahCX8ux

// Customer demo houses - 917 MHz
//----------------------------------------------------
//SN506  Blue House      C3B996B9F76C    /oGQ_PBSAUppO
//SN508  Orange House    730D72A6E22F    /2866vQYBgUpC
//SN513  Black House     DF04146F1DF0    /ZT8GBL-7RrgD
//SN514  Yellow House    00E329B56259    /609atPXTxkX7

// Solmetric - 917 MHz
//----------------------------------------------------
//SN506                   C3B996B9F76C    /oGQ_PBSAUppO
//SN511                   C1B16ADC8E57    /4R2NSeUUtys8
//SN513                   DF04146F1DF0    /ZT8GBL-7RrgD
//SN514                   00E329B56259    /609atPXTxkX7

// Field demo - 915.5 MHz
//----------------------------------------------------
//SN503  Shirlee         4E562573DBA0    /tRNE2WbS2CGw
//SN505  Sugiyama        BA48D077C2A8    /RVKEMRdCLmKj
//SN507  Gibson          67AE0AAFD4E2    /S6QExe1f2KTi
//SN509  Green House     16240A06C1FC    /D1PRYwJmmHAi
//SN512  Beckman         6917511534FD    /kRQMPFuKmzDM

// Manufacturing - 915.5 MHz
//----------------------------------------------------
//SN501
//SN502
//SN504                  B930FA057CB6    /w8Bdk3n0iWt3
//SN510 
//SN511
//SN515  Bad LoRa        4E44238D7110    /VRa-gimZfDGJ


// Choose gateway unit
function setGateway(requestedGateway) {
    gateway = requestedGateway;
    switch(requestedGateway) {
// PROTO 4'S
         case "SN402":
            interest.url = "https://agent.electricimp.com/oHMQMg_lcxsT";
            break;
        case "SN403":
            interest.url = "https://agent.electricimp.com/wXqOLIl3KiLB";
            break;
        case "SN404":
            interest.url = "https://agent.electricimp.com/QGO7JQAzyiev";
            break;            
        case "SN405":
            interest.url = "https://agent.electricimp.com/CyPoe3l9E5Od";
            break;
        case "SN406":
            interest.url = "https://agent.electricimp.com/hxsSiYETEEpd";
            break;
        case "SN407":
            interest.url = "https://agent.electricimp.com/hxsSiYETEEpd";
            break;      
// PROTO 5'S
         case "SN501":
            interest.url = "";
            break;      
         case "SN502":
            interest.url = "";
            break; 
         case "SN503":
            interest.url = "https://agent.electricimp.com/tRNE2WbS2CGw";
            break;      
         case "SN504":
            interest.url = "https://agent.electricimp.com/w8Bdk3n0iWt3";
            break;
         case "SN505":
            interest.url = "https://agent.electricimp.com/RVKEMRdCLmKj";
            break;      
         case "SN506":
            interest.url = "https://agent.electricimp.com/oGQ_PBSAUppO";
            break; 
         case "SN507":
            interest.url = "https://agent.electricimp.com/S6QExe1f2KTi";
            break;      
         case "SN508":
            interest.url = "https://agent.electricimp.com/2866vQYBgUpC";
            break;  
         case "SN509":
            interest.url = "https://agent.electricimp.com/D1PRYwJmmHAi";
            break;      
         case "SN510":
            interest.url = "";
            break; 
         case "SN511":
            interest.url = "https://agent.electricimp.com/4R2NSeUUtys8";
            break;      
         case "SN512":
            interest.url = "https://agent.electricimp.com/kRQMPFuKmzDM";
            break;
         case "SN513":
            interest.url = "https://agent.electricimp.com/ZT8GBL-7RrgD";
            break;      
         case "SN514":
            interest.url = "https://agent.electricimp.com/609atPXTxkX7";
            break; 
         case "SN515":
            interest.url = "https://agent.electricimp.com/VRa-gimZfDGJ";
            break;      
        default:
            interest.url = "";
    }
    //console.log("Setting gateway to " + requestedGateway);
    updateParamTable(target,interest,gateway);

  }




// Choose target unit
function setTarget(requestedTarget) {
    target = requestedTarget;
    switch(requestedTarget) {
// PROTO 4'S
        case "SN402":
            interest.deviceIdHash = "D85F6461EB91";
             break;
        case "SN403":
            interest.deviceIdHash = "018C268ECB5B";
            break;
        case "SN404":
            interest.deviceIdHash = "2BF6EF3EFD90";
            break;
        case "SN405":
            interest.deviceIdHash = "718A34D8423A";
            break;
        case "SN406":
            interest.deviceIdHash = "C5F6371C8A03";
            break;
        case "SN407":
            interest.deviceIdHash = "4CA33E88EDAA";
            break;
// PROTO 5'S
        case "SN501":
            interest.deviceIdHash = "";
             break;
        case "SN502":
            interest.deviceIdHash = "";
            break;
        case "SN503":
            interest.deviceIdHash = "4E562573DBA0";
            break;
        case "SN504":
            interest.deviceIdHash = "B930FA057CB6";
            break;
        case "SN505":
            interest.deviceIdHash = "BA48D077C2A8";
            break;
        case "SN506":
            interest.deviceIdHash = "C3B996B9F76C";
            break;
        case "SN507":
            interest.deviceIdHash = "67AE0AAFD4E2";
            break;
        case "SN508":
            interest.deviceIdHash = "730D72A6E22F";
            break;
        case "SN509":
            interest.deviceIdHash = "16240A06C1FC";
            break;
        case "SN510":
            interest.deviceIdHash = "";
            break;
        case "SN511":
            interest.deviceIdHash = "C1B16ADC8E57";
            break;
        case "SN512":
            interest.deviceIdHash = "6917511534FD";
            break;
        case "SN513":
            interest.deviceIdHash = "DF04146F1DF0";
            break;
        case "SN514":
            interest.deviceIdHash = "00E329B56259";
            break;
        case "SN515":
            interest.deviceIdHash = "4E44238D7110";
            break;
        default:
            interest.deviceIdHash = "";
            console.log("Setting target to default");
    }
    //console.log("Setting target to " + requestedTarget); 
    updateParamTable(target,interest,gateway);

}

// Scan the WiFi environment, optionally choose the SSID of the network to scane
function scanWiFi(){
    wiFiSSID = prompt("Desired SSID?", "Operant");
    interest.rw = 'read';
    interest.category = 'wiFi';
    interest.task = 'scan';
    interest.parameters = wiFiSSID;
    interest.dataFormat = 'string';
    interest.displayName = "Scan WiFi for SSID " + interest.parameters;
    updateParamTable(target,interest,gateway);

}

// Read the Modbus,must know detailed Modbus command
function readModbus(){
    modbusCommand = prompt("Modbus Read Command?", "01_00000001_9600_8_1");
    interest.rw = 'read';
    interest.category = 'modbus';
    interest.task = 'fc03';
    interest.parameters = modbusCommand;
    interest.dataFormat = 'string';
    interest.displayName = "Read Modbus: " + interest.parameters;
    updateParamTable(target,interest,gateway);
 
}


// Read the Modbus, built from SunSpec register map
function readSunSpec(sunSpecName){
    interest.rw = 'read';
    interest.category = 'modbus';
    interest.task = 'fc03';
    switch(sunSpecName) {
        case "Mn":
            interest.parameters = '64_C3540010_9600_8_1';
            interest.firstDataChar = 6;
            interest.lastDataChar = 37;
            interest.dataFormat = 'ascii';
            interest.scaleFactor = 0;
            interest.offsetFactor = 0;
            interest.unitString = '';
            interest.displayName = "Manufacturer";
            break;
        case "M_AC_Current":
            interest.parameters = '64_C3970001_9600_8_1';
            interest.firstDataChar = 6;
            interest.lastDataChar = 9;
            interest.dataFormat = 'hex';
            interest.scaleFactor = 0.01;
            interest.offsetFactor = 0;
            interest.unitString = 'A';
            interest.displayName = "AC Current (sum of active phases)";
            break;
        case "M_AC_Voltage_LN":
            interest.parameters = '64_C39C0001_9600_8_1';
            interest.firstDataChar = 6;
            interest.lastDataChar = 9;
            interest.dataFormat = 'hex';
            interest.scaleFactor = 0.1;
            interest.offsetFactor = 0;
            interest.unitString = 'V';
            interest.displayName = "Line to Neutral AC Voltage (average of active phases)";
            break;
        case "M_AC_Freq":
            interest.parameters = '64_C3A50001_9600_8_1';
            interest.firstDataChar = 6;
            interest.lastDataChar = 9;
            interest.dataFormat = 'hex';
            interest.scaleFactor = 0.01;
            interest.offsetFactor = 0;
            interest.unitString = 'Hz';
            interest.displayName = "AC Frequency";
            break;
        case "M_AC_Power":
            interest.parameters = '64_C3A70001_9600_8_1';
            interest.firstDataChar = 6;
            interest.lastDataChar = 9;
            interest.dataFormat = 'hex';
            interest.scaleFactor = 10;
            interest.offsetFactor = 0;
            interest.unitString = 'W';
            interest.displayName = "Total Real Power(sum of active phases)";
            break;
        case "M_Imported":
            interest.parameters = '64_C3C30002_9600_8_1';
            interest.firstDataChar = 6;
            interest.lastDataChar = 13;
            interest.dataFormat = 'hex';
            interest.scaleFactor = 0.001;
            interest.offsetFactor = 0;
            interest.unitString = 'kWh';
            interest.displayName = "Total Imported Real Energy";
            break;
        default:
            interest.parameters =  "";
    } 
    updateParamTable(target,interest,gateway);
}

// Format the data for pretty display
function formatData(rawData, interest){
    var returnDataString = "";

    // remove any leading or trailing numbers (esp Modbus)    
    var cleanData = rawData.substring(interest.firstDataChar, interest.lastDataChar + 1);

    // convert to decimal if hex
    switch(interest.dataFormat){
        case 'hex':
            var numericData = 0;
            numericData = parseInt(cleanData, 16); 
            // apply scale factor and offset
            numericData = numericData * interest.scaleFactor + interest.offsetFactor;
            // Add units string at end of data
            returnDataString = numericData + " " + interest.unitString;
        break;
        case 'ascii':
            var asciiCode = 0;
            for (i = 0; i < cleanData.length; i+=2) { 
                asciiCode = parseInt(cleanData.substring(i,i+2), 16);
                returnDataString += String.fromCharCode(asciiCode);
            }
        break;
        default:
            returnDataString = rawData;
        }
        console.log("data: " + returnDataString);

return returnDataString
}



function updateParamTable(targetID, interest, gatewayID){
    var x = document.getElementById("paramTable").rows[1].cells;
    x[0].innerHTML = targetID;
    x[1].innerHTML = interest.displayName;
    x[2].innerHTML = gatewayID;
}

// read the web UI to determine the unit that is being targeted
function expressInterest(buttonID) {

    console.log(interest);

    var waitDisplay = "Sending to " + target;
    if (target != gateway){
        waitDisplay += " via " + gateway ;
    }
    buttonID.style.background='#1474BF';
    buttonID.innerHTML = waitDisplay;

    // actual web POST
    $.ajax({
        url: interest.url,
        timeout: 15000,
        data: JSON.stringify(interest), // convert interest string to JSON
        type: 'POST',
            success : function(response) {
                presentableData = formatData(response, interest);
                var successDisplay = target + " | " + presentableData;
                buttonID.innerHTML = successDisplay;
                buttonID.style.background='#90A878';
            },
            error : function(jqXHR, textStatus, err) {
                //var errorResponse = jqXHR.status + ' ' + textStatus + ': ' + err + ' - ' + jqXHR.responseText;
                var errorResponse = err ;

                console.log(errorResponse);
                buttonID.innerHTML = errorResponse;
                buttonID.style.background='#D7AB4B';
            }
    });


    }

      $( window ).on( "load", function() {
        updateParamTable(target,interest,gateway);
        console.log("page loaded");
    });
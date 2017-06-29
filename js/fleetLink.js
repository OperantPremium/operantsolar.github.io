// FleetLink Mobirise Javascript 
//Randy King 5/25/2017
// default Interest with reasonable values for SN404
var target = "SN403";
var gateway = "SN403";
var wiFiSSID = "";

var interest = {
    'usng': "21566247",
    'deviceIdHash' : "018C268ECB5B",
    'rw': 'read',
    'category': 'modbus',
    'task': 'fc03',
    'parameters': '64_C3A50001_9600_8_1',
    'url' : "https://agent.electricimp.com/wXqOLIl3KiLB",
}

var displayFactors = {
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
//----------------------------------------------------------------------------------

// R&D development units - 918.5 MHz
//----------------------------------------------------------------------------------
//SN                     DeviceIdHash    Agent URL       USNG Location   DeviceID
//----------------------------------------------------------------------------------

//SN402 [Shirlie]        D85F6461EB91    /oHMQMg_lcxsT   21016306        56dc4c
//SN403 [Carriage Ln]    018C268ECB5B    /wXqOLIl3KiLB   21566247        56dd24
//SN404 [Sugi Outside]   2BF6EF3EFD90    /QGO7JQAzyiev   21236282        56ddc8
//SN405 [Gibson]         718A34D8423A    /CyPoe3l9E5Od   21426258        56ddb2
//SN406 [Beckman]        C5F6371C8A03    /hxsSiYETEEpd   21896255        56dd18
//SN407 [Sugi Inside]    4CA33E88EDAA    /VifAbahCX8ux   21226282        56ddde
//SN504 [Corbett Cir]    B930FA057CB6    /w8Bdk3n0iWt3   20706278        5728d2
//SN508 [Kiva Pl]        730D72A6E22F    /2866vQYBgUpC   20916258        572874

// Larkfield demo - 915.5 MHz
//----------------------------------------------------------------------------------
//SN                     DeviceId        Agent URL       USNG Location
//----------------------------------------------------------------------------------
//SN503  Shirlie         4E562573DBA0    /tRNE2WbS2CGw   21016306
//SN505  Sugi Outside    BA48D077C2A8    /RVKEMRdCLmKj   21226282
//SN507  Gibson          67AE0AAFD4E2    /S6QExe1f2KTi   21426258
//SN509  Sugi Inside     16240A06C1FC    /D1PRYwJmmHAi   21236282
//SN512  Beckman         6917511534FD    /kRQMPFuKmzDM   21896255

// Customer demo houses - 917 MHz
//----------------------------------------------------------------------------------
//SN                     DeviceId        Agent URL       USNG Location
//----------------------------------------------------------------------------------
//SN506  Blue House      C3B996B9F76C    /oGQ_PBSAUppO   
//SN513  Black House     DF04146F1DF0    /ZT8GBL-7RrgD
//SN514  Yellow House    00E329B56259    /609atPXTxkX7


// Manufacturing - 915.5 MHz
//----------------------------------------------------------------------------------
//SN                     DeviceId        Agent URL       USNG Location
//----------------------------------------------------------------------------------
//SN501
//SN502
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
            interest.url = "https://agent.electricimp.com/VifAbahCX8ux";
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
    updateParamTable(target,interest,displayFactors,gateway);

  }




// Choose target unit
function setTarget(requestedTarget) {
    target = requestedTarget;
    switch(requestedTarget) {
// PROTO 4'S
        case "SN402":
            interest.deviceIdHash = "D85F6461EB91";
            interest.usng = "21016306";
             break;
        case "SN403":
            interest.deviceIdHash = "018C268ECB5B";
            interest.usng = "21566247";
            break;
        case "SN404":
            interest.deviceIdHash = "2BF6EF3EFD90";
            interest.usng = "21236282";
            break;
        case "SN405":
            interest.deviceIdHash = "718A34D8423A";
            interest.usng = "21426258";
            break;
        case "SN406":
            interest.deviceIdHash = "C5F6371C8A03";
            interest.usng = "21896255";
            break;
        case "SN407":
            interest.deviceIdHash = "4CA33E88EDAA";
            interest.usng = "21226282";
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
            interest.usng = "21016306";
            break;
        case "SN504":
            interest.deviceIdHash = "B930FA057CB6";
            interest.usng = "20706278";
            break;
        case "SN505":
            interest.deviceIdHash = "BA48D077C2A8";
            interest.usng = "21226282";
            break;
        case "SN506":
            interest.deviceIdHash = "C3B996B9F76C";
            break;
        case "SN507":
            interest.deviceIdHash = "67AE0AAFD4E2";
            interest.usng = "21426258";
            break;
        case "SN508":
            interest.deviceIdHash = "730D72A6E22F";
            interest.usng = "20916258";
            break;
        case "SN509":
            interest.deviceIdHash = "16240A06C1FC";
            interest.usng = "21236282";
            break;
        case "SN510":
            interest.deviceIdHash = "";
            break;
        case "SN511":
            interest.deviceIdHash = "C1B16ADC8E57";
            break;
        case "SN512":
            interest.deviceIdHash = "6917511534FD";
            interest.usng = "21896255";
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
    updateParamTable(target,interest,displayFactors,gateway);

}

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


// Read the Modbus, built from SunSpec register map
function readSunSpec(sunSpecName){
    interest.rw = 'read';
    interest.category = 'modbus';
    interest.task = 'fc03';
    switch(sunSpecName) {
    //================================================================================
    // COMMON
    //================================================================================
        case "Mn":
            interest.parameters = '64_C3540010_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 37;
            displayFactors.dataFormat = 'ascii';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Manufacturer";
            break;
        case "Md":
            interest.parameters = '64_C3640010_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 37;
            displayFactors.dataFormat = 'ascii';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Model";
            break;
        case "Opt":
            interest.parameters = '64_C3740008_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 21;
            displayFactors.dataFormat = 'ascii';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Option";
            break;    
        case "Vr":
            interest.parameters = '64_C37C0008_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 21;
            displayFactors.dataFormat = 'ascii';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Version";
            break;    
        case "SN":
            interest.parameters = '64_C3840010_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 37;
            displayFactors.dataFormat = 'ascii';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Serial Number";
            break;    
        case "DA":
            interest.parameters = '64_C3940001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Device Address";
            break;  
    //================================================================================
    // CURRENT
    //================================================================================
        case "M_AC_Current":
            interest.parameters = '64_C3970001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "AC Current (sum of active phases)";
            break;
        case "M_AC_Current_A":
            interest.parameters = '64_C3980001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "Phase A AC Current";
            break;
        case "M_AC_Current_B":
            interest.parameters = '64_C3A80001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "Phase B AC Current";
            break;            
        case "M_AC_Current_C":
            interest.parameters = '64_C3B80001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "Phase C AC Current";
            break;    
        case "M_AC_Current":
            interest.parameters = '64_C3970001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "AC Current (sum of active phases)";
            break;
        case "M_AC_Current_A":
            interest.parameters = '64_C3980001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "Phase A AC Current";
            break;
        case "M_AC_Current_B":
            interest.parameters = '64_C3A80001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "Phase B AC Current";
            break;            
        case "M_AC_Current_C":
            interest.parameters = '64_C3B80001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'A';
            displayFactors.displayName = "Phase C AC Current";
            break;               
    //================================================================================
    // VOLTAGE
    //================================================================================
    // LINE TO NEUTRAL
    //================================================================================        
        case "M_AC_Voltage_LN":
            interest.parameters = '64_C39C0001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Line to Neutral AC Voltage (average of active phases)";
            break;
        case "M_AC_Voltage_AN":
            interest.parameters = '64_C39D0001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Phase A to Neutral AC Voltage";
            break;
        case "M_AC_Voltage_BN":
            interest.parameters = '64_C39E0001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Phase B to Neutral AC Voltage";
            break;                        
        case "M_AC_Voltage_CN":
            interest.parameters = '64_C39F0001_9600_8_1';
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
            interest.parameters = '64_C3A00001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Line to Line AC Voltage (average of active phases)";
            break;
        case "M_AC_Voltage_AB":
            interest.parameters = '64_C3A10001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Phase A to Phase B AC Voltage";
            break;
        case "M_AC_Voltage_BC":
            interest.parameters = '64_C3A20001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Phase B to Phase C AC Voltage";
            break;     
        case "M_AC_Voltage_CA":
            interest.parameters = '64_C3A30001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'V';
            displayFactors.displayName = "Phase C to Phase A AC Voltage";
            break;                                                         
    //================================================================================
    // FREQUENCY
    //================================================================================
        case "M_AC_Freq":
            interest.parameters = '64_C3A50001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 0.01;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Hz';
            displayFactors.displayName = "AC Frequency";
            break;
    //================================================================================
    // POWER
    //================================================================================
    // REAL
    //================================================================================             
        case "M_AC_Power":
            interest.parameters = '64_C3A70001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'W';
            displayFactors.displayName = "Total Real Power(sum of active phases)";
            break;
        case "M_AC_Power_A":
            interest.parameters = '64_C3A80001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'W';
            displayFactors.displayName = "Phase A AC Real Power";
            break;
        case "M_AC_Power_B":
            interest.parameters = '64_C3A90001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'W';
            displayFactors.displayName = "Phase B AC Real Power";
            break;
        case "M_AC_Power_C":
            interest.parameters = '64_C3AA0001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'W';
            displayFactors.displayName = "Phase C AC Real Power";
            break;
    //================================================================================
    // POWER
    //================================================================================
    // APPARENT
    //================================================================================  
        case "M_AC_VA":
            interest.parameters = '64_C3AC0001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VA';
            displayFactors.displayName = "Total AC Apparent Power(sum of active phases)";
            break;
        case "M_AC_VA_A":
            interest.parameters = '64_C3AD0001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VA';
            displayFactors.displayName = "Phase A AC Apparent Power";
            break;
        case "M_AC_VA_B":
            interest.parameters = '64_C3AE0001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VA';
            displayFactors.displayName = "Phase B AC Apparent Power";
            break;
        case "M_AC_VA_C":
            interest.parameters = '64_C3AF0001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VA';
            displayFactors.displayName = "Phase C AC Apparent Power";
            break;
    //================================================================================
    // POWER
    //================================================================================
    // REACTIVE
    //================================================================================     
        case "M_AC_VAR":
            interest.parameters = '64_C3B10001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAR';
            displayFactors.displayName = "Total AC Reactive Power(sum of active phases)";
            break;
        case "M_AC_VAR_A":
            interest.parameters = '64_C3B20001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAR';
            displayFactors.displayName = "Phase A AC Reactive Power";
            break;
        case "M_AC_VAR_B":
            interest.parameters = '64_C3B30001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAR';
            displayFactors.displayName = "Phase B AC Reactive Power";
            break;
        case "M_AC_VAR_C":
            interest.parameters = '64_C3B40001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 10;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAR';
            displayFactors.displayName = "Phase C AC Reactive Power";
            break;
    //================================================================================
    // POWER FACTOR
    //================================================================================
        case "M_AC_PF":
            interest.parameters = '64_C3B60001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Average Power Factor(average of active phases)";
            break;
        case "M_AC_PF_A":
            interest.parameters = '64_C3B70001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Phase A Power Factor";
            break;
        case "M_AC_PF_B":
            interest.parameters = '64_C3B80001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Phase B Power Factor";
            break;
        case "M_AC_PF_C":
            interest.parameters = '64_C3B90001_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 9;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = "Phase C Power Factor";
            break;
    //================================================================================
    // ACCUMULATED REAL ENERGY
    //================================================================================
    // EXPORTED
    //================================================================================ 
        case "M_Exported":
            interest.parameters = '64_C3BB0002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Total Exported Real Energy";
            break;
        case "M_Exported_A":
            interest.parameters = '64_C3BD0002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Phase A Exported Real Energy";
            break;
        case "M_Exported_B":
            interest.parameters = '64_C3BF0002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Phase B Exported Real Energy";
            break;
        case "M_Exported_C":
            interest.parameters = '64_C3C10002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Phase C Exported Real Energyy";
            break; 
    //================================================================================
    // ACCUMULATED REAL ENERGY
    //================================================================================
    // IMPORTED
    //================================================================================     
        case "M_Imported":
            interest.parameters = '64_C3C30002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Total Imported Real Energy";
            break;
        case "M_Imported_A":
            interest.parameters = '64_C3C50002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Phase A Imported Real Energy";
            break;
        case "M_Imported_B":
            interest.parameters = '64_C3C70002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Phase B Imported Real Energy";
            break;
        case "M_Imported_C":
            interest.parameters = '64_C3C90002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'Wh';
            displayFactors.displayName = "Phase C Imported Real Energy";
            break;  
    //================================================================================
    // ACCUMULATED APPARENT ENERGY
    //================================================================================
    // EXPORTED
    //================================================================================      
        case "M_Exported_VA":
            interest.parameters = '64_C3CC0002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Total Imported Real Energy";
            break;
        case "M_Exported_VA_A":
            interest.parameters = '64_C3CE0002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Phase A Exported Apparent Energy";
            break;
        case "M_Exported_VA_B":
            interest.parameters = '64_C3D00002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Phase B Exported Apparent Energy";
            break;
        case "M_Exported_VA_C":
            interest.parameters = '64_C3D20002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Phase C Exported Apparent Energy";
            break;                                   
    //================================================================================
    // ACCUMULATED APPARENT ENERGY
    //================================================================================
    // IMPORTED
    //================================================================================      
        case "M_Imported_VA":
            interest.parameters = '64_C3D40002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Total Imported Apparent Energy";
            break;
        case "M_Imported_VA_A":
            interest.parameters = '64_C3D60002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Phase A Imported Apparent Energy";
            break;
        case "M_Imported_VA_B":
            interest.parameters = '64_C3D80002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Phase B Imported Apparent Energy";
            break;
        case "M_Imported_VA_C":
            interest.parameters = '64_C3DA0002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VAh';
            displayFactors.displayName = "Phase C Imported Apparent Energy";
            break; 

    //================================================================================
    // ACCUMULATED REACTIVE ENERGY
    //================================================================================
    // IMPORTED
    //================================================================================      
        case "M_Import_VARh_Q1":
            interest.parameters = '64_C3DD0002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Quadrant 1: Total Imported Reactive Energyy";
            break;
        case "M_Import_VARh_Q1A":
            interest.parameters = '64_C3DF0002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase A - Quadrant 1: Imported Reactive Energy";
            break;
        case "M_Import_VARh_Q1B":
            interest.parameters = '64_C3E10002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase B - Quadrant 1: Imported Reactive Energyy";
            break;
        case "M_Import_VARh_Q1C":
            interest.parameters = '64_C3E30002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase C - Quadrant 1: Imported Reactive Energy";
            break; 
        case "M_Import_VARh_Q2":
            interest.parameters = '64_C3E50002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Quadrant 2: Total Imported Reactive Energy";
            break;
        case "M_Import_VARh_Q2A":
            interest.parameters = '64_C3E70002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase A - Quadrant 2: Imported Reactive Energy";
            break;
        case "M_Import_VARh_Q2B":
            interest.parameters = '64_C3E90002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase B - Quadrant 2: Imported Reactive Energy";
            break;
        case "M_Import_VARh_Q2C":
            interest.parameters = '64_C3EB0002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase C - Quadrant 2: Imported Reactive Energy";
            break;             
    //================================================================================
    // ACCUMULATED REACTIVE ENERGY
    //================================================================================
    // EXPORTED
    //================================================================================   
        case "M_Export_VARh_Q3":
            interest.parameters = '64_C3ED0002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Quadrant 3: Total Exported Reactive Energy";
            break;
        case "M_Export_VARh_Q3A":
            interest.parameters = '64_C3EF0002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase A - Quadrant 3: Exported Reactive Energy";
            break;
        case "M_Export_VARh_Q3B":
            interest.parameters = '64_C3F10002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase B - Quadrant 3: Exported Reactive Energy";
            break;
        case "M_Export_VARh_Q3C":
            interest.parameters = '64_C3F30002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase C - Quadrant 3: Exported Reactive Energy";
            break; 
            case "M_Export_VARh_Q4":
            interest.parameters = '64_C3F50002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Quadrant 4: Total Exported Reactive Energyy";
            break;
        case "M_Export_VARh_Q4A":
            interest.parameters = '64_C3F70002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase A - Quadrant 4: Exported Reactive Energy";
            break;
        case "M_Export_VARh_Q4B":
            interest.parameters = '64_C3F90002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase B - Quadrant 4: Exported Reactive Energy";
            break;
        case "M_Export_VARh_Q4C":
            interest.parameters = '64_C3FB0002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'VARh';
            displayFactors.scaleFactor = 1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = 'VARh';
            displayFactors.displayName = "Phase C - Quadrant 4: Exported Reactive Energy";
            break; 
    //================================================================================
    // EVENTS
    //================================================================================       
        case "M_Events":
            interest.parameters = '64_C3FE0002_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 13;
            displayFactors.dataFormat = 'hex';
            displayFactors.scaleFactor =  1;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = 'M_EVENT_ flags';
            break; 
    //================================================================================
    // EVENTS
    // If command not implemented, display requested name but return Manufacturer's name
    // This is something any SunSpec equipment can do
    //================================================================================   
        default:
            interest.parameters = '64_C3540010_9600_8_1';
            displayFactors.firstDataChar = 6;
            displayFactors.lastDataChar = 37;
            displayFactors.dataFormat = 'ascii';
            displayFactors.scaleFactor = 0;
            displayFactors.offsetFactor = 0;
            displayFactors.unitString = '';
            displayFactors.displayName = sunSpecName;    } 

    updateParamTable(target,interest,displayFactors,gateway);
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
            // apply scale factor and offset
            numericData = numericData * displayFactors.scaleFactor + displayFactors.offsetFactor;
            // Add units string at end of data
            returnDataString = numericData + " " + displayFactors.unitString;
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



function updateParamTable(target, interest, displayFactors, gatewayID){
    var x = document.getElementById("paramTable").rows[1].cells;
    x[0].innerHTML = gateway;
    x[1].innerHTML = displayFactors.displayName;
    x[2].innerHTML = target;
}

// read the web UI to determine the unit that is being targeted
function expressInterest(buttonID) {

// Trap the special case of write the geolocation to a unit, which uses fixed predefined geolocation in the Interest
// Until you write a unit's geolocation into flash, you wouldn;t know what usng to use to address it, otherwise
var tempUSNG = interest.usng; // First save the unit's expected geolocation temporarily (will put back after Express Interest below)
if (interest.rw == 'write'&& interest.category == 'flash' && interest.task == 'geoSelf'){
    interest.usng = '45898592'; // predefined geolocation used for writing actual geolocation to flash
}

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
        timeout: 35000,
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
    interest.usng = tempUSNG ; // Return the unit's expected geolcation 

    }

      $( window ).on( "load", function() {
        updateParamTable(target,interest,displayFactors,gateway);
        console.log("page loaded");
    });
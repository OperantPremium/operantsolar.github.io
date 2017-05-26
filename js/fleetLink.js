// FleetLink Mobirise Javascript 
//Randy King 5/25/2017
// default Interest with reasonable values for SN404
var target = "SN404";
var gateway = "SN404";
var wiFiSSID = "";

var interest = {
    'usng': "28475668",
    'deviceIdHash' : "2BF6EF3EFD90",
    'rw': 'read',
    'category': 'wiFi',
    'task': 'scan',
    'parameters': '',
    'url' : "https://agent.electricimp.com/QGO7JQAzyiev"
}


// Agent URLs as reference for GATEWAY
//SN402 = /oHMQMg_lcxsT
//SN403 = /wXqOLIl3KiLB
//SN404 = /QGO7JQAzyiev
//SN405 = /CyPoe3l9E5Od
//SN406 = /hxsSiYETEEpd
//SN407 = /VifAbahCX8ux
//SN506 (Blue) = /oGQ_PBSAUppO
//SN508 (Orange) = /2866vQYBgUpC
//SN509 (Green) = /D1PRYwJmmHAi
//SN513 (Black) = /ZT8GBL-7RrgD
//SN514 (Yellow) = /609atPXTxkX7
//SN515 = /VRa-gimZfDGJ

// Choose gateway unit
function setGateway(requestedGateway) {
    gateway = requestedGateway;
    switch(requestedGateway) {
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
        default:
            interest.url = "https://agent.electricimp.com/VifAbahCX8ux";
    }
    console.log("Setting gateway to " + requestedGateway);
  }


// Choose the SSID of the network to scane
function chooseNetwork(){
    wiFiSSID = prompt("Desired SSID?", "");
    //console.log("User chose SSID: " + wiFiSSID);

    interest.rw = 'read';
    interest.category = 'wiFi';
    interest.task = 'scan';
    interest.parameters = wiFiSSID;
}

// Device ID hashes as reference for TARGET
//SN402 = D85F6461EB91
//SN403 = 018C268ECB5B
//SN404 = 2BF6EF3EFD90
//SN405 = 718A34D8423A
//SN406 = C5F6371C8A03
//SN407 = 4CA33E88EDAA
//SN506 (Blue) = C3B996B9F76C
//SN508 (Orange) = 730D72A6E22F
//SN509 (Green) = 16240A06C1FC
//SN513 (Black) = DF04146F1DF0
//SN514 (Yellow) = 00E329B56259
//SN515 = 4E44238D7110

// Choose target unit
function setTarget(requestedTarget) {
    target = requestedTarget;
    switch(requestedTarget) {
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
        default:
            interest.deviceIdHash = "2BF6EF3EFD90";
            console.log("Setting target to default");
    }
    console.log("Setting target to " + requestedTarget); 

}


// read the web UI to determine the unit that is being targeted
    function getRSSI(buttonID) {
        // Add the SSID as a parameter
        //interest.parameters = wiFiSSID;
        console.log(interest);

        var waitDisplay = "Scanning " + target;
        if (target != gateway){
            waitDisplay += " via " + gateway ;
        }

       buttonID.style.background='#1474BF';

        // actual web POST
        $.ajax({
            url: interest.url,
            timeout: 15000,
            data: JSON.stringify(interest), // convert interest string to JSON
            type: 'POST',
              success : function(response) {
                    var successDisplay = target + ": " + response;
                    if (target != gateway){
                        successDisplay += " via " + gateway;
                    }
                    console.log(successDisplay);
                    buttonID.innerHTML = successDisplay;
                    buttonID.style.background='#90A878';
              },
              error : function(jqXHR, textStatus, err) {
                    //var errorResponse = jqXHR.status + ' ' + textStatus + ': ' + err + ' - ' + jqXHR.responseText;
                    var errorResponse = err + ' - ' + jqXHR.responseText;

                    console.log(errorResponse);
                    buttonID.innerHTML = errorResponse;
                    buttonID.style.background='#90A878';
              }
        });

        buttonID.innerHTML = waitDisplay;
      }

// FleetLink Mobirise Javascript 
//Randy King 5/25/2017
// default Interest with reasonable values for SN404
var target = "SN404";
var gateway = "SN404";
var interest = {
    'usng': "28475668",
    'deviceIdHash' : "2BF6EF3EFD90",
    'rw': 'read',
    'category': 'wiFi',
    'task': 'scan',
    'parameters' : '',
    'url' : "https://agent.electricimp.com/QGO7JQAzyiev"
}

// Choose gateway unit
function setGateway(requestedGateway) {
    gateway = requestedGateway;
    switch(requestedGateway) {
        case "SN403":
            interest.url = "https://agent.electricimp.com/wXqOLIl3KiLB";
            console.log("Setting gateway to SN403");
            break;
        case "SN404":
            interest.url = "https://agent.electricimp.com/QGO7JQAzyiev";
            console.log("Setting gateway to SN404");
            break;
        case "SN406":
            interest.url = "https://agent.electricimp.com/hxsSiYETEEpd";
            console.log("Setting gateway to SN406");
            break;            
        default:
            interest.url = "https://agent.electricimp.com/QGO7JQAzyiev";
            console.log("Setting gateway to default");
    }
  }

// Choose target unit
function setTarget(requestedTarget) {
    target = requestedTarget;
    switch(requestedTarget) {
        case "SN403":
            interest.deviceIdHash = "018C268ECB5B";
            console.log("Setting target to SN403");
            break;
        case "SN404":
            interest.deviceIdHash = "2BF6EF3EFD90";
            console.log("Setting target to SN404");
            break;
        case "SN406":
            interest.deviceIdHash = "C5F6371C8A03";
            console.log("Setting target to SN406");
            break;
        default:
            interest.deviceIdHash = "2BF6EF3EFD90";
            console.log("Setting target to default");
    }
}


// read the web UI to determine the unit that is being targeted
    function getRSSI(context) {

        var waitDisplay = "...Scan WiFi of " + target;
        if (target != gateway){
            waitDisplay += " (via " + gateway + ")";
        }
        else {
            waitDisplay += " (direct)"
        }


        // actual web POST
        $.ajax({
            url: interest.url,
            timeout: 15000,
            data: JSON.stringify(interest), // convert interest string to JSON
            type: 'POST',
              success : function(response) {
                  var successDisplay = target + ": " + response;
                  if (target != gateway){
                      successDisplay += " (via " + gateway + ")";
                  }
                  else {
                    successDisplay += " (direct)"
                  }
                  console.log(successDisplay);
                  context.innerHTML = successDisplay;
              },
              error : function(jqXHR, textStatus, err) {
                  var errorResponse = jqXHR.status + ' ' + textStatus + ': ' + err + ' - ' + jqXHR.responseText;
                  console.log(errorResponse);
                  context.innerHTML = "Error";
              }
        });

        context.innerHTML = waitDisplay;
      }

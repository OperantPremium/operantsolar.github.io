// FleetLink app
//Randy King 1/4/2016


// Variable setup and default values



// read the web UI to determine the unit that is being targeted
    function getRSSI(context) {
      console.log("Getting RSSI");
      var RSSI = -46;
      // default Interest with reasonable values for SN404

      var interest = {
            'usng': "28475668",
            'deviceIdHash' : "2BF6EF3EFD90",
            'rw': 'read',
            'category': 'wiFi',
            'task': 'scan',
            'parameters' : 'Operant',
      }
      
      // actual web POST
      $.ajax({
          url: "https://agent.electricimp.com/QGO7JQAzyiev",
          timeout: 15000,
          data: JSON.stringify(interest), // convert interest string to JSON
          type: 'POST',
          success : function(response) {
            console.log("response: " + response);
            console.log(response);
            context.innerHTML = response;
            },
          error : function(jqXHR, textStatus, err) {
            var errorResponse = jqXHR.status + ' ' + textStatus + ': ' + err + ' - ' + jqXHR.responseText;
            console.log(errorResponse);
          }
        });


      context.innerHTML = "Scanning...";
      }

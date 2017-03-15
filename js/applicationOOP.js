// FleetLink app
//Randy King 1/4/2016


// Variable setup and default values

var baseURL = "https://agent.electricimp.com";

var mapFleetLink;
var myLatLng = {lat: 38.491, lng: -122.717};
var routePath1;
var routePath2;
var routeCoordinates1 = [];
var routeCoordinates2 = [];
var routeColor1 = '#33FF66'; //'rgb(0,128,255)'
var routeColor2 = '#33FF66'; //'rgb(0,128,255)'
var wifiOn;
var targetCoordinates;
var targetColor = '#33FF66';

var targetUnitKey;
var accessUnitKey;

var fleetLink = {
          1: {
            'serialNumber': '402',  // only use last 8 digits of MAC to save packet characters
            'macAddress': '56dc4c',
            'agentURL': '/oHMQMg_lcxsT',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300320002',
            'onlineStatus': true,
            'position' : {lat: 38.490,lon: -122.7226}
              },
          2: {
            'serialNumber': '403',
            'macAddress': '56dd24',
            'agentURL': '/wXqOLIl3KiLB',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300320002',
            'onlineStatus': true,
            'position' : {lat: 38.492, lon: -122.721}
              },
          3: {
            'serialNumber': '404',
            'macAddress': '56ddc8',
            'agentURL': '/QGO7JQAzyiev',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300320002',
            'onlineStatus': true,
            'position' : {lat: 38.491, lon: -122.7135}
          },

          4: {
            'serialNumber': '405',
            'macAddress': '56ddb2',
            'agentURL': '/CyPoe3l9E5Od',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300320002',
            'onlineStatus': true,
            'position' : {lat: 38.4898, lon: -122.7181}
          },

            5: {
            'serialNumber': '407',
            'macAddress': '56ddde',
            'agentURL': '/VifAbahCX8ux',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300320002',
            'onlineStatus': false,
            'position' : {lat: 38.4882, lon: -122.716}
          } /*,
          6: {
            'serialNumber': 'F',
            'macAddress': '0c2a690a2d54',
            'agentURL': '/uEIDmJoynW-o',
            'onlineStatus': true,
            'position' : {lat: 38.495, lon: -122.706}
          }*/

    };

    var interestPacket = {
          'GeoLoc': "18SUJ22850705",
          'DeviceIdHash' : "123456",
          'ModbusCmd' : "010300240002"
    }

    function updateAccessPointAndTargetKeys()
    {
      // Unit is specified by Serial Number in browser, but we need the MAC address for the interest packet
      targetUnitSerialNumber = document.getElementById("selectedUnit").value;
      accessUnitSerialNumber = document.getElementById("selectedAccessPoint").value ;
      Object.keys(fleetLink).forEach(function(key,index){
            // key: the name of the object key
            // index: the ordinal position of the key within the object
            if (fleetLink[key].serialNumber == targetUnitSerialNumber) {
              targetUnitKey = key; // This is a global variable I use throughout: the site we want data from
            }
            if (fleetLink[key].serialNumber == accessUnitSerialNumber) {
              accessUnitKey = key;// This is a global variable I use throughout: the site we're sending the interest packet to first
            }
      });
    }

    function buildInterestPacket() {
      // Unit is specified by Serial Number in browser, but we need the MAC address for the interest packet
      targetUnitSerialNumber = document.getElementById("selectedUnit").value;
      accessUnitSerialNumber = document.getElementById("selectedAccessPoint").value ;
      //console.log("Target: " + targetUnitSerialNumber + " gateWay: " + accessUnitSerialNumber);
      Object.keys(fleetLink).forEach(function(key,index){
            // key: the name of the object key
            // index: the ordinal position of the key within the object
            if (fleetLink[key].serialNumber == targetUnitSerialNumber) {
              targetUnitKey = key; // This is a global variable I use throughout: the site we want data from
            }
            if (fleetLink[key].serialNumber == accessUnitSerialNumber) {
              accessUnitKey = key;// This is a global variable I use throughout: the site we're sending the interest packet to first
            }
      });
      switch (document.getElementById("dataModel").value) {
        case "c":
        break;
        case "s":
        break;
        case "m":
          interestPacket.GeoLoc = fleetLink[targetUnitKey].geoLoc;
          interestPacket.DeviceIdHash = fleetLink[targetUnitKey].macAddress;
          interestPacket.ModbusCmd = fleetLink[targetUnitKey].modbusCmd;
        break;
        case "f":
        break;
        default:
          console.log("data model not recognized")
      }
      interestPacket.name ;
    }


    function clearDisplay() {
        routePath1.setMap(null);
        routePath2.setMap(null);
        targetCircle.setMap(null);
        document.getElementById("stringDataRepresentation").textContent = "--";
    }


    function expressInterestPacket() {
      // disable the Go button
      document.getElementById("expressInterestPacket").disabled = "disabled";
      //clearDisplay();
      // play a swoosh
      new Audio("img/swoosh.mp3").play();
      buildInterestPacket();
      //console.log("Packet: " + JSON.stringify(interestPacket));
      $.ajax({
      // send the interest packet to the selected agent and expect a data packet in response
          url: baseURL + fleetLink[accessUnitKey].agentURL,
          timeout: 15000,
          data: JSON.stringify(interestPacket), // convert interest packet string to JSON
          //dataType: 'json',
          //contentType: "application/json",
          type: 'POST',
          success : function(response) {
              //document.getElementById("expressInterestPacket").disabled = false; // re-enable the Go button
              console.log("response: " + response);
                //if ('data' in response) {
                  //console.log(dataTable);
                  //var dataTable = JSON.parse(response.data);
                  displayData(response);

                  //traceRoute(dataTable.trace); //display the route trace
                  new Audio("img/smallBell2.wav").play();  // sound chime to indicate successful data packet reception
                  setTimeout(function(){document.getElementById("expressInterestPacket").disabled = false;}, 10000 );
                //}
          },
          error : function(jqXHR, textStatus, err) {

              var errorResponse = jqXHR.status + ' ' + textStatus + ': ' + err + ' - ' + jqXHR.responseText;
//               document.getElementById("returnedDataPacket").textContent = errorResponse;
              setTimeout(function(){document.getElementById("expressInterestPacket").disabled = false;}, 10000 );
          }
        });
      }

      function displayData(response) {
        document.getElementById("stringDataRepresentation").value = response;
      }

      function drawMarker(fleetLinkKey) {
        var markerLat = fleetLink[fleetLinkKey].position.lat;
        var markerLng = fleetLink[fleetLinkKey].position.lon;
        //console.log("At DrawMarker " + markerLat + "  " + markerLng + " online? " + fleetLink[fleetLinkKey].onlineStatus)
        var markerLatLng = {lat: markerLat, lng: markerLng};
        var iconImage;

        // choose marker based on online status and whether access point
        if (fleetLink[fleetLinkKey].onlineStatus) {
            if(fleetLinkKey == accessUnitKey) {
              iconImage = "img/iconOnlineAccess.png";
            } else {
              iconImage = "img/iconOnlineHouse.png";
            }
        } else {
              iconImage = "img/iconOfflineHouse.png";
        }
      }

      function updateMarkers() {
           //console.log("updating map..");
           //clearDisplay();
           buildInterestPacket();
           // for (var key in fleetLink) {
           //     drawMarker(key);
           // }
      }

      function updatewifiOn()
      {
         wifiOn = [null];
         var wifiItems = document.getElementsByName("chk_group[]");
         for(var i = 0; i < wifiItems.length; i++)
         {
            if (wifiItems[i].checked) {
              wifiOn[i] = wifiItems[i];
            }
         }
         //update the display area show devices that have wifi on..
         //alert("wifiOn; " + wifiOn.length);
      }

      function traceRoute(trace)   {

            routeCoordinates1 = [null];
            var lineSymbol = {
                path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW
            };

            for (var i=0; i<= Math.floor(trace.length/2); i++) {
                var thisSerialNumber = trace.slice(i,i+1);
                for (var key in fleetLink) {
                    if (fleetLink[key].serialNumber == thisSerialNumber) {
                        routeCoordinates1[i] = new google.maps.LatLng({lat: fleetLink[key].position.lat, lng: fleetLink[key].position.lon});
                    }
                }
            }

            routePath1 = new google.maps.Polyline({
            path: routeCoordinates1,
            icons: [{
                icon: lineSymbol,
                offset: '100%'
            }],
            geodesic: true,
            strokeColor: routeColor1,
            strokeOpacity: 0.8,
            strokeWeight: 2
            });
            routePath1.setMap(mapFleetLink);

            routeCoordinates2 = [null];

            for (var i= 0; i<= Math.floor(trace.length/2); i++) {
                var thisSerialNumber = trace.slice(i + Math.floor(trace.length/2),i + Math.floor(trace.length/2) +1);
                for (var key in fleetLink) {
                    if (fleetLink[key].serialNumber == thisSerialNumber) {
                        routeCoordinates2[i] = new google.maps.LatLng({lat: fleetLink[key].position.lat, lng: fleetLink[key].position.lon});
                    }
                }
            }

            routePath2 = new google.maps.Polyline({
            path: routeCoordinates2,
            icons: [{
                icon: lineSymbol,
                offset: '100%'
            }],
            geodesic: true,
            strokeColor: routeColor2,
            strokeOpacity: 0.8,
            strokeWeight: 2
            });
            routePath2.setMap(mapFleetLink);

            targetCoordinates = new google.maps.LatLng({lat: fleetLink[targetUnitKey].position.lat, lng: fleetLink[targetUnitKey].position.lon});

            targetCircle = new google.maps.Circle({
              strokeColor: targetColor,
              strokeOpacity: 1.0,
              strokeWeight: 3,
              fillColor: "white",
              fillOpacity: 0.0,
              map: mapFleetLink,
              center: targetCoordinates,
              radius: 50
            });


      }

      function initMap() {
        // Draw default map
          mapFleetLink = new google.maps.Map(document.getElementById('map'), {
            zoom: 16,
           mapTypeId: google.maps.MapTypeId.SATELLITE,
            center: myLatLng
          });


          routePath1 = new google.maps.Polyline({
          path: routeCoordinates1,
          geodesic: true,
          strokeColor: routeColor1,
          strokeOpacity: 0.7,
          strokeWeight: 4
          });

          routePath1.setMap(mapFleetLink);

          routePath2 = new google.maps.Polyline({
          path: routeCoordinates2,
          geodesic: true,
          strokeColor: routeColor2,
          strokeOpacity: 0.7,
          strokeWeight: 4
          });

          routePath2.setMap(mapFleetLink);

            targetCircle = new google.maps.Circle({
            strokeColor: targetColor,
            strokeOpacity: 0.8,
            strokeWeight: 2,
            fillColor: "white",
            fillOpacity: 0.15,
            map: mapFleetLink,
            center: targetCoordinates,
            radius: 20
          });

      }

      function showHideControls(){
        var selectedDataModel = document.getElementById("dataModel").value;
        switch(selectedDataModel){
          case "c": // choose
          document.getElementById("sunSpecPanelContainer").style.visibility="hidden";
          document.getElementById("modbusPanelContainer").style.visibility="hidden";
          document.getElementById("fleetlinkPanelContainer").style.visibility="hidden";
          break;
          case "s": // sunspec
          document.getElementById("sunSpecPanelContainer").style.visibility="visible";
          document.getElementById("modbusPanelContainer").style.visibility="hidden";
          document.getElementById("fleetlinkPanelContainer").style.visibility="hidden";
          break;
          case "m": // modbus
          document.getElementById("sunSpecPanelContainer").style.visibility="hidden";
          document.getElementById("modbusPanelContainer").style.visibility="visible";
          document.getElementById("fleetlinkPanelContainer").style.visibility="hidden";
          break;
          case "f": // fleetlink
          document.getElementById("sunSpecPanelContainer").style.visibility="hidden";
          document.getElementById("modbusPanelContainer").style.visibility="hidden";
          document.getElementById("fleetlinkPanelContainer").style.visibility="visible";
          break;
        }
      }

      function getCheckedBoxes(chkboxName) {
        var checkboxes = document.getElementsByName(chkboxName);
        var checkboxesChecked = [];
        // loop over them all
        for (var i=0; i<checkboxes.length; i++) {
          // And stick the checked ones onto an array...
          if (checkboxes[i].checked) {
              checkboxesChecked.push(checkboxes[i]);
          }
        }
        // Return the array if it is non-empty, or null
        return checkboxesChecked.length > 0 ? checkboxesChecked : null;
      }

      function drawImages() {
        var drawing = document.getElementById("_deviceIndicators");
        var con = drawing.getContext("2d");
        var item404 = document.getElementById("404Img");
        con.drawImage(item404, 10, 170, 60, 60);
        var item405 = document.getElementById("405Img");
        con.drawImage(item405, 530, 170, 60, 60);
        var item402 = document.getElementById("402Img");
        con.drawImage(item402, 270, 10, 60, 60);
        var item403 = document.getElementById("403Img");
        con.drawImage(item403, 270, 170, 60, 60);
        var item407 = document.getElementById("403Img");
        con.drawImage(item407, 270, 330, 60, 60);

        //get selected Unit
        updateAccessPointAndTargetKeys();
        var accPointImg = document.getElementById("_gatewayIcon");
        var targetImg = document.getElementById("_targetIcon");
        var x = 0;
        var y = 0;
        //console.log("AccessPointKey: " + accessUnitKey);
        switch(fleetLink[accessUnitKey].serialNumber) {
          case "402":
            x = 270;
            y = 80;
          break;
          case "403":
            x = 270;
            y = 240;
          break;
          case "404":
            x = 10;
            y = 240
          break;
          case "405":
            x = 530;
            y = 240;
          break;
          case "407":
            x = 270;
            y = 260;
          break;
        }
        con.drawImage(accPointImg, x, y, 60, 60);
        x = 0;
        y = 0;
        //console.log("TargetKey: " + targetUnitKey);
        switch(fleetLink[targetUnitKey].serialNumber) {
          case "402":
            x = 270;
            y = 80;
          break;
          case "403":
            x = 270;
            y = 240;
          break;
          case "404":
            x = 10;
            y = 240
          break;
          case "405":
            x = 530;
            y = 240;
          break;
          case "407":
            x = 270;
            y = 260;
          break;
        }
        con.drawImage(targetImg, x, y, 60, 60);

        //get checked checkboxesvar 
        var checkedBoxes = getCheckedBoxes("chk_group[]");
        for (var i = 0; i < checkedBoxes.length; i++) {
          //draw wifi red or green
          //console.log(checkedBoxes[i].value); 
        }
      }

      $( document ).ready(function() {
          // Do the following after the page is ready
          //console.log( "Initializing..." );
          //initMap();
          drawImages();
          document.getElementById("dataModel").value = "m" ; // default to Modbus data model
          showHideControls();
          buildInterestPacket();
          updateMarkers();
          document.getElementById("expressInterestPacket").disabled = "disabled";
          setTimeout(function(){document.getElementById("expressInterestPacket").disabled = false;}, 100 );
          });

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
var targetCoordinates;
var targetColor = '#33FF66';

var targetUnitKey;
var accessUnitKey;
var edgeDist = 30;
var imgSize = 70;
var targetGatewaySize = 40;
var wifiImgSize = 40;
var targetGatewayOffset = 2;

var fleetLink = {
          1: {
            'serialNumber': '402',  // only use last 8 digits of MAC to save packet characters
            'macAddress': '56dc4c',
            'agentURL': '/oHMQMg_lcxsT',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300240002',
            'onlineStatus': true,
            'sensorScale' : 1.0,
            'position' : {lat: 38.490,lon: -122.7226}
              },
          2: {
            'serialNumber': '403',
            'macAddress': '56dd24',
            'agentURL': '/wXqOLIl3KiLB',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300240002',
            'onlineStatus': true,
            'sensorScale' : 1.0,
            'position' : {lat: 38.492, lon: -122.721}
              },
          3: {
            'serialNumber': '404',
            'macAddress': '56ddc8',
            'agentURL': '/QGO7JQAzyiev',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300240002',
            'onlineStatus': true,
            'sensorScale' : 0.956,
            'position' : {lat: 38.491, lon: -122.7135}
          },

          4: {
            'serialNumber': '405',
            'macAddress': '56ddb2',
            'agentURL': '/CyPoe3l9E5Od',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300240002',
            'onlineStatus': true,
            'sensorScale' : 0.979,
            'position' : {lat: 38.4898, lon: -122.7181}
          },

          5: {
            'serialNumber': '407',
            'macAddress': '56ddde',
            'agentURL': '/VifAbahCX8ux',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300960002',
            'onlineStatus': true,
            'sensorScale' : -1.089,
            'position' : {lat: 38.4882, lon: -122.716}
          }, 

          6: {
            'serialNumber': '406',
            'macAddress': '56dd18',
            'agentURL': '/hxsSiYETEEpd',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300240002',
            'onlineStatus': true,
            'sensorScale' : 1.0,
            'position' : {lat: 38.4882, lon: -122.716}
          } 
    };

    var interestPacket = {
          'GeoLoc': "18SUJ22850705",
          'DeviceIdHash' : "123456",
          'ModbusCmd' : "010300240002"
    }

    function getTargetKey() {
      var targetKey = null;
      targetUnitSerialNumber = document.getElementById("selectedUnit").value;
      Object.keys(fleetLink).forEach(function(key,index){
            // key: the name of the object key
            // index: the ordinal position of the key within the object
            if (fleetLink[key].serialNumber == targetUnitSerialNumber) {
              targetKey = key; // This is a global variable I use throughout: the site we want data from
            }
      });
      return targetKey;
    }

    function getGatewayKey() {
      var gatewayKey = null;
      accessUnitSerialNumber = document.getElementById("selectedAccessPoint").value ;
      Object.keys(fleetLink).forEach(function(key,index){
            // key: the name of the object key
            // index: the ordinal position of the key within the object
            if (fleetLink[key].serialNumber == accessUnitSerialNumber) {
              gatewayKey = key;// This is a global variable I use throughout: the site we're sending the interest packet to first
            }
      }); 
      return gatewayKey;     
    }

    function setGateway (selGateway) {
      //console.log("gateway: " + selGateway);
      var serial = fleetLink[selGateway].serialNumber;
      ccessUnitSerialNumber = document.getElementById("selectedAccessPoint").value = serial;
      accessUnitKey = selGateway;
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
      interestPacket.GeoLoc = fleetLink[targetUnitKey].geoLoc;
      interestPacket.DeviceIdHash = fleetLink[targetUnitKey].macAddress;
      interestPacket.ModbusCmd = fleetLink[targetUnitKey].modbusCmd;
      interestPacket.name;
    }

    function expressInterestPacket() {
      clearResult();
      // disable the Go button
      document.getElementById("expressInterestPacket").disabled = "disabled";
      // play a swoosh
      new Audio("img/swoosh.mp3").play();
      buildInterestPacket();
      //console.log("Packet: " + JSON.stringify(interestPacket));
      $.ajax({
      // send the interest packet to the selected agent and expect a data packet in response
          url: baseURL + fleetLink[accessUnitKey].agentURL,
          timeout: 15000,
          data: JSON.stringify(interestPacket), // convert interest packet string to JSON
          type: 'POST',
          success : function(response) {
            //console.log("response: " + response);
            displayData(response);
            new Audio("img/smallBell2.wav").play();  // sound chime to indicate successful data packet reception
            setTimeout(function(){document.getElementById("expressInterestPacket").disabled = false;}, 10000 );
          },
          error : function(jqXHR, textStatus, err) {
            var errorResponse = jqXHR.status + ' ' + textStatus + ': ' + err + ' - ' + jqXHR.responseText;
//          document.getElementById("returnedDataPacket").textContent = errorResponse;
            setTimeout(function(){document.getElementById("expressInterestPacket").disabled = false;}, 10000 );
          }
        });
      }

      // Display the result fetched after sending the modbus command.
      function displayData(response) {
        if (response != null) {
          //get substring of hex chars.
          var hexStr = response.substring(10,14) + response.substring(6,10);
          var output = parseFloat("0x" + hexStr);
          var result = fleetLink[targetUnitKey].sensorScale * output;
          document.getElementById("stringDataRepresentation").value = result.toFixed(2) + " A";
        }
      }

      // Clear the result from the result display text box
      function clearResult() {
        document.getElementById("stringDataRepresentation").value = "";
      }

      function parseFloat(str) {
          var float = 0, sign, order, mantiss,exp,
          int = 0, multi = 1;
          if (/^0x/.exec(str)) {
              int = parseInt(str,16);
          }else{
              for (var i = str.length -1; i >=0; i -= 1) {
                  if (str.charCodeAt(i)>255) {
                      console.log('Wrong string parametr'); 
                      return false;
                  }
                  int += str.charCodeAt(i) * multi;
                  multi *= 256;
              }
          }
          sign = (int>>>31)?-1:1;
          exp = (int >>> 23 & 0xff) - 127;
          mantissa = ((int & 0x7fffff) + 0x800000).toString(2);
          for (i=0; i<mantissa.length; i+=1){
              float += parseInt(mantissa[i])? Math.pow(2,exp):0;
              exp--;
          }
          return float*sign;
      }

      function updateMarkers() {
        clearResult();
        initGateway();
        drawImages();
        buildInterestPacket();
      }

      function updatewifiOn(){
        var wifiItems = document.getElementsByName("chk_group[]");
        for(var i = 0; i < wifiItems.length; i++) {
          Object.keys(fleetLink).forEach(function(key,index){
            if (wifiItems[i].value == fleetLink[key].serialNumber) {
              if (wifiItems[i].checked) {
                fleetLink[key].onlineStatus = true;
              }
              else {
                fleetLink[key].onlineStatus = false;
              }
            }
          });
         }
         initGateway();
         //update the display area show devices that have wifi on..
         drawImages();
      }

      // Fetch all the Wifi Enabled checkboxes..
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

      // Draw the images of the devices, wifi enabled state in the canvas.
      function drawImages() {
        var drawing = document.getElementById("_deviceIndicators");
        var con = drawing.getContext("2d");
        con.fillStyle = "#f3efe0";
        var width = drawing.width;
        var height = drawing.height;
        var hCent = height/2;
        var wCent = width/2;
        var leftOffset = edgeDist;
        var rightOffset = width - edgeDist;
        var topOffset = edgeDist;
        var bottomOffset = height - edgeDist;
        con.fillRect(0, 0, drawing.width, drawing.height);

        //draw imp devices..
        var item404 = document.getElementById("404Img");
        con.drawImage(item404, edgeDist, hCent - imgSize/2, imgSize, imgSize);
        var item405 = document.getElementById("405Img");
        con.drawImage(item405, rightOffset - imgSize, hCent - imgSize/2, imgSize, imgSize);
        var item402 = document.getElementById("402Img");
        con.drawImage(item402, wCent - imgSize/2, topOffset, imgSize, imgSize);
        // var item403 = document.getElementById("403Img");
        // con.drawImage(item403, wCent - imgSize/2, hCent - imgSize/2, imgSize, imgSize);
        var item406 = document.getElementById("406Img");
        con.drawImage(item406, wCent - imgSize/2, hCent - imgSize/2, imgSize, imgSize);
        var item407 = document.getElementById("407Img");
        con.drawImage(item407, wCent - imgSize/2, bottomOffset - 2*imgSize, imgSize, imgSize);

        //get selected Unit
        updateAccessPointAndTargetKeys();
        var accPointImg = document.getElementById("_gatewayIcon");
        var targetImg = document.getElementById("_targetIcon");
        var x = 0;
        var y = 0;
        console.log("AccessPointKey: " + accessUnitKey);
        switch(fleetLink[accessUnitKey].serialNumber) {
          case "402":
            x = wCent - imgSize/2;
            y = edgeDist + imgSize + targetGatewayOffset;
          break;
          case "403":
          case "406":
            x = wCent - imgSize/2;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          case "404":
            x = edgeDist;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          case "405":
            x = width - imgSize - edgeDist - targetGatewayOffset;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          case "407":
            x = wCent - imgSize/2;
            y = height - edgeDist - imgSize;
          break;
        }
        con.drawImage(accPointImg, x, y, targetGatewaySize, targetGatewaySize);
        x = 0;
        y = 0;
        //console.log("TargetKey: " + targetUnitKey);
        switch(fleetLink[targetUnitKey].serialNumber) {
          case "402":
            x = wCent - imgSize/2;
            y = edgeDist + imgSize + targetGatewayOffset;
          break;
          case "403":
          case "406":
            x = wCent - imgSize/2;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          case "404":
            x = edgeDist;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          case "405":
            x = width - imgSize - edgeDist - targetGatewayOffset;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          case "407":
            x = wCent - imgSize/2;
            y = height - edgeDist - imgSize;
          break;
        }
        con.drawImage(targetImg, x, y, targetGatewaySize, targetGatewaySize);
        drawWifi();
      }

      function drawWifi() {
        var drawing = document.getElementById("_deviceIndicators");
        var con = drawing.getContext("2d");
        var greenImg = document.getElementById("_greenWifi");
        var redImg = document.getElementById("_redWifi");
        var width = drawing.width;
        var height = drawing.height;
        var hCent = height/2;
        var wCent = width/2;
        var leftOffset = edgeDist;
        var rightOffset = width - edgeDist;
        var topOffset = edgeDist;
        var bottomOffset = height - edgeDist;

        Object.keys(fleetLink).forEach(function(key,index){
          if (fleetLink[key].onlineStatus) {
            //console.log("SNo: " + fleetLink[key].serialNumber + " wifi: " + fleetLink[key].onlineStatus);
            switch(fleetLink[key].serialNumber) {
              case "402":
                x = hCent - imgSize/2 - wifiImgSize/2;
                y = edgeDist - wifiImgSize/2;
              break;
              case "403":
              case "406":
                x = hCent - imgSize/2 - wifiImgSize/2;
                y = hCent - imgSize/2 - wifiImgSize/2;
              break;
              case "404":
                x = edgeDist - wifiImgSize/2;
                y = hCent - imgSize/2 - wifiImgSize/2;
              break;
              case "405":
                x = rightOffset - imgSize - wifiImgSize/2;
                y = hCent - imgSize/2 - wifiImgSize/2;
              break;
              case "407":
                x = hCent - imgSize/2 - wifiImgSize/2;
                y = bottomOffset - 2*imgSize - wifiImgSize/2;
              break;
            }
            con.drawImage(greenImg, x, y, wifiImgSize, wifiImgSize);          
          }
          else {
            switch(fleetLink[key].serialNumber) {
              case "402":
                x = hCent - imgSize/2 - wifiImgSize/2;
                y = edgeDist - wifiImgSize/2;
              break;
              case "403":
              case "406":
                x = hCent - imgSize/2 - wifiImgSize/2;
                y = hCent - imgSize/2 - wifiImgSize/2;
              break;
              case "404":
                x = edgeDist - wifiImgSize/2;
                y = hCent - imgSize/2 - wifiImgSize/2;
              break;
              case "405":
                x = rightOffset - imgSize - wifiImgSize/2;
                y = hCent - imgSize/2 - wifiImgSize/2;
              break;
              case "407":
                x = hCent - imgSize/2 - wifiImgSize/2;
                y = bottomOffset - 2*imgSize - wifiImgSize/2;
              break;
            }
            con.drawImage(redImg, x, y, wifiImgSize, wifiImgSize);          
          }
        });
      }

      function initGateway() {
        //if the target is online the gateway is the target.
        var targetKey = getTargetKey();
        if (targetKey != null) {
          targetUnitKey = targetKey;
          if (fleetLink[targetKey].onlineStatus) {
            setGateway(targetKey);
            accessUnitKey = targetKey;
          }
          else {
          //if it is not then
          //make the listof units that are online.
          //select on at random.
            var wifilist = [null];
            var i = 0;
            Object.keys(fleetLink).forEach(function(key,index) {
              if (fleetLink[key].onlineStatus) {
                if (fleetLink[key].serialNumber != "403") wifilist[i]= key;
                i++;
              }
            });
            if (wifilist.length == 0) {
              alert("WiFi has to be enabled on atleast one unit");
            }
            else {
              var entry = wifilist[Math.floor(Math.random()*wifilist.length)];
              if (entry != null) setGateway(entry);
              //document.getElementById("selectedAccessPoint").value = accessUnitKey;
            }
          }
        }
      }

      $( document ).ready(function() {
          updatewifiOn();
          console.log("done drawing");
          buildInterestPacket();
          updateMarkers();
          document.getElementById("expressInterestPacket").disabled = "disabled";
          setTimeout(function(){document.getElementById("expressInterestPacket").disabled = false;}, 100 );
          });

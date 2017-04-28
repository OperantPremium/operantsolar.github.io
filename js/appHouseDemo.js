// FleetLink app
//Randy King 1/4/2016


// Variable setup and default values

var baseURL = "https://agent.electricimp.com";
var targetUnitKey;
var accessUnitKey;
var edgeDist = 30;
var imgSize = 100;
var targetGatewaySize = 65;
var wifiImgSize = 35;
var targetGatewayOffset = -5;

// Data struvture to hold unit specific values for fleet
var fleetLink = {
          /*
          // Proto 4
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
          // Proto 4
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
          // Proto 4
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
          // Proto 4
           4: {
            'serialNumber': '405',
            'macAddress': '56ddb2',
            'agentURL': '/CyPoe3l9E5Od',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300240002',
            'onlineStatus': true,
            'sensorScale' : 1.008,
            'position' : {lat: 38.4898, lon: -122.7181}
          },
          // Proto 4
           5: {
            'serialNumber': '406',
            'macAddress': '56ddde',
            'agentURL': '/VifAbahCX8ux',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300960002',
            'onlineStatus': true,
            'sensorScale' : -1.089,
            'position' : {lat: 38.4882, lon: -122.716}
          }, 
          // Proto 4
           6: {
            'serialNumber': '407',
            'macAddress': '56dd18',
            'agentURL': '/hxsSiYETEEpd',
            'geoLoc': '18SUJ22850705',
            'modbusCmd' : '010300240002',
            'onlineStatus': true,
            'sensorScale' : 1.0,
            'position' : {lat: 38.4882, lon: -122.716}
          }, 
          */
          // Proto 5 Blue House
          7: {
            'serialNumber': '506',  
            'agentURL': '/oGQ_PBSAUppO ',
            'usng': '28475668',
            'deviceIdHash': 'C3B996B9F76C',
            'category': 'modbus',
            'task': 'fc03',
            'parameters' : '01_00000001_9600_8_1',
            'onlineStatus': true,
            'sensorScale' : 0.01221001221 // = (20 mA / 4095 counts) [WellPro modbus cal factor] / (400 mA/1000 W/m^2) [solar panel cal]
              },
          // Proto 5 Orange House
          8: {
            'serialNumber': '508',
            'agentURL': '/2866vQYBgUpC',
            'usng': '28475668',
            'deviceIdHash': '730D72A6E22F',
            'category': 'modbus',
            'task': 'fc03',
            'parameters' : '01_00000001_9600_8_1',
            'onlineStatus': true,
            'sensorScale' : 1.0
              },
          // Proto 5 Green House          
          9: {
            'serialNumber': '509',
            'agentURL': '/D1PRYwJmmHAi',
            'usng': '28475668',
            'deviceIdHash': '16240A06C1FC',
            'category': 'modbus',
            'task': 'fc03',
            'parameters' : '01_00000001_9600_8_1',
            'onlineStatus': true,
            'sensorScale' : 3.25
          },
          // Proto 5 Black House
          10: {
            'serialNumber': '513',
            'agentURL': '/ZT8GBL-7RrgD',
            'usng': '28475668',
            'deviceIdHash': 'DF04146F1DF0',
            'category': 'modbus',
            'task': 'fc03',
            'parameters' : '01_00000001_9600_8_1',
            'onlineStatus': true,
            'sensorScale' : 0.01221001221 // = (20 mA / 4095 counts) [WellPro modbus cal factor] / (400 mA/1000 W/m^2) [solar panel cal]
          },
          // Proto 5 Yellow House
          11: {
            'serialNumber': '514',
            'agentURL': '/609atPXTxkX7',
            'usng': '28475668',
            'deviceIdHash': '00E329B56259',
            'category': 'modbus',
            'task': 'fc03',
            'parameters' : '01_00000001_9600_8_1',
            'onlineStatus': true,
            'sensorScale' : 0.01221001221 // = (20 mA / 4095 counts) [WellPro modbus cal factor] / (400 mA/1000 W/m^2) [solar panel cal]
          } 
          // Bad PCB
          /*
          12: {
            'serialNumber': '515',
            'agentURL': '/VRa-gimZfDGJ',
            'usng': '28475668',
            'deviceIdHash': '4E44238D7110',
            'category': 'modbus',
            'task': 'fc03',
            'parameters' : '01_00000001_9600_8_1',
            'onlineStatus': true,
            'sensorScale' : 0.01221001221 // = (20 mA / 4095 counts) [WellPro modbus cal factor] / (400 mA/1000 W/m^2) [solar panel cal]
          } 
          */
    };

// default Interest with reasonable values for SN404
    var interestPacket = {
          'usng': "28475668",
          'deviceIdHash' : "2BF6EF3EFD90",
          'rw': 'read',
          'category': 'modbus',
          'task': 'fc03',
          'parameters' : '01_00000001_9600_8_1',
    }

// read the web UI to determine the unit that is being targeted
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

// read the web UI to determine which unit's agent should receive the
    function setGateway (selGateway) {
      //console.log("gateway: " + selGateway);
      var serial = fleetLink[selGateway].serialNumber;
      accessUnitSerialNumber = document.getElementById("selectedAccessPoint").value = serial;
      accessUnitKey = selGateway;
    }

// 
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
      // Unit is specified by Serial Number in browser, but we need the other properties for the actual interest packet
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
      interestPacket.usng = fleetLink[targetUnitKey].usng;
      interestPacket.deviceIdHash = fleetLink[targetUnitKey].deviceIdHash;
      interestPacket.rw = "read";
      interestPacket.category = fleetLink[targetUnitKey].category;
      interestPacket.task = fleetLink[targetUnitKey].task;     
      interestPacket.parameters = fleetLink[targetUnitKey].parameters;
      interestPacket.name;  // what does this line do?? RK
    }

    // send the interest packet to the selected agent and expect a data packet in response
    function expressInterestPacket() {
      // Make the UI represent the Express Interest action
      clearResult();
      // disable the Go button
      document.getElementById("expressInterestPacket").disabled = "disabled";
      // play a swoosh
      new Audio("img/swoosh.mp3").play();
      buildInterestPacket();
      console.log("Packet: " + JSON.stringify(interestPacket));

      // actual web POST
      $.ajax({
          url: baseURL + fleetLink[accessUnitKey].agentURL,
          timeout: 15000,
          data: JSON.stringify(interestPacket), // convert interest packet string to JSON
          type: 'POST',
          success : function(response) {
            //console.log("response: " + response);
            displayData(response);
            setTimeout(function(){document.getElementById("expressInterestPacket").disabled = false;}, 10000 );
          },
          error : function(jqXHR, textStatus, err) {
            var errorResponse = jqXHR.status + ' ' + textStatus + ': ' + err + ' - ' + jqXHR.responseText;
            document.getElementById("returnedDataPacket").textContent = errorResponse;
            setTimeout(function(){document.getElementById("expressInterestPacket").disabled = false;}, 10000 );
          }
        });
      }

      // Display the result fetched after sending the modbus command.
      function displayData(response) {
        if (response != null) {
          new Audio("img/smallBell2.wav").play();  // sound chime to indicate successful data packet reception
          //get substring of hex chars.
          var hexStr = response.substring(6,10);
          var output = parseInt("0x" + hexStr, 16);
          var result = fleetLink[targetUnitKey].sensorScale * output;
          document.getElementById("stringDataRepresentation").value = result.toFixed(0) + "  W/m^2";
          new Audio("img/swoosh.mp3").play();
        }
      }

      // Clear the result from the result display text box
      function clearResult() {
        document.getElementById("stringDataRepresentation").value = "";
      }
/*
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
*/
      function updateMarkers() {
        clearResult();
        initGateway();
        drawImages();
        buildInterestPacket();
      }

      function updatewifiOn(){
        var wifiItems = document.getElementsByName("chk_group[]");

        var numCheckBoxesChecked = 0;

        for(var i = 0; i < wifiItems.length; i++) {
          Object.keys(fleetLink).forEach(function(key,index){
            if (wifiItems[i].value == fleetLink[key].serialNumber) {
              if (wifiItems[i].checked) {
                fleetLink[key].onlineStatus = true;
                numCheckBoxesChecked ++;
              }
              else {
                fleetLink[key].onlineStatus = false;
              }
            }
          });
         }

        // RK change to disable Go button if no units are WiFi enabled
        console.log("checking number of checkboxes checked...");
        if (numCheckBoxesChecked == 0 ) {
            document.getElementById("expressInterestPacket").disabled = true;
            console.log("all check boxes unchecked, GO button disabled!");
        } else  {
            document.getElementById("expressInterestPacket").disabled = false;
             console.log("a check box checked, GO button enabled");
        }

         initGateway();
         //update the display area show devices that have wifi on..
         drawImages();
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
        var topOffset = 2.5*edgeDist;
        var bottomOffset = height - 1.5*edgeDist;
        con.fillRect(0, 0, drawing.width, drawing.height);

        //draw  FleetLink units
        // Left Side
        var item509 = document.getElementById("509Img");
        con.drawImage(item509, edgeDist, hCent - imgSize/2, imgSize, imgSize);
        // Right Side
        var item506 = document.getElementById("506Img");
        con.drawImage(item506, rightOffset - imgSize, hCent - imgSize/2, imgSize, imgSize);
        // Top
        var item513 = document.getElementById("513Img");
        con.drawImage(item513, wCent - imgSize/2, topOffset, imgSize, imgSize);
        // Center
        var item514 = document.getElementById("514Img");
        con.drawImage(item514, wCent - imgSize/2, hCent - imgSize/2, imgSize, imgSize);
        // Bottom
        var item508 = document.getElementById("508Img");
        con.drawImage(item508, wCent - imgSize/2, bottomOffset - 1.4*imgSize, imgSize, imgSize);

        //get selected Unit
        updateAccessPointAndTargetKeys();
        var accPointImg = document.getElementById("_gatewayIcon");
        var targetImg = document.getElementById("_targetIcon");
        var x = 0;
        var y = 0;
        console.log("AccessPointKey: " + accessUnitKey);
        switch(fleetLink[accessUnitKey].serialNumber) {
          // Top
          case "513":
            x = wCent - imgSize/4;
            y = edgeDist + 1.45*imgSize + targetGatewayOffset;
          break;
          // Center
          case "514":
            x = wCent - imgSize/4;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          // Left
          case "509":
            x = edgeDist + imgSize/4;;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          // Right
          case "506":
            x = width - 3/4*imgSize - edgeDist - targetGatewayOffset;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          // Bottom
          case "508":
            x = wCent - imgSize/4;
            y = bottomOffset - 1.5*edgeDist ;
          break;
        }
        console.log("x=" + x + ", y=" + y);
        con.drawImage(accPointImg, x, y, targetGatewaySize, targetGatewaySize);
        x = 0;
        y = 0;
        //console.log("TargetKey: " + targetUnitKey);
        switch(fleetLink[targetUnitKey].serialNumber) {
          // Top
          case "513":
            x = wCent - imgSize/4;
            y = edgeDist + 1.45*imgSize + targetGatewayOffset;
          break;
          // Center
          case "514":
            x = wCent - imgSize/4;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          // Left
          case "509":
            x = edgeDist + imgSize/4;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          // Right
          case "506":
            x = width - 3/4*imgSize - edgeDist - targetGatewayOffset;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          // Bottom
          case "508":
            x = wCent - imgSize/4;
            y = bottomOffset - 1.5*edgeDist ;
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
              // Top
              case "513":
                x = hCent - imgSize/2; 
                y = edgeDist+ 0.45*imgSize; 
              break;
              // Center
              case "514":
                x = hCent - imgSize/2;
                y = hCent - imgSize/2;
              break;
              // Left
              case "509":
                x = edgeDist;
                y = hCent - imgSize/2;
              break;
              // Right
              case "506":
                x = rightOffset - imgSize;
                y = hCent - imgSize/2;
              break;
              // Bottom
              case "508":
                x = hCent - imgSize/2;
                y = bottomOffset - 1.55*imgSize;
              break;
            }
            con.drawImage(greenImg, x, y, wifiImgSize, wifiImgSize);          
          }
          else {
            switch(fleetLink[key].serialNumber) {
              //Top
              case "513":
                x = hCent - imgSize/2;
                y = edgeDist + 0.45*imgSize;
              break;
              // center
              case "514":
                x = hCent - imgSize/2;
                y = hCent - imgSize/2;
              break;
              // Left
              case "509":
                x = edgeDist;
                y = hCent - imgSize/2 ;
              break;
              // Right
              case "506":
                x = rightOffset - imgSize;
                y = hCent - imgSize/2;
              break;
              // Bottom
              case "508":
                x = hCent - imgSize/2;
                y = bottomOffset - 1.55*imgSize;
              break;
            }
            con.drawImage(redImg, x, y, wifiImgSize, wifiImgSize);          
          }
        });
      }

      function getRandomInt(min, max) {
        return Math.floor(Math.random() * (max - min + 1) + min);
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
                if (fleetLink[key].serialNumber != "403") {
                  //console.log("key added to keylist for next gateway: " + key);
                  wifilist[i]= key;
                  i++;
                }
              }
            });
            if (wifilist.length == 0) {
              alert("WiFi has to be enabled on atleast one unit");
            }
            else {
              var randIndex = getRandomInt(0, wifilist.length);
              //console.log("random index: " + randIndex + " list length: " + wifilist.length);
              if (randIndex < 0 || randIndex >= wifilist.length) randIndex = 0;
              var entry = wifilist[randIndex];
              //console.log("selected gateway: " + entry);
              if (entry != null) 
                setGateway(entry);
              else
                entry = wifilist[0];
            }
          }
        }
      }

      $( document ).ready(function() {
      });
        
      $( window ).on( "load", function() {
        updatewifiOn();
        buildInterestPacket();
        updateMarkers();
        document.getElementById("expressInterestPacket").disabled = "disabled";
        setTimeout(function(){document.getElementById("expressInterestPacket").disabled = false;}, 100 );
      });

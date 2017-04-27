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
          1: {
            'serialNumber': '402',  
            'agentURL': '/oHMQMg_lcxsT',
            'usng': '28475668',
            'deviceIdHash': 'D85F6461EB91',
            'category': 'modbus',
            'task': 'fc03',
            'parameters' : '01_00000001_9600_8_1',
            'onlineStatus': true,
            'sensorScale' : 1.0
              },
          2: {
            'serialNumber': '403',
            'agentURL': '/wXqOLIl3KiLB',
            'usng': '28475668',
            'deviceIdHash': '018C268ECB5B',
            'category': 'modbus',
            'task': 'fc03',
            'parameters' : '01_00000001_9600_8_1',
            'onlineStatus': true,
            'sensorScale' : 1.0
              },
          3: {
            'serialNumber': '404',
            'agentURL': '/QGO7JQAzyiev',
            'usng': '28475668',
            'deviceIdHash': '2BF6EF3EFD90',
            'category': 'modbus',
            'task': 'fc03',
            'parameters' : '01_00000001_9600_8_1',
            'onlineStatus': true,
            'sensorScale' : 0.01221001221 // = (20 mA / 4095 counts) [WellPro modbus cal factor] / (400 mA/1000 W/m^2) [solar panel cal]
          },

          4: {
            'serialNumber': '405',
            'agentURL': '/CyPoe3l9E5Od',
            'usng': '28475668',
            'deviceIdHash': '718A34D8423A',
            'category': 'modbus',
            'task': 'fc03',
            'parameters' : '01_00000001_9600_8_1',
            'onlineStatus': true,
            'sensorScale' : 1.0
          },

          5: {
            'serialNumber': '407',
            'agentURL': '/VifAbahCX8ux',
            'usng': '28475668',
            'deviceIdHash': 'C5F6371C8A03',
            'category': 'modbus',
            'task': 'fc03',
            'parameters' : '01_00000001_9600_8_1',
            'onlineStatus': true,
            'sensorScale' : 1.0
          }, 

          6: {
            'serialNumber': '406',
            'agentURL': '/hxsSiYETEEpd',
            'usng': '28475668',
            'deviceIdHash': '4CA33E88EDAA',
            'category': 'modbus',
            'task': 'fc03',
            'parameters' : '01_00000001_9600_8_1',
            'onlineStatus': true,
            'sensorScale' : 1.0
          } 
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
            console.log("response: " + response);
            displayData(response);
            new Audio("img/smallBell2.wav").play();  // sound chime to indicate successful data packet reception
            setTimeout(function(){document.getElementById("expressInterestPacket").disabled = false;}, 14000 );
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
          //get substring of hex chars.
          var hexStr = response.substring(6,10);
          var output = parseInt("0x" + hexStr, 16);
          var result = fleetLink[targetUnitKey].sensorScale * output;
          document.getElementById("stringDataRepresentation").value = result.toFixed(2) + " W/m^2";
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
        con.drawImage(item407, wCent - imgSize/2, bottomOffset - 1.2*imgSize, imgSize, imgSize);

        //get selected Unit
        updateAccessPointAndTargetKeys();
        var accPointImg = document.getElementById("_gatewayIcon");
        var targetImg = document.getElementById("_targetIcon");
        var x = 0;
        var y = 0;
        console.log("AccessPointKey: " + accessUnitKey);
        switch(fleetLink[accessUnitKey].serialNumber) {
          case "402":
            x = wCent - imgSize/4;
            y = edgeDist + imgSize + targetGatewayOffset;
          break;
          case "403":
          case "406":
            x = wCent - imgSize/4;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          case "404":
            x = edgeDist + imgSize/4;;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          case "405":
            x = width - 3/4*imgSize - edgeDist - targetGatewayOffset;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          case "407":
            x = wCent - imgSize/4;
            y = bottomOffset - edgeDist ;
          break;
        }
        console.log("x=" + x + ", y=" + y);
        con.drawImage(accPointImg, x, y, targetGatewaySize, targetGatewaySize);
        x = 0;
        y = 0;
        //console.log("TargetKey: " + targetUnitKey);
        switch(fleetLink[targetUnitKey].serialNumber) {
          case "402":
            x = wCent - imgSize/4;
            y = edgeDist + imgSize + targetGatewayOffset;
          break;
          case "403":
          case "406":
            x = wCent - imgSize/4;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          case "404":
            x = edgeDist + imgSize/4;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          case "405":
            x = width - 3/4*imgSize - edgeDist - targetGatewayOffset;
            y = hCent + imgSize/2 + targetGatewayOffset;
          break;
          case "407":
            x = wCent - imgSize/4;
            //y = height - edgeDist - imgSize;
            y = bottomOffset - edgeDist ;
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
                x = hCent - imgSize/2; 
                y = edgeDist; 
              break;
              case "403":
              case "406":
                x = hCent - imgSize/2;
                y = hCent - imgSize/2;
              break;
              case "404":
                x = edgeDist;
                y = hCent - imgSize/2;
              break;
              case "405":
                x = rightOffset - imgSize;
                y = hCent - imgSize/2;
              break;
              case "407":
                x = hCent - imgSize/2;
                y = bottomOffset - 1.2*imgSize;
              break;
            }
            con.drawImage(greenImg, x, y, wifiImgSize, wifiImgSize);          
          }
          else {
            switch(fleetLink[key].serialNumber) {
              case "402":
                x = hCent - imgSize/2;
                y = edgeDist;
              break;
              case "403":
              case "406":
                x = hCent - imgSize/2;
                y = hCent - imgSize/2;
              break;
              case "404":
                x = edgeDist;
                y = hCent - imgSize/2 ;
              break;
              case "405":
                x = rightOffset - imgSize;
                y = hCent - imgSize/2;
              break;
              case "407":
                x = hCent - imgSize/2;
                y = bottomOffset - 1.2*imgSize;
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

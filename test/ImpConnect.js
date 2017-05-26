var http = require('https')
const querystring = require('querystring');

// (C) 2017 Operant Solar
// All rights reserved
//
// @author: Rama Nadendla <rama.nadendla@operantsolar.com>

var gatewayURL = '/QGO7JQAzyiev'; //sn404 

//The base agent url is: agent.electricimp.com/ +  gateway URL
var options = {
  host: 'agent.electricimp.com',
  path: gatewayURL,
  method: 'POST',
  headers: {
      'Content-Type': 'application/json',
  timeout: 120000,
  }
};

//The following lines are the default parameters for the impConnect script
  // USNG
  var _usng = "28475668";
  // device identifier
  var _deviceIdHash = "2BF6EF3EFD90";
  // readwrite
  var _rw = "read";
  //Category
  var _category = "wiFi";
  // task is the command or query to send
  var _task = "scanRssi";
  // parameters are passsed to the task and can be multiple (separated by commas)
  var _parameters = "";


// the defaults parameters can be overridden by command line switches as shown below
process.argv.forEach(function (val, index, array) {
  if (val.includes("gatewayURL"))
  {
    var entries = val.split("=");
    options.path = entries[1];
  }
  else if(val.includes("usng"))
  {
      var entries = val.split("=");
      _usng = entries[1];
  }
  else if (val.includes("deviceIdHash")) 
  {
     var entries = val.split("=");
     _deviceIdHash = entries[1];
  }
  else if(val.includes("rw"))
  {
      var entries = val.split("=");
      _rw = entries[1];
  }
  else if(val.includes("category"))
  {
      var entries = val.split("=");
      _category = entries[1];
  }
  else if(val.includes("task"))
  {
      var entries = val.split("=");
      _task = entries[1];
  }else if(val.includes("parameters"))
  {
      var entries = val.split("=");
      _parameters = entries[1];
  }
  
  
  
  
});


callback = function(response) {
  var str = '';

  //another chunk of data has been recieved, so append it to `str`
  response.on('data', function (chunk) {
    str += chunk;
  });

  //the whole response has been received, so we just print it out here
  response.on('end', function () {
    console.log("Data: " + str); //Buffer(str, 'hex').toString('ascii'));
  });
}

// following is just to print a pretty string version of interest
var interestString = "/fl/" + _usng + "/" + _deviceIdHash + "/" + _rw + "/" + _category + "/" + _task+ "/" + _parameters;
console.log("Interest: " + interestString + " sent to Agent URL " + options.path);


var req = http.request(options, callback);
req.timeout = 30000;

var fetchItem = {};
fetchItem["deviceIdHash"] = _deviceIdHash
fetchItem["usng"] = _usng;
fetchItem["rw"] = _rw;
fetchItem["category"] = _category;
fetchItem["task"] = _task;
fetchItem["parameters"] = _parameters;

console.log("Interest: " + JSON.stringify(fetchItem) + " sent to Agent URL " + options.path);

req.write(JSON.stringify(fetchItem));
req.end();
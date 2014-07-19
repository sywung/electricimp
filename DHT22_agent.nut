// max round-trip time: agent -> device -> agent
const TIMEOUT = 10.0;

// response queue
HttpResponses <- {};

// Send timeout responses when required
function CleanResponses() {
    // get current time
    local now = time();
    
    // loop through response queue
    foreach(t, resp in HttpResponses) {
        // if request has timed-out
        if (now - t > TIMEOUT) {
            // log it, send the response, then delete it
            server.log("Request " + t + " timed-out");
            resp.send(408, "Request Timed-out");
            delete HttpResponses[t];
        }
    }
    // check for timeouts every seconds
    imp.wakeup(1.0, CleanResponses);
} CleanResponses();

// sends a response based on a timestamp
function SendResponse(t, code, body) {
    // if the response is in our queue (it hasn't timed out)
    if (t in HttpResponses) {
        // send it
        HttpResponses[t].send(code, body);
        delete HttpResponses[t];
    } else {
        // if it wasn't in the queue, log a message
        server.log("Response " + t + " not found in response queue");
    }
}

// when we get a request
http.onrequest(function(request, response) {
    // get current timestamp
    local t = time();
    server.log("Got a request: " + t);
    
   
    // add request to request queue
    //server.log("response:",response);
    HttpResponses[t] <- response;

    // pass on to device
    try {
    // check if the user sent led as a query parameter
    
    if ("led" in request.query) {
      
      // if they did, and led=1.. set our variable to 1
      if (request.query.led == "1" || request.query.led == "0") {
        // convert the led query parameter to an integer
        local ledState = request.query.led.tointeger();
 
        // send "led" message to device, and send ledState as the data
        device.send("led", ledState); 
      }
    }
    device.send("GetValue", t);
    // send a response back saying everything was OK.
    //response.send(200, "OK");
  } catch (ex) {
    response.send(500, "Internal Server Error: " + ex);
  }
    
});

device.on("GetValueResponse", function(p) {
    local t = p.t;
    local data = http.jsonencode({ A_Time=t, Volt = p.v, Light=p.l , LED=p.LED,D_Time=p.dt});
    server.log(p.v+" "+p.l);
    // send the response

    SendResponse(t, 200, data);
});

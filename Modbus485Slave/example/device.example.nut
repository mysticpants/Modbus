modbus <- Modbus485Slave(hardware.uart2, hardware.pinL, 1, { debug = true });


/*
modbus.onRead(function(error, request){
	if (error) {
		server.error(error);
	} else {
		foreach (key, value in request) {
		    server.log(key + " : " + value);
		}
	}
	return [true,false,false,true,true];
}.bindenv(this));


modbus.onRead(function(error, request){
	if (error) {
		server.error(error);
	} else {
		foreach (key, value in request) {
		    server.log(key + " : " + value);
		}
	}
	return [18,29,30, 59, 47];
}.bindenv(this));
*/

modbus.onWrite(function(slaveID, functionCode, startingAddress, quantity, values) {
    server.log("slaveID : " + slaveID);
    server.log("functionCode : " + functionCode);
    server.log("startingAddress : " + startingAddress);
    server.log("Quantity : " + quantity);
    server.log("Values : \n");
    foreach (index, value in values) {
    	server.log("\t" + index + " : " + value);
    }
}.bindenv(this));

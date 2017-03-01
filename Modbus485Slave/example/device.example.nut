modbus <- Modbus485Slave(hardware.uart2, hardware.pinL, 1, {debug = true});


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

modbus.onWrite(function(error, request){
	if (error) {
		server.error(error);
	} else {
		foreach (key, value in request.writeValues) {
			server.log(key + " : " + value);
		}
	}
}.bindenv(this));
modbus <- Modbus485Slave(hardware.uart2, hardware.pinL, 1);


modbus.onRead(function(error, info){
	if (error) {
		server.error(error);
	} else {
		foreach (key, value in info) {
		    server.log(key + " : " + value);
		}
	}
	return [true,false,false,true,true];
});

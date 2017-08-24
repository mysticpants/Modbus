#require "CRC16.class.nut:1.0.0"
#require "ModbusSlave.device.lib.nut:1.0.0"
#require "Modbus485Slave.device.lib.nut:1.0.0"

modbus <- Modbus485Slave(hardware.uart2, hardware.pinL, 1, { debug = true });

modbus.onError(function(error) {
    server.error(error);
});

// a holding register read example
modbus.onRead(function(slaveID, functionCode, startingAddress, quantity) {
    server.log("slaveID : " + slaveID);
    server.log("functionCode : " + functionCode);
    server.log("startingAddress : " + startingAddress);
    server.log("Quantity : " + quantity);
    return [18, 29, 30, 59, 47];
}.bindenv(this));

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

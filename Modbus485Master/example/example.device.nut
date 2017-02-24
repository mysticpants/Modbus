#require "CRC16.class.nut:1.0.0"
#require "ModbusRTU.class.nut:1.0.0"
#require "Modbus485Master.class.nut:1.0.0"
// this example demonstrates how to write and read values into/from holding registers

// instantiate the the Modbus485Master object
local params = {
    uart = hardware.uart2,
    rts  = hardware.pinL
};
modbus <- Modbus485Master(params);

// write values into 3 holding registers starting at address 9
modbus.write(0x01, MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER, 9, 3, [188, 80, 18], function(error, res) {
    if (error) {
        server.error(error);
    } else {
        // read values from 3 holding registers starting at address 9
        modbus.read(0x01, MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER, 9, 3, function(error, res) {
            if (error) {
                server.error(error);
            } else {
                // 188
                server.log(res[0]);
                // 80
                server.log(res[1]);
                // 18
                server.log(res[2]);
            }
        });
    }
});

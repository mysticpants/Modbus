#require "CRC16.class.nut:1.0.0"
#require "ModbusRTU.device.lib.nut:1.0.0"
#require "ModbusMaster.device.lib.nut:1.0.0"
#require "Modbus485Master.device.lib.nut:1.0.0"

// this example demonstrates how to write and read values into/from holding registers
const DEVICE_ADDRESS = 0x01;
// instantiate the the Modbus485Master object
modbus <- Modbus485Master(hardware.uart2, hardware.pinL);

// write values into 3 holding registers starting at address 9
modbus.write(DEVICE_ADDRESS, MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER, 9, 3, [188, 80, 18], function(error, res) {
    if (error) {
        server.error(error);
    } else {
        // read values from 3 holding registers starting at address 9
        modbus.read(DEVICE_ADDRESS, MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER, 9, 3, function(error, res) {
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

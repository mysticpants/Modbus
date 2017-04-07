#require "W5500.device.nut:1.0.0"
#require "ModbusRTU.class.nut:1.0.0"
#require "ModbusMaster.class.nut:1.0.0"
#require "ModbusTCPMaster.class.nut:1.0.0"

// this example shows how to use readWriteMultipleRegisters

// configure spi
local spi = hardware.spi0;
spi.configure(CLOCK_IDLE_LOW | MSB_FIRST | USE_CS_L, 1000);

local wiz = W5500(hardware.pinXC, spi, null, hardware.pinXA);
wiz.configureNetworkSettings("192.168.1.30", "255.255.255.0", "192.168.1.1");

// instantiate a modbus object
local modbus = ModbusTCPMaster(wiz);


// the device address and port
local connectionSettings = {
    "destIP"     : "192.168.1.90",
    "destPort"   : 502
};

// open the connection
modbus.connect(networkSettings, connectionSettings, function(error, conn) {
    if (error) {
        server.log(error);
    } else {
        // read and write multiple registers in one go , with read run before write
        modbus.readWriteMultipleRegisters(0x0A, 2, 0x0A, 2, [28, 88], function(error, result) {
            if (error) {
                server.error(error);
            } else {
                foreach (index, value in result) {
                    server.log(format("Index : %d, value : %d", index, value));
                }
            }
        });
    }
});

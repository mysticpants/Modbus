// MIT License
//
// Copyright 2017-2020 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

#require "W5500.device.nut:1.0.0"
#require "ModbusRTU.device.lib.nut:1.0.2"
#require "ModbusMaster.device.lib.nut:1.0.2"
#require "ModbusTCPMaster.device.lib.nut:1.1.1"

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
modbus.connect(connectionSettings, function(error, conn) {
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

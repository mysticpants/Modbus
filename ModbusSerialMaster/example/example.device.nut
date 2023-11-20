// MIT License
//
// Copyright 2017-19 Electric Imp
// Copyright 2020-23 KORE Wireless
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

#require "CRC16.class.nut:1.0.0"
#require "ModbusRTU.device.lib.nut:1.0.2"
#require "ModbusMaster.device.lib.nut:1.0.2"
#require "ModbusSerialMaster.device.lib.nut:2.0.1"

// Hardware used: Fieldbus Gateway and Kojo
// Click PLC C0-02DR-D connectied via RS485 ports

// This example demonstrates how to write and read values
// into/from holding registers.

const DEVICE_ADDRESS = 0x01;
// instantiate the the Modbus485Master object
local params = {"baudRate" : 38400, "parity" : PARITY_ODD};
modbus <- ModbusSerialMaster(hardware.uart2, hardware.pinL, params);

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

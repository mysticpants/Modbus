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
#require "ModbusSlave.device.lib.nut:1.0.2"
#require "ModbusSerialSlave.device.lib.nut:2.0.1"

// Hardware used: Fieldbus Gateway and Kojo
// Click PLC C0-02DR-D connectied via RS485 ports

// This example demonstrates a holding register read.

const SLAVE_ID = 0x01;

local params = {"baudRate" : 38400, "parity" : PARITY_ODD, "debug" : true};
modbus <- ModbusSerialSlave(SLAVE_ID, hardware.uart2, hardware.pinL, params);

modbus.onError(function(error) {
    server.error(error);
});

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

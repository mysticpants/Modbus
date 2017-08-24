// MIT License
//
// Copyright 2017 Electric Imp
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
#require "ModbusSlave.device.lib.nut:1.0.1"
#require "Modbus485Slave.device.lib.nut:1.0.1"

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

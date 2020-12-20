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

class ModbusTCPMaster extends ModbusMaster {
    static VERSION = "1.1.0";
    static MAX_TRANSACTION_COUNT = 65535;
    _transactions = null;
    _wiz = null;
    _transactionCount = null;
    _connection = null;
    _connectionSettings = null;
    _shouldRetry = null;
    _connectCallback = null;
    _reconnectCallback = null;
    //TODO Passing methods' parameters via class fields is not a good pattern.
    //TODO But the base class ModbusMaster must be redesigned to get rid of this pattern.
    _deviceAddress = null;

    //
    // Constructor for ModbusTCPMaster
    //
    // @param  {object} wiz - The W5500 object
    // @param  {bool} debug - false by default. If enabled, the outgoing and incoming ADU will be printed for debugging purpose
    //
    constructor(wiz, debug = false) {
        base.constructor(debug);
        _wiz = wiz;
        _transactionCount = 1;
        _transactions = {};
    }

    //
    // configure and open a TCP connection
    //
    // @param  {table} networkSettings - The network settings table. It entails sourceIP, subnet, gatewayIP
    // @param  {table} connectionSettings - The connection settings table. It entails device IP and port
    // @param  {function} connectCallback - The function to be fired when the connection is established
    // @param  {function} reconnectCallback - The function to be fired when the connection is reestablished
    //
    function connect(connectionSettings, connectCallback = null, reconnectCallback = null) {
        _shouldRetry = true;
        _connectCallback = connectCallback;
        _reconnectCallback = reconnectCallback;
        _connectionSettings = connectionSettings;
        _wiz.onReady(function() {
            local destIP = connectionSettings.destIP;
            local destPort = connectionSettings.destPort;
            _wiz.openConnection(destIP, destPort, _onConnect.bindenv(this));
        }.bindenv(this));
    }

    //
    // close the existing TCP connection
    //
    // @param  {function} callback - The function to be fired when the connection is closed
    //
    function disconnect(callback = null) {
        _shouldRetry = false;
        _connection.close(callback);
    }

    //
    // This function performs a combination of one read operation and one write operation in a single MODBUS transaction.
    // The write operation is performed before the read.
    //
    // @param {integer} readingStartAddress - The address from which it begins reading values
    // @param {integer} readQuantity - The number of consecutive addresses values are read from
    // @param {integer} writeStartAddress - The address from which it begins writing values
    // @param {integer} writeQuantity - The number of consecutive addresses values are written into
    // @param {blob} writeValue - The value written into the holding register
    // @param {function} callback - The function to be fired when it receives response regarding this request
    // @param {integer} deviceAddress - The unique address that identifies a device
    //
    function readWriteMultipleRegisters(readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue, callback = null, deviceAddress = 0) {
        _deviceAddress = deviceAddress;
        base.readWriteMultipleRegisters(readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue, callback);
    }

    //
    // This function modifies the contents of a specified holding register using a combination of an AND mask,
    // an OR mask, and the register's current contents.
    // The function can be used to set or clear individual bits in the register.
    //
    // @param {integer} referenceAddress - The address of the holding register the value is written into
    // @param {integer} AND_mask - The AND mask
    // @param {integer} OR_mask - The OR mask
    // @param {function} callback - The function to be fired when it receives response regarding this request
    // @param {integer} deviceAddress - The unique address that identifies a device
    //
    function maskWriteRegister(referenceAddress, AND_Mask, OR_Mask, callback = null, deviceAddress = 0) {
        _deviceAddress = deviceAddress;
        base.maskWriteRegister(referenceAddress, AND_Mask, OR_Mask, callback);
    }

    //
    // This function reads the description of the type, the current status, and other information specific to a remote device.
    //
    // @param {function} callback - The function to be fired when it receives response regarding this request
    // @param {integer} deviceAddress - The unique address that identifies a device
    //
    function reportSlaveID(callback = null, deviceAddress = 0) {
        _deviceAddress = deviceAddress;
        base.reportSlaveID(callback);
    }

    //
    // This function allows reading the identification and additional information relative to the physical
    // and functional description of a remote device.
    //
    // @param {enum} readDeviceIdCode - read device id code
    // @param {enum} objectId - object id
    // @param {function} callback - The function to be fired when it receives response regarding this request
    // @param {integer} deviceAddress - The unique address that identifies a device
    //
    function readDeviceIdentification(readDeviceIdCode, objectId, callback = null, deviceAddress = 0) {
        _deviceAddress = deviceAddress;
        base.readDeviceIdentification(readDeviceIdCode, objectId, callback);
    }

    //
    // This function provides a series of tests for checking the communication system between a client (Master) device
    // and a server (Slave), or for checking various internal error conditions within a server.
    //
    // @param {integer} subFunctionCode - The Sub-function Code
    // @param {blob} data - The data field required by Modbus request
    // @param {function} callback - The function to be fired when it receives response regarding this request
    // @param {integer} deviceAddress - The unique address that identifies a device
    //
    function diagnostics(subFunctionCode, data, callback = null, deviceAddress = 0) {
        _deviceAddress = deviceAddress;
        base.diagnostics(subFunctionCode, data, callback);
    }

    //
    // This function reads the contents of eight Exception Status outputs in a remote device
    //
    // @param {function} callback - The function to be fired when it receives response regarding this request
    // @param {integer} deviceAddress - The unique address that identifies a device
    //
    function readExceptionStatus(callback = null, deviceAddress = 0) {
        _deviceAddress = deviceAddress;
        base.readExceptionStatus(callback);
    }

    //
    // This is the generic function to read values from a single coil register or multiple coils registers.
    //
    // @param {enum} targetType - The Target Type
    // @param {integer} startingAddress - The address from which it begins reading values
    // @param {integer} quantity - The number of consecutive addresses the values are read from
    // @param {function} callback - The function to be fired when it receives response regarding this request
    // @param {integer} deviceAddress - The unique address that identifies a device
    //
    function read(targetType, startingAddress, quantity, callback, deviceAddress = 0) {
        _deviceAddress = deviceAddress;
        base.read(targetType, startingAddress, quantity, callback);
    }

    //
    // This is the generic function to write values into coils or holding registers.
    //
    // @param {enum} targetType - The Target Type
    // @param {integer} startingAddress - The address from which it begins writing values
    // @param {integer} quantity - The number of consecutive addresses the values are written into
    // @param {integer, Array[integer,Bool], Bool, blob} values - The values written into Coils or Registers
    // @param {function} callback - The function to be fired when it receives response regarding this request
    // @param {integer} deviceAddress - The unique address that identifies a device
    //
    function write(targetType, startingAddress, quantity, values, callback = null, deviceAddress = 0) {
        _deviceAddress = deviceAddress;
        base.write(targetType, startingAddress, quantity, values, callback);
    }

    //
    // The callback function to be fired when the connection is established
    //
    function _onConnect(error, conn) {
        if (error) {
            return _callbackHandler(error, null, _connectCallback);
        }
        _connection = conn;
        _connection.onReceive(_parseADU.bindenv(this));
        _connection.onDisconnect(_onDisconnect.bindenv(this));
        _callbackHandler(null, conn, _connectCallback);
    }

    //
    // The callback function to be fired when the connection is dropped
    //
    function _onDisconnect(conn) {
        _connection = null;
        if (_shouldRetry) {
            if (_reconnectCallback != null) {
                _connectCallback = _reconnectCallback;
            }
            _wiz.openConnection(_connectionSettings.destIP, _connectionSettings.destPort, _onConnect.bindenv(this));
        }
    }

    //
    // The callback function to be fired it receives a packet
    //
    function _parseADU(error, ADU) {
        if (error) {
            return _callbackHandler(error, null, _connectCallback);
        }
        ADU.seek(0);
        local header = ADU.readblob(7);
        local transactionID = swap2(header.readn('w'));
        local PDU = ADU.readblob(ADU.len() - 7);
        local params = null;
        try {
            params = _transactions[transactionID];
        } catch (error) {
            return _callbackHandler(format("Error parsing the response, transactionID %d does not exist", transactionID), null, _connectCallback);
        }
        local callback = params.callback;
        params.PDU <- PDU;
        try {
            local result = ModbusRTU.parse(params);
            _callbackHandler(null, result, callback);
        } catch (error) {
            _callbackHandler(error, null, callback);
        }
        _transactions.rawdelete(transactionID);
        _log(ADU, "Incoming ADU: ");
    }

    //
    // create an ADU
    //
    function _createADU(PDU) {
        local ADU = blob();
        ADU.writen(swap2(_transactionCount), 'w');
        ADU.writen(swap2(0x0000), 'w');
        ADU.writen(swap2(PDU.len() + 1), 'w');
        ADU.writen(_deviceAddress, 'b');
        ADU.writeblob(PDU);
        return ADU;
    }

    //
    // send the ADU via Ethernet
    //
    function _send(PDU, properties) {
        _transactions[_transactionCount] <- properties;
        local ADU = _createADU(PDU);
        // with or without success in transmission of data, the transaction count would be advanced
        _transactionCount = (_transactionCount + 1) % MAX_TRANSACTION_COUNT;
        _connection.transmit(ADU, function(error) {
            if (error) {
                _callbackHandler(error, null, properties.callback);
            } else {
                _log(ADU, "Outgoing ADU: ");
            }
        }.bindenv(this));
    }

    //
    // fire the callback
    //
    function _callbackHandler(error, result, callback) {
        if (callback) {
            if (error) {
                callback(error, null);
            } else {
                callback(null, result);
            }
        }
    }
}

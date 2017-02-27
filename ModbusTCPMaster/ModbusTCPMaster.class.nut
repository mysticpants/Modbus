// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

class ModbusTCPMaster extends ModbusMaster {
    static MAX_TRANSACTION_COUNT = 65535;
    _transactions = null;
    _wiz = null;
    _transactionCount = null;
    _connection = null;
    _connectionSettings = null;
    _shouldRetry = null;
    _connectCallback = null;

    //
    // Constructor for ModbusTCPMaster
    //
    // @param  {object} wiz - The W5500 object
    // @param  {bool} debug - false by default. If enabled, the outgoing and incoming ADU will be printed for debugging purpose
    //
    constructor(wiz, debug = false) {
        base(debug);
        _wiz = wiz;
        _transactionCount = 1;
        _transactions = {};
    }

    //
    // configure and open a TCP connection
    //
    // @param  {table} networkSettings - The network settings table. It entails sourceIP, subnet, gatewayIP
    // @param  {table} connectionSettings - The connection settings table. It entails device IP and port
    // @param  {function} callback - The function to be fired when the connection is established
    //
    function connect(networkSettings, connectionSettings, callback = null) {
        local sourceIP = networkSettings.sourceIP;
        local subnet = ("subnet" in networkSettings) ? networkSettings.subnet: null;
        local gatewayIP = ("gatewayIP" in networkSettings) ? networkSettings.gatewayIP: null;
        local mac = ("mac" in networkSettings) ? networkSettings.mac: null;
        _shouldRetry = true;
        _connectCallback = callback;
        _connectionSettings = connectionSettings;
        _wiz.onReady(function() {
            local destIP = connectionSettings.destIP;
            local destPort = connectionSettings.destPort;
            _wiz.configureNetworkSettings(sourceIP, subnet, gatewayIP, mac);
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
    // This function reads the description of the type, the current status, and other information specific to a remote device.
    //
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
    function reportSlaveID(callback = null) {
        return base.reportSlaveID(null, callback);
    }

    //
    // This is the generic function to write values into coils or holding registers .
    //
    // @param {enum} targetType - The address from which it begins reading values
    // @param {integer} startingAddress - The address from which it begins writing values
    // @param {integer} quantity - The number of consecutive addresses the values are written into
    // @param {integer, Array[integer, Bool], Bool, blob} values - The values written into Coils or Registers
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
    function write(targetType, startingAddress, quantity, values, callback = null) {
        return base.write(null, targetType, startingAddress, quantity, values, callback);
    }

    //
    // This is the generic function to read values from a single coil, register or multiple coils, registers .
    //
    // @param {enum} targetType - The address from which it begins reading values
    // @param {integer} startingAddress - The address from which it begins reading values
    // @param {integer} quantity - The number of consecutive addresses the values are read from
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
    function read(targetType, startingAddress, quantity, callback = null) {
        return base.read(null, targetType, startingAddress, quantity, callback);
    }

    //
    // This function reads the contents of eight Exception Status outputs in a remote device
    //
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
    function readExceptionStatus(callback = null) {
        return base.readExceptionStatus(null, callback);
    }

    //
    // This function provides a series of tests for checking the communication system between a client ( Master) device and a server ( Slave), or for checking various internal error conditions within a server.
    //
    // @param {integer} deviceAddress - The unique address that identifies a device
    // @param {integer} subFunctionCode - The address from which it begins reading values
    // @param {blob} data - The data field required by Modbus request
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
    function diagnostics(subFunctionCode, data, callback = null) {
        return base.diagnostics(null, subFunctionCode, data, callback);
    }

    //
    // This function modifies the contents of a specified holding register using a combination of an AND mask, an OR mask, and the register's current contents. The function can be used to set or clear individual bits in the register.
    //
    // @param {integer} referenceAddress - The address of the holding register the value is written into
    // @param {integer} AND_mask - The AND mask
    // @param {integer} OR_mask - The OR mask
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
    function maskWriteRegister(referenceAddress, AND_Mask, OR_Mask, callback = null) {
        return base.maskWriteRegister(null, referenceAddress, AND_Mask, OR_Mask, callback);
    }

    //
    // This function performs a combination of one read operation and one write operation in a single MODBUS transaction. The write operation is performed before the read.
    //
    // @param {integer} readingStartAddress - The address from which it begins reading values
    // @param {integer} readQuantity - The number of consecutive addresses values are read from
    // @param {integer} writeStartAddress - The address from which it begins writing values
    // @param {integer} writeQuantity - The number of consecutive addresses values are written into
    // @param {blob} writeValue - The value written into the holding register
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
    function readWriteMultipleRegisters(readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue, callback = null) {
        return base.readWriteMultipleRegisters(null, readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue, callback);
    }

    //
    // This function allows reading the identification and additional information relative to the physical and functional description of a remote device, only.
    //
    // @param {enum} readDeviceIdCode - read device id code
    // @param {enum} objectId - object id
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
    function readDeviceIdentification(readDeviceIdCode, objectId, callback = null) {
        return base.readDeviceIdentification(null, readDeviceIdCode, objectId, callback);
    }

    //
    // The callback function to be fired when the connection is established
    //
    function _onConnect(error, conn) {
        _connection = conn;
        _connection.onReceive(_parseADU.bindenv(this));
        _connection.onDisconnect(_onDisconnect.bindenv(this));
        _callbackHandler(error, conn, _connectCallback);
    }

    //
    // The callback function to be fired when the connection is dropped
    //
    function _onDisconnect(conn) {
        _connection = null;
        if (_shouldRetry) {
            _connectCallback = null;
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
        local params = _transactions[transactionID];
        local callback = params.callback;
        params.PDU <- PDU;
        try {
            local result = ModbusRTU.parse(params);
            _callbackHandler(null, result, callback);
        } catch (error) {
            _callbackHandler(error, null, callback);
        }
        _transactions.rawdelete(transactionID);
        _log(ADU,"Incoming ADU: ");
    }

    //
    // create an ADU
    //
    function _createADU(deviceAddress, PDU) {
        local ADU = blob();
        ADU.writen(swap2(_transactionCount), 'w');
        ADU.writen(swap2(0x0000), 'w');
        ADU.writen(swap2(PDU.len() + 1), 'w');
        ADU.writen(0x00, 'b');
        ADU.writeblob(PDU);
        return ADU;
    }

    //
    // send the ADU via Ethernet
    //
    function _send(deviceAddress, PDU, properties) {
        _transactions[_transactionCount] <- properties;
        local ADU = _createADU(deviceAddress, PDU);
        _connection.transmit(ADU, function(error) {
            if (error) {
                _callbackHandler(error, null, properties.callback);
            } else {
                _transactionCount = (_transactionCount + 1) % MAX_TRANSACTION_COUNT;
                _log(ADU,"Outgoing ADU: ");
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

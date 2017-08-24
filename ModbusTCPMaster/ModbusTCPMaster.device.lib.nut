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

class ModbusTCPMaster extends ModbusMaster {
    static VERSION = "1.0.1";
    static MAX_TRANSACTION_COUNT = 65535;
    _transactions = null;
    _wiz = null;
    _transactionCount = null;
    _connection = null;
    _connectionSettings = null;
    _shouldRetry = null;
    _connectCallback = null;
    _reconnectCallback = null;

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
        ADU.writen(0x00, 'b');
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

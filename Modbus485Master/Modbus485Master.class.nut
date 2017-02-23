// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT


//------------------------------------------------------------------------------

class Modbus485Master {
    static VERSION = "1.0.0";
    static MINIMUM_RESPONSE_LENGTH = 5;
    _uart               = null;
    _rts                = null;
    _timeout            = null;
    _responseTimer      = null;
    _receiveBuffer      = null;
    _expectedResType    = null;
    _expectedResAddr    = null;
    _expectedResLen     = null;
    _quantity           = null;
    _callbackHandler    = null;
    _queue              = null;
    _debug              = null;

  /*
   * Constructor for Modbus485Master
   *
   * @param  {object} uart - The UART object
   * @param  {object} rts - The pin used as RTS
   * @param  {integer} baudRate - 19200 bit/sec by dafult
   * @param  {integer} dateBits - Word size , 8 bit by default
   * @param  {enum} parity - PARITY_NONE by default
   * @param  {integer} stopBits - 1 bit by default
   * @param  {float} timeout - 1.0 second by default
   * @param  {bool} debug - false by default. If enabled, the outgoing and incoming ADU will be printed for debugging purpose
   *
   */
    constructor(uart, rts, baudRate = 19200, dataBits = 8, parity = PARITY_NONE, stopBits = 1, timeout = 1.0, debug = false) {

        if (!("CRC16" in getroottable())) throw "Must include CRC16 library v1.0.0+";
        if (!("ModbusRTU" in getroottable())) throw "Must include ModbusRTU library v1.0.0+";
        _uart          = uart;
        _rts           = rts
        _timeout       = timeout;
        _receiveBuffer = blob();
        _queue         = [];
        _debug         = debug;
        _uart.configure(baudRate, dataBits, parity, stopBits, NO_CTSRTS, _uartCallback.bindenv(this));
        _rts.configure(DIGITAL_OUT, 0);
    }


  /*
   * This function performs a combination of one read operation and one write operation in a single MODBUS transaction. The write operation is performed before the read.
   *
   * @param {integer} deviceAddress - The unique address that identifies a device
   * @param {integer} readingStartAddress - The address from which it begins reading values
   * @param {integer} readQuantity - The number of consecutive addresses values are read from
   * @param {integer} writeStartAddress - The address from which it begins writing values
   * @param {integer} writeQuantity - The number of consecutive addresses values are written into
   * @param {blob} writeValue - The value written into the holding register
   * @param {function} callback - The function to be fired when it receives response regarding this request
   */
    function readWriteMultipleRegisters(deviceAddress, readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue, callback = null) {
        _enqueue(function() {
            _quantity = readQuantity;
            local PDU = ModbusRTU.createReadWriteMultipleRegistersPDU(readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue);
            _send(deviceAddress, PDU, ModbusRTU.FUNCTION_CODES.readWriteMultipleRegisters.resLen(readQuantity), callback);
        }.bindenv(this));
    }

    /*
     * This function modifies the contents of a specified holding register using a combination of an AND mask, an OR mask, and the register's current contents. The function can be used to set or clear individual bits in the register.
     *
     * @param {integer} deviceAddress - The unique address that identifies a device
     * @param {integer} referenceAddress - The address of the holding register the value is written into
     * @param {integer} AND_mask - The AND mask
     * @param {integer} OR_mask - The OR mask
     * @param {function} callback - The function to be fired when it receives response regarding this request
     */
    function maskWriteRegister(deviceAddress, referenceAddress, AND_Mask, OR_Mask, callback = null) {
        _enqueue(function() {
            local PDU = ModbusRTU.createMaskWriteRegisterPDU(referenceAddress, AND_Mask, OR_Mask);
            _send(deviceAddress, PDU, ModbusRTU.FUNCTION_CODES.maskWriteRegister.resLen, callback);
        }.bindenv(this));
    }

    /*
     * This function reads the description of the type, the current status, and other information specific to a remote device.
     *
     * @param {integer} deviceAddress - The unique address that identifies a device
     * @param {function} callback - The function to be fired when it receives response regarding this request
     */
    function reportSlaveID(deviceAddress, callback = null) {
        _enqueue(function() {
            local PDU = ModbusRTU.createReportSlaveIdPDU();
            _send(deviceAddress, PDU, ModbusRTU.FUNCTION_CODES.reportSlaveID.resLen, callback);
        }.bindenv(this));
    }

    /*
     * This function allows reading the identification and additional information relative to the physical and functional description of a remote device, only.
     *
     * @param {integer} deviceAddress - The unique address that identifies a device
     * @param {enum} readDeviceIdCode - read device id code
     * @param {enum} objectId - object id
     * @param {function} callback - The function to be fired when it receives response regarding this request
     */
    function readDeviceIdentification(deviceAddress, readDeviceIdCode, objectId, callback = null) {
        _enqueue(function() {
            local PDU = ModbusRTU.createReadDeviceIdentificationPDU(readDeviceIdCode,objectId);
            _send(deviceAddress, PDU, ModbusRTU.FUNCTION_CODES.readDeviceIdentification.resLen, callback);
        }.bindenv(this));
    }

    /*
     * This function provides a series of tests for checking the communication system between a client ( Master) device and a server ( Slave), or for checking various internal error conditions within a server.
     *
     * @param {integer} deviceAddress - The unique address that identifies a device
     * @param {integer} subFunctionCode - The address from which it begins reading values
     * @param {blob} data - The data field required by Modbus request
     * @param {function} callback - The function to be fired when it receives response regarding this request
     */
    function diagnostics(deviceAddress, subFunctionCode, data, callback = null) {
        _enqueue(function() {
            local wordCount = data.len() / 2;
            local PDU = ModbusRTU.createDiagnosticsPDU(subFunctionCode ,data);
            _quantity = wordCount ;
            _send(deviceAddress, PDU, ModbusRTU.FUNCTION_CODES.diagnostics.resLen(wordCount), callback);
        }.bindenv(this));
    }

    /*
     * This function reads the contents of eight Exception Status outputs in a remote device
     *
     * @param {integer} deviceAddress - The unique address that identifies a device
     * @param {function} callback - The function to be fired when it receives response regarding this request
     */
    function readExceptionStatus(deviceAddress, callback = null) {
        _enqueue(function() {
            local PDU = ModbusRTU.createReadExceptionStatusPDU();
            _send(deviceAddress, PDU, ModbusRTU.FUNCTION_CODES.readExceptionStatus.resLen, callback);
        }.bindenv(this));
    }


    /*
     * This is the generic function to read values from a single coil ,register or multiple coils , registers .
     *
     * @param {integer} deviceAddress - The unique address that identifies a device
     * @param {enum} targetType - The address from which it begins reading values
     * @param {integer} startingAddress - The address from which it begins reading values
     * @param {integer} quantity - The number of consecutive addresses the values are read from
     * @param {function} callback - The function to be fired when it receives response regarding this request
     */
    function read(deviceAddress, targetType, startingAddress, quantity, callback = null) {
        _enqueue(function() {
            try {
                _quantity = quantity;
                local PDU = null;
                local resLen = null;
                switch (targetType) {
                    case MODBUSRTU_TARGET_TYPE.COIL:
                        PDU = ModbusRTU.createReadPDU(ModbusRTU.FUNCTION_CODES.readCoils, startingAddress, quantity);
                        resLen = ModbusRTU.FUNCTION_CODES.readCoils.resLen(quantity);
                        break;
                    case MODBUSRTU_TARGET_TYPE.DISCRETE_INPUT:
                        PDU = ModbusRTU.createReadPDU(ModbusRTU.FUNCTION_CODES.readInputs, startingAddress, quantity);
                        resLen = ModbusRTU.FUNCTION_CODES.readInputs.resLen(quantity);
                        break;
                    case MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER:
                        PDU = ModbusRTU.createReadPDU(ModbusRTU.FUNCTION_CODES.readHoldingRegs, startingAddress, quantity);
                        resLen = ModbusRTU.FUNCTION_CODES.readHoldingRegs.resLen(quantity);
                        break;
                    case MODBUSRTU_TARGET_TYPE.INPUT_REGISTER:
                        PDU = ModbusRTU.createReadPDU(ModbusRTU.FUNCTION_CODES.readInputRegs, startingAddress, quantity);
                        resLen = ModbusRTU.FUNCTION_CODES.readInputRegs.resLen(quantity);
                        break;
                    default:
                        throw MODBUSRTU_EXCEPTION.INVALID_TARGET_TYPE;
                }
                _send(deviceAddress, PDU, resLen, callback);
            } catch (error) {
                _callbackHandler = callback;
                _errorCb(error);
            }
        }.bindenv(this))
    }

    /*
     * This is the generic function to write values into coils or holding registers .
     *
     * @param {integer} deviceAddress - The unique address that identifies a device
     * @param {enum} targetType - The address from which it begins reading values
     * @param {integer} startingAddress - The address from which it begins writing values
     * @param {integer} quantity - The number of consecutive addresses the values are written into
     * @param {integer, Array[integer,Bool], Bool, blob} values - The values written into Coils or Registers
     * @param {function} callback - The function to be fired when it receives response regarding this request
     */
    function write(deviceAddress, targetType, startingAddress, quantity, values, callback = null) {
        _enqueue(function() {
            try {
                _quantity = quantity;
                switch (targetType) {
                    case MODBUSRTU_TARGET_TYPE.COIL:
                        return _writeCoils(deviceAddress, startingAddress, quantity, values, callback);
                    case MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER:
                        return _writeRegs(deviceAddress, startingAddress, quantity, values, callback);
                    default:
                        throw MODBUSRTU_EXCEPTION.INVALID_TARGET_TYPE;
                }
            } catch (error) {
                _callbackHandler = callback;
                _errorCb(error);
            }
        }.bindenv(this));
    }


    /*
     * Invoke RESPONSE_TIMEOUT exception in certain seconds
     *
     * @param {float} timeout - The time in which exception RESPONSE_TIMEOUT will be invoked
     */
    function _responseTimeoutFactory(timeout) {
        return imp.wakeup(timeout, function() {
            _responseTimer = null;
            _errorCb(MODBUSRTU_EXCEPTION.RESPONSE_TIMEOUT);
        }.bindenv(this));
    }


    /*
     * Clear previous command
     *
     */
    function _clearPreviousCommand() {
        if (_responseTimer != null) {
            imp.cancelwakeup(_responseTimer);
            _responseTimer = null;
        }
        _quantity        = null;
        _expectedResType = null;
        _expectedResAddr = null;
        _expectedResLen  = null;
        _receiveBuffer.seek(0);
    }


    /*
     * the callback fired when a byte is received via UART
     *
     */
    function _uartCallback() {
        const MAX_RECEIVE_BUFFER_LENGTH = 300;
        local byte = _uart.read();
        while ((byte != -1) && (_receiveBuffer.len() < MAX_RECEIVE_BUFFER_LENGTH)) {
            if ((_receiveBuffer.len() > 0) || (byte != 0x00)) {
                _receiveBuffer.writen(byte, 'b');
            }
            byte = _uart.read();
        }
        if (_expectedResType != null) {
            _processBuffer();
        }
    }

    /*
     * process the receive buffer (ADU)
     *
     */
    function _processBuffer() {
        try {
            local bufferLength = _receiveBuffer.len();
            if (bufferLength < MINIMUM_RESPONSE_LENGTH) {
                return ;
            }
            // skip the device address
            _receiveBuffer.seek(1);
            // Parse and handle variable length responses
            local params = {
                PDU              = _receiveBuffer.readblob(bufferLength - 1),
                expectedResType  = _expectedResType,
                quantity         = _quantity,
                expectedResLen   = _expectedResLen
            };
            local result = ModbusRTU.parse(params);
            if (result == false) {
                // Keep waiting for more data
                return _receiveBuffer.seek(bufferLength);
            } else if (result == -1) {
                // Not the expected function code response. Shuffle forward and wait for more data.
                return _receiveBuffer.seek(1);
            } else {
                if (_expectedResLen == null) {
                    _expectedResLen = _calculateResponseLen(_expectedResType, result);
                    return _receiveBuffer.seek(bufferLength); // waiting for more data
                }
                if (bufferLength < _expectedResLen + 3) {
                    return _receiveBuffer.seek(bufferLength); // waiting for more data
                }
                //  got a valid packet
                if(_hasValidCRC(_receiveBuffer)) {
                    _clearPreviousCommand();
                    imp.wakeup(0, function() {
                        if (_callbackHandler) {
                            _callbackHandler(null, result);
                        }
                        _dequeue();
                    }.bindenv(this));
                } else {
                    throw MODBUSRTU_EXCEPTION.INVALID_CRC;
                }
            }
        } catch (error) {
            _errorCb(error);
        }
        _log(_receiveBuffer);
    }

    /*
     * calculate the length of the response from based on the result
     *
     */
    function _calculateResponseLen(expectedResType, result) {
        switch (_expectedResType) {
            case ModbusRTU.FUNCTION_CODES.readDeviceIdentification.fcode:
                // the first 7 bytes in the response
                local resLen = 7;
                foreach (value in result) {
                    resLen += value.len() + 2;
                }
                return resLen;
            case ModbusRTU.FUNCTION_CODES.reportSlaveID.fcode:
                // 3 bytes from function code, byte count, indicator
                return 3 + result.slaveId.len();
        }
    }

    /*
     * function to create ADU
     *
     */
    function _createADU(deviceAddress, PDU) {
        local ADU = blob();
        ADU.writen(deviceAddress, 'b');
        ADU.writeblob(PDU);
        ADU.writen(CRC16.calculate(ADU), 'w');
        return ADU;
    }


    /*
     * send the ADU
     *
     */
    function _send(deviceAddress, PDU, responseLength, callback) {
        _receiveBuffer = blob();
        if (deviceAddress > 0x00) {
            _expectedResAddr = deviceAddress;
            _expectedResType = PDU[0];
            _expectedResLen  = responseLength;
        }
        _callbackHandler = callback;
        local frame = _createADU(deviceAddress, PDU);
        local rw = _rts.write.bindenv(_rts);
        local uw = _uart.write.bindenv(_uart);
        local uf = _uart.flush.bindenv(_uart);
        rw(1);
        uw(frame);
        uf();
        rw(0);
        _log(frame);
        _responseTimer = _responseTimeoutFactory(_timeout);
    }



    /*
     * It determines if the ADU is valid
     *
     * @param {blob} frame - ADU
     */
    function _hasValidCRC(ADU) {
        local length = ADU.len();
        ADU.seek(0);
        local expectedCRC = CRC16.calculate(ADU.readblob(length - 2));
        local receivedCRC = ADU.readn('w');
        return (receivedCRC == expectedCRC);
    }


    /*
     * fire the callback function provided by the user when there is an error
     *
     */
    function _errorCb(err) {
        _clearPreviousCommand();
        imp.wakeup(0, function() {
            if (_callbackHandler) {
                _callbackHandler(err, false);
            }
            _dequeue();
        }.bindenv(this))
    }

    /*
     * put the function into a queue
     *
     */
    function _enqueue(queueFunction) {
        _queue.push(queueFunction);
        if (_queue.len() == 1) {
            imp.wakeup(0, queueFunction);
        }
    }

    /*
     * remove the function from a queue
     *
     */
    function _dequeue() {
        _queue.remove(0);
        if (_queue.len() > 0) {
            _queue[0]();
        }
    }

    /*
     * remove the function from a queue
     *
     */
    function _log(message) {
        if (_debug) {
            server.log(message);
        }
    }


    /*
     * construct the write coil ADU
     *
     */
    function _writeCoils(deviceAddress, startingAddress, quantity, values, callback = null) {
        local numBytes = math.ceil(quantity/8.0);
        local newvalues = blob(numBytes);
        switch (typeof values) {
            case "array":
                if (quantity != values.len()) {
                    throw MODBUSRTU_EXCEPTION.INVALID_ARG_LENGTH;
                }
                local byte, bitshift;
                foreach (bit,val in values) {
                    byte = bit / 8;
                    bitshift = bit % 8;
                    newvalues[byte] = newvalues[byte] | ((val ? 1 : 0) << bitshift);
                }
                values = newvalues;
                break;
            case "integer":
                newvalues.writen(swap2(values), 'w');
                values = newvalues;
                break;
            case "bool":
                newvalues.writen(swap2(values ? 0xFF00 : 0x0000), 'w');
                values = newvalues;
                break;
            case "blob":
                break;
            default:
                throw MODBUSRTU_EXCEPTION.INVALID_VALUES;
        }
        local request = (quantity == 1) ? ModbusRTU.FUNCTION_CODES.writeSingleCoil : ModbusRTU.FUNCTION_CODES.writeMultipleCoils;
        local PDU = ModbusRTU.createWritePDU(request,startingAddress,numBytes,quantity,values);
        _send(deviceAddress, PDU, ModbusRTU.FUNCTION_CODES.writeMultipleCoils.resLen, callback);
    }

    /*
     * construct the write registers ADU
     *
     */
    function _writeRegs(deviceAddress, startingAddress, quantity, values, callback = null) {
        local numBytes = quantity * 2;
        local newvalues = blob(numBytes);
        switch (typeof values) {
            case "array":
                if (quantity != values.len()) {
                    throw MODBUSRTU_EXCEPTION.INVALID_ARG_LENGTH;
                }
                foreach (val in values) {
                    newvalues.writen(swap2(val), 'w');
                }
                values = newvalues;
                break;
            case "integer":
                newvalues.writen(swap2(values), 'w');
                values = newvalues;
                break;
            case "blob":
                break;
            default:
                throw MODBUSRTU_EXCEPTION.INVALID_VALUES;
        }
        local request = (quantity == 1) ? ModbusRTU.FUNCTION_CODES.writeSingleReg : ModbusRTU.FUNCTION_CODES.writeMultipleRegs;
        local PDU = ModbusRTU.createWritePDU(request,startingAddress,numBytes,quantity,values);
        _send(deviceAddress, PDU, ModbusRTU.FUNCTION_CODES.writeMultipleRegs.resLen, callback);
    }
}


//------------------------------------------------------------------------------

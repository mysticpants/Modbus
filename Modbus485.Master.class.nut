
// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT


class Modbus485 {
    static VERSION = "1.0.0";
}

//------------------------------------------------------------------------------

class Modbus485.Master {
    static MINIMUM_REQUEST_LENGTH = 5;
    _uart               = null;
    _rts                = null;
    _charTime           = null;
    _timeout            = null;
    _responseTimer      = null;
    _turnaroundTime     = null;
    _receiveBuffer      = null;
    _expectedResType    = null;
    _expectedResAddr    = null;
    _expectedResLen     = null;
    _startingAddress    = null;
    _targetType         = null;
    _quantity           = null;
    _callbackHandler    = null;
    _queue              = null;

  /*
   * Constructor for Modbus485.Master
   *
   * @param  {Object} uart - The UART object
   * @param  {Object} rts - The pin used as RTS
   * @param  {Int} baudRate - 19200 bit/sec by dafult
   * @param  {Int} dateBits - Word size , 8 bit by default
   * @param  {Constant} parity - PARITY_NONE by default
   * @param  {Int} stopBits - 1 bit by default
   * @param  {Float} timeout - 1.0 second by default
   *
   *
   */
    constructor(uart, rts, baudRate = 19200, dataBits = 8, parity = PARITY_NONE, stopBits = 1, timeout = 1.0) {

        if (!("CRC16" in getroottable())) throw "Include CRC16 library v1.0.0+";
        _uart          = uart;
        _rts           = rts
        _charTime      = 1.0 / baudRate;
        _timeout       = timeout;
        _receiveBuffer = blob();
        _queue         = [];
        _uart.configure(baudRate, dataBits, parity, stopBits, NO_CTSRTS, _uartCallback.bindenv(this));
        _rts.configure(DIGITAL_OUT, 0);
    }


  /*
   * This function performs a combination of one read operation and one write operation in a single MODBUS transaction. The write operation is performed before the read.
   *
   * @param {Int} deviceAddress - The unique address that identifies a device
   * @param {Int} readingStartAddress - The address from which it begins reading values
   * @param {Int} readQuantity - The number of consecutive addresses values are read from
   * @param {Int} writeStartAddress - The address from which it begins writing values
   * @param {Int} writeQuantity - The number of consecutive addresses values are written into
   * @param {Blob} writeValue - The value written into the holding register
   * @param {Function} callback - The function to be fired when it receives response regarding this request
   */
    function readWriteMultipleRegisters (deviceAddress, readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue ,callback = null ){
        _enqueue(function (){
            _quantity = readQuantity;
            local PDU = Modbus.createReadWriteMultipleRegistersPDU(readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue);
            _send(deviceAddress,PDU, Modbus.FUNCTION_CODES.readWriteMultipleRegisters.resLen(readQuantity),callback);
        }.bindenv(this));
    }

    /*
     * This function modifies the contents of a specified holding register using a combination of an AND mask, an OR mask, and the register's current contents. The function can be used to set or clear individual bits in the register.
     *
     * @param {Int} deviceAddress - The unique address that identifies a device
     * @param {Int} referenceAddress - The address of the holding register the value is written into
     * @param {Int} AND_mask - The AND mask
     * @param {Int} OR_mask - The OR mask
     * @param {Function} callback - The function to be fired when it receives response regarding this request
     */
    function maskWriteRegister (deviceAddress,referenceAddress , AND_Mask , OR_Mask , callback = null ){
        _enqueue(function (){
            local PDU = Modbus.createMaskWriteRegisterPDU(referenceAddress , AND_Mask , OR_Mask);
            _send(deviceAddress,PDU,Modbus.FUNCTION_CODES.maskWriteRegister.resLen,callback);
        }.bindenv(this));
    }

    /*
     * This function reads the description of the type, the current status, and other information specific to a remote device.
     *
     * @param {Int} deviceAddress - The unique address that identifies a device
     * @param {Function} callback - The function to be fired when it receives response regarding this request
     */
    function reportSlaveID (deviceAddress,callback = null) {
        _enqueue(function (){
            local PDU = Modbus.createReportSlaveIdPDU();
            _send(deviceAddress,PDU,Modbus.FUNCTION_CODES.reportSlaveID.resLen,callback);
        }.bindenv(this));
    }

    /*
     * This function allows reading the identification and additional information relative to the physical and functional description of a remote device, only.
     *
     * @param {Int} deviceAddress - The unique address that identifies a device
     * @param {Enum} readDeviceIdCode - read device id code
     * @param {Enum} objectId - Object id
     * @param {Function} callback - The function to be fired when it receives response regarding this request
     */
    function readDeviceIdentification (deviceAddress, readDeviceIdCode , objectId , callback = null ){
        _enqueue(function (){
            local PDU = Modbus.createreadDeviceIdentificationPDU(readDeviceIdCode,objectId);
            _send(deviceAddress, PDU, Modbus.FUNCTION_CODES.readDeviceIdentification.resLen, callback);
        }.bindenv(this));
    }

    /*
     * This function provides a series of tests for checking the communication system between a client ( Master) device and a server ( Slave), or for checking various internal error conditions within a server.
     *
     * @param {Int} deviceAddress - The unique address that identifies a device
     * @param {Int} subFunctionCode - The address from which it begins reading values
     * @param {Blob} data - The data field required by Modbus request
     * @param {Function} callback - The function to be fired when it receives response regarding this request
     */
    function diagnostics (deviceAddress, subFunctionCode ,data,callback = null){
        _enqueue(function() {
            local wordCount = data.len() / 2;
            local PDU = Modbus.createDiagnosticsPDU(subFunctionCode ,data);
            _quantity = wordCount ;
            _send(deviceAddress,PDU,Modbus.FUNCTION_CODES.diagnostics.resLen(wordCount),callback);
        }.bindenv(this));

    }

    /*
     * This function reads the contents of eight Exception Status outputs in a remote device
     *
     * @param {Int} deviceAddress - The unique address that identifies a device
     * @param {Function} callback - The function to be fired when it receives response regarding this request
     */
    function readExceptionStatus (deviceAddress,callback = null){
        _enqueue(function() {
            local PDU = Modbus.createReadExceptionStatusPDU();
            _send(deviceAddress,PDU, Modbus.FUNCTION_CODES.readExceptionStatus.resLen , callback);
        }.bindenv(this));
    }


    /*
     * This is the generic function to read values from a single coil ,register or multiple coils , registers .
     *
     * @param {Int} deviceAddress - The unique address that identifies a device
     * @param {Enum} targetType - The address from which it begins reading values
     * @param {Int} startingAddress - The address from which it begins reading values
     * @param {Int} quantity - The number of consecutive addresses the values are read from
     * @param {Function} callback - The function to be fired when it receives response regarding this request
     */
    function read(deviceAddress, targetType, startingAddress, quantity, callback = null) {
        _enqueue(function() {
            _startingAddress = startingAddress;
            _targetType = targetType;
            _quantity = quantity;
            local PDU = null;
            local resLen = null;
            switch (targetType) {
                case MODBUS_TARGET_TYPE.COIL:
                    PDU = Modbus.createReadPDU(Modbus.FUNCTION_CODES.readCoils, startingAddress, quantity);
                    resLen = Modbus.FUNCTION_CODES.readCoils.resLen;
                    break;
                case MODBUS_TARGET_TYPE.DISCRETE_INPUT:
                    PDU = Modbus.createReadPDU(Modbus.FUNCTION_CODES.readInputs, startingAddress, quantity);
                    resLen = Modbus.FUNCTION_CODES.readInputs.resLen;
                    break;
                case MODBUS_TARGET_TYPE.HOLDING_REGISTER:
                    PDU = Modbus.createReadPDU(Modbus.FUNCTION_CODES.readHoldingRegs, startingAddress, quantity);
                    resLen = Modbus.FUNCTION_CODES.readHoldingRegs.resLen;
                    break;
                case MODBUS_TARGET_TYPE.INPUT_REGISTER:
                    PDU = Modbus.createReadPDU(Modbus.FUNCTION_CODES.readInputRegs, startingAddress, quantity);
                    resLen = Modbus.FUNCTION_CODES.readInputRegs.resLen;
                    break;
                default:
                    throw "read() with invalid targetType: " + targetType;
            }
        _send(deviceAddress, PDU, resLen, callback);
        }.bindenv(this))
    }

    /*
     * This is the generic function to write values into coils or holding registers .
     *
     * @param {Int} deviceAddress - The unique address that identifies a device
     * @param {Enum} targetType - The address from which it begins reading values
     * @param {Int} startingAddress - The address from which it begins writing values
     * @param {Int} quantity - The number of consecutive addresses the values are written into
     * @param {Int, Array[Int,Bool], Bool, Blob} values - The values written into Coils or Registers
     * @param {Function} callback - The function to be fired when it receives response regarding this request
     */
    function write(deviceAddress, targetType, startingAddress, quantity, values, callback = null) {
        _enqueue(function() {
            _startingAddress = startingAddress;
            _targetType = targetType;
            _quantity = quantity;
            switch (targetType) {
                case MODBUS_TARGET_TYPE.COIL:
                    return _writeCoils(deviceAddress, startingAddress, quantity, values, callback);
                case MODBUS_TARGET_TYPE.HOLDING_REGISTER:
                    return _writeRegs(deviceAddress, startingAddress, quantity, values, callback);
                default:
                    throw "write() with invalid targetType: " + targetType;
            }
        }.bindenv(this));
    }

    /*
     * It determines if the ADU is valid
     *
     * @param {Blob} frame - ADU
     * @param {Int} length - The length of the frame
     */
    function _hasValidCRC(frame, length) {
        frame.seek(0);
        local expectedCRC = CRC16.calculate(frame.readblob(length - 2));
        local receivedCRC = frame.readn('w');
        return (receivedCRC == expectedCRC);
    }

    /*
     * Invoke RESPONSE_TIMEOUT exception in certain seconds
     *
     * @param {Float} timeout - The time in which exception RESPONSE_TIMEOUT will be invoked
     */
    function _responseTimeoutFactory(timeout) {
        return imp.wakeup(timeout, function() {
            _responseTimer = null;
            _errorCb(MODBUS_EXCEPTION.RESPONSE_TIMEOUT);
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
        _startingAddress = null;
        _targetType      = null;
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
        local byte = _uart.read();
        while ((byte != -1) && (_receiveBuffer.len() < 300)) {
            if (_receiveBuffer.len() > 0 || byte != 0x00) {
                _receiveBuffer.writen(byte, 'b');
            }
            byte = _uart.read();
        }
        if (_expectedResType != null && _receiveBuffer.len() >= MINIMUM_REQUEST_LENGTH) {
            _processBuffer();
        }
    }

    /*
     * process the receive buffer (ADU)
     *
     */
    function _processBuffer() {
        local bufferLength = _receiveBuffer.len();
        if (bufferLength < MINIMUM_REQUEST_LENGTH) {
            return _receiveBuffer.seek(bufferLength);
        }
        _receiveBuffer.seek(0);
        local address = _receiveBuffer.readn('b');
        local functionCode = _receiveBuffer.readn('b');
        server.log(_receiveBuffer);
        if ((functionCode & 0x80) == 0x80) {
            local exceptionCode = _receiveBuffer.readn('b');
            if (_hasValidCRC(_receiveBuffer, bufferLength)) {
                _errorCb(exceptionCode);
            } else {
                _errorCb(MODBUS_EXCEPTION.INVALID_CRC);
            }
            return;
        } else if (_expectedResLen == null) {
            _expectedResLen = _receiveBuffer.readn('b') + 2;
        }
        // Parse and handle variable length responses
        local params = {
            functionCode     = functionCode,
            buffer           = _receiveBuffer,
            expectedResType  = _expectedResType,
            expectedResLen   = _expectedResLen,
            quantity         = _quantity

        };
        local result = Modbus.parse(params);
        if (result == false) {
            // Keep waiting for more data
            return _receiveBuffer.seek(bufferLength);
        } else if (functionCode != _expectedResType) {
            // Not the expected function code response. Shuffle forward and wait for more data.
            return _receiveBuffer.seek(1);
        }
        // Check the CRC
        if (_hasValidCRC(_receiveBuffer, bufferLength)) {
            // Got a valid packet!
            _clearPreviousCommand();
            imp.wakeup(0, function() {
                if (_callbackHandler) {
                    _callbackHandler(null, address, result);
                }
                _dequeue();
            }.bindenv(this))
        } else {
            /*
            // We are failing the CRC check
            _receiveBuffer.seek(0)
            local address = _receiveBuffer.readn('b');
            local type = _receiveBuffer.readn('b');
            local length  = _receiveBuffer.readn('b');
            local nullByte = _receiveBuffer.readn('b');

            local expectedLength = _receiveBuffer.len() - 6;
            if (address == _expectedResAddr && type == _expectedResType && length == expectedLength && nullByte == 0x00) {
            */
               _errorCb(MODBUS_EXCEPTION.INVALID_CRC);
            /*
                return;
            }


            // Hack the data buffer???
            _receiveBuffer.seek(0);
            _receiveBuffer.writen(_expectedResAddr, 'b');
            _receiveBuffer.writen(_expectedResType, 'b');
            _receiveBuffer.writen(expectedLength, 'w');
            _receiveBuffer.seek(0, 'e');

            _processBuffer();
            */
        }

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
            _expectedResLen = responseLength;
        }
        _callbackHandler = callback;
        local frame = blob();
        frame.writen(deviceAddress, 'b');
        frame.writeblob(PDU);
        frame.writen(CRC16.calculate(frame), 'w');
        local rw = _rts.write.bindenv(_rts);
        local uw = _uart.write.bindenv(_uart);
        local uf = _uart.flush.bindenv(_uart);
        rw(1);
        uw(frame);
        uf();
        rw(0);
        server.log(frame);
        _responseTimer = _responseTimeoutFactory(_timeout);

    }

    /*
     * fire the callback function provided by the user when there is an error
     *
     */
    function _errorCb(err) {
        local addr = _startingAddress;
        _clearPreviousCommand();
        imp.wakeup(0, function() {
            if (_callbackHandler) _callbackHandler(err, addr, false);
            _dequeue();
        }.bindenv(this))
    }

    /*
     * put the function into a queue
     *
     */
    function _enqueue(queueFunction) {
        _queue.push(queueFunction);
        if (_queue.len() == 1) imp.wakeup(0, queueFunction);
    }

    /*
     * remove the function from a queue
     *
     */
    function _dequeue() {
        _queue.remove(0);
        if (_queue.len() > 0) _queue[0]();
    }


    /*
     * construct the write coil ADU
     *
     */
    function _writeCoils(deviceAddress, startingAddress, quantity, values, callback = null) {
        try{
            local numBytes = math.ceil(quantity/8.0);
            local newvalues = blob(numBytes);
            switch (typeof values) {
                case "array":
                    if (quantity != values.len()){
                        server.error(format("values wrong length: %d != %d", values.len(), quantity));
                        throw MODBUS_EXCEPTION.INVALID_ARG_LENGTH;
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
                    server.error(format("values wrong type: %s", typeof values));
                    throw MODBUS_EXCEPTION.INVALID_VALUES;
            }
            local request = (quantity == 1) ? Modbus.FUNCTION_CODES.writeSingleCoil : Modbus.FUNCTION_CODES.writeMultipleCoils;
            local PDU = Modbus.createWritePDU(request,startingAddress,numBytes,quantity,values);
            _send(deviceAddress, PDU, Modbus.FUNCTION_CODES.writeMultipleCoils.resLen, callback);
        }
        catch(error){
           _callbackHandler = callback;
           _errorCb(error);
        }
    }

    /*
     * construct the write registers ADU
     *
     */
    function _writeRegs(deviceAddress, startingAddress, quantity, values, callback = null) {
        try{
            local numBytes = quantity * 2;
            local newvalues = blob(numBytes);
            switch (typeof values) {
                case "array":
                    if (quantity != values.len()) {
                        server.error(format("values wrong length: %d != %d", values.len(), quantity));
                        throw MODBUS_EXCEPTION.INVALID_ARG_LENGTH;
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
                    server.error(format("values wrong type: %s", typeof values));
                    throw MODBUS_EXCEPTION.INVALID_VALUES;
            }
            local request = (quantity == 1) ? Modbus.FUNCTION_CODES.writeSingleReg : Modbus.FUNCTION_CODES.writeMultipleRegs;
            local PDU = Modbus.createWritePDU(request,startingAddress,numBytes,quantity,values);
            _send(deviceAddress, PDU, Modbus.FUNCTION_CODES.writeMultipleRegs.resLen, callback);

        } catch(error){
            _callbackHandler = callback;
            _errorCb(error);
        }
    }
}


//------------------------------------------------------------------------------

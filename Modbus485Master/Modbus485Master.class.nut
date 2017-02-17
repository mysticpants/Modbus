// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT


//------------------------------------------------------------------------------

class Modbus485Master {
    static VERSION = "1.0.0";
    static MINIMUM_RESPONSE_LENGTH = 5;
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
    _debug              = null;

  /*
   * Constructor for Modbus485Master
   *
   * @param  {Object} uart - The UART object
   * @param  {Object} rts - The pin used as RTS
   * @param  {Int} baudRate - 19200 bit/sec by dafult
   * @param  {Int} dateBits - Word size , 8 bit by default
   * @param  {Constant} parity - PARITY_NONE by default
   * @param  {Int} stopBits - 1 bit by default
   * @param  {Float} timeout - 1.0 second by default
   * @param  {Boolean} debug - false by default. If enabled, the outgoing and incoming ADU will be printed for debugging purpose
   *
   */
    constructor(uart, rts, baudRate = 19200, dataBits = 8, parity = PARITY_NONE, stopBits = 1, timeout = 1.0, debug = false) {

        if (!("CRC16" in getroottable())) throw "Must include CRC16 library v1.0.0+";
        if (!("ModbusRTU" in getroottable())) throw "Must include ModbusRTU library v1.0.0+";
        _uart          = uart;
        _rts           = rts
        _charTime      = 1.0 / baudRate;
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
   * @param {Int} deviceAddress - The unique address that identifies a device
   * @param {Int} readingStartAddress - The address from which it begins reading values
   * @param {Int} readQuantity - The number of consecutive addresses values are read from
   * @param {Int} writeStartAddress - The address from which it begins writing values
   * @param {Int} writeQuantity - The number of consecutive addresses values are written into
   * @param {Blob} writeValue - The value written into the holding register
   * @param {Function} callback - The function to be fired when it receives response regarding this request
   */
    function readWriteMultipleRegisters (deviceAddress, readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue, callback = null){
        _enqueue(function (){
            _quantity = readQuantity;
            local PDU = ModbusRTU.createReadWriteMultipleRegistersPDU(readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue);
            _send(deviceAddress,PDU, ModbusRTU.FUNCTION_CODES.readWriteMultipleRegisters.resLen(readQuantity),callback);
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
    function maskWriteRegister (deviceAddress, referenceAddress, AND_Mask, OR_Mask, callback = null){
        _enqueue(function (){
            local PDU = ModbusRTU.createMaskWriteRegisterPDU(referenceAddress , AND_Mask , OR_Mask);
            _send(deviceAddress,PDU,ModbusRTU.FUNCTION_CODES.maskWriteRegister.resLen,callback);
        }.bindenv(this));
    }

    /*
     * This function reads the description of the type, the current status, and other information specific to a remote device.
     *
     * @param {Int} deviceAddress - The unique address that identifies a device
     * @param {Function} callback - The function to be fired when it receives response regarding this request
     */
    function reportSlaveID (deviceAddress, callback = null) {
        _enqueue(function (){
            local PDU = ModbusRTU.createReportSlaveIdPDU();
            _send(deviceAddress,PDU,ModbusRTU.FUNCTION_CODES.reportSlaveID.resLen,callback);
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
    function readDeviceIdentification (deviceAddress, readDeviceIdCode, objectId, callback = null){
        _enqueue(function (){
            local PDU = ModbusRTU.createReadDeviceIdentificationPDU(readDeviceIdCode,objectId);
            _send(deviceAddress, PDU, ModbusRTU.FUNCTION_CODES.readDeviceIdentification.resLen, callback);
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
    function diagnostics (deviceAddress, subFunctionCode, data, callback = null){
        _enqueue(function() {
            local wordCount = data.len() / 2;
            local PDU = ModbusRTU.createDiagnosticsPDU(subFunctionCode ,data);
            _quantity = wordCount ;
            _send(deviceAddress,PDU,ModbusRTU.FUNCTION_CODES.diagnostics.resLen(wordCount),callback);
        }.bindenv(this));

    }

    /*
     * This function reads the contents of eight Exception Status outputs in a remote device
     *
     * @param {Int} deviceAddress - The unique address that identifies a device
     * @param {Function} callback - The function to be fired when it receives response regarding this request
     */
    function readExceptionStatus (deviceAddress, callback = null){
        _enqueue(function() {
            local PDU = ModbusRTU.createReadExceptionStatusPDU();
            _send(deviceAddress,PDU, ModbusRTU.FUNCTION_CODES.readExceptionStatus.resLen , callback);
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
            try{
                _startingAddress = startingAddress;
                _targetType = targetType;
                _quantity = quantity;
                local PDU = null;
                local resLen = null;
                switch (targetType) {
                    case MODBUS_TARGET_TYPE.COIL:
                        PDU = ModbusRTU.createReadPDU(ModbusRTU.FUNCTION_CODES.readCoils, startingAddress, quantity);
                        resLen = ModbusRTU.FUNCTION_CODES.readCoils.resLen(quantity);
                        break;
                    case MODBUS_TARGET_TYPE.DISCRETE_INPUT:
                        PDU = ModbusRTU.createReadPDU(ModbusRTU.FUNCTION_CODES.readInputs, startingAddress, quantity);
                        resLen = ModbusRTU.FUNCTION_CODES.readInputs.resLen(quantity);
                        break;
                    case MODBUS_TARGET_TYPE.HOLDING_REGISTER:
                        PDU = ModbusRTU.createReadPDU(ModbusRTU.FUNCTION_CODES.readHoldingRegs, startingAddress, quantity);
                        resLen = ModbusRTU.FUNCTION_CODES.readHoldingRegs.resLen(quantity);
                        break;
                    case MODBUS_TARGET_TYPE.INPUT_REGISTER:
                        PDU = ModbusRTU.createReadPDU(ModbusRTU.FUNCTION_CODES.readInputRegs, startingAddress, quantity);
                        resLen = ModbusRTU.FUNCTION_CODES.readInputRegs.resLen(quantity);
                        break;
                    default:
                        throw MODBUS_EXCEPTION.INVALID_TARGET_TYPE;
                }
                _send(deviceAddress, PDU, resLen, callback);
            }catch(error){
                _callbackHandler = callback;
                _errorCb(error);
            }
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
            try{
                _startingAddress = startingAddress;
                _targetType = targetType;
                _quantity = quantity;
                switch (targetType) {
                    case MODBUS_TARGET_TYPE.COIL:
                        return _writeCoils(deviceAddress, startingAddress, quantity, values, callback);
                    case MODBUS_TARGET_TYPE.HOLDING_REGISTER:
                        return _writeRegs(deviceAddress, startingAddress, quantity, values, callback);
                    default:
                        throw MODBUS_EXCEPTION.INVALID_TARGET_TYPE;
                }
            }catch(error){
                _callbackHandler = callback;
                _errorCb(error);
            }
        }.bindenv(this));
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
        if (_expectedResType != null) {
            _processBuffer();
        }
    }

    /*
     * process the receive buffer (ADU)
     *
     */
    function _processBuffer() {
        try{
            local bufferLength = _receiveBuffer.len();
            if (bufferLength < MINIMUM_RESPONSE_LENGTH) {
                return ;
            }
            _receiveBuffer.seek(1); // skip the device address
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
                if (_expectedResLen == null){
                    _expectedResLen = _calculateResponseLen(_expectedResType, result);
                    return _receiveBuffer.seek(bufferLength); // waiting for more data
                }
                if (bufferLength < _expectedResLen + 3){
                    return _receiveBuffer.seek(bufferLength); // waiting for more data
                }
                //  got a valid packet
                if(_hasValidCRC(_receiveBuffer)){
                    _clearPreviousCommand();
                    imp.wakeup(0, function() {
                        if (_callbackHandler) {
                            _callbackHandler(null, result);
                        }
                        _dequeue();
                    }.bindenv(this));
                } else{
                    throw MODBUS_EXCEPTION.INVALID_CRC;
                }
            }
        } catch(error){
              _errorCb(error);
        }
        _log(_receiveBuffer);
    }

    /*
     * calculate the length of the response from based on the result
     *
     */
    function _calculateResponseLen(expectedResType, result){
        switch(_expectedResType){
            case ModbusRTU.FUNCTION_CODES.readDeviceIdentification.fcode :
                local resLen = 7;
                foreach (value in result) {
                    resLen += value.len() + 2;
                }
                return resLen;
            case ModbusRTU.FUNCTION_CODES.reportSlaveID.fcode :
                return 3 + result.slaveId.len(); //  function code  , byte count , indicator
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
            _expectedResLen = responseLength;
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
     * @param {Blob} frame - ADU
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
            if (_callbackHandler) _callbackHandler(err, false);
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
     * remove the function from a queue
     *
     */
    function _log(message) {
        if(_debug){
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
                if (quantity != values.len()){
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
                throw MODBUS_EXCEPTION.INVALID_VALUES;
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
                throw MODBUS_EXCEPTION.INVALID_VALUES;
        }
        local request = (quantity == 1) ? ModbusRTU.FUNCTION_CODES.writeSingleReg : ModbusRTU.FUNCTION_CODES.writeMultipleRegs;
        local PDU = ModbusRTU.createWritePDU(request,startingAddress,numBytes,quantity,values);
        _send(deviceAddress, PDU, ModbusRTU.FUNCTION_CODES.writeMultipleRegs.resLen, callback);
    }
}


//------------------------------------------------------------------------------

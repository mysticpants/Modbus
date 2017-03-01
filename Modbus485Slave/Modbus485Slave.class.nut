class Modbus485Slave {
    static VERSION = "1.0.0";
    _slaveID = null;
    _uart = null;
    _rts = null;
    _debug = null;
    _receiveBuffer = null;
    _shouldParseADU = null;
    _minInterval = null;
    _onReadCallback = null;
    _onWriteCallback = null;

    constructor(uart, rts, slaveID, params = {}) {
        if (!("CRC16" in getroottable())) {
            throw "Must include CRC16 library v1.0.0+";
        }
        if (!("ModbusSlave" in getroottable())) {
            throw "Must include ModbusSlave library v1.0.0+";
        }
        _uart = uart;
        _rts = rts;
        _slaveID = slaveID;
        _shouldParseADU = true;
        _debug = ("debug" in params) ? params.debug : false;
        local baudRate = ("baudRate" in params) ? params.baudRate : 19200;
        local dataBits = ("dataBits" in params) ? params.dataBits : 8;
        local parity = ("parity" in params) ? params.parity : PARITY_NONE;
        local stopBits = ("stopBits" in params) ? params.stopBits : 1;
        _receiveBuffer = blob();
        // 4.5 characters time in microseconds
        _minInterval = 45000000.0 / baudRate;
        _uart.configure(baudRate, dataBits, parity, stopBits, TIMING_ENABLED, _onReceive.bindenv(this));
        _rts.configure(DIGITAL_OUT, 0);
    }

    function read(targetType, address) {
        return ModbusSlave.read(targetType, address);
    }

    function onRead(callback) {
        _onReadCallback = callback;
    }

    function write(targetType, address, value) {
        return ModbusSlave.write(targetType, address, value);
    }

    function onWrite(callback) {
        _onWriteCallback = callback;
    }

    function _onReceive() {
        local data = _uart.read();
        while (data != -1) {
            if (_receiveBuffer.len() > 0 || data != 0x00) {
                local interval = data >> 8;
                if (interval > _minInterval) {
                    // new frame, reset the _receiveBuffer
                    _receiveBuffer = blob();
                    _shouldParseADU = true;
                }
                _receiveBuffer.writen(data, 'b');
            }
            data = _uart.read();
        }
        const MIN_REQUEST_LENGTH = 4;
        if (_shouldParseADU && _receiveBuffer.len() >= MIN_REQUEST_LENGTH) {
            _processReceiveBuffer();
        }
    }

    function _processReceiveBuffer() {
        _receiveBuffer.seek(0);
        local bufferLength = _receiveBuffer.len();
        local slaveID = _receiveBuffer.readn('b');
        if (_slaveID != slaveID) {
            return _shouldParseADU = false;
        }
        local PDU = _receiveBuffer.readblob(bufferLength - 1);
        local result = ModbusSlave.parse(PDU);
        if (result == false) {
            return _receiveBuffer.seek(bufferLength);
        }
        if (bufferLength < result.expectedReqLen + 3) {
            return _receiveBuffer.seek(bufferLength);
        }
        if (!_hasValidCRC()) {
             throw "Invalid CRC";
        }
        _log(_receiveBuffer,"Incoming ADU : ");
        local input = null, response = null;
        local functionCode = result.functionCode;
        switch (functionCode) {
            case ModbusSlave.FUNCTION_CODES.readCoil.fcode:
            case ModbusSlave.FUNCTION_CODES.readDiscreteInput.fcode:
                input = _onReadCallback(null, result);
                response = _createReadCoilPDU(result, input);
                break;
            case ModbusSlave.FUNCTION_CODES.readRegister.fcode:
            case ModbusSlave.FUNCTION_CODES.readInputRegister.fcode:
                input = _onReadCallback(null, result);
                response = _createReadRegisterPDU(result, input);
                break;
            case ModbusSlave.FUNCTION_CODES.writeCoil.fcode:
            case ModbusSlave.FUNCTION_CODES.writeRegister.fcode:
                input = _onWriteCallback(null, result);
                response = _createWritePDU(result, input, true);
                break;
            case ModbusSlave.FUNCTION_CODES.writeCoils.fcode:
            case ModbusSlave.FUNCTION_CODES.writeRegisters.fcode:
                input = _onWriteCallback(null, result);
                response = _createWritePDU(result, input, false);
                break;
        }
        local ADU = _createADU(response);
        _send(ADU);
    }

    function _createADU(PDU) {
        local ADU = blob();
        ADU.writen(_slaveID, 'b');
        ADU.writeblob(PDU);
        ADU.writen(CRC16.calculate(ADU), 'w');
        return ADU;
    }

    function _createWritePDU(request, input, isSingleWrite) {
        local PDU = blob();
        if (input == true || input == null) {
            PDU.writen(request.functionCode, 'b');
            PDU.writen(swap2(request.startingAddress), 'w');
            if (isSingleWrite) {
                PDU.writen(swap2(request.writeValues), 'w');
            } else {
                PDU.writen(swap2(request.quantity), 'w');
            }
        } else {
            PDU = ModbusSlave.createErrorPDU(request.functionCode, (input == false) ? 1 : input);
        }
        return PDU;
    }

    function _createReadCoilPDU(request, values) {
        local byteNum = math.ceil(request.quantity / 8.0);
        local PDU = blob();
        PDU.writen(request.functionCode, 'b');
        PDU.writen(byteNum, 'b');
        switch (typeof values) {
            case "integer":
                PDU.writen((values == 1 ? 1 : 0), 'b');
                break;
            case "array":
                if (request.quantity != values.len()) {
                    throw "quantity is not equal to the length of values";
                }
                local status = blob(byteNum);
                local mask = 1;
                local byte = 0;
                foreach (index, value in values) {
                    if (value) {
                        status[byte] = mask | status[byte];
                    }
                    mask = mask << 1;
                    if (index % 8 == 7) {
                        byte++;
                        mask = 1;
                    }
                }
                PDU.writeblob(status);
            case "bool":
                PDU.writen((values ? 1 : 0), 'b');
                break;
            case "blob":
                PDU.writeblob(values);
            default:
                throw "Invalid Value Type";
        }
        return PDU;
    }

    function _createReadRegisterPDU(request, values) {
        local PDU = blob();
        local quantity = request.quantity;
        PDU.writen(request.functionCode, 'b');
        PDU.writen(2 * quantity, 'b');
        switch (typeof values) {
            case "integer":
                PDU.writen(swap2(values), 'w');
                break;
            case "array":
                if (quantity != values.len()) {
                    throw "quantity is not equal to the length of values";
                }
                foreach (value in values) {
                    PDU.writen(swap2(value), 'w');
                }
                break;
            case "blob":
                PDU.writeblob(values);
                break;
            default:
                throw "Invalid Value Type";
        }
        return PDU;
    }

    function _send(ADU) {
        local rw = _rts.write.bindenv(_rts);
        local uw = _uart.write.bindenv(_uart);
        local uf = _uart.flush.bindenv(_uart);
        rw(1);
        uw(ADU);
        uf();
        rw(0);
        _log(ADU,"Outgoing ADU : ");
    }

    function _log(message, prefix = "") {
        if (_debug) {
            switch (typeof message) {
                case "blob":
                    local mes = prefix;
                    foreach (value in message) {
                        mes += format("%02X ", value);
                    }
                    return server.log(mes);
                default:
                    return server.log(message);
            }
        }
    }

    function _hasValidCRC() {
        _receiveBuffer.seek(0);
        local content = _receiveBuffer.readblob(_receiveBuffer.len() - 2);
        local crc = _receiveBuffer.readn('w');
        return (crc == CRC16.calculate(content));
    }
}

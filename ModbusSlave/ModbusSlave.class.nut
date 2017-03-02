
enum MODBUSSLAVE_TARGET_TYPE {
    COIL,
    DISCRETE_INPUT,
    HOLDING_REGISTER,
    INPUT_REGISTER
}

enum MODBUSSLAVE_EXCEPTION {
    ILLEGAL_FUNCTION = 0x01,
    ILLEGAL_DATA_ADDR = 0x02,
    ILLEGAL_DATA_VAL = 0x03,
    SLAVE_DEVICE_FAIL = 0x04,
    ACKNOWLEDGE = 0x05,
    SLAVE_DEVICE_BUSY = 0x06,
    NEGATIVE_ACKNOWLEDGE = 0x07,
    MEMORY_PARITY_ERROR = 0x08,
}


class ModbusSlave {
    static VERSION = "1.0.0";
    static FUNCTION_CODES = {
        readCoil = {
            fcode = 0x01,
            reqLen = 5
        },
        readDiscreteInput = {
            fcode = 0x02,
            reqLen = 5
        },
        readRegister = {
            fcode = 0x03,
            reqLen = 5
        },
        readInputRegister = {
            fcode = 0x04,
            reqLen = 5
        },
        writeCoil = {
            fcode = 0x05,
            reqLen = 5
        },
        writeRegister = {
            fcode = 0x06,
            reqLen = 5
        },
        writeCoils = {
            fcode = 0x0F,
            reqLen = null
        },
        writeRegisters = {
            fcode = 0x10,
            reqLen = null
        }
    };
    _debug = null;
    _onReadCallback = null;
    _onWriteCallback = null;

    constructor(debug) {
        _debug = debug;
    }

    function parse(PDU) {
        PDU.seek(0);
        local length = PDU.len();
        local functionCode = PDU.readn('b');
        local expectedReqLen = _getRequestLength(functionCode);
        local startingAddress = null;
        local quantity = null;
        local writeValues = null;
        local byteNum = null;
        if (expectedReqLen == null && length > 6) {
            startingAddress = swap2(PDU.readn('w'));
            quantity = swap2(PDU.readn('w'));
            byteNum = PDU.readn('b');
            expectedReqLen = byteNum + 6;
        } else {
            return false;
        }
        if (length < expectedReqLen) {
            // not enough data
            return false;
        }
        switch (functionCode) {
            case FUNCTION_CODES.readInputRegister.fcode:
            case FUNCTION_CODES.readRegister.fcode:
            case FUNCTION_CODES.readDiscreteInput.fcode:
            case FUNCTION_CODES.readCoil.fcode:
                startingAddress = swap2(PDU.readn('w'));
                quantity = swap2(PDU.readn('w'));
                break;
            case FUNCTION_CODES.writeCoil.fcode:
            case FUNCTION_CODES.writeRegister.fcode:
                startingAddress = swap2(PDU.readn('w'));
                writeValues = swap2(PDU.readn('w'));
                quantity = 1;
                break;
            case FUNCTION_CODES.writeCoils.fcode:
                local values = PDU.readblob(byteNum);
                writeValues = [];
                foreach (index, byte in values) {
                    local position = 0;
                    while (writeValues.len() != quantity) {
                        local bit = (byte >> (position % 8)) & 1;
                        writeValues.push(bit == 1 ? true : false);
                        position++;
                        if (position % 8 == 0) {
                            break;
                        }
                    }
                }
                break;
            case FUNCTION_CODES.writeRegisters.fcode:
                PDU.seek(6);
                local values = PDU.readblob(quantity * 2);
                writeValues = [];
                while (!values.eos()) {
                    writeValues.push(swap2(values.readn('w')));
                }
                break;
        }
        local result = {
            expectedReqLen = expectedReqLen,
            functionCode = functionCode,
            quantity = quantity,
            startingAddress = startingAddress
        };
        if (writeValues) {
            result.writeValues <- writeValues;
        }
        return result;
    }


    function onRead(callback) {
        _onReadCallback = callback;
    }

    function onWrite(callback) {
        _onWriteCallback = callback;
    }

    function _createErrorPDU(functionCode, error) {
        local PDU = blob();
        PDU.writen(functionCode | 0x80, 'b');
        PDU.writen(error, 'b');
        return PDU;
    }

    function _createPDU(result, slaveID) {
        local input = null, PDU = null;
        local functionCode = result.functionCode;
        local startingAddress = result.startingAddress;
        local quantity = result.quantity;
        switch (functionCode) {
            case ModbusSlave.FUNCTION_CODES.readCoil.fcode:
            case ModbusSlave.FUNCTION_CODES.readDiscreteInput.fcode:
                input = _onReadCallback ? _onReadCallback(slaveID, functionCode, startingAddress, quantity) : null;
                PDU = _createReadCoilPDU(result, input);
                break;
            case ModbusSlave.FUNCTION_CODES.readRegister.fcode:
            case ModbusSlave.FUNCTION_CODES.readInputRegister.fcode:
                input = _onReadCallback ? _onReadCallback(slaveID, functionCode, startingAddress, quantity) : null;
                PDU = _createReadRegisterPDU(result, input);
                break;
            case ModbusSlave.FUNCTION_CODES.writeCoil.fcode:
            case ModbusSlave.FUNCTION_CODES.writeRegister.fcode:
                input = _onWriteCallback ? _onWriteCallback(slaveID, functionCode, startingAddress, quantity, result.writeValues) : null;
                PDU = _createWritePDU(result, input, true);
                break;
            case ModbusSlave.FUNCTION_CODES.writeCoils.fcode:
            case ModbusSlave.FUNCTION_CODES.writeRegisters.fcode:
                input = _onWriteCallback ? _onWriteCallback(slaveID, functionCode, startingAddress, quantity, result.writeValues) : null;
                PDU = _createWritePDU(result, input, false);
                break;
        }
        return PDU;
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
            PDU = ModbusSlave._createErrorPDU(request.functionCode, (input == false) ? 1 : input);
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
                break;
            case "bool":
                PDU.writen((values ? 1 : 0), 'b');
                break;
            case "blob":
                PDU.writeblob(values);
                break;
            case "null":
                PDU.writeblob(blob(byteNum));
                break;
            default:
                throw "Invalid Value Type";
        }
        return PDU;
    }

    function _createReadRegisterPDU(request, values) {
        local PDU = blob();
        local quantity = request.quantity;
        local byteNum = 2 * quantity;
        PDU.writen(request.functionCode, 'b');
        PDU.writen(byteNum, 'b');
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
            case "null":
                PDU.writeblob(blob(byteNum));
                break;
            default:
                throw "Invalid Value Type";
        }
        return PDU;
    }

    function _getRequestLength(functionCode) {
        foreach (value in FUNCTION_CODES) {
            if (value.fcode == functionCode) {
                return value.reqLen
            }
        }
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

    function _send(PDU);

    function _createADU(PDU);

}

// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

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
    _callbacks = null;
    _onReadCallback = null;
    _onWriteCallback = null;

    //
    // Constructor for ModbusSlave
    //
    // @param  {bool} debug - the debug flag
    //
    constructor(debug) {
        _debug = debug;
        _callbacks = {
            onRequestWrite = null,
            onRequestRead = null,
            onError = null,
            onResponseWrite = null,
            onResponseRead = null
        };
    }

    //
    // the parse the request PDU
    //
    // @params {blob} PDU  the PDU extracted from the request ADU
    //
    function _parse(PDU) {
        PDU.seek(0);
        local length = PDU.len();
        local functionCode = PDU.readn('b');
        local expectedReqLen = _getRequestLength(functionCode);
        local startingAddress = null;
        local quantity = null;
        local writeValues = null;
        local byteNum = null;
        // if it is a function code we do not support
        if (expectedReqLen == -1) {
            throw {
                error = MODBUSSLAVE_EXCEPTION.ILLEGAL_FUNCTION,
                functionCode = functionCode
            };
        } else if (expectedReqLen == null) {
            if (length > 6) {
                startingAddress = swap2(PDU.readn('w'));
                quantity = swap2(PDU.readn('w'));
                byteNum = PDU.readn('b');
                expectedReqLen = byteNum + 6;
            } else {
                return false;
            }
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

    //
    // set the onRead callback
    //
    // @params {function} callback  the callback to be fired on the receipt of a read request
    //
    function onRead(callback) {
        _callbacks["onRequestRead"] = callback;
    }

    //
    // set the onWrite callback
    //
    // @params {function} callback  the callback to be fired on the receipt of a write request
    //
    function onWrite(callback) {
        _callbacks["onRequestWrite"] = callback;
    }

    //
    // set the onError callback
    //
    // @params {function} callback  the callback to be fired when there is an error
    //
    function onError(callback) {
        _callbacks["onError"] = callback;
    }

    //
    // create the PDU for the error response
    //
    // @params {integer} functionCode  the function code
    // @params {integer} error  the Modbus exception code
    //
    function _createErrorPDU(functionCode, error) {
        local PDU = blob();
        PDU.writen(functionCode | 0x80, 'b');
        PDU.writen(error, 'b');
        return PDU;
    }

    //
    // create the PDU for normal response
    //
    // @params {table} request  it contains information about the parsed request
    // @params {integer} slaveID  the slave ID
    //
    function _createPDU(request, slaveID) {
        local input = null, PDU = null;
        local functionCode = request.functionCode;
        local startingAddress = request.startingAddress;
        local quantity = request.quantity;
        local onReadCallback = _callbacks["onRequestRead"];
        local onWriteCallback = _callbacks["onRequestWrite"];
        switch (functionCode) {
            case ModbusSlave.FUNCTION_CODES.readCoil.fcode:
            case ModbusSlave.FUNCTION_CODES.readDiscreteInput.fcode:
                input = onReadCallback ? onReadCallback(slaveID, functionCode, startingAddress, quantity) : null;
                PDU = _createReadCoilPDU(request, input);
                break;
            case ModbusSlave.FUNCTION_CODES.readRegister.fcode:
            case ModbusSlave.FUNCTION_CODES.readInputRegister.fcode:
                input = onReadCallback ? onReadCallback(slaveID, functionCode, startingAddress, quantity) : null;
                PDU = _createReadRegisterPDU(request, input);
                break;
            case ModbusSlave.FUNCTION_CODES.writeCoil.fcode:
            case ModbusSlave.FUNCTION_CODES.writeRegister.fcode:
                input = onWriteCallback ? onWriteCallback(slaveID, functionCode, startingAddress, quantity, request.writeValues) : null;
                PDU = _createWritePDU(request, input, true);
                break;
            case ModbusSlave.FUNCTION_CODES.writeCoils.fcode:
            case ModbusSlave.FUNCTION_CODES.writeRegisters.fcode:
                input = onWriteCallback ? onWriteCallback(slaveID, functionCode, startingAddress, quantity, request.writeValues) : null;
                PDU = _createWritePDU(request, input, false);
                break;
        }
        return PDU;
    }

    //
    // create the PDU for write response
    //
    // @params {table} request  it contains information about the parsed request
    // @params {bool, null, integer} input  the returned value from the onWrite callback
    // @params {bool} isSingleWrite  an indicator if it is a single write
    //
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
            PDU = ModbusSlave._createErrorPDU(request.functionCode, (input == false) ? MODBUSSLAVE_EXCEPTION.ILLEGAL_FUNCTION : input);
        }
        return PDU;
    }

    //
    // create the PDU for read coil response
    //
    // @params {table} request  it contains information about the parsed request
    // @params {bool, null, integer, array, blob} input  the returned value from the onRead callback
    //
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

    //
    // create the PDU for read register response
    //
    // @params {table} request  it contains information about the parsed request
    // @params {null, integer, array, blob} input  the returned value from the onRead callback
    //
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

    //
    // return the expected length of the PDU according to its function code
    //
    // @params {integer} functionCode  the function code
    //
    function _getRequestLength(functionCode) {
        foreach (value in FUNCTION_CODES) {
            if (value.fcode == functionCode) {
                return value.reqLen
            }
        }
        return -1;
    }

    //
    // log the message
    //
    // @params {blob, string} message  the message to be logged
    // @params {string} prefix  the optional prefix to be pre-pend to the message
    //

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

    //
    // abstract function to send a packet
    //
    function _send(PDU);

    //
    // abstract function to create an ADU
    //
    function _createADU(PDU);
}

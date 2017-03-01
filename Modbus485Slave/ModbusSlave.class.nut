const MAX_TABLE_ENTRY = 10000;


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

    static COIL_TABLE = array(MAX_TABLE_ENTRY, 0);
    static DISCRETE_INPUT_TABLE = array(MAX_TABLE_ENTRY, 0);
    static HOLDING_REGISTER_TABLE = array(MAX_TABLE_ENTRY, 0);
    static INPUT_REGISTER_TABLE = array(MAX_TABLE_ENTRY, 0);
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

    static function parse(PDU) {
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
                    while(writeValues.len() != quantity) {
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

    static function write(targetType, address, value) {
        if (0 < address && address <= 9999) {
            switch (targetType) {
                case MODBUSSLAVE_TARGET_TYPE.COIL:
                    return COIL_TABLE[address] = value;
                case MODBUSSLAVE_TARGET_TYPE.DISCRETE_INPUT:
                    return DISCRETE_INPUT_TABLE[address] = value;
                case MODBUSSLAVE_TARGET_TYPE.HOLDING_REGISTER:
                    return HOLDING_REGISTER_TABLE[address] = value;
                case MODBUSSLAVE_TARGET_TYPE.INPUT_REGISTER:
                    return INPUT_REGISTER_TABLE[address] = value;
                default:
                    throw "Invalid Target Type";
            }
        }
        throw "Invalid address";

    }

    static function read(targetType, address) {
        if (0 < address && address <= 9999) {
            switch (targetType) {
                case MODBUSSLAVE_TARGET_TYPE.COIL:
                    return COIL_TABLE[address];
                case MODBUSSLAVE_TARGET_TYPE.DISCRETE_INPUT:
                    return DISCRETE_INPUT_TABLE[address];
                case MODBUSSLAVE_TARGET_TYPE.HOLDING_REGISTER:
                    return HOLDING_REGISTER_TABLE[address];
                case MODBUSSLAVE_TARGET_TYPE.INPUT_REGISTER:
                    return INPUT_REGISTER_TABLE[address];
                default:
                    throw "Invalid Target Type";
            }
        }
        throw "Invalid address";
    }

    static function createErrorPDU(functionCode, error) {
        local PDU = blob();
        PDU.writen(functionCode | 0x80, 'b');
        PDU.writen(error, 'b');
        return PDU;
    }

    static function log(message, prefix) {
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

    static function _getRequestLength(functionCode) {
        foreach (value in FUNCTION_CODES) {
            if (value.fcode == functionCode) {
                return value.reqLen
            }
        }
    }
}

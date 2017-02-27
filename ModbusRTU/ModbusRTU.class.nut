// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

enum MODBUSRTU_SUB_FUNCTION_CODE {
    RETURN_QUERY_DATA = 0x0000,
    RESTART_COMMUNICATION_OPTION = 0x0001,
    RETURN_DIAGNOSTICS_REGISTER = 0x0002,
    CHANGE_ASCII_INPUT_DELIMITER = 0x0003,
    FORCE_LISTEN_ONLY_MODE = 0x0004,
    CLEAR_COUNTERS_AND_DIAGNOSTICS_REGISTER = 0x000A,
    RETURN_BUS_MESSAGE_COUNT = 0x000B,
    RETURN_BUS_COMMUNICATION_ERROR_COUNT = 0x000C,
    RETURN_BUS_EXCEPTION_ERROR_COUNT = 0x000D,
    RETURN_SLAVE_MESSAGE_COUNT = 0x000E,
    RETURN_SLAVE_NO_RESPONSE_COUNT = 0x000F,
    RETURN_SLAVE_NAK_COUNT = 0x0010,
    RETURN_SLAVE_BUSY_COUNT = 0x0011,
    RETURN_BUS_CHARACTER_OVERRUN_COUNT = 0x0012,
    CLEAR_OVERRUN_COUNTER_AND_FLAG = 0x0014
}

enum MODBUSRTU_EXCEPTION {
    ILLEGAL_FUNCTION = 0x01,
    ILLEGAL_DATA_ADDR = 0x02,
    ILLEGAL_DATA_VAL = 0x03,
    SLAVE_DEVICE_FAIL = 0x04,
    ACKNOWLEDGE = 0x05,
    SLAVE_DEVICE_BUSY = 0x06,
    NEGATIVE_ACKNOWLEDGE = 0x07,
    MEMORY_PARITY_ERROR = 0x08,
    RESPONSE_TIMEOUT = 0x50,
    INVALID_CRC = 0x51,
    INVALID_ARG_LENGTH = 0x52,
    INVALID_DEVICE_ADDR = 0x53,
    INVALID_TARGET_TYPE = 0x57,
    INVALID_VALUES = 0x58,
    INVALID_QUANTITY = 0x59,
}


enum MODBUSRTU_TARGET_TYPE {
    COIL,
    DISCRETE_INPUT,
    INPUT_REGISTER,
    HOLDING_REGISTER,
}

enum MODBUSRTU_READ_DEVICE_CODE {
    BASIC = 0x01,
    REGULAR = 0x02,
    EXTENDED = 0x03,
    SPECIFIC = 0x04,
}

enum MODBUSRTU_OBJECT_ID {
    VENDOR_NAME = 0x00,
    PRODUCT_CODE = 0x01,
    MAJOR_MINOR_REVISION = 0x02,
    VENDOR_URL = 0x03,
    PRODUCT_NAME = 0x04,
    MODEL_NAME = 0x05,
    USER_APPLICATION_NAME = 0x06,
}

class ModbusRTU {
    static VERSION = "1.0.0";
     // resLen and reqLen are the length of the PDU
    static FUNCTION_CODES = {
            readCoils = {
                fcode   = 0x01,
                reqLen  = 5,
                resLen  = function(n) {
                    return 2 + math.ceil(n / 8.0);
                }
            },
            readInputs = {
                fcode   = 0x02,
                reqLen  = 5,
                resLen  = function(n) {
                    return 2 + math.ceil(n / 8.0);
                }
            },
            readHoldingRegs = {
                fcode   = 0x03,
                reqLen  = 5,
                resLen  = function(n) {
                    return 2 * n + 2;
                }
            },
            readInputRegs = {
                fcode   = 0x04,
                reqLen  = 5,
                resLen  = function(n) {
                    return 2 * n + 2;
                }
            },
            writeSingleCoil = {
                fcode   = 0x05,
                reqLen  = 5,
                resLen  = 5
            },
            writeSingleReg = {
                fcode   = 0x06,
                reqLen  = 5,
                resLen  = 5
            },
            writeMultipleCoils = {
                fcode   = 0x0F,
                reqLen  = function(n) {
                    return 6 + math.ceil(n / 8.0);
                },
                resLen  = 5
            },
            writeMultipleRegs = {
                fcode   = 0x10,
                reqLen  = function(n) {
                    return 6 + n * 2;
                },
                resLen  = 5
            },
            readExceptionStatus = {
                fcode   = 0x07,
                reqLen  = 1,
                resLen  = 2
            },
            diagnostics = {
                fcode   = 0x08,
                reqLen  = function(n) {
                    return 3 + n * 2;
                },
                resLen  = function(n) {
                    return 3 + n * 2;
                }
            },
            reportSlaveID = {
                fcode   = 0x11,
                reqLen  = 1,
                resLen  = null
            },
            readDeviceIdentification = {
                fcode   = 0x2B,
                reqLen  = 4,
                resLen  = null
            },
            maskWriteRegister = {
                fcode   = 0x16,
                reqLen  = 7,
                resLen  = 7
            },
            readFIFOQueue = {
                fcode   = 0x18,
                reqLen  = 3,
                resLen  = function(n) {
                    return 5 + n * 2;
                }
            },
            readWriteMultipleRegisters = {
                fcode   = 0x17,
                reqLen  = function(n) {
                    return 10 + n * 2;
                },
                resLen  = function(n) {
                    return 2 + n * 2;
                }
            }
    }

    //
    // function to create PDU for readWriteMultipleRegisters
    //
    static function createReadWriteMultipleRegistersPDU(readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue) {
        local readWriteMultipleRegisters = FUNCTION_CODES.readWriteMultipleRegisters;
        local PDU = blob(readWriteMultipleRegisters.reqLen(writeQuantity));
        PDU.writen(readWriteMultipleRegisters.fcode, 'b');
        PDU.writen(swap2(readingStartAddress), 'w');
        PDU.writen(swap2(readQuantity), 'w');
        PDU.writen(swap2(writeStartAddress), 'w');
        PDU.writen(swap2(writeQuantity), 'w');
        PDU.writen(writeValue.len(), 'b');
        PDU.writeblob(writeValue);
        return PDU;
    }

    //
    // function to create PDU for maskWriteRegister
    //
    static function createMaskWriteRegisterPDU(referenceAddress, AND_Mask, OR_Mask) {
        local maskWriteRegister = FUNCTION_CODES.maskWriteRegister;
        local PDU = blob(maskWriteRegister.reqLen);
        PDU.writen(maskWriteRegister.fcode, 'b');
        PDU.writen(swap2(referenceAddress), 'w');
        PDU.writen(swap2(AND_Mask), 'w');
        PDU.writen(swap2(OR_Mask), 'w');
        return PDU;
    }

    //
    // function to create PDU for reportSlaveID
    //
    static function createReportSlaveIdPDU() {
        local reportSlaveID = FUNCTION_CODES.reportSlaveID;
        local PDU = blob(reportSlaveID.reqLen);
        PDU.writen(reportSlaveID.fcode, 'b');
        return PDU;
    }

    //
    // function to create PDU for readDeviceIdentification
    //
    static function createReadDeviceIdentificationPDU(readDeviceIdCode, objectId) {
        const MEI_TYPE = 0x0E;
        local readDeviceIdentification = FUNCTION_CODES.readDeviceIdentification;
        local PDU = blob(readDeviceIdentification.reqLen);
        PDU.writen(readDeviceIdentification.fcode, 'b');
        PDU.writen(MEI_TYPE, 'b');
        PDU.writen(readDeviceIdCode, 'b');
        PDU.writen(objectId, 'b');
        return PDU;
    }

    //
    // function to create PDU for diagnostics
    //
    static function createDiagnosticsPDU(subFunctionCode, data) {
        local diagnostics = FUNCTION_CODES.diagnostics;
        local PDU = blob(diagnostics.reqLen(data.len() / 2));
        PDU.writen(diagnostics.fcode, 'b');
        PDU.writen(swap2(subFunctionCode), 'w');
        PDU.writeblob(data);
        return PDU;
    }

    //
    // function to create PDU for readExceptionStatus
    //
    static function createReadExceptionStatusPDU() {
        local readExceptionStatus = FUNCTION_CODES.readExceptionStatus;
        local PDU = blob(readExceptionStatus.reqLen);
        PDU.writen(readExceptionStatus.fcode, 'b');
        return PDU;
    }

    //
    // function to create PDU for read
    //
    static function createReadPDU(targetType, startingAddress, quantity) {
        local PDU = blob(targetType.reqLen);
        PDU.writen(targetType.fcode, 'b');
        PDU.writen(swap2(startingAddress), 'w');
        PDU.writen(swap2(quantity), 'w');
        return PDU;
    }

    //
    // function to create PDU for write
    //
    static function createWritePDU(targetType, startingAddress, numBytes, quantity, values) {
        local PDU = blob();
        PDU.writen(targetType.fcode, 'b');
        PDU.writen(swap2(startingAddress), 'w');
        if (quantity > 1) {
            PDU.writen(swap2(quantity), 'w');
            PDU.writen(numBytes, 'b');
        }
        PDU.writeblob(values);
        return PDU;
    }


    //
    // function to parse the incoming ADU
    //
    static function parse(params) {
        local PDU = params.PDU;
        local functionCode = PDU.readn('b');
        local expectedResType = params.expectedResType;
        local expectedResLen = params.expectedResLen;
        local result = false;
        if ((functionCode & 0x80) == 0x80) {
            // exception code
            throw PDU.readn('b');
        }
        if (expectedResLen && (PDU.len() < expectedResLen)) {
            return false;
        }
        if (functionCode != expectedResType){
            return -1;
        }
        switch (functionCode) {
            case FUNCTION_CODES.readExceptionStatus.fcode:
                return _readExceptionStatus(PDU);
            case FUNCTION_CODES.readDeviceIdentification.fcode:
                return _readDeviceIdentification(PDU);
            case FUNCTION_CODES.reportSlaveID.fcode:
                return _reportSlaveID(PDU);
            case FUNCTION_CODES.diagnostics.fcode:
                return _diagnostics(PDU, params.quantity);
            case FUNCTION_CODES.readCoils.fcode:
            case FUNCTION_CODES.readInputs.fcode:
            case FUNCTION_CODES.readHoldingRegs.fcode:
            case FUNCTION_CODES.readInputRegs.fcode:
            case FUNCTION_CODES.readWriteMultipleRegisters.fcode:
                return _readData(PDU, expectedResType, params.quantity);
            case FUNCTION_CODES.writeSingleCoil.fcode:
            case FUNCTION_CODES.writeSingleReg.fcode:
            case FUNCTION_CODES.writeMultipleCoils.fcode:
            case FUNCTION_CODES.writeMultipleRegs.fcode:
            case FUNCTION_CODES.maskWriteRegister.fcode:
                return _writeData(PDU);
        }
    }

    //
    // function to parse ADU for diagnostics
    //
    static function _diagnostics(PDU, quantity) {
        PDU.seek(3);
        local result = [];
        while (result.len() != quantity) {
            result.push(swap2(PDU.readn('w')));
        }
        return result;
    }

    //
    // function to parse ADU for readExceptionStatus
    //
    static function _readExceptionStatus(PDU) {
        PDU.seek(1);
        return PDU.readn('b');
    }

    //
    // function to parse ADU for write
    //
    static function _writeData(PDU) {
        return true;
    }

    //
    // function to parse ADU for read
    //
    static function _readData(PDU, expectedResType, quantity) {
        PDU.seek(2);
        local result = [];
        switch (expectedResType) {
            case FUNCTION_CODES.readCoils.fcode:
            case FUNCTION_CODES.readInputs.fcode:
                while (!PDU.eos()) {
                    local byte = PDU.readn('b');
                    local bitmask = 1;
                    for (local bit = 0; bit < 8; ++ bit) {
                        result.push((byte & (bitmask << bit)) != 0x00);
                        if (result.len() == quantity) {
                            // move the pointer to the end to break out of the while loop
                            PDU.seek(0, 'e');
                            break;
                        }
                    }
                }
                break;
            case FUNCTION_CODES.readWriteMultipleRegisters.fcode:
            case FUNCTION_CODES.readHoldingRegs.fcode:
            case FUNCTION_CODES.readInputRegs.fcode:
                while (result.len() != quantity) {
                    result.push(swap2(PDU.readn('w')));
                }
                break;
        }
        return result;
    }

    //
    // function to parse ADU for reportSlaveID
    //
    static function _reportSlaveID(PDU) {
        PDU.seek(1);
        local byteCount = PDU.readn('b');
        if (PDU.len() - PDU.tell() >= byteCount) {
             local results = {
                 slaveId      = PDU.readstring(byteCount - 1),
                 runIndicator = ((PDU.readn('b') == 0) ? false: true),
             };
             return results;
        }
        return false;
    }

    //
    // function to parse ADU for readDeviceIdentification
    //
    static function _readDeviceIdentification(PDU) {
         if (PDU.len() < 7) {
             // Not enough data for this function code
             return false;
         }
         PDU.seek(6);
         local objectCount = PDU.readn('b');
         local objects = {};
         while (objects.len() < objectCount) {
             if (PDU.len() - PDU.tell() < 2) {
                 // Not enough data
                 return false;
             }
             local currentObjectId = PDU.readn('b');
             local currentObjectLen = PDU.readn('b');
             if (PDU.len() - PDU.tell() < currentObjectLen) {
                 // Not enough data
                 return false;
             }
             objects[currentObjectId] <- PDU.readstring(currentObjectLen);
         }
         return objects;
     }
}

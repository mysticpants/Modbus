// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

//------------------------------------------------------------------------------
// Constants

enum MODBUS_SUB_FUNCTION_CODE {
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

enum MODBUS_EXCEPTION {
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
    INVALID_ADDRESS = 0x54,
    INVALID_ADDRESS_RANGE = 0x55,
    INVALID_ADDRESS_TYPE = 0x56,
    INVALID_TARGET_TYPE = 0x57,
    INVALID_VALUES = 0x58,
}

enum MODBUS_ADDRESS_TYPE {
    DIRECT,
    STANDARD,
    EXTENDED,
}

enum MODBUS_TARGET_TYPE {
    COIL,
    DISCRETE_INPUT,
    INPUT_REGISTER,
    HOLDING_REGISTER,
}

enum MODBUS_READ_DEVICE_CODE {
    BASIC = 0x01,
    REGULAR = 0x02,
    EXTENDED = 0x03,
    SPECIFIC = 0x04
}

enum MODBUS_OBJECT_ID {
    VENDOR_NAME = 0x00,
    PRODUCT_CODE = 0x01,
    MAJOR_MINOR_REVISION = 0x02,
    VENDOR_URL = 0x03,
    PRODUCT_NAME = 0x04,
    MODEL_NAME = 0x05,
    USER_APPLICATION_NAME = 0x06,
}



//------------------------------------------------------------------------------

class ModbusRTU {

    static VERSION = "1.0.0";
     // resLen and reqLen are the length of the PDU
    static FUNCTION_CODES = {
            readCoils = {
                fcode   = 0x01,
                reqLen  = 5,
                resLen  = null
            },
            readInputs = {
                fcode   = 0x02,
                reqLen  = 5,
                resLen  = null
            },
            readHoldingRegs = {
                fcode   = 0x03,
                reqLen  = 5,
                resLen  = null
            },
            readInputRegs = {
                fcode   = 0x04,
                reqLen  = 5,
                resLen  = null
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
                reqLen  = function(n) { return 6 + math.ceil(n/8.0); },
                resLen  = 5
            },
            writeMultipleRegs = {
                fcode   = 0x10,
                reqLen  = function(n) { return 6 + n*2; },
                resLen  = 5
            },
            readExceptionStatus = {
                fcode   = 0x07,
                reqLen  = 1,
                resLen  = 2
            },
            diagnostics = {
                fcode   = 0x08,
                reqLen  = function(n) { return 3 + n*2; },
                resLen  = function (n) { return 3 + n*2; }
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
                resLen  = function (n) { return 5 + n*2; }
            },
            readWriteMultipleRegisters = {
                fcode   = 0x17,
                reqLen  = function (n){ return 10 + n*2; },
                resLen  = function (n){ return 2 + n*2; }
            },
            readFileRecord = {
                fcode   = 0x14,
                reqLen  = function (n){ return 2 + n*7; },
                resLen  = null
            },
            writeFileRecord = {
                fcode   = 0x15,
                reqLen  = function (n){ return 2 + n},
                resLen  = null
            }
    }

    /*
     * function to create PDU for readWriteMultipleRegisters
     *
     */
    static function createReadWriteMultipleRegistersPDU (readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue){
        local readWriteMultipleRegisters = FUNCTION_CODES.readWriteMultipleRegisters;
        local PDU = blob(readWriteMultipleRegisters.reqLen(writeQuantity));
        PDU.writen(readWriteMultipleRegisters.fcode,'b');
        PDU.writen(swap2(readingStartAddress),'w');
        PDU.writen(swap2(readQuantity),'w');
        PDU.writen(swap2(writeStartAddress),'w');
        PDU.writen(swap2(writeQuantity),'w');
        writeValue.swap2();
        PDU.writen(swap2(writeValue.len()),'w');
        PDU.writeblob(writeValue);
        return PDU;
    }

    /*
     * function to create PDU for maskWriteRegister
     *
     */
    static function createMaskWriteRegisterPDU (referenceAddress , AND_Mask , OR_Mask){
        local maskWriteRegister = FUNCTION_CODES.maskWriteRegister;
        local PDU = blob(maskWriteRegister.reqLen);
        PDU.writen(maskWriteRegister.fcode,'b');
        PDU.writen(swap2(referenceAddress),'w');
        PDU.writen(swap2(AND_Mask),'w');
        PDU.writen(swap2(OR_Mask),'w');
        return PDU;
    }

    /*
     * function to create PDU for reportSlaveID
     *
     */
    static function createReportSlaveIdPDU(){
        local reportSlaveID = FUNCTION_CODES.reportSlaveID;
        local PDU = blob(reportSlaveID.reqLen);
        PDU.writen(reportSlaveID.fcode,'b');
        return PDU;
    }

    /*
     * function to create PDU for readDeviceIdentification
     *
     */
    static function createreadDeviceIdentificationPDU(readDeviceIdCode,objectId ){
        const MEI_TYPE = 0x0E;
        local readDeviceIdentification = FUNCTION_CODES.readDeviceIdentification;
        local PDU = blob(readDeviceIdentification.reqLen);
        PDU.writen(readDeviceIdentification.fcode,'b');
        PDU.writen(MEI_TYPE,'b');
        PDU.writen(readDeviceIdCode,'b');
        PDU.writen(objectId,'b');
        return PDU;
    }

    /*
     * function to create PDU for diagnostics
     *
     */
    static function createDiagnosticsPDU (subFunctionCode ,data){
        local diagnostics = FUNCTION_CODES.diagnostics;
        local PDU = blob(diagnostics.reqLen(data.len()/2));
        PDU.writen(diagnostics.fcode,'b');
        PDU.writen(swap2(subFunctionCode),'w');
        PDU.writeblob(data);
        return PDU;
    }

    /*
     * function to create PDU for readExceptionStatus
     *
     */
    static function createReadExceptionStatusPDU (){
        local readExceptionStatus = FUNCTION_CODES.readExceptionStatus;
        local PDU = blob(readExceptionStatus.reqLen);
        PDU.writen(readExceptionStatus.fcode,'b');
        return PDU;
    }

    /*
     * function to create PDU for read
     *
     */
    static function createReadPDU (functionCode,startingAddress, quantity){
        local PDU = blob(functionCode.reqLen);
        PDU.writen(functionCode.fcode, 'b');
        PDU.writen(swap2(startingAddress), 'w');
        PDU.writen(swap2(quantity),'w');
        return PDU;
    }

    /*
     * function to create PDU for write
     *
     */
    static function createWritePDU (functionCode,startingAddress,numBytes ,quantity, values){
        local PDU = blob();
        PDU.writen(functionCode.fcode, 'b');
        PDU.writen(swap2(startingAddress), 'w');
        if (quantity > 1) {
            PDU.writen(swap2(quantity), 'w');
            PDU.writen(numBytes, 'b');
        }
        PDU.writeblob(values);
        return PDU;
    }


    /*
     * function to parse the incoming ADU
     *
     */
    static function parse(params){

        local buffer = params.buffer;
        buffer.seek(1); // skip the device address
        local functionCode = buffer.readn('b');
        local expectedResLen = params.expectedResLen;
        local expectedResType = params.expectedResType;
        local result = false;
        if ((functionCode & 0x80) == 0x80){
            if (_hasValidCRC(buffer)){
                throw buffer.readn('b'); // exception code
            } else {
                throw MODBUS_EXCEPTION.INVALID_CRC;
            }
        } else if (expectedResLen == null) {
            expectedResLen = buffer.readn('b') + 2;
        }

        if (functionCode != expectedResType){
            return -1;
        }

        switch (functionCode) {
            case FUNCTION_CODES.readExceptionStatus.fcode:
                result = _readExceptionStatus(buffer,expectedResLen);
                break;
            case FUNCTION_CODES.readDeviceIdentification.fcode:
                result = _readDeviceIdentification(buffer);
                break;
            case FUNCTION_CODES.reportSlaveID.fcode:
                result = _reportSlaveID(buffer);
                break;
            case FUNCTION_CODES.diagnostics.fcode:
                result = _diagnostics(buffer,expectedResLen,params.quantity);
                break;
            case FUNCTION_CODES.readCoils.fcode:
            case FUNCTION_CODES.readInputs.fcode:
            case FUNCTION_CODES.readHoldingRegs.fcode:
            case FUNCTION_CODES.readInputRegs.fcode:
            case FUNCTION_CODES.readWriteMultipleRegisters.fcode:
                result = _readData(buffer,expectedResType ,expectedResLen,params.quantity);
                break;
            case FUNCTION_CODES.writeSingleCoil.fcode:
            case FUNCTION_CODES.writeSingleReg.fcode:
            case FUNCTION_CODES.writeMultipleCoils.fcode:
            case FUNCTION_CODES.writeMultipleRegs.fcode:
            case FUNCTION_CODES.maskWriteRegister.fcode:
                result = _writeData(buffer,expectedResLen);
                break;
        }

        if ((result != false) && (!_hasValidCRC(buffer))){
            throw MODBUS_EXCEPTION.INVALID_CRC;
        }
        return result;
    }


    /*
     * function to parse ADU for diagnostics
     *
     */
    function _diagnostics (buffer,expectedResLen , quantity){
        if (buffer.len() < expectedResLen + 3){
            return false;
        }
        buffer.seek(4);
        local result = [];
        while(result.len() != quantity){
            result.push(swap2(buffer.readn('w')));
        }
        return result;
    }

    /*
     * function to parse ADU for readExceptionStatus
     *
     */
    function _readExceptionStatus(buffer , expectedResLen){
        if (buffer.len() < expectedResLen + 3){
            return false;
        }
        buffer.seek(2);
        return buffer.readn('b');
    }


    /*
     * function to parse ADU for write
     *
     */
    function _writeData(buffer,expectedResLen) {
        if (buffer.len() < expectedResLen + 3) {
            // Not enough data
            return false;
        }
        return true;
    }

    /*
     * function to parse ADU for read
     *
     */
    function _readData(buffer ,expectedResType , expectedResLen , quantity ) {
        if (buffer.len() < expectedResLen + 3) {
            // Not enough data
            return false;
        }
        buffer.seek(3);
        local result = [];
        switch (expectedResType) {
            case FUNCTION_CODES.readCoils.fcode:
            case FUNCTION_CODES.readInputs.fcode:
                while (!buffer.eos()) {
                    local byte = buffer.readn('b');
                    local bitmask = 1;
                    for (local bit = 0; bit < 8; ++bit) {
                        result.push((byte & (bitmask << bit)) != 0x00);
                        if (result.len() == quantity) {
                            buffer.seek(0,'e'); // move the pointer to the end to break out of the while loop
                            break;
                        }
                    }
                }
                break;
            case FUNCTION_CODES.readWriteMultipleRegisters.fcode:
            case FUNCTION_CODES.readHoldingRegs.fcode:
            case FUNCTION_CODES.readInputRegs.fcode:
                while (result.len() != quantity) {
                    result.push(swap2(buffer.readn('w')))
                }
                break;
        }
        return result;
    }

    /*
     * function to parse ADU for reportSlaveID
     *
     */
    function _reportSlaveID(buffer){
        buffer.seek(2);
        local byteCount = buffer.readn('b');
        if (buffer.len() - buffer.tell() > byteCount + 1){ // when we have the whole ADU
             local results = {
                 slaveId = buffer.readstring(byteCount - 1),
                 runIndicator = ((buffer.readn('b') == 0) ? false : true)
             };
             return results;
        }
        return false;
    }

    /*
     * function to parse ADU for readDeviceIdentification
     *
     */
    function _readDeviceIdentification(buffer) {
        if (buffer.len() < 8) {
            // Not enough data for this function code
            return false;
        }
        buffer.seek(7);
        local objectCount = buffer.readn('b');
        local objects = {};
        while (objects.len() < objectCount){
            if (buffer.len() - buffer.tell() < 2) {
                // Not enough data
                return false;
            }
            local currentObjectId = buffer.readn('b');
            local currentObjectLen = buffer.readn('b');
            if (buffer.len() - buffer.tell() < currentObjectLen) {
                // Not enough data
                return false;
            }
            objects[currentObjectId] <- buffer.readstring(currentObjectLen);
        }
        if (buffer.len() - buffer.tell() < 2) {
            // Not enough data , wait for the CRC bytes
            return false;
        }
        return objects;
    }

    /*
     * function to determine if the given address is valid
     *
     */
    function _isValidAddress(addressType, address) {
        switch (addressType) {
            case MODBUS_ADDRESS_TYPE.DIRECT:
                return (address >= 0 && address <= 9998);
            case MODBUS_ADDRESS_TYPE.STANDARD:
                return (address >= 00001 && address <= 09999) ||
                       (address >= 10001 && address <= 19999) ||
                       (address >= 30001 && address <= 39999) ||
                       (address >= 40001 && address <= 49999);
            case MODBUS_ADDRESS_TYPE.EXTENDED:
                return (address >= 000001 && address <= 065536) ||
                       (address >= 100001 && address <= 165536) ||
                       (address >= 300001 && address <= 365536) ||
                       (address >= 400001 && address <= 465536);
            default:
                return false;
        }

    }


    /*
     * function to determine the type based on the given address
     *
     */
    function _getTargetType(addressType, address) {
        switch (addressType) {
            case MODBUS_ADDRESS_TYPE.DIRECT:
                server.error("Target type must be provided for direct addressing");
                throw MODBUS_EXCEPTION.INVALID_TARGET_TYPE;
            case MODBUS_ADDRESS_TYPE.STANDARD:
                if        (address >= 1 && address <= 9999) {
                    return MODBUS_TARGET_TYPE.COIL;
                } else if (address >= 10001 && address <= 19999) {
                    return MODBUS_TARGET_TYPE.DISCRETE_INPUT;
                } else if (address >= 30001 && address <= 39999) {
                    return MODBUS_TARGET_TYPE.INPUT_REGISTER;
                } else if (address >= 40001 && address <= 49999) {
                    return MODBUS_TARGET_TYPE.HOLDING_REGISTER;
                }
                break;

            case MODBUS_ADDRESS_TYPE.EXTENDED:
                if (address >= 1 && address <= 65536) {
                    return MODBUS_TARGET_TYPE.COIL;
                } else if (address >= 100001 && address <= 165536) {
                    return MODBUS_TARGET_TYPE.DISCRETE_INPUT;
                } else if (address >= 300001 && address <= 365536) {
                    return MODBUS_TARGET_TYPE.INPUT_REGISTER;
                } else if (address >= 400001 && address <= 465536) {
                    return MODBUS_TARGET_TYPE.HOLDING_REGISTER;
                }
                break;
        }
        return false;
    }


    /*
     * function to determine the offset
     *
     */
    function _getTargetOffset(addressType, targetType) {
        switch (addressType) {
            case MODBUS_ADDRESS_TYPE.DIRECT:
                return 0;
            case MODBUS_ADDRESS_TYPE.STANDARD:
                switch (targetType) {
                    case MODBUS_TARGET_TYPE.COIL:             return 1;
                    case MODBUS_TARGET_TYPE.DISCRETE_INPUT:   return 10001;
                    case MODBUS_TARGET_TYPE.INPUT_REGISTER:   return 30001;
                    case MODBUS_TARGET_TYPE.HOLDING_REGISTER: return 40001;
                }
                break;
            case MODBUS_ADDRESS_TYPE.EXTENDED:
                switch (targetType) {
                    case MODBUS_TARGET_TYPE.COIL:             return 1;
                    case MODBUS_TARGET_TYPE.DISCRETE_INPUT:   return 100001;
                    case MODBUS_TARGET_TYPE.INPUT_REGISTER:   return 300001;
                    case MODBUS_TARGET_TYPE.HOLDING_REGISTER: return 400001;
                }
                break;
        }
        return false;
    }


    /*
     * It determines if the ADU is valid
     *
     * @param {Blob} frame - ADU
     */
    function _hasValidCRC(frame) {
        local length = frame.len();
        local currentPosition = frame.tell();
        frame.seek(0);
        local expectedCRC = CRC16.calculate(frame.readblob(length - 2));
        local receivedCRC = frame.readn('w');
        frame.seek(currentPosition);
        return (receivedCRC == expectedCRC);
    }



}

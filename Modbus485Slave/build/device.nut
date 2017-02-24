const CRC16_LOOKUP_LOW   = "\x00\xC0\xC1\x01\xC3\x03\x02\xC2\xC6\x06\x07\xC7\x05\xC5\xC4\x04\xCC\x0C\x0D\xCD\x0F\xCF\xCE\x0E\x0A\xCA\xCB\x0B\xC9\x09\x08\xC8\xD8\x18\x19\xD9\x1B\xDB\xDA\x1A\x1E\xDE\xDF\x1F\xDD\x1D\x1C\xDC\x14\xD4\xD5\x15\xD7\x17\x16\xD6\xD2\x12\x13\xD3\x11\xD1\xD0\x10\xF0\x30\x31\xF1\x33\xF3\xF2\x32\x36\xF6\xF7\x37\xF5\x35\x34\xF4\x3C\xFC\xFD\x3D\xFF\x3F\x3E\xFE\xFA\x3A\x3B\xFB\x39\xF9\xF8\x38\x28\xE8\xE9\x29\xEB\x2B\x2A\xEA\xEE\x2E\x2F\xEF\x2D\xED\xEC\x2C\xE4\x24\x25\xE5\x27\xE7\xE6\x26\x22\xE2\xE3\x23\xE1\x21\x20\xE0\xA0\x60\x61\xA1\x63\xA3\xA2\x62\x66\xA6\xA7\x67\xA5\x65\x64\xA4\x6C\xAC\xAD\x6D\xAF\x6F\x6E\xAE\xAA\x6A\x6B\xAB\x69\xA9\xA8\x68\x78\xB8\xB9\x79\xBB\x7B\x7A\xBA\xBE\x7E\x7F\xBF\x7D\xBD\xBC\x7C\xB4\x74\x75\xB5\x77\xB7\xB6\x76\x72\xB2\xB3\x73\xB1\x71\x70\xB0\x50\x90\x91\x51\x93\x53\x52\x92\x96\x56\x57\x97\x55\x95\x94\x54\x9C\x5C\x5D\x9D\x5F\x9F\x9E\x5E\x5A\x9A\x9B\x5B\x99\x59\x58\x98\x88\x48\x49\x89\x4B\x8B\x8A\x4A\x4E\x8E\x8F\x4F\x8D\x4D\x4C\x8C\x44\x84\x85\x45\x87\x47\x46\x86\x82\x42\x43\x83\x41\x81\x80\x40";
const CRC16_LOOKUP_HIGH  = "\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40";

class CRC16 {
  static version = [1,0,0];
  static defaultInitValue = 0xFFFF;

  
  static function calculate(data, start = null, end = null, initValue = null) {
      
      if(start == null) start = 0;

      
      if(end == null) end = data.len();

      
      if(initValue == null) initValue = defaultInitValue;

      
      local index;
      local lo = initValue & 0xFF;
      local hi = (initValue >> 8 ) & 0xFF;

      
      for(local i = start; i < end; i++) {
          index = lo ^ data[i];
          lo    = hi ^ CRC16_LOOKUP_HIGH[index];
          hi    = CRC16_LOOKUP_LOW[index];
      }

      return (hi << 8) | lo;
  }
}

const MAX_TABLE_ENTRY = 10000;

class ModbusSlave {

    static COIL_TABLE = array(MAX_TABLE_ENTRY, 0);
    static DISCRETE_INPUT_TABLE = array(MAX_TABLE_ENTRY, 0);
    static HOLDING_REGISTER_TABLE = blob(2 * MAX_TABLE_ENTRY);
    static INPUT_REGISTER_TABLE = blob(2 * MAX_TABLE_ENTRY);

    static function perform(PDU) {
        PDU.seek(0);
        local functionCode = PDU.readn('b');
        local expectedReqLen = _getRequestLength(functionCode);
        local response = null;
        if (PDU.len() < expectedReqLen) {
            
            return false;
        }
        switch (functionCode) {
            case 0x11:
                response = _createReportSlaveIdPDU();
                break;
        }
        return {
            response = response,
            expectedReqLen = expectedReqLen
        }
    }

    static function write() {

    }

    static function read() {

    }

    static function _getRequestLength(functionCode) {
        foreach (value in ModbusRTU.FUNCTION_CODES) {
            if (functionCode == value.fcode) {
                return value.reqLen;
            }
        }
    }

    static function _createReportSlaveIdPDU() {
        local PDU = blob();
        PDU.writen(0x11,'b');
        PDU.writestring(hardware.getdeviceid());
        PDU.writen(0x00, 'b');
        return PDU;
    }
}





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
    INVALID_ADDRESS = 0x54,
    INVALID_ADDRESS_RANGE = 0x55,
    INVALID_ADDRESS_TYPE = 0x56,
    INVALID_TARGET_TYPE = 0x57,
    INVALID_VALUES = 0x58,
    INVALID_QUANTITY = 0x59,
}

enum MODBUSRTU_ADDRESS_TYPE {
    DIRECT,
    STANDARD,
    EXTENDED,
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

    
    
    
    static function createMaskWriteRegisterPDU(referenceAddress, AND_Mask, OR_Mask) {
        local maskWriteRegister = FUNCTION_CODES.maskWriteRegister;
        local PDU = blob(maskWriteRegister.reqLen);
        PDU.writen(maskWriteRegister.fcode, 'b');
        PDU.writen(swap2(referenceAddress), 'w');
        PDU.writen(swap2(AND_Mask), 'w');
        PDU.writen(swap2(OR_Mask), 'w');
        return PDU;
    }

    
    
    
    static function createReportSlaveIdPDU() {
        local reportSlaveID = FUNCTION_CODES.reportSlaveID;
        local PDU = blob(reportSlaveID.reqLen);
        PDU.writen(reportSlaveID.fcode, 'b');
        return PDU;
    }

    
    
    
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

    
    
    
    static function createDiagnosticsPDU(subFunctionCode, data) {
        local diagnostics = FUNCTION_CODES.diagnostics;
        local PDU = blob(diagnostics.reqLen(data.len() / 2));
        PDU.writen(diagnostics.fcode, 'b');
        PDU.writen(swap2(subFunctionCode), 'w');
        PDU.writeblob(data);
        return PDU;
    }

    
    
    
    static function createReadExceptionStatusPDU() {
        local readExceptionStatus = FUNCTION_CODES.readExceptionStatus;
        local PDU = blob(readExceptionStatus.reqLen);
        PDU.writen(readExceptionStatus.fcode, 'b');
        return PDU;
    }

    
    
    
    static function createReadPDU(targetType, startingAddress, quantity) {
        local PDU = blob(targetType.reqLen);
        PDU.writen(targetType.fcode, 'b');
        PDU.writen(swap2(startingAddress), 'w');
        PDU.writen(swap2(quantity), 'w');
        return PDU;
    }

    
    
    
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


    
    
    
    static function parse(params) {
        local PDU = params.PDU;
        local functionCode = PDU.readn('b');
        local expectedResType = params.expectedResType;
        local expectedResLen = params.expectedResLen;
        local result = false;
        if ((functionCode & 0x80) == 0x80) {
            
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

    
    
    
    static function _diagnostics(PDU, quantity) {
        PDU.seek(3);
        local result = [];
        while (result.len() != quantity) {
            result.push(swap2(PDU.readn('w')));
        }
        return result;
    }

    
    
    
    static function _readExceptionStatus(PDU) {
        PDU.seek(1);
        return PDU.readn('b');
    }

    
    
    
    static function _writeData(PDU) {
        return true;
    }

    
    
    
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

    
    
    
    static function _readDeviceIdentification(PDU) {
         if (PDU.len() < 7) {
             
             return false;
         }
         PDU.seek(6);
         local objectCount = PDU.readn('b');
         local objects = {};
         while (objects.len() < objectCount) {
             if (PDU.len() - PDU.tell() < 2) {
                 
                 return false;
             }
             local currentObjectId = PDU.readn('b');
             local currentObjectLen = PDU.readn('b');
             if (PDU.len() - PDU.tell() < currentObjectLen) {
                 
                 return false;
             }
             objects[currentObjectId] <- PDU.readstring(currentObjectLen);
         }
         return objects;
     }

    
    
    
    static function _isValidAddress(addressType, address) {
        switch (addressType) {
            case MODBUSRTU_ADDRESS_TYPE.DIRECT:
                return (address >= 0 && address <= 9998);
            case MODBUSRTU_ADDRESS_TYPE.STANDARD:
                return (address >= 00001 && address <= 09999) ||
                       (address >= 10001 && address <= 19999) ||
                       (address >= 30001 && address <= 39999) ||
                       (address >= 40001 && address <= 49999);
            case MODBUSRTU_ADDRESS_TYPE.EXTENDED:
                return (address >= 000001 && address <= 065536) ||
                       (address >= 100001 && address <= 165536) ||
                       (address >= 300001 && address <= 365536) ||
                       (address >= 400001 && address <= 465536);
            default:
                return false;
        }
    }

    
    
    
    static function _getTargetType(addressType, address) {
        switch (addressType) {
            case MODBUSRTU_ADDRESS_TYPE.DIRECT:
                server.error("Target type must be provided for direct addressing");
                throw MODBUSRTU_EXCEPTION.INVALID_TARGET_TYPE;
            case MODBUSRTU_ADDRESS_TYPE.STANDARD:
                if (address >= 1 && address <= 9999) {
                    return MODBUSRTU_TARGET_TYPE.COIL;
                } else if (address >= 10001 && address <= 19999) {
                    return MODBUSRTU_TARGET_TYPE.DISCRETE_INPUT;
                } else if (address >= 30001 && address <= 39999) {
                    return MODBUSRTU_TARGET_TYPE.INPUT_REGISTER;
                } else if (address >= 40001 && address <= 49999) {
                    return MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER;
                }
                break;
            case MODBUSRTU_ADDRESS_TYPE.EXTENDED:
                if (address >= 1 && address <= 65536) {
                    return MODBUSRTU_TARGET_TYPE.COIL;
                } else if (address >= 100001 && address <= 165536) {
                    return MODBUSRTU_TARGET_TYPE.DISCRETE_INPUT;
                } else if (address >= 300001 && address <= 365536) {
                    return MODBUSRTU_TARGET_TYPE.INPUT_REGISTER;
                } else if (address >= 400001 && address <= 465536) {
                    return MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER;
                }
                break;
        }
        return false;
    }

    
    
    
    static function _getTargetOffset(addressType, targetType) {
        switch (addressType) {
            case MODBUSRTU_ADDRESS_TYPE.DIRECT:
                return 0;
            case MODBUSRTU_ADDRESS_TYPE.STANDARD:
                switch (targetType) {
                    case MODBUSRTU_TARGET_TYPE.COIL:             return 1;
                    case MODBUSRTU_TARGET_TYPE.DISCRETE_INPUT:   return 10001;
                    case MODBUSRTU_TARGET_TYPE.INPUT_REGISTER:   return 30001;
                    case MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER: return 40001;
                }
                break;
            case MODBUSRTU_ADDRESS_TYPE.EXTENDED:
                switch (targetType) {
                    case MODBUSRTU_TARGET_TYPE.COIL:             return 1;
                    case MODBUSRTU_TARGET_TYPE.DISCRETE_INPUT:   return 100001;
                    case MODBUSRTU_TARGET_TYPE.INPUT_REGISTER:   return 300001;
                    case MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER: return 400001;
                }
                break;
        }
        return false;
    }
}


class Modbus485Slave {
    static VERSION = "1.0.0";

    _slaveID = null;
    _uart = null;
    _rts = null;
    _debug = null;
    _receiveBuffer = null;
    _shouldParseADU = null;

    constructor(params){
        if (!("CRC16" in getroottable())) throw "Must include CRC16 library v1.0.0+";
        _uart = params.uart;
        _rts = params.rts;
        _slaveID = params.slaveID;
        _shouldParseADU = true;
        _debug = ("debug" in params) ? params.debug : false;
        local baudRate = ("baudRate" in params) ? params.baudRate : 19200;
        local dataBits = ("dataBits" in params) ? params.dataBits : 8;
        local parity = ("parity" in params) ? params.parity : PARITY_NONE;
        local stopBits = ("stopBits" in params) ? params.stopBits : 1;
        _receiveBuffer = blob();
        _uart.configure(baudRate, dataBits, parity, stopBits, TIMING_ENABLED, function(){
            
            local  minInterval = 45000000.0 / baudRate;
            _onReceive(minInterval);
        }.bindenv(this));
        _rts.configure(DIGITAL_OUT, 0);
    }

    function _onReceive(minInterval) {
        local data = _uart.read();
        while ((data != -1) && (_receiveBuffer.len() < 300)) {
            if (_receiveBuffer.len() > 0 || data != 0x00) {
                local interval = data >> 8;
                if (interval > minInterval) {
                    
                    _receiveBuffer = blob();
                    _shouldParseADU = true;
                }
                _receiveBuffer.writen(data, 'b');
            }
            data = _uart.read();
        }
        if (_shouldParseADU && _receiveBuffer.len() > 1) {
            _processReceiveBuffer();
        }
    }

    function _processReceiveBuffer() {
        _receiveBuffer.seek(0);
        server.log(_receiveBuffer);
        local bufferLength = _receiveBuffer.len();
        local slaveID = _receiveBuffer.readn('b');
        if (_slaveID != slaveID) {
            return _shouldParseADU = false;
        }
        local PDU = _receiveBuffer.readblob(bufferLength - 1);
        local result = ModbusSlave.perform(PDU);
        if (result == false) {
            return _receiveBuffer.seek(bufferLength);
        }
        if (bufferLength < result.expectedReqLen + 3) {
            return _receiveBuffer.seek(bufferLength);
        }
        if (_hasValidCRC()) {
            server.log("valid");
        }
        local ADU = blob();
        ADU.writen(_slaveID, 'b');
        ADU.writeblob(result.response);
        ADU.writen(CRC16.calculate(ADU),'w');
        _send(ADU);

    }

    function _send(ADU) {
        server.log(ADU);
    }

    function _hasValidCRC(){
        _receiveBuffer.seek(0);
        local content = _receiveBuffer.readblob(_receiveBuffer.len() - 2);
        local crc = _receiveBuffer.readn('w');
        return (crc == CRC16.calculate(content));
    }
}

modbus <- Modbus485Slave({
    uart = hardware.uart2,
    rts  = hardware.pinL,
    slaveID = 1
});


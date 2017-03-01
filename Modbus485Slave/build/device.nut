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
        if (expectedReqLen == null) {
            startingAddress = swap2(PDU.readn('w'));
            quantity = swap2(PDU.readn('w'));
            expectedReqLen = quantity * 2 + 6;
        }
        if (length < expectedReqLen) {
            
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

    static function _getRequestLength(functionCode) {
        foreach (value in FUNCTION_CODES) {
            if (value.fcode == functionCode) {
                return value.reqLen
            }
        }
    }

    static function createErrorPDU(functionCode, error) {
        local PDU = blob();
        PDU.writen(functionCode | 0x80, 'b');
        PDU.writen(error, 'b');
        return PDU;
    }

}


class Modbus485Slave {
    static VERSION = "1.0.0";
    static MIN_REQUEST_LENGTH = 4;
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
        while ((data != -1) && (_receiveBuffer.len() < 300)) {
            if (_receiveBuffer.len() > 0 || data != 0x00) {
                local interval = data >> 8;
                if (interval > _minInterval) {
                    
                    _receiveBuffer = blob();
                    _shouldParseADU = true;
                }
                _receiveBuffer.writen(data, 'b');
            }
            data = _uart.read();
        }
        if (_shouldParseADU && _receiveBuffer.len() >= MIN_REQUEST_LENGTH) {
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
        local result = ModbusSlave.parse(PDU);
        if (result == false) {
            return _receiveBuffer.seek(bufferLength);
        }
        if (bufferLength < result.expectedReqLen + 3) {
            return _receiveBuffer.seek(bufferLength);
        }
        if (!_hasValidCRC()) {
            
        }
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
        if (input == true) {
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
        server.log(ADU);
    }

    function _hasValidCRC() {
        _receiveBuffer.seek(0);
        local content = _receiveBuffer.readblob(_receiveBuffer.len() - 2);
        local crc = _receiveBuffer.readn('w');
        return (crc == CRC16.calculate(content));
    }
}

modbus <- Modbus485Slave(hardware.uart2, hardware.pinL, 1);




modbus.onWrite(function(error, request){
	if (error) {
		server.error(error);
	} else {
		foreach (key, value in request.writeValues) {
			server.log(key + " : " + value);
		}
	}
});

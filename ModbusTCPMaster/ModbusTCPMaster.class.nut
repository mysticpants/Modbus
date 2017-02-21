

class ModbusTCPMaster {

    static VERSION = "1.0.0";
    static MAX_TRANSACTION_COUNT = 255;

    _transactions = null;
    _wiz = null;
    _transactionCount = null;
    _connection = null;
    _connectionSettings = null;
    _shouldRetry = null;
    _connectCallback = null;
    _debug = null;

    constructor (spi, interruptPin, csPin, resetPin, debug = false){
        _wiz = W5500.API(spi, interruptPin, csPin, resetPin);
        _transactionCount = 1;
        _transactions = {};
        _debug = debug;
    }


    function connect(networkSettings, connectionSettings, callback = null){
        _shouldRetry = true;
        _connectCallback = callback;
        _connectionSettings = connectionSettings;
        _wiz.configureNetworkSettings(networkSettings);
        _wiz.openConnection(connectionSettings, _onConnect.bindenv(this));
    }

    function _onConnect(error, conn) {
        _connection = conn;
        _wiz.setReceiveCallback(_connection, _parseADU.bindenv(this));
        _wiz.setDisconnectCallback(_connection, _onDisconnect.bindenv(this));
        _callbackHandler(error,conn,_connectCallback);
    }

    function _onDisconnect(conn){
        if (_shouldRetry) {
            _connectCallback = null;
            _wiz.openConnection(_connectionSettings, _onConnect.bindenv(this));
        }
    }

    function disconnect(){
        _shouldRetry = false;
        _wiz.closeConnection(_connection);
    }


    function reportSlaveID(callback = null) {
        local properties = {
            expectedResLen = ModbusRTU.FUNCTION_CODES.reportSlaveID.resLen,
            expectedResType = ModbusRTU.FUNCTION_CODES.reportSlaveID.fcode,
            callback = callback
        };
        _send(ModbusRTU.createReportSlaveIdPDU(), properties);
    }

    function write(targetType, startingAddress, quantity, values, callback = null) {
        try{
            if (quantity < 1) {
                throw MODBUSRTU_EXCEPTION.INVALID_QUANTITY;
            }
            switch(targetType) {
                case MODBUSRTU_TARGET_TYPE.COIL :
                    return _writeCoils(startingAddress, quantity, values, callback);
                case MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER :
                    return _writeRegisters(startingAddress, quantity, values, callback);
                default :
                    throw MODBUSRTU_EXCEPTION.INVALID_TARGET_TYPE;
            }
        } catch (error) {
            _callbackHandler(error,null,callback);
        }
    }




    function read(targetType, startingAddress, quantity, callback = null) {
        try {
            local PDU = null;
            local resLen = null;
            local resType = null;
            switch (targetType) {
                case MODBUSRTU_TARGET_TYPE.COIL:
                    PDU = ModbusRTU.createReadPDU(ModbusRTU.FUNCTION_CODES.readCoils, startingAddress, quantity);
                    resLen = ModbusRTU.FUNCTION_CODES.readCoils.resLen(quantity);
                    resType = ModbusRTU.FUNCTION_CODES.readCoils.fcode;
                    break;
                case MODBUSRTU_TARGET_TYPE.DISCRETE_INPUT:
                    PDU = ModbusRTU.createReadPDU(ModbusRTU.FUNCTION_CODES.readInputs, startingAddress, quantity);
                    resLen = ModbusRTU.FUNCTION_CODES.readInputs.resLen(quantity);
                    resType = ModbusRTU.FUNCTION_CODES.readInputs.fcode;
                    break;
                case MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER:
                    PDU = ModbusRTU.createReadPDU(ModbusRTU.FUNCTION_CODES.readHoldingRegs, startingAddress, quantity);
                    resLen = ModbusRTU.FUNCTION_CODES.readHoldingRegs.resLen(quantity);
                    resType = ModbusRTU.FUNCTION_CODES.readHoldingRegs.fcode;
                    break;
                case MODBUSRTU_TARGET_TYPE.INPUT_REGISTER:
                    PDU = ModbusRTU.createReadPDU(ModbusRTU.FUNCTION_CODES.readInputRegs, startingAddress, quantity);
                    resLen = ModbusRTU.FUNCTION_CODES.readInputRegs.resLen(quantity);
                    resType = ModbusRTU.FUNCTION_CODES.readInputRegs.fcode;
                    break;
                default:
                    throw MODBUSRTU_EXCEPTION.INVALID_TARGET_TYPE;
            }
            local properties = {
                expectedResLen = resLen,
                expectedResType = resType,
                quantity = quantity,
                callback = callback
            };
            _send(PDU, properties);
        } catch (error) {
            _callbackHandler(error,null,callback);
        }
    }



    function readExceptionStatus(callback = null) {
        local properties = {
            expectedResLen = ModbusRTU.FUNCTION_CODES.readExceptionStatus.resLen,
            expectedResType = ModbusRTU.FUNCTION_CODES.readExceptionStatus.fcode,
            callback = callback
        };
        _send(ModbusRTU.createReadExceptionStatusPDU(), properties);
    }

    function diagnostics(subFunctionCode, data, callback = null) {
        local quantity = data.len() / 2;
        local properties = {
            expectedResLen = ModbusRTU.FUNCTION_CODES.diagnostics.resLen(quantity),
            expectedResType = ModbusRTU.FUNCTION_CODES.diagnostics.fcode,
            quantity = quantity,
            callback = callback
        };
        _send(ModbusRTU.createDiagnosticsPDU(subFunctionCode, data), properties);
    }

    function maskWriteRegister(referenceAddress, AND_Mask, OR_Mask, callback = null) {
        local properties = {
            expectedResLen = ModbusRTU.FUNCTION_CODES.maskWriteRegister.resLen,
            expectedResType = ModbusRTU.FUNCTION_CODES.maskWriteRegister.fcode,
            callback = callback
        };
        _send(ModbusRTU.createMaskWriteRegisterPDU(referenceAddress, AND_Mask, OR_Mask), properties);
    }

    function readWriteMultipleRegisters(readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue, callback = null) {
        writeValue = _processWriteRegistersValues(writeQuantity, writeValue);
        local properties = {
            expectedResLen = ModbusRTU.FUNCTION_CODES.readWriteMultipleRegisters.resLen(readQuantity),
            expectedResType = ModbusRTU.FUNCTION_CODES.readWriteMultipleRegisters.fcode,
            quantity = readQuantity,
            callback = callback
        };
        _send(ModbusRTU.createReadWriteMultipleRegistersPDU(readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue), properties);
    }

    function readDeviceIdentification(readDeviceIdCode, objectId, callback = null) {
        local properties = {
            expectedResLen = ModbusRTU.FUNCTION_CODES.readDeviceIdentification.resLen,
            expectedResType = ModbusRTU.FUNCTION_CODES.readDeviceIdentification.fcode,
            callback = callback
        };
        _send(ModbusRTU.createReadDeviceIdentificationPDU(readDeviceIdCode, objectId), properties);
    }


    function _parseADU(error, connection, ADU){
        if (error) {
            _callbackHandler(error,null,_connectCallback);
        }
        ADU.seek(0);
        local header = ADU.readblob(7);
        local transactionID = swap2(header.readn('w'));
        local PDU = ADU.readblob(ADU.len() - 7);
        local params = _transactions[transactionID];
        local callback = params.callback;
        params.PDU <- PDU;
        try {
            local result = ModbusRTU.parse(params);
            _callbackHandler(null,result,callback);
        } catch(error) {
            _callbackHandler(error,null,callback);
        }
        _transactions.rawdelete(transactionID);
    }

    function _createADU(PDU) {
        local ADU = [0x00,_transactionCount,0x00,0x00,0x00,PDU.len() + 1,0x00];
        foreach (value in PDU) {
            ADU.push(value);
        }
        return ADU;
    }

    function _send(PDU, properties) {
        _transactions[_transactionCount] <- properties;
        local ADU = _createADU(PDU);
        _wiz.transmit(_connection,ADU);
        _transactionCount ++ ;
        if (_transactionCount > MAX_TRANSACTION_COUNT) {
            _transactionCount = 1;
        }
    }

    function _writeCoils(startingAddress, quantity, values, callback) {
          local numBytes = math.ceil(quantity / 8.0);
          local writeValues = blob(numBytes);
          local functionType = (quantity == 1) ? ModbusRTU.FUNCTION_CODES.writeSingleCoil : ModbusRTU.FUNCTION_CODES.writeMultipleCoils ;
          switch (typeof values) {
              case "integer" :
                  writeValues.writen(swap2(values),'w');
                  break;
              case "bool" :
                  writeValues.writen(swap2(values ? 0xFF00 : 0),'w');
                  break;
              case "blob" :
                  writeValues = values;
                  break;
              case "array" :
                  if (quantity != values.len()){
                      throw MODBUSRTU_EXCEPTION.INVALID_ARG_LENGTH;
                  }
                  local byte, bitshift;
                  foreach (bit,val in values) {
                      byte = bit / 8;
                      bitshift = bit % 8;
                      writeValues[byte] = writeValues[byte] | ((val ? 1 : 0) << bitshift);
                  }
                  break;
              default :
                  throw MODBUSRTU_EXCEPTION.INVALID_VALUES;
          }
          local properties = {
              callback = callback,
              expectedResType = functionType.fcode,
              expectedResLen = functionType.resLen,
              quantity = quantity
          };
          _send(ModbusRTU.createWritePDU(functionType,startingAddress, numBytes, quantity ,writeValues), properties);

    }

    function _processWriteRegistersValues(quantity, values) {
        local writeValues = blob();
        switch (typeof values) {
            case "integer" :
                writeValues.writen(swap2(values),'w');
                break;
            case "blob" :
                writeValues = values;
                break;
            case "array" :
                if (quantity != values.len()){
                    throw MODBUSRTU_EXCEPTION.INVALID_ARG_LENGTH;
                }
                foreach (value in values) {
                    writeValues.writen(swap2(value), 'w');
                }
                break;
            default :
                throw MODBUSRTU_EXCEPTION.INVALID_VALUES;
        }
        return writeValues;
    }

    function _writeRegisters(startingAddress, quantity, values, callback) {
        local numBytes =  quantity * 2;
        local writeValues = _processWriteRegistersValues(quantity, values);
        local functionType = (quantity == 1) ? ModbusRTU.FUNCTION_CODES.writeSingleReg : ModbusRTU.FUNCTION_CODES.writeMultipleRegs ;
        local properties = {
            callback = callback,
            expectedResType = functionType.fcode,
            expectedResLen = functionType.resLen,
            quantity = quantity
        };
        _send(ModbusRTU.createWritePDU(functionType,startingAddress, numBytes, quantity ,writeValues), properties);
    }


    function _callbackHandler(error, result, callback){
        if (callback) {
            if (error) {
                callback(error,null);
            } else {
                callback(null, result);
            }
        }
    }


}

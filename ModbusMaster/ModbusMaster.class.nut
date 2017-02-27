class ModbusMaster {
    static VERSION = "1.0.0";
    _debug = null;

    constructor(debug) {
        _debug = debug;
    }

    function reportSlaveID(callback = null) {
        local properties = {
            expectedResLen = ModbusRTU.FUNCTION_CODES.reportSlaveID.resLen,
            expectedResType = ModbusRTU.FUNCTION_CODES.reportSlaveID.fcode,
            callback = callback
        };
        _send(ModbusRTU.createReportSlaveIdPDU(), properties);
    }

    //
    // This function reads the contents of eight Exception Status outputs in a remote device
    //
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
    function readExceptionStatus(callback = null) {
        local properties = {
            expectedResLen = ModbusRTU.FUNCTION_CODES.readExceptionStatus.resLen,
            expectedResType = ModbusRTU.FUNCTION_CODES.readExceptionStatus.fcode,
            callback = callback
        };
        _send(ModbusRTU.createReadExceptionStatusPDU(), properties);
    }

    //
    // This function provides a series of tests for checking the communication system between a client ( Master) device and a server ( Slave), or for checking various internal error conditions within a server.
    //
    // @param {integer} deviceAddress - The unique address that identifies a device
    // @param {integer} subFunctionCode - The address from which it begins reading values
    // @param {blob} data - The data field required by Modbus request
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
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

    //
    // This function modifies the contents of a specified holding register using a combination of an AND mask, an OR mask, and the register's current contents. The function can be used to set or clear individual bits in the register.
    //
    // @param {integer} referenceAddress - The address of the holding register the value is written into
    // @param {integer} AND_mask - The AND mask
    // @param {integer} OR_mask - The OR mask
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
    function maskWriteRegister(referenceAddress, AND_Mask, OR_Mask, callback = null) {
        local properties = {
            expectedResLen = ModbusRTU.FUNCTION_CODES.maskWriteRegister.resLen,
            expectedResType = ModbusRTU.FUNCTION_CODES.maskWriteRegister.fcode,
            callback = callback
        };
        _send(ModbusRTU.createMaskWriteRegisterPDU(referenceAddress, AND_Mask, OR_Mask), properties);
    }

    //
    // This function performs a combination of one read operation and one write operation in a single MODBUS transaction. The write operation is performed before the read.
    //
    // @param {integer} readingStartAddress - The address from which it begins reading values
    // @param {integer} readQuantity - The number of consecutive addresses values are read from
    // @param {integer} writeStartAddress - The address from which it begins writing values
    // @param {integer} writeQuantity - The number of consecutive addresses values are written into
    // @param {blob} writeValue - The value written into the holding register
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
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

    //
    // This function allows reading the identification and additional information relative to the physical and functional description of a remote device, only.
    //
    // @param {enum} readDeviceIdCode - read device id code
    // @param {enum} objectId - object id
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
    function readDeviceIdentification(readDeviceIdCode, objectId, callback = null) {
        local properties = {
            expectedResLen = ModbusRTU.FUNCTION_CODES.readDeviceIdentification.resLen,
            expectedResType = ModbusRTU.FUNCTION_CODES.readDeviceIdentification.fcode,
            callback = callback
        };
        _send(ModbusRTU.createReadDeviceIdentificationPDU(readDeviceIdCode, objectId), properties);
    }

    //
    // This is the generic function to write values into coils or holding registers .
    //
    // @param {enum} targetType - The address from which it begins reading values
    // @param {integer} startingAddress - The address from which it begins writing values
    // @param {integer} quantity - The number of consecutive addresses the values are written into
    // @param {integer, Array[integer, Bool], Bool, blob} values - The values written into Coils or Registers
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
    function write(targetType, startingAddress, quantity, values, callback = null) {
        try {
            if (quantity < 1) {
                throw MODBUSRTU_EXCEPTION.INVALID_QUANTITY;
            }
            switch (targetType) {
                case MODBUSRTU_TARGET_TYPE.COIL:
                    return _writeCoils(startingAddress, quantity, values, callback);
                case MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER:
                    return _writeRegisters(startingAddress, quantity, values, callback);
                default:
                    throw MODBUSRTU_EXCEPTION.INVALID_TARGET_TYPE;
            }
        } catch (error) {
            _callbackHandler(error, null, callback);
        }
    }

    //
    // This is the generic function to read values from a single coil, register or multiple coils, registers .
    //
    // @param {enum} targetType - The address from which it begins reading values
    // @param {integer} startingAddress - The address from which it begins reading values
    // @param {integer} quantity - The number of consecutive addresses the values are read from
    // @param {function} callback - The function to be fired when it receives response regarding this request
    //
    function read(targetType, startingAddress, quantity, callback = null) {
        try {
            local PDU = null;
            local resLen = null;
            local resType = null;
            if (quantity < 1) {
                throw MODBUSRTU_EXCEPTION.INVALID_QUANTITY;
            }
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
            _callbackHandler(error, null, callback);
        }
    }

    //
    // construct a writeCoils request
    //
    function _writeCoils(startingAddress, quantity, values, callback) {
        local numBytes = math.ceil(quantity / 8.0);
        local writeValues = blob(numBytes);
        local functionType = (quantity == 1) ? ModbusRTU.FUNCTION_CODES.writeSingleCoil : ModbusRTU.FUNCTION_CODES.writeMultipleCoils;
        switch (typeof values) {
            case "integer":
                writeValues.writen(swap2(values), 'w');
                break;
            case "bool":
                writeValues.writen(swap2(values ? 0xFF00 : 0), 'w');
                break;
            case "blob":
                writeValues = values;
                break;
            case "array":
                if (quantity != values.len()) {
                    throw MODBUSRTU_EXCEPTION.INVALID_ARG_LENGTH;
                }
                local byte, bitshift;
                foreach (bit, val in values) {
                    byte = bit / 8;
                    bitshift = bit % 8;
                    writeValues[byte] = writeValues[byte] | ((val ? 1 : 0) << bitshift);
                }
                break;
            default:
                throw MODBUSRTU_EXCEPTION.INVALID_VALUES;
        }
        local properties = {
            callback = callback,
            expectedResType = functionType.fcode,
            expectedResLen = functionType.resLen,
            quantity = quantity
        };
        _send(ModbusRTU.createWritePDU(functionType, startingAddress, numBytes, quantity, writeValues), properties);
    }

    //
    // construct a writeRegisters request
    //
    function _writeRegisters(startingAddress, quantity, values, callback) {
        local numBytes = quantity * 2;
        local writeValues = _processWriteRegistersValues(quantity, values);
        local functionType = (quantity == 1) ? ModbusRTU.FUNCTION_CODES.writeSingleReg : ModbusRTU.FUNCTION_CODES.writeMultipleRegs;
        local properties = {
            callback = callback,
            expectedResType = functionType.fcode,
            expectedResLen = functionType.resLen,
            quantity = quantity
        };
        _send(ModbusRTU.createWritePDU(functionType, startingAddress, numBytes, quantity, writeValues), properties);
    }

    //
    // process the values written into the holding registers
    //
    function _processWriteRegistersValues(quantity, values) {
        local writeValues = blob();
        switch (typeof values) {
            case "integer":
                writeValues.writen(swap2(values), 'w');
                break;
            case "blob":
                writeValues = values;
                break;
            case "array":
                if (quantity != values.len()) {
                    throw MODBUSRTU_EXCEPTION.INVALID_ARG_LENGTH;
                }
                foreach (value in values) {
                    writeValues.writen(swap2(value), 'w');
                }
                break;
            default:
                throw MODBUSRTU_EXCEPTION.INVALID_VALUES;
        }
        return writeValues;
    }

    //
    // log the message
    //
    function _log(message, ...) {
        if (_debug) {
            switch (typeof message) {
                case "blob":
                    local mes = vargv[0];
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
    // send the ADU
    //
    function _send(PDU, properties);

    //
    // fire the callback
    //
    function _callbackHandler(error, result, callback);

    //
    // create an ADU
    //
    function _createADU(PDU);
}

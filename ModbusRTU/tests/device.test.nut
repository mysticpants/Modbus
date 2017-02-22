const MINIMUM_RESPONSE_LENGTH = 5;
const DEVICE_ADDRESS = 0x01;


function parse (fakeBuffer, params){
    local length = fakeBuffer.len();
    if (length < MINIMUM_RESPONSE_LENGTH){
        return false;
    }
    fakeBuffer.seek(1);
    params.PDU <- fakeBuffer.readblob(length - 1);
    local result = ModbusRTU.parse(params);
    if (result == false) {
        return fakeBuffer.seek(length);
    }
    return result;
}


class DeviceTestCase extends ImpTestCase {

  function setUp() {
    return "testing Modbus";
  }


  function testCreateReadWriteMultipleRegistersPDU() {
    local readingStartAddress = 0x0001;
    local readQuantity = 5;
    local writeStartAddress = 0x000A;
    local writeQuantity = 1;
    local writeValue = blob();
    writeValue.writen(0xff00,'w');
    local expectedPDU = blob();
    expectedPDU.writen(ModbusRTU.FUNCTION_CODES.readWriteMultipleRegisters.fcode,'b');
    expectedPDU.writen(swap2(readingStartAddress),'w');
    expectedPDU.writen(swap2(readQuantity),'w');
    expectedPDU.writen(swap2(writeStartAddress),'w');
    expectedPDU.writen(swap2(writeQuantity),'w');
    expectedPDU.writen(writeValue.len(),'b');
    expectedPDU.writeblob(writeValue);
    local PDU = ModbusRTU.createReadWriteMultipleRegistersPDU(readingStartAddress,readQuantity,writeStartAddress,writeQuantity,writeValue);
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }


  function testCreateMaskWriteRegisterPDU() {
    local referenceAddress = 0x000A;
    local AND_Mask = 0xFFFF;
    local OR_Mask = 0x0000;
    local expectedPDU = blob();
    expectedPDU.writen(ModbusRTU.FUNCTION_CODES.maskWriteRegister.fcode,'b');
    expectedPDU.writen(swap2(referenceAddress),'w');
    expectedPDU.writen(swap2(AND_Mask),'w');
    expectedPDU.writen(swap2(OR_Mask),'w');
    local PDU = ModbusRTU.createMaskWriteRegisterPDU(referenceAddress , AND_Mask , OR_Mask);
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }


  function testCreateReportSlaveIdPDU() {
    local expectedPDU = blob();
    expectedPDU.writen(ModbusRTU.FUNCTION_CODES.reportSlaveID.fcode,'b');
    local PDU = ModbusRTU.createReportSlaveIdPDU();
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }


  function testCreatereadDeviceIdentificationPDU() {
    local readDeviceIdCode = MODBUSRTU_READ_DEVICE_CODE.BASIC;
    local objectId = MODBUSRTU_OBJECT_ID.VENDOR_NAME;
    local expectedPDU = blob();
    expectedPDU.writen(ModbusRTU.FUNCTION_CODES.readDeviceIdentification.fcode,'b');
    expectedPDU.writen((0x0E),'b');
    expectedPDU.writen((readDeviceIdCode),'b');
    expectedPDU.writen((objectId),'b');
    local PDU = ModbusRTU.createReadDeviceIdentificationPDU(readDeviceIdCode , objectId);
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }


  function testCreateDiagnosticsPDU() {
    local subFunctionCode = MODBUSRTU_SUB_FUNCTION_CODE.RETURN_QUERY_DATA;
    local data = blob();
    data.writen(swap2(0x0000),'w')
    local expectedPDU = blob();
    expectedPDU.writen(ModbusRTU.FUNCTION_CODES.diagnostics.fcode,'b');
    expectedPDU.writen(swap2(subFunctionCode),'w');
    expectedPDU.writeblob(data);
    local PDU = ModbusRTU.createDiagnosticsPDU(subFunctionCode , data);
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }


  function testCreateReadExceptionStatusPDU() {
    local expectedPDU = blob();
    expectedPDU.writen(ModbusRTU.FUNCTION_CODES.readExceptionStatus.fcode,'b');
    local PDU = ModbusRTU.createReadExceptionStatusPDU();
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }

  function testCreateReadPDU(){
    local functionCode = ModbusRTU.FUNCTION_CODES.readCoils;
    local startingAddress = 0x000A;
    local quantity = 1;
    local expectedPDU = blob();
    expectedPDU.writen(functionCode.fcode,'b');
    expectedPDU.writen(swap2(startingAddress),'w');
    expectedPDU.writen(swap2(quantity),'w');
    local PDU = ModbusRTU.createReadPDU(functionCode,startingAddress,quantity);
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }

  function testWritePDUWithSignleCoil(){
    local functionCode = ModbusRTU.FUNCTION_CODES.writeSingleCoil;
    local startingAddress = 0x000A;
    local quantity = 1;
    local numBytes = 2 * quantity;
    local values = blob();
    values.writen(swap2(0),'w');
    local expectedPDU = blob();
    expectedPDU.writen(functionCode.fcode,'b');
    expectedPDU.writen(swap2(startingAddress),'w');
    expectedPDU.writeblob(values);
    local PDU = ModbusRTU.createWritePDU(functionCode,startingAddress,numBytes,quantity,values);
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }

  function testWritePDUWithSignleRegister(){
    local functionCode = ModbusRTU.FUNCTION_CODES.writeSingleReg;
    local startingAddress = 0x000A;
    local quantity = 1;
    local numBytes = 2 * quantity;
    local values = blob();
    values.writen(swap2(1818),'w');
    local expectedPDU = blob();
    expectedPDU.writen(functionCode.fcode,'b');
    expectedPDU.writen(swap2(startingAddress),'w');
    expectedPDU.writeblob(values);
    local PDU = ModbusRTU.createWritePDU(functionCode,startingAddress,numBytes,quantity,values);
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }


  function testWritePDUWithMultipleRegisters(){
    local functionCode = ModbusRTU.FUNCTION_CODES.writeMultipleRegs;
    local startingAddress = 0x000A;
    local quantity = 2;
    local numBytes = 2 * quantity;
    local values = blob();
    values.writen(swap2(1818),'w');
    values.writen(swap2(2828),'w');
    local expectedPDU = blob();
    expectedPDU.writen(functionCode.fcode,'b');
    expectedPDU.writen(swap2(startingAddress),'w');
    expectedPDU.writen(swap2(quantity),'w');
    expectedPDU.writen(numBytes,'b');
    expectedPDU.writeblob(values);
    local PDU = ModbusRTU.createWritePDU(functionCode,startingAddress,numBytes,quantity,values);
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }

  function testWritePDUWithMultipleCoils(){
    local functionCode = ModbusRTU.FUNCTION_CODES.writeMultipleCoils;
    local startingAddress = 0x000A;
    local quantity = 2;
    local numBytes = math.ceil(quantity / 8.0);
    local values = blob();
    values.writen(0x03,'b');
    local expectedPDU = blob();
    expectedPDU.writen(functionCode.fcode,'b');
    expectedPDU.writen(swap2(startingAddress),'w');
    expectedPDU.writen(swap2(quantity),'w');
    expectedPDU.writen(numBytes,'b');
    expectedPDU.writeblob(values);
    local PDU = ModbusRTU.createWritePDU(functionCode,startingAddress,numBytes,quantity,values);
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }


  function testParseReportSlaveID(){
    local result = null;
    local fakeBuffer = blob();
    local slaveID = "abcde";
    local runIndicator = 0xFF;
    local functionCode = ModbusRTU.FUNCTION_CODES.reportSlaveID.fcode;
    fakeBuffer.writen(DEVICE_ADDRESS,'b');
    fakeBuffer.writen(functionCode,'b');
    fakeBuffer.writen(slaveID.len() + 1,'b');
    fakeBuffer.writestring(slaveID);
    fakeBuffer.writen(runIndicator,'b');
    fakeBuffer.seek(0);
    local mockBuffer = blob();
    while(true){
        if (!fakeBuffer.eos()){
            local byte = fakeBuffer.readn('b');
            mockBuffer.writen(byte,'b');
            local params = {
                functionCode = functionCode,
                expectedResLen = ModbusRTU.FUNCTION_CODES.reportSlaveID.resLen,
                expectedResType = functionCode
            };
            result = parse(mockBuffer, params);
        } else {
            break;
        }
    }
    this.assertTrue(result.slaveId == slaveID);
    this.assertTrue(result.runIndicator == (runIndicator == 0? false : true));
  }

  function testParseReadExceptionStatus(){
    local result = null;
    local fakeBuffer = blob();
    local outputData = 0x03;
    local functionCode = ModbusRTU.FUNCTION_CODES.readExceptionStatus.fcode;
    fakeBuffer.writen(DEVICE_ADDRESS,'b');
    fakeBuffer.writen(functionCode,'b');
    fakeBuffer.writen(outputData,'b');
    fakeBuffer.writen(CRC16.calculate(fakeBuffer),'w');
    fakeBuffer.seek(0);
    local mockBuffer = blob();
    while(true){
        if (!fakeBuffer.eos()){
            local byte = fakeBuffer.readn('b');
            mockBuffer.writen(byte,'b');
            local params = {
                functionCode = functionCode,
                expectedResLen = ModbusRTU.FUNCTION_CODES.readExceptionStatus.resLen,
                expectedResType = functionCode
            };
            result = parse(mockBuffer, params);
        } else {
            break;
        }
    }
    this.assertTrue(outputData == result);
  }

  function testParseMarkWriteRegister(){
    local result = null;
    local fakeBuffer = blob();
    local functionCode = ModbusRTU.FUNCTION_CODES.maskWriteRegister.fcode;
    fakeBuffer.writen(DEVICE_ADDRESS,'b');
    fakeBuffer.writen(functionCode,'b');
    fakeBuffer.writen(0x0009,'w');
    fakeBuffer.writen(0x0000,'w');
    fakeBuffer.writen(0x1111,'w');
    fakeBuffer.writen(CRC16.calculate(fakeBuffer),'w');
    fakeBuffer.seek(0);
    local mockBuffer = blob();
    while(true){
        if (!fakeBuffer.eos()){
            local byte = fakeBuffer.readn('b');
            mockBuffer.writen(byte,'b');
            local params = {
                functionCode = functionCode,
                expectedResLen = ModbusRTU.FUNCTION_CODES.maskWriteRegister.resLen,
                expectedResType = functionCode
            };
            result = parse(mockBuffer, params);
        } else {
            break;
        }
    }
    this.assertTrue(result);
  }




  function testParseReadWriteMultipleRegisters(){
    local result = null;
    local fakeBuffer = blob();
    local readValue = 0x0808;
    local functionCode = ModbusRTU.FUNCTION_CODES.readWriteMultipleRegisters.fcode;
    fakeBuffer.writen(DEVICE_ADDRESS,'b');
    fakeBuffer.writen(functionCode,'b');
    fakeBuffer.writen(0x02,'b');
    fakeBuffer.writen(swap2(readValue),'w'); // read value
    fakeBuffer.writen(CRC16.calculate(fakeBuffer),'w');
    fakeBuffer.seek(0);
    local mockBuffer = blob();
    while(true){
        if (!fakeBuffer.eos()){
            local byte = fakeBuffer.readn('b');
            mockBuffer.writen(byte,'b');
            local params = {
                functionCode = functionCode,
                expectedResType = functionCode,
                expectedResLen = ModbusRTU.FUNCTION_CODES.readWriteMultipleRegisters.resLen(1),
                quantity = 1
            };
            result = parse(mockBuffer, params);
        } else {
            break;
        }
    }
    this.assertTrue(result.pop() == readValue);
  }



  function testParseDiagnostics(){
    local fakeBuffer = blob();
    local result = null;
    local data = 0xFF00;
    local functionCode = ModbusRTU.FUNCTION_CODES.diagnostics.fcode;
    fakeBuffer.writen(DEVICE_ADDRESS,'b');
    fakeBuffer.writen(functionCode,'b');
    fakeBuffer.writen(swap2(0x0001),'w');
    fakeBuffer.writen(swap2(data),'w');
    fakeBuffer.writen(CRC16.calculate(fakeBuffer),'w');
    fakeBuffer.seek(0);
    local mockBuffer = blob();
    while(true){
        if (!fakeBuffer.eos()){
            local byte = fakeBuffer.readn('b');
            mockBuffer.writen(byte,'b');
            local params = {
                functionCode = functionCode,
                expectedResType = functionCode,
                expectedResLen = ModbusRTU.FUNCTION_CODES.diagnostics.resLen(1),
                quantity = 1
            };
            result = parse(mockBuffer, params);
        } else {
            break;
        }
    }
    this.assertTrue(data == result.pop());
  }


  function testParseReadDeviceIdentification(){
    local fakeBuffer = blob();
    local result = null;
    local vendorName = "MysticPants";
    local produceCode = "CONCTOR";
    local functionCode = ModbusRTU.FUNCTION_CODES.readDeviceIdentification.fcode;
    fakeBuffer.writen(DEVICE_ADDRESS,'b');
    fakeBuffer.writen(functionCode,'b');
    fakeBuffer.writen(0x0E,'b');
    fakeBuffer.writen(0x01,'b');
    fakeBuffer.writen(0x01,'b');
    fakeBuffer.writen(0xFF,'b');
    fakeBuffer.writen(0x00,'b');
    fakeBuffer.writen(0x02,'b');// number of objects
    // first object
    fakeBuffer.writen(0x00,'b');
    fakeBuffer.writen(11,'b');
    fakeBuffer.writestring(vendorName);
    // second object
    fakeBuffer.writen(0x01,'b');
    fakeBuffer.writen(7,'b');
    fakeBuffer.writestring(produceCode);
    fakeBuffer.writen(CRC16.calculate(fakeBuffer),'w');
    fakeBuffer.seek(0);
    local mockBuffer = blob();
    while(true){
        if (!fakeBuffer.eos()){
            local byte = fakeBuffer.readn('b');
            mockBuffer.writen(byte,'b');
            local params = {
                functionCode = functionCode,
                expectedResType = functionCode,
                expectedResLen = ModbusRTU.FUNCTION_CODES.readDeviceIdentification.resLen,
            };
            result = parse(mockBuffer, params);
        } else {
            break;
        }
    }
    this.assertEqual(result[0x00] ,vendorName);
    this.assertEqual(result[0x01] ,produceCode);
  }




  function testParseReadCoils(){
    local fakeBuffer = blob();
    local result = null;
    local coilStatus = 0xAA; // 10101010
    local functionCode = ModbusRTU.FUNCTION_CODES.readCoils.fcode;
    local quantity = 8;
    fakeBuffer.writen(DEVICE_ADDRESS,'b');
    fakeBuffer.writen(functionCode,'b');
    fakeBuffer.writen(0x01,'b'); // byte count
    fakeBuffer.writen(coilStatus,'b'); // coil status
    fakeBuffer.writen(CRC16.calculate(fakeBuffer),'w');
    fakeBuffer.seek(0);
    local mockBuffer = blob();
    while(true){
        if (!fakeBuffer.eos()){
            local byte = fakeBuffer.readn('b');
            mockBuffer.writen(byte,'b');
            local params = {
                functionCode = functionCode,
                expectedResType = functionCode,
                expectedResLen = ModbusRTU.FUNCTION_CODES.readCoils.resLen(quantity),
                quantity = quantity
            };
            result = parse(mockBuffer, params);
        } else {
            break;
        }
    }
    for(local position = 0; position < quantity ; position++){
        local bit = (coilStatus >> position) & 1;
        local status = (bit == 1)? true : false;
        this.assertTrue(status == result[position]);
    }
  }


  function testParseReadRegisters(){
    local fakeBuffer = blob();
    local result = null;
    local values = blob();
    local functionCode = ModbusRTU.FUNCTION_CODES.readHoldingRegs.fcode;
    values.writen(swap2(18),'w');
    values.writen(swap2(28),'w');
    fakeBuffer.writen(DEVICE_ADDRESS,'b');
    fakeBuffer.writen(functionCode,'b');
    fakeBuffer.writen(4,'b'); // byte count
    fakeBuffer.writeblob(values); // registers value
    fakeBuffer.writen(CRC16.calculate(fakeBuffer),'w');
    fakeBuffer.seek(0);
    local quantity = values.len()/2;
    local mockBuffer = blob();
    while(true){
        if (!fakeBuffer.eos()){
            local byte = fakeBuffer.readn('b');
            mockBuffer.writen(byte,'b');
            local params = {
                functionCode = functionCode,
                expectedResType = functionCode,
                expectedResLen = ModbusRTU.FUNCTION_CODES.readHoldingRegs.resLen(quantity),
                quantity = quantity
            };
            result = parse(mockBuffer, params);
        } else {
            break;
        }
    }
    values.seek(0);
    foreach (value in result) {
        local expectedValue = swap2(values.readn('w'));
        this.assertTrue(expectedValue == value);
    }

  }


  function testModbusException (){
     local result = null;
     local fakeBuffer = blob();
     local functionCode = ModbusRTU.FUNCTION_CODES.readCoils.fcode;
     fakeBuffer.writen(DEVICE_ADDRESS,'b');
     fakeBuffer.writen(0x81,'b');
     fakeBuffer.writen(MODBUSRTU_EXCEPTION.ILLEGAL_FUNCTION,'b');// ILLEGAL_FUNCTION
     fakeBuffer.writen(CRC16.calculate(fakeBuffer),'w');
     fakeBuffer.seek(0);
     local quantity = 8;
     local mockBuffer = blob();
     try {
         while(true){
             if (!fakeBuffer.eos()){
                 local byte = fakeBuffer.readn('b');
                 mockBuffer.writen(byte,'b');
                 local params = {
                     functionCode = functionCode,
                     expectedResType = functionCode,
                     expectedResLen = ModbusRTU.FUNCTION_CODES.readCoils.resLen(quantity),
                     quantity = quantity
                 };
                 result = parse(mockBuffer, params);
             } else {
                 break;
             }
         }
     } catch(error){
        this.assertTrue(error == MODBUSRTU_EXCEPTION.ILLEGAL_FUNCTION);
     }
  }



  function testInvalidCRC(){
    local result = null;
    local fakeBuffer = blob();
    local outputData = 0x03;
    local functionCode = ModbusRTU.FUNCTION_CODES.readExceptionStatus.fcode ;
    fakeBuffer.writen(DEVICE_ADDRESS,'b');
    fakeBuffer.writen(functionCode,'b');
    fakeBuffer.writen(outputData,'b');
    fakeBuffer.writen(0xabcd,'w'); // invalid crc
    fakeBuffer.seek(0);
    local mockBuffer = blob();
    try{
        while(true){
            if (!fakeBuffer.eos()){
                local byte = fakeBuffer.readn('b');
                mockBuffer.writen(byte,'b');
                local params = {
                    expectedResLen = ModbusRTU.FUNCTION_CODES.readExceptionStatus.resLen,
                    expectedResType = functionCode,
                    functionCode = functionCode
                };
                result = parse(mockBuffer, params);
            } else {
                break;
            }
        }
    }catch(error){
        this.assertTrue(error == MODBUSRTU_EXCEPTION.INVALID_CRC);
    }
  }


  function tearDown() {
    return "Test finished";
  }

}

const CRC16_LOOKUP_LOW   = "\x00\xC0\xC1\x01\xC3\x03\x02\xC2\xC6\x06\x07\xC7\x05\xC5\xC4\x04\xCC\x0C\x0D\xCD\x0F\xCF\xCE\x0E\x0A\xCA\xCB\x0B\xC9\x09\x08\xC8\xD8\x18\x19\xD9\x1B\xDB\xDA\x1A\x1E\xDE\xDF\x1F\xDD\x1D\x1C\xDC\x14\xD4\xD5\x15\xD7\x17\x16\xD6\xD2\x12\x13\xD3\x11\xD1\xD0\x10\xF0\x30\x31\xF1\x33\xF3\xF2\x32\x36\xF6\xF7\x37\xF5\x35\x34\xF4\x3C\xFC\xFD\x3D\xFF\x3F\x3E\xFE\xFA\x3A\x3B\xFB\x39\xF9\xF8\x38\x28\xE8\xE9\x29\xEB\x2B\x2A\xEA\xEE\x2E\x2F\xEF\x2D\xED\xEC\x2C\xE4\x24\x25\xE5\x27\xE7\xE6\x26\x22\xE2\xE3\x23\xE1\x21\x20\xE0\xA0\x60\x61\xA1\x63\xA3\xA2\x62\x66\xA6\xA7\x67\xA5\x65\x64\xA4\x6C\xAC\xAD\x6D\xAF\x6F\x6E\xAE\xAA\x6A\x6B\xAB\x69\xA9\xA8\x68\x78\xB8\xB9\x79\xBB\x7B\x7A\xBA\xBE\x7E\x7F\xBF\x7D\xBD\xBC\x7C\xB4\x74\x75\xB5\x77\xB7\xB6\x76\x72\xB2\xB3\x73\xB1\x71\x70\xB0\x50\x90\x91\x51\x93\x53\x52\x92\x96\x56\x57\x97\x55\x95\x94\x54\x9C\x5C\x5D\x9D\x5F\x9F\x9E\x5E\x5A\x9A\x9B\x5B\x99\x59\x58\x98\x88\x48\x49\x89\x4B\x8B\x8A\x4A\x4E\x8E\x8F\x4F\x8D\x4D\x4C\x8C\x44\x84\x85\x45\x87\x47\x46\x86\x82\x42\x43\x83\x41\x81\x80\x40";
const CRC16_LOOKUP_HIGH  = "\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40";

class CRC16 {
  static version = [1,0,0];
  static defaultInitValue = 0xFFFF;

  // Calculate the CRC16 of data [string or blob] for a given range
  static function calculate(data, start = null, end = null, initValue = null) {
      //Start is inclusive
      if(start == null) start = 0;

      // End is exclusive
      if(end == null) end = data.len();

      // Check if we should  use a non-default value
      if(initValue == null) initValue = defaultInitValue;

      // index is a convenience varaiable
      local index;
      local lo = initValue & 0xFF;
      local hi = (initValue >> 8 ) & 0xFF;

      // Loop through the data
      for(local i = start; i < end; i++) {
          index = lo ^ data[i];
          lo    = hi ^ CRC16_LOOKUP_HIGH[index];
          hi    = CRC16_LOOKUP_LOW[index];
      }

      return (hi << 8) | lo;
  }
}


function parseReadExceptionStatus (fakeBuffer){
    local length = fakeBuffer.len();
    local params = {
        functionCode = ModbusRTU.FUNCTION_CODES.readExceptionStatus.fcode,
        buffer = fakeBuffer,
        expectedResLen = ModbusRTU.FUNCTION_CODES.readExceptionStatus.resLen,
        expectedResType = ModbusRTU.FUNCTION_CODES.readExceptionStatus.fcode
    };
    local result = ModbusRTU.parse(params);
    if (result == false) {
        return fakeBuffer.seek(length);
    }
    return result;
}


function parseMaskWriteRegister(fakeBuffer){
    local length = fakeBuffer.len();
    local params = {
        functionCode = ModbusRTU.FUNCTION_CODES.maskWriteRegister.fcode,
        buffer = fakeBuffer,
        expectedResLen = ModbusRTU.FUNCTION_CODES.maskWriteRegister.resLen,
        expectedResType = ModbusRTU.FUNCTION_CODES.maskWriteRegister.fcode
    };
    local result = ModbusRTU.parse(params);
    if (result == false) {
        return fakeBuffer.seek(length);
    }
    return result;
}


function parseReadWriteMultipleRegisters (fakeBuffer){
    local length = fakeBuffer.len();
    local params = {
        functionCode = ModbusRTU.FUNCTION_CODES.readWriteMultipleRegisters.fcode,
        expectedResType = ModbusRTU.FUNCTION_CODES.readWriteMultipleRegisters.fcode,
        buffer = fakeBuffer,
        expectedResLen = ModbusRTU.FUNCTION_CODES.readWriteMultipleRegisters.resLen(1),
        quantity = 1
    };
    local result = ModbusRTU.parse(params);
    if (result == false) {
        return fakeBuffer.seek(length);
    }
    return result ;
}

function parseDiagnostics (fakeBuffer){
    local result = null;
    local length = fakeBuffer.len();
    local params = {
        functionCode = ModbusRTU.FUNCTION_CODES.diagnostics.fcode,
        expectedResType = ModbusRTU.FUNCTION_CODES.diagnostics.fcode,
        buffer = fakeBuffer,
        expectedResLen = ModbusRTU.FUNCTION_CODES.diagnostics.resLen(1),
        quantity = 1
    };
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
    expectedPDU.writen(swap2(writeValue.len()),'w');
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
    local readDeviceIdCode = MODBUS_READ_DEVICE_CODE.BASIC;
    local objectId = MODBUS_OBJECT_ID.VENDOR_NAME;
    local expectedPDU = blob();
    expectedPDU.writen(ModbusRTU.FUNCTION_CODES.readDeviceIdentification.fcode,'b');
    expectedPDU.writen((0x0E),'b');
    expectedPDU.writen((readDeviceIdCode),'b');
    expectedPDU.writen((objectId),'b');
    local PDU = ModbusRTU.createreadDeviceIdentificationPDU(readDeviceIdCode , objectId);
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }


  function testCreateDiagnosticsPDU() {
    local subFunctionCode = MODBUS_SUB_FUNCTION_CODE.RETURN_QUERY_DATA;
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

  function testCreateADU (){
    local PDU = ModbusRTU.createReadExceptionStatusPDU();
    local deviceAddress = 0x01;
    local ADU = ModbusRTU.createADU(deviceAddress, PDU);
    local expectedADU = blob();
    expectedADU.writen(deviceAddress,'b');
    expectedADU.writeblob(PDU);
    expectedADU.writen(CRC16.calculate(expectedADU),'w');
    this.assertTrue(expectedADU.tostring() == ADU.tostring());
  }

  function testParseReadExceptionStatus(){
    local result = null;
    local fakeBuffer = blob();
    local outputData = 0x03;
    fakeBuffer.writen(0x01,'b');
    fakeBuffer.writen(0x07,'b');
    fakeBuffer.writen(outputData,'b');
    fakeBuffer.writen(CRC16.calculate(fakeBuffer),'w');
    fakeBuffer.seek(0);
    local mockBuffer = blob();
    while(true){
        if (!fakeBuffer.eos()){
            local byte = fakeBuffer.readn('b');
            mockBuffer.writen(byte,'b');
            result = parseReadExceptionStatus(mockBuffer);
        } else {
            break;
        }
    }
    this.assertTrue(outputData == result);
  }

  function testParseMarkWriteRegister(){
    local result = null;
    local fakeBuffer = blob();
    fakeBuffer.writen(0x01,'b');
    fakeBuffer.writen(0x016,'b');
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
            result = parseMaskWriteRegister(mockBuffer);
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
    fakeBuffer.writen(0x01,'b');
    fakeBuffer.writen(0x017,'b');
    fakeBuffer.writen(0x02,'b');
    fakeBuffer.writen(swap2(readValue),'w'); // read value
    fakeBuffer.writen(CRC16.calculate(fakeBuffer),'w');
    fakeBuffer.seek(0);
    local mockBuffer = blob();
    while(true){
        if (!fakeBuffer.eos()){
            local byte = fakeBuffer.readn('b');
            mockBuffer.writen(byte,'b');
            result = parseReadWriteMultipleRegisters(mockBuffer);
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
    fakeBuffer.writen(0x01,'b');
    fakeBuffer.writen(0x08,'b');
    fakeBuffer.writen(swap2(0x0001),'w');
    fakeBuffer.writen(swap2(data),'w');
    fakeBuffer.writen(CRC16.calculate(fakeBuffer),'w');
    fakeBuffer.seek(0);
    local mockBuffer = blob();
    while(true){
        if (!fakeBuffer.eos()){
            local byte = fakeBuffer.readn('b');
            mockBuffer.writen(byte,'b');
            result = parseDiagnostics(mockBuffer);
        } else {
            break;
        }
    }
    this.assertTrue(data == result.pop());

  }

  function tearDown() {
    return "Test finished";
  }

}

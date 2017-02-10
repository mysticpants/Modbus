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

  function tearDown() {
    return "Test finished";
  }

}

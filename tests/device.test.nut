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
    expectedPDU.writen(Modbus.FUNCTION_CODES.readWriteMultipleRegisters.fcode,'b');
    expectedPDU.writen(swap2(readingStartAddress),'w');
    expectedPDU.writen(swap2(readQuantity),'w');
    expectedPDU.writen(swap2(writeStartAddress),'w');
    expectedPDU.writen(swap2(writeQuantity),'w');
    expectedPDU.writen(swap2(writeValue.len()),'w');
    writeValue.swap2();
    expectedPDU.writeblob(writeValue);
    writeValue.swap2();
    local PDU = Modbus.createReadWriteMultipleRegistersPDU(readingStartAddress,readQuantity,writeStartAddress,writeQuantity,writeValue);
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }


  function testCreateMaskWriteRegisterPDU() {
    local referenceAddress = 0x000A;
    local AND_Mask = 0xFFFF;
    local OR_Mask = 0x0000;
    local expectedPDU = blob();
    expectedPDU.writen(Modbus.FUNCTION_CODES.maskWriteRegister.fcode,'b');
    expectedPDU.writen(swap2(referenceAddress),'w');
    expectedPDU.writen(swap2(AND_Mask),'w');
    expectedPDU.writen(swap2(OR_Mask),'w');
    local PDU = Modbus.createMaskWriteRegisterPDU(referenceAddress , AND_Mask , OR_Mask);
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }


  function testCreateReportSlaveIdPDU() {
    local expectedPDU = blob();
    expectedPDU.writen(Modbus.FUNCTION_CODES.reportSlaveID.fcode,'b');
    local PDU = Modbus.createReportSlaveIdPDU();
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }


  function testCreatereadDeviceIdentificationPDU() {
    local readDeviceIdCode = READ_DEVICE_CODE.BASIC;
    local objectId = OBJECT_ID.VENDOR_NAME;
    local expectedPDU = blob();
    expectedPDU.writen(Modbus.FUNCTION_CODES.readDeviceIdentification.fcode,'b');
    expectedPDU.writen((0x0E),'b');
    expectedPDU.writen((readDeviceIdCode),'b');
    expectedPDU.writen((objectId),'b');
    local PDU = Modbus.createreadDeviceIdentificationPDU(readDeviceIdCode , objectId);
    this.assertTrue(expectedPDU.tostring() == PDU.tostring());
  }

  function tearDown() {
    return "Test finished";
  }

}

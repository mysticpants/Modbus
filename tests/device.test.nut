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

  function tearDown() {
    return "Test finished";
  }

}

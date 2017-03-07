// it is a bit hard to write test cases if the hardware is involved,
// so the idea is to create a fake buffer and simulate the parsing requests and creating responses

const SLAVE_ID = 1;
const MIN_REQUEST_LENGTH = 4;
const PASS_MESSAGE = "Pass";

function onReceive(modbus, buffer) {
    local ADU = null;
    while (!buffer.eos()) {
        modbus._receiveBuffer.writen(buffer.readn('b'), 'b');
        if (modbus._receiveBuffer.len() >= MIN_REQUEST_LENGTH) {
            ADU = modbus._processReceiveBuffer();
        }
    }
    return ADU;
}

class DeviceTestCase extends ImpTestCase {
    _modbus = null;

    function setUp() {
        _modbus = Modbus485Slave(hardware.uart2, hardware.pinL, SLAVE_ID);
        return "Modbus485Slave";
    }

    function testSetSlaveID() {
        local newSlaveID = 2;
        _modbus.setSlaveID(newSlaveID);
        this.assertTrue(_modbus._slaveID = newSlaveID);
    }

    function testSetSlaveIDWithWrongType() {
        try {
            _modbus.setSlaveID(false);
        } catch (error) {
            return this.assertTrue(true);
        }
        this.assertTrue(false);
    }

    function testOnReadCoilsWithArrayOfBooleanReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x01;
        local expectedStartingAddress = 0x0A;
        local returnValue = [true, false, false, true, false, true, false, true, true];
        local expectedQuantity = returnValue.len();
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onRead(function(slaveID, functionCode, startingAddress, quantity) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(math.ceil(expectedQuantity / 8.0), 'b');
        // 10101001
        // 00000001
        expectedADU.writen(0xA9, 'b');
        expectedADU.writen(0x01, 'b');
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnReadCoilsWithArrayOfIntegerReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x01;
        local expectedStartingAddress = 0x0A;
        local returnValue = [1, 1, 0, 0, 1, 0, 0, 1, 1];
        local expectedQuantity = returnValue.len();
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onRead(function(slaveID, functionCode, startingAddress, quantity) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(math.ceil(expectedQuantity / 8.0), 'b');
        // 10010011
        // 00000001
        expectedADU.writen(0x93, 'b');
        expectedADU.writen(0x01, 'b');
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnReadCoilsWithNullReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x01;
        local expectedStartingAddress = 0x0A;
        local expectedQuantity = 4;
        local returnValue = null;
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onRead(function(slaveID, functionCode, startingAddress, quantity) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(math.ceil(expectedQuantity / 8.0), 'b');
        // 00000000
        expectedADU.writen(0x00, 'b');
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnReadCoilWithIntegerReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x01;
        local expectedStartingAddress = 0x0A;
        local expectedQuantity = 1;
        local returnValue = 1;
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onRead(function(slaveID, functionCode, startingAddress, quantity) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(math.ceil(expectedQuantity / 8.0), 'b');
        // 00000001
        expectedADU.writen(0x01, 'b');
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnReadCoilWithBooleanReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x01;
        local expectedStartingAddress = 0x0A;
        local expectedQuantity = 1;
        local returnValue = true;
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onRead(function(slaveID, functionCode, startingAddress, quantity) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(math.ceil(expectedQuantity / 8.0), 'b');
        // 00000001
        expectedADU.writen(0x01, 'b');
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnReadCoilsWithBlobReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x01;
        local expectedStartingAddress = 0x0A;
        local expectedQuantity = 2;
        local returnValue = blob();
        returnValue.writen(0x05, 'b');
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onRead(function(slaveID, functionCode, startingAddress, quantity) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(math.ceil(expectedQuantity / 8.0), 'b');
        // 00000001
        expectedADU.writeblob(returnValue);
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnWriteCoilWithTrueReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x05;
        local expectedStartingAddress = 0x0A;
        local expectedQuantity = 1;
        local expectedWriteValues = 0xFF00;
        local returnValue = true;
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedWriteValues), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onWrite(function(slaveID, functionCode, startingAddress, quantity, writeValues) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            this.assertTrue(writeValues == expectedWriteValues);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(swap2(expectedStartingAddress), 'w');
        expectedADU.writen(swap2(expectedWriteValues), 'w');
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnWriteCoilWithNullReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x05;
        local expectedStartingAddress = 0x0A;
        local expectedQuantity = 1;
        local expectedWriteValues = 0xFF00;
        local returnValue = null;
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedWriteValues), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onWrite(function(slaveID, functionCode, startingAddress, quantity, writeValues) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            this.assertTrue(writeValues == expectedWriteValues);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(swap2(expectedStartingAddress), 'w');
        expectedADU.writen(swap2(expectedWriteValues), 'w');
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnWriteCoilWithExceptionCodeReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x05;
        local expectedStartingAddress = 0x0A;
        local expectedQuantity = 1;
        local expectedWriteValues = 0xFF00;
        local returnValue = MODBUSSLAVE_EXCEPTION.ILLEGAL_DATA_ADDR;
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedWriteValues), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onWrite(function(slaveID, functionCode, startingAddress, quantity, writeValues) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            this.assertTrue(writeValues == expectedWriteValues);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode | 0x80, 'b');
        expectedADU.writen(returnValue, 'b');
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnWriteCoilWithFlaseReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x05;
        local expectedStartingAddress = 0x0A;
        local expectedQuantity = 1;
        local expectedWriteValues = 0xFF00;
        local returnValue = false;
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedWriteValues), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onWrite(function(slaveID, functionCode, startingAddress, quantity, writeValues) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            this.assertTrue(writeValues == expectedWriteValues);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode | 0x80, 'b');
        expectedADU.writen(MODBUSSLAVE_EXCEPTION.ILLEGAL_FUNCTION, 'b');
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnReadRegisterWithNullReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x03;
        local expectedStartingAddress = 0x0A;
        local expectedQuantity = 2;
        local returnValue = null;
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onRead(function(slaveID, functionCode, startingAddress, quantity) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(expectedQuantity * 2, 'b');
        expectedADU.writeblob(blob(expectedQuantity * 2));
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnReadRegisterWithIntegerReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x03;
        local expectedStartingAddress = 0x0A;
        local expectedQuantity = 1;
        local returnValue = 188;
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onRead(function(slaveID, functionCode, startingAddress, quantity) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(expectedQuantity * 2, 'b');
        expectedADU.writen(swap2(returnValue), 'w');
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnReadRegistersWithBlobReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x03;
        local expectedStartingAddress = 0x0A;
        local expectedQuantity = 1;
        local returnValue = blob();
        returnValue.writen(288, 'b');
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onRead(function(slaveID, functionCode, startingAddress, quantity) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(expectedQuantity * 2, 'b');
        expectedADU.writeblob(returnValue);
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnReadRegistersWithIntegerReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x03;
        local expectedStartingAddress = 0x0A;
        local returnValue = [8, 18, 28, 38, 58, 68, 78, 88, 98];
        local expectedQuantity = returnValue.len();
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onRead(function(slaveID, functionCode, startingAddress, quantity) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(expectedQuantity * 2, 'b');
        foreach (value in returnValue) {
            expectedADU.writen(swap2(value), 'w');
        }
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnReadRegistersWithNullReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x03;
        local expectedStartingAddress = 0x0A;
        local expectedQuantity = 9;
        local returnValue = null;
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onRead(function(slaveID, functionCode, startingAddress, quantity) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(expectedQuantity * 2, 'b');
        expectedADU.writeblob(blob(expectedQuantity * 2));
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnReadRegistersWithBlobReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x03;
        local expectedStartingAddress = 0x0A;
        local expectedQuantity = 2;
        local returnValue = blob();
        returnValue.writen(swap2(888), 'w');
        returnValue.writen(swap2(1888), 'w');
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onRead(function(slaveID, functionCode, startingAddress, quantity) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(expectedQuantity * 2, 'b');
        expectedADU.writeblob(returnValue);
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnWriteRegistersWithTrueReturned() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x10;
        local expectedStartingAddress = 0x0A;
        local expectedWriteValues = [88, 188];
        local expectedQuantity = expectedWriteValues.len();
        local returnValue = true;
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(expectedQuantity * 2, 'b');
        foreach (value in expectedWriteValues) {
            fakeBuffer.writen(swap2(value), 'w');
        }
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onWrite(function(slaveID, functionCode, startingAddress, quantity, writeValues) {
            this.assertTrue(slaveID == SLAVE_ID);
            this.assertTrue(functionCode == expectedFunctionCode);
            this.assertTrue(startingAddress == expectedStartingAddress);
            this.assertTrue(quantity == expectedQuantity);
            this.assertDeepEqual(writeValues, expectedWriteValues);
            return returnValue;
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode, 'b');
        expectedADU.writen(swap2(expectedStartingAddress), 'w');
        expectedADU.writen(swap2(expectedQuantity), 'w');
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testUnsupportedFunctionCode() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x07;
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(CRC16.calculate(fakeBuffer), 'w');
        fakeBuffer.seek(0);
        _modbus.onWrite(function(slaveID, functionCode, startingAddress, quantity, writeValues) {
            // this should not be called
            this.assertTrue(false);
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        local expectedADU = blob();
        expectedADU.writen(SLAVE_ID, 'b');
        expectedADU.writen(expectedFunctionCode | 0x80, 'b');
        expectedADU.writen(MODBUSSLAVE_EXCEPTION.ILLEGAL_FUNCTION, 'b');
        expectedADU.writen(CRC16.calculate(expectedADU), 'w');
        this.assertTrue(ADU.tostring() == expectedADU.tostring());
        return PASS_MESSAGE;
    }

    function testOnError() {
        setUp();
        local fakeBuffer = blob();
        local expectedFunctionCode = 0x10;
        local expectedStartingAddress = 0x0A;
        local expectedWriteValues = [88, 188];
        local expectedQuantity = expectedWriteValues.len();
        local returnValue = true;
        fakeBuffer.writen(SLAVE_ID, 'b');
        fakeBuffer.writen(expectedFunctionCode, 'b');
        fakeBuffer.writen(swap2(expectedStartingAddress), 'w');
        fakeBuffer.writen(swap2(expectedQuantity), 'w');
        fakeBuffer.writen(expectedQuantity * 2, 'b');
        foreach (value in expectedWriteValues) {
            fakeBuffer.writen(swap2(value), 'w');
        }
        // wrong CRC
        fakeBuffer.writen(swap2(CRC16.calculate(fakeBuffer)), 'w');
        fakeBuffer.seek(0);
        _modbus.onError(function(error) {
            this.assertTrue(true);
        }.bindenv(this));
        _modbus.onWrite(function(slaveID, functionCode, startingAddress, quantity, writeValues) {
            this.assertTrue(false);
        }.bindenv(this));
        local ADU = onReceive(_modbus, fakeBuffer);
        return PASS_MESSAGE;
    }

    function tearDown() {
        return "Test finished";
    }
}

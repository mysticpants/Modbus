const SLAVE_ID = 1;

class DeviceTestCase extends ImpTestCase {
    _PASS_MESSAGE = "Pass";
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

    function testSniff() {
        this.assertTrue(_modbus.isSniffer == false);
        _modbus.sniff(true);
        this.assertTrue(_modbus.isSniffer);
    }

    function testSniffWithWrongType() {
        try {
            _modbus.sniff(1);
        } catch (error) {
            return this.assertTrue(true);
        }
        this.assertTrue(false);
    }

    function tearDown() {
        return "Test finished";
    }
}

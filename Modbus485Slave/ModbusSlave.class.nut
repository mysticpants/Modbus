const MAX_TABLE_ENTRY = 10000;

class ModbusSlave {

    static COIL_TABLE = array(MAX_TABLE_ENTRY, 0);
    static DISCRETE_INPUT_TABLE = array(MAX_TABLE_ENTRY, 0);
    static HOLDING_REGISTER_TABLE = blob(2 * MAX_TABLE_ENTRY);
    static INPUT_REGISTER_TABLE = blob(2 * MAX_TABLE_ENTRY);

    static function perform(PDU) {
        PDU.seek(0);
        local functionCode = PDU.readn('b');
        local expectedReqLen = _getRequestLength(functionCode);
        local response = null;
        if (PDU.len() < expectedReqLen) {
            // not enough data
            return false;
        }
        switch (functionCode) {
            case 0x11:
                response = _createReportSlaveIdPDU();
                break;
        }
        return {
            response = response,
            expectedReqLen = expectedReqLen,
            functionCode = functionCode
        }
    }

    static function write() {

    }

    static function read() {

    }

    static function _getRequestLength(functionCode) {
        foreach (value in ModbusRTU.FUNCTION_CODES) {
            if (functionCode == value.fcode) {
                return value.reqLen;
            }
        }
    }

    static function _createReportSlaveIdPDU() {
        local PDU = blob();
        PDU.writen(0x11,'b');
        PDU.writestring(hardware.getdeviceid());
        PDU.writen(0x00, 'b');
        return PDU;
    }
}

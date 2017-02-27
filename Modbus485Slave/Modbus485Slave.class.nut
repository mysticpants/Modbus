
class Modbus485Slave {
    static VERSION = "1.0.0";

    _slaveID = null;
    _uart = null;
    _rts = null;
    _debug = null;
    _receiveBuffer = null;
    _shouldParseADU = null;

    constructor(params){
        if (!("CRC16" in getroottable())) throw "Must include CRC16 library v1.0.0+";
        _uart = params.uart;
        _rts = params.rts;
        _slaveID = params.slaveID;
        _shouldParseADU = true;
        _debug = ("debug" in params) ? params.debug : false;
        local baudRate = ("baudRate" in params) ? params.baudRate : 19200;
        local dataBits = ("dataBits" in params) ? params.dataBits : 8;
        local parity = ("parity" in params) ? params.parity : PARITY_NONE;
        local stopBits = ("stopBits" in params) ? params.stopBits : 1;
        _receiveBuffer = blob();
        _uart.configure(baudRate, dataBits, parity, stopBits, TIMING_ENABLED, function(){
            // 4.5 characters interval
            local  minInterval = 45000000.0 / baudRate;
            _onReceive(minInterval);
        }.bindenv(this));
        _rts.configure(DIGITAL_OUT, 0);
    }

    function _onReceive(minInterval) {
        local data = _uart.read();
        while ((data != -1) && (_receiveBuffer.len() < 300)) {
            if (_receiveBuffer.len() > 0 || data != 0x00) {
                local interval = data >> 8;
                if (interval > minInterval) {
                    // new frame, reset the _receiveBuffer
                    _receiveBuffer = blob();
                    _shouldParseADU = true;
                }
                _receiveBuffer.writen(data, 'b');
            }
            data = _uart.read();
        }
        if (_shouldParseADU && _receiveBuffer.len() > 1) {
            _processReceiveBuffer();
        }
    }

    function _processReceiveBuffer() {
        _receiveBuffer.seek(0);
        server.log(_receiveBuffer);
        local bufferLength = _receiveBuffer.len();
        local slaveID = _receiveBuffer.readn('b');
        if (_slaveID != slaveID) {
            return _shouldParseADU = false;
        }
        local PDU = _receiveBuffer.readblob(bufferLength - 1);
        local result = ModbusSlave.perform(PDU);
        if (result == false) {
            return _receiveBuffer.seek(bufferLength);
        }
        if (bufferLength < result.expectedReqLen + 3) {
            return _receiveBuffer.seek(bufferLength);
        }
        local response = result.response;
        if (!_hasValidCRC()) {
            response = _errorResponse(result.functionCode, MODBUSRTU_EXCEPTION.INVALID_CRC)
        }
        local ADU = _createADU(response);
        _send(ADU);
    }

    function _createADU(PDU) {
        local ADU = blob();
        ADU.writen(_slaveID, 'b');
        ADU.writeblob(PDU);
        ADU.writen(CRC16.calculate(ADU),'w');
        return ADU;
    }

    function _errorResponse(functionCode, error) {
        local PDU = blob();
        PDU.writen(functionCode | 0x80, 'b');
        PDU.writen(error, 'b');
        return PDU;
    }

    function _send(ADU) {
        server.log(ADU);
    }

    function _hasValidCRC(){
        _receiveBuffer.seek(0);
        local content = _receiveBuffer.readblob(_receiveBuffer.len() - 2);
        local crc = _receiveBuffer.readn('w');
        return (crc == CRC16.calculate(content));
    }
}

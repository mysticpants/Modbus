
class Modbus485Slave extends ModbusSlave {
    _slaveID = null;
    _uart = null;
    _rts = null;
    _receiveBuffer = null;
    _shouldParseADU = null;
    _minInterval = null;

    constructor(uart, rts, slaveID, params = {}) {
        if (!("CRC16" in getroottable())) {
            throw "Must include CRC16 library v1.0.0+";
        }
        base.constructor (("debug" in params) ? params.debug : false);
        _uart = uart;
        _rts = rts;
        _slaveID = slaveID;
        _shouldParseADU = true;
        local baudRate = ("baudRate" in params) ? params.baudRate : 19200;
        local dataBits = ("dataBits" in params) ? params.dataBits : 8;
        local parity = ("parity" in params) ? params.parity : PARITY_NONE;
        local stopBits = ("stopBits" in params) ? params.stopBits : 1;
        _receiveBuffer = blob();
        // 4.5 characters time in microseconds
        _minInterval = 45000000.0 / baudRate;
        _uart.configure(baudRate, dataBits, parity, stopBits, TIMING_ENABLED, _onReceive.bindenv(this));
        _rts.configure(DIGITAL_OUT, 0);
    }

    function _onReceive() {
        local data = _uart.read();
        while (data != -1) {
            if (_receiveBuffer.len() > 0 || data != 0x00) {
                local interval = data >> 8;
                if (interval > _minInterval) {
                    // new frame, reset the _receiveBuffer
                    _receiveBuffer = blob();
                    _shouldParseADU = true;
                }
                _receiveBuffer.writen(data, 'b');
            }
            data = _uart.read();
        }
        const MIN_REQUEST_LENGTH = 4;
        if (_shouldParseADU && _receiveBuffer.len() >= MIN_REQUEST_LENGTH) {
            _processReceiveBuffer();
        }
    }

    function _processReceiveBuffer() {
        _receiveBuffer.seek(0);
        local bufferLength = _receiveBuffer.len();
        local slaveID = _receiveBuffer.readn('b');
        if (_slaveID != slaveID) {
            return _shouldParseADU = false;
        }
        local PDU = _receiveBuffer.readblob(bufferLength - 1);
        local result = ModbusSlave.parse(PDU);
        if (result == false) {
            return _receiveBuffer.seek(bufferLength);
        }
        if (bufferLength < result.expectedReqLen + 3) {
            return _receiveBuffer.seek(bufferLength);
        }
        if (!_hasValidCRC()) {
             throw "Invalid CRC";
        }
        _log(_receiveBuffer,"Incoming ADU : ");
        local ADU = _createADU(_createPDU(result));
        _send(ADU);
    }

    function _createADU(PDU) {
        local ADU = blob();
        ADU.writen(_slaveID, 'b');
        ADU.writeblob(PDU);
        ADU.writen(CRC16.calculate(ADU), 'w');
        return ADU;
    }

    function _send(ADU) {
        local rw = _rts.write.bindenv(_rts);
        local uw = _uart.write.bindenv(_uart);
        local uf = _uart.flush.bindenv(_uart);
        rw(1);
        uw(ADU);
        uf();
        rw(0);
        _log(ADU,"Outgoing ADU : ");
    }

    function _hasValidCRC() {
        _receiveBuffer.seek(0);
        local content = _receiveBuffer.readblob(_receiveBuffer.len() - 2);
        local crc = _receiveBuffer.readn('w');
        return (crc == CRC16.calculate(content));
    }
}

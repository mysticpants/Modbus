
class Modbus485Slave {
    static VERSION = "1.0.0";

    _slaveID = null;
    _uart = null;
    _rts = null;
    _debug = null;
    _receiveBuffer = null;

    constructor(params){
        if (!("CRC16" in getroottable())) throw "Must include CRC16 library v1.0.0+";
        _uart = params.uart;
        _rts = params.rts;
        _slaveID = params.slaveID;
        _debug = ("debug" in params) ? params.debug : false;
        local baudRate = ("baudRate" in params) ? params.baudRate : 19200;
        local dataBits = ("dataBits" in params) ? params.dataBits : 8;
        local parity = ("parity" in params) ? params.parity : PARITY_NONE;
        local stopBits = ("stopBits" in params) ? params.stopBits : 1;
        _receiveBuffer = blob();
        _uart.configure(baudRate, dataBits, parity, stopBits, TIMING_ENABLED, function(){
            local  minInterval = 4.0 / baudRate;
            _onReceive(minInterval);
        }.bindenv(this));
        _rts.configure(DIGITAL_OUT, 0);
    }

    function _onReceive(minInterval){
        local data = _uart.read();
        while ((data != -1) && (_receiveBuffer.len() < 300)) {
            if (_receiveBuffer.len() > 0 || data != 0x00) {
                local interval = data >> 8;
                if (interval < minInterval) {
                    _receiveBuffer.writen(data, 'b');
                } else {
                    // do something here
                }
            }
            data = _uart.read();
        }
        server.log(_receiveBuffer);
    }
}


modbus <- Modbus485Slave({
    uart = hardware.uart2,
    rts  = hardware.pinL,
    slaveID = 1
});

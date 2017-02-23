
class Modbus485Slave {
    static VERSION = "1.0.0";

    _slaveID = null;
    _uart = null;
    _rts = null;
    _baudRate = null;
    _dataBits = null;
    _parity = null;
    _stopBits = null;
    _debug = null;
    _receiveBuffer = null;

    constructor(uart, rts, slaveID, baudRate = 19200, dataBits = 8, parity = PARITY_NONE, stopBits = 1, debug = false){
        if (!("CRC16" in getroottable())) throw "Must include CRC16 library v1.0.0+";
        _uart = uart;
        _rts = rts;
        _slaveID = slaveID;
        _baudRate = baudRate;
        _dataBits = dataBits;
        _parity = parity;
        _stopBits = stopBits;
        _debug = debug;
        _receiveBuffer = blob();
        _uart.configure(baudRate, dataBits, parity, stopBits, NO_CTSRTS, _onReceive.bindenv(this));
        _rts.configure(DIGITAL_OUT, 0);
    }

    function _onReceive(){
        local byte = _uart.read();
        while ((byte != -1) && (_receiveBuffer.len() < 300)) {
            if (_receiveBuffer.len() > 0 || byte != 0x00) {
                _receiveBuffer.writen(byte, 'b');
            }
            byte = _uart.read();
        }
    }
}

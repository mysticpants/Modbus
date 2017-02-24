modbus <- Modbus485Slave({
    uart = hardware.uart2,
    rts  = hardware.pinL,
    slaveID = 1
});

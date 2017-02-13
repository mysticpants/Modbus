#require "CRC16.class.nut:1.0.0"
#require "ModbusRTU.class.nut:1.0.0"
#require "Modbus485Master.class.nut:1.0.0"

modbus <- Modbus485Master(hardware.uart2, hardware.pinL);

modbus.write(0x01,MODBUS_TARGET_TYPE.HOLDING_REGISTER,9,3,[188,80,18],function(error,res){
    if (error){
        server.error(error);
    } else {
        server.log(res);
        modbus.read(0x01,MODBUS_TARGET_TYPE.HOLDING_REGISTER,9,3,function(error,res){
            if (error){
                server.error(error);
            } else {
                server.log(res[0]); // 188
                server.log(res[1]); // 80
                server.log(res[2]); // 18
            }
        })

    }
});

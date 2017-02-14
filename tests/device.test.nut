
class DeviceTestCase extends ImpTestCase {

  _modbus = null;
  _NOT_SUPPORT_MESSAGE = "This function is not supported by the device";
  _PASS_MESSAGE = "Pass";

  function setUp() {
      _modbus = Modbus485Master(hardware.uart2, hardware.pinL);
      return "Modbus485Master";
  }


  function testReadCoils(){
      local deviceAddress = 1;
      local targetType = MODBUS_TARGET_TYPE.COIL;
      local startingAddress = 1;
      local quantity = 5;
      return Promise(function(resolve, reject){
          _modbus.read(deviceAddress, targetType, startingAddress, quantity, function(error,result){
                if(error){
                    if (error == MODBUS_EXCEPTION.ILLEGAL_FUNCTION){
                        reject(_NOT_SUPPORT_MESSAGE);
                    } else{
                        reject("Error code : " + error);
                    }
                } else{
                    this.assertTrue(result.len() == quantity);
                    resolve(_PASS_MESSAGE);
                }
            }.bindenv(this));
        }.bindenv(this));
  }



  function testReadDiscreteInput(){
      local deviceAddress = 1;
      local targetType = MODBUS_TARGET_TYPE.DISCRETE_INPUT;
      local startingAddress = 1;
      local quantity = 6;
      return Promise(function(resolve, reject){
          _modbus.read(deviceAddress, targetType, startingAddress, quantity, function(error,result){
                if(error){
                    if (error == MODBUS_EXCEPTION.ILLEGAL_FUNCTION){
                        reject(_NOT_SUPPORT_MESSAGE);
                    } else{
                        reject("Error code : " + error);
                    }
                } else{
                    this.assertTrue(result.len() == quantity);
                    resolve(_PASS_MESSAGE);
                }
            }.bindenv(this));
        }.bindenv(this));
  }

  function testReadInputRegisters(){
      local deviceAddress = 1;
      local targetType = MODBUS_TARGET_TYPE.INPUT_REGISTER;
      local startingAddress = 1;
      local quantity = 7;
      return Promise(function(resolve, reject){
          _modbus.read(deviceAddress, targetType, startingAddress, quantity, function(error,result){
                if(error){
                    if (error == MODBUS_EXCEPTION.ILLEGAL_FUNCTION){
                        reject(_NOT_SUPPORT_MESSAGE);
                    } else{
                        reject("Error code : " + error);
                    }
                } else{
                    this.assertTrue(result.len() == quantity);
                    resolve(_PASS_MESSAGE);
                }
            }.bindenv(this));
        }.bindenv(this));
  }


  function testReadRegisters(){
      local deviceAddress = 1;
      local targetType = MODBUS_TARGET_TYPE.HOLDING_REGISTER;
      local startingAddress = 1;
      local quantity = 8;
      return Promise(function(resolve, reject){
          _modbus.read(deviceAddress, targetType, startingAddress, quantity, function(error,result){
                if(error){
                    if (error == MODBUS_EXCEPTION.ILLEGAL_FUNCTION){
                        reject(_NOT_SUPPORT_MESSAGE);
                    } else{
                        reject("Error code : " + error);
                    }
                } else{
                    this.assertTrue(result.len() == quantity);
                    resolve(_PASS_MESSAGE);
                }
            }.bindenv(this));
        }.bindenv(this));
  }

  function testReportSlaveID(){
      local deviceAddress = 1;
      return Promise(function(resolve, reject){
            _modbus.reportSlaveID(deviceAddress, function(error, result){
                if(error){
                    if (error == MODBUS_EXCEPTION.ILLEGAL_FUNCTION){
                        reject(_NOT_SUPPORT_MESSAGE);
                    } else{
                        reject("Error code : " + error);
                    }
                } else{
                    this.assertTrue(result.len() == 2);
                    resolve(_PASS_MESSAGE);
                }
              }.bindenv(this));
        }.bindenv(this));
  }


  function tearDown() {
    return "Test finished";
  }
}

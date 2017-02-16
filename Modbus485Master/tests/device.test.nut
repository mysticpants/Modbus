
const DEVICE_ADDRESS = 1;


function errorMessage (error, resolve,reject){
    switch(error){
        case MODBUS_EXCEPTION.ILLEGAL_FUNCTION :
          return resolve("This function is not supported by the device");
        case MODBUS_EXCEPTION.ILLEGAL_DATA_ADDR :
          return resolve("Illegal data address, please try a different address");
        case MODBUS_EXCEPTION.RESPONSE_TIMEOUT :
          return reject("Timeout. No response from the device");
        default :
          return reject("Error code : " + error);
    }
}


class DeviceTestCase extends ImpTestCase {

  _PASS_MESSAGE = "Pass";
  _modbus = null;

  function setUp() {
      _modbus = Modbus485Master(hardware.uart2, hardware.pinL);
      return "Modbus485Master";
  }


  function testReadCoils(){
      local targetType = MODBUS_TARGET_TYPE.COIL;
      local startingAddress = 1;
      local quantity = 5;
      return Promise(function(resolve, reject){
          _modbus.read(DEVICE_ADDRESS, targetType, startingAddress, quantity, function(error,result){
                if(error){
                    errorMessage(error, resolve ,reject);
                } else{
                    this.assertTrue(result.len() == quantity);
                    local message = "Index : Coil Status \n";
                    foreach (key, value in result) {
                        message += key + " : " + value + "\n";
                    }
                    resolve(message);
                }
            }.bindenv(this));
        }.bindenv(this));
  }



  function testReadDiscreteInput(){
      local targetType = MODBUS_TARGET_TYPE.DISCRETE_INPUT;
      local startingAddress = 1;
      local quantity = 6;
      return Promise(function(resolve, reject){
          _modbus.read(DEVICE_ADDRESS, targetType, startingAddress, quantity, function(error,result){
                if(error){
                    errorMessage(error, resolve ,reject);
                } else{
                    this.assertTrue(result.len() == quantity);
                    local message = "Index : Discrete Input Status \n";
                    foreach (key, value in result) {
                        message += key + " : " + value + "\n";
                    }
                    resolve(message);
                }
            }.bindenv(this));
        }.bindenv(this));
  }

  function testReadInputRegisters(){
      local targetType = MODBUS_TARGET_TYPE.INPUT_REGISTER;
      local startingAddress = 1;
      local quantity = 7;
      return Promise(function(resolve, reject){
          _modbus.read(DEVICE_ADDRESS, targetType, startingAddress, quantity, function(error,result){
                if(error){
                    errorMessage(error, resolve ,reject);
                } else{
                    this.assertTrue(result.len() == quantity);
                    local message = "Index : Input Register Value \n";
                    foreach (key, value in result) {
                        message += key + " : " + value + "\n";
                    }
                    resolve(message);
                }
            }.bindenv(this));
        }.bindenv(this));
  }


  function testReadRegisters(){
      local targetType = MODBUS_TARGET_TYPE.HOLDING_REGISTER;
      local startingAddress = 1;
      local quantity = 8;
      return Promise(function(resolve, reject){
          _modbus.read(DEVICE_ADDRESS, targetType, startingAddress, quantity, function(error,result){
                if(error){
                    errorMessage(error, resolve ,reject);
                } else{
                    this.assertTrue(result.len() == quantity);
                    local message = "Index : Holding Register Value \n";
                    foreach (key, value in result) {
                        message += key + " : " + value + "\n";
                    }
                    resolve(message);
                }
            }.bindenv(this));
        }.bindenv(this));
  }

  function testReportSlaveID(){
      return Promise(function(resolve, reject){
            _modbus.reportSlaveID(DEVICE_ADDRESS, function(error, result){
                if(error){
                    errorMessage(error, resolve ,reject);
                } else{
                    this.assertTrue(result.len() == 2);
                    local message = "Key : Content \n";
                    foreach (key, value in result) {
                        message += key + " : " + value + "\n";
                    }
                    resolve(message);
                }
              }.bindenv(this));
        }.bindenv(this));
  }

  function testReadWriteMultipleRegisters(){
      local readingStartAddress = 0x01;
      local readQuantity = 2;
      local writeStartAddress = 0x0A;
      local writeQuantity = 1;
      local writeValue = blob();
      writeValue.writen(swap2(1828),'w');
      return Promise(function(resolve, reject){
            _modbus.readWriteMultipleRegisters(DEVICE_ADDRESS, readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result.len() == readQuantity);
                      local message = "Index : Holding Register Value \n";
                      foreach (key, value in result) {
                          message += key + " : " + value + "\n";
                      }
                      resolve(message);
                  }
              }.bindenv(this));
        }.bindenv(this));
  }

  function testMaskWriteRegister(){
      local referenceAddress = 0x0A;
      local AND_Mask = 0xFFFF;
      local OR_Mask = 0x0000;
      return Promise(function(resolve, reject){
            _modbus.maskWriteRegister(DEVICE_ADDRESS, referenceAddress, AND_Mask, OR_Mask, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result);
                      resolve(_PASS_MESSAGE);
                  }
              }.bindenv(this));
        }.bindenv(this));
  }


  function testReadDeviceIdentification(){
      local readDeviceIdCode = MODBUS_READ_DEVICE_CODE.BASIC;
      local objectId = MODBUS_OBJECT_ID.VENDOR_NAME;
      return Promise(function(resolve, reject){
            _modbus.readDeviceIdentification(DEVICE_ADDRESS, readDeviceIdCode, objectId, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result.len() == 3);
                      local message = "Object ID : Content \n";
                      foreach (key,value in result ) {
                          message += key + " : " + value + "\n";
                      }
                      resolve(message);
                  }
              }.bindenv(this));
        }.bindenv(this));
  }


  function testDiagnostics(){
      local subFunctionCode = MODBUS_SUB_FUNCTION_CODE.RETURN_QUERY_DATA;
      local data = blob();
      data.writen(swap2(0xFF00),'w');
      return Promise(function(resolve, reject){
            _modbus.diagnostics(DEVICE_ADDRESS, subFunctionCode, data, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result.tostring() == data.tostring());
                      resolve(_PASS_MESSAGE);
                  }
              }.bindenv(this));
        }.bindenv(this));
  }

  function testReadExceptionStatus(){
      return Promise(function(resolve, reject){
            _modbus.readExceptionStatus(DEVICE_ADDRESS, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      resolve(result);
                  }
              }.bindenv(this));
        }.bindenv(this));
  }

  function testWriteSingleCoilBoolean(){
      local targetType = MODBUS_TARGET_TYPE.COIL;
      local startingAddress = 0x0A;
      local quantity = 1;
      local values = true;
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result);
                      resolve(result);
                  }
              }.bindenv(this))
        }.bindenv(this));
  }


  function testWriteSingleCoilInt(){
      local targetType = MODBUS_TARGET_TYPE.COIL;
      local startingAddress = 0x0A;
      local quantity = 1;
      local values = 0x0000;
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result);
                      resolve(result);
                  }
              }.bindenv(this))
        }.bindenv(this));
  }

  function testWriteSingleCoilBlob(){
      local targetType = MODBUS_TARGET_TYPE.COIL;
      local startingAddress = 0x0A;
      local quantity = 1;
      local values = blob();
      values.writen(swap2(0xFF00),'w');
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result);
                      resolve(result);
                  }
              }.bindenv(this))
        }.bindenv(this));
  }


  function testWriteMultipleCoilsBoolean(){
      local targetType = MODBUS_TARGET_TYPE.COIL;
      local startingAddress = 0x0A;
      local values = [true,false];
      local quantity = values.len();
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result);
                      resolve(result);
                  }
              }.bindenv(this))
        }.bindenv(this));
  }


  function testWriteMutipleCoilsInt(){
      local targetType = MODBUS_TARGET_TYPE.COIL;
      local startingAddress = 0x0A;
      local values = [0x0000,0xFF00];
      local quantity = values.len();
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result);
                      resolve(result);
                  }
              }.bindenv(this))
        }.bindenv(this));
  }

  function testWriteMutipleCoilsBlob(){
      local targetType = MODBUS_TARGET_TYPE.COIL;
      local startingAddress = 0x01;
      local values = blob();
      local quantity = 8;
      values.writen(0x0A,'b');
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result);
                      resolve(result);
                  }
              }.bindenv(this))
        }.bindenv(this));
  }




  function testWriteSingleRegisterInt(){
      local targetType = MODBUS_TARGET_TYPE.HOLDING_REGISTER;
      local startingAddress = 0x0A;
      local quantity = 1;
      local values = 1828;
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result);
                      resolve(result);
                  }
              }.bindenv(this))
        }.bindenv(this));
  }

  function testWriteSingleRegisterBlob(){
      local targetType = MODBUS_TARGET_TYPE.HOLDING_REGISTER;
      local startingAddress = 0x0A;
      local quantity = 1;
      local values = blob();
      values.writen(swap2(8818),'w');
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result);
                      resolve(result);
                  }
              }.bindenv(this))
        }.bindenv(this));
  }




  function testWriteMutipleRegistersInt(){
      local targetType = MODBUS_TARGET_TYPE.HOLDING_REGISTER;
      local startingAddress = 0x0A;
      local values = [18,28];
      local quantity = values.len();
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result);
                      resolve(result);
                  }
              }.bindenv(this))
        }.bindenv(this));
  }

  function testWriteMutipleRegistersBlob(){
      local targetType = MODBUS_TARGET_TYPE.HOLDING_REGISTER;
      local startingAddress = 0x01;
      local values = blob();
      local quantity = 2;
      values.writen(swap2(8880),'w');
      values.writen(swap2(8),'w');
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      errorMessage(error, resolve ,reject);
                  } else{
                      this.assertTrue(result);
                      resolve(result);
                  }
              }.bindenv(this))
        }.bindenv(this));
  }



  function testInvalidArgumentLengthExceptionWriteCoils(){
      local targetType = MODBUS_TARGET_TYPE.COIL;
      local startingAddress = 0x01;
      local values = [true, false];
      local quantity = values.len() + 1;
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      this.assertTrue(error == MODBUS_EXCEPTION.INVALID_ARG_LENGTH);
                      resolve(_PASS_MESSAGE);
                  }else{
                      reject("Exception is not thrown");
                  }
              }.bindenv(this))
        }.bindenv(this));
  }


  function testInvalidArgumentLengthExceptionWriteRegisters(){
      local targetType = MODBUS_TARGET_TYPE.HOLDING_REGISTER;
      local startingAddress = 0x0A;
      local values = [8, 80];
      local quantity = values.len() + 1;
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      this.assertTrue(error == MODBUS_EXCEPTION.INVALID_ARG_LENGTH);
                      resolve(_PASS_MESSAGE);
                  }else{
                      reject("Exception is not thrown");
                  }
              }.bindenv(this))
        }.bindenv(this));
  }

  function testInvalidValuesWriteCoils(){
      local targetType = MODBUS_TARGET_TYPE.COIL;
      local startingAddress = 0x01;
      local values = {"1":false , "2":true};
      local quantity = values.len();
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      this.assertTrue(error == MODBUS_EXCEPTION.INVALID_VALUES);
                      resolve(_PASS_MESSAGE);
                  }else{
                      reject("Exception is not thrown");
                  }
              }.bindenv(this))
        }.bindenv(this));
  }


  function testInvalidValuesWriteRegisters(){
      local targetType = MODBUS_TARGET_TYPE.HOLDING_REGISTER;
      local startingAddress = 0x0A;
      local values = {"1":88 , "2":880};
      local quantity = values.len();
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      this.assertTrue(error == MODBUS_EXCEPTION.INVALID_VALUES);
                      resolve(_PASS_MESSAGE);
                  }else{
                      reject("Exception is not thrown");
                  }
              }.bindenv(this))
        }.bindenv(this));
  }

  function testInvalidTargetTypeWrite(){
      local targetType = MODBUS_TARGET_TYPE.DISCRETE_INPUT;
      local startingAddress = 0x01;
      local values = [true, false];
      local quantity = values.len();
      return Promise(function(resolve, reject){
            _modbus.write(DEVICE_ADDRESS, targetType, startingAddress, quantity, values, function(error, result){
                  if(error){
                      this.assertTrue(error == MODBUS_EXCEPTION.INVALID_TARGET_TYPE);
                      resolve(_PASS_MESSAGE);
                  }else{
                      reject("Exception is not thrown");
                  }
              }.bindenv(this))
        }.bindenv(this));
  }


  function testInvalidTargetTypeRead(){
      local targetType = "2";
      local startingAddress = 0x01;
      local quantity = 5;
      return Promise(function(resolve, reject){
            _modbus.read(DEVICE_ADDRESS, targetType, startingAddress, quantity, function(error, result){
                  if(error){
                      this.assertTrue(error == MODBUS_EXCEPTION.INVALID_TARGET_TYPE);
                      resolve(_PASS_MESSAGE);
                  }else{
                      reject("Exception is not thrown");
                  }
              }.bindenv(this))
        }.bindenv(this));
  }

  function tearDown() {
    return "Test finished";
  }
}

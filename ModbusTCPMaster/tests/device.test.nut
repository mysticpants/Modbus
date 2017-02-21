

function errorMessage(error,resolve, reject){
    switch(error) {
        case MODBUSRTU_EXCEPTION.ILLEGAL_FUNCTION :
            return resolve("This function is not supported by the device");
        case MODBUSRTU_EXCEPTION.ILLEGAL_DATA_ADDR :
            return resolve("Illegal address. Try a different address");
        case MODBUSRTU_EXCEPTION.ILLEGAL_DATA_VAL :
            return resolve("Illegal data value. Provide a different value");
        default :
            return reject("Error : " + error);
    }
}

const PASS_MESSAGE = "Pass";

class DeviceTestCase extends ImpTestCase {

  _wiz = null;
  _modbus = null;
  _connection = null;

  function setUp() {
    local spi = hardware.spi0;
    spi.configure(CLOCK_IDLE_LOW | MSB_FIRST | USE_CS_L, 1000);
    _modbus = ModbusTCP(spi, hardware.pinXC, null, hardware.pinXA);
    _connection = Promise (function(resolve,reject){
        _modbus.connect({
            "gatewayIP"  : [192, 168, 201, 1],
            "subnet"     : [255, 255, 255, 0],
            "sourceIP"   : [192, 168, 1, 30]
        },{
            "destIP"     : [192, 168, 1, 90],
            "destPort"   : [0x01, 0xF6]
        },function(error,conn){
            resolve("Connection established");
        }.bindenv(this));
    }.bindenv(this));
    return _connection;
  }

  function testReportSlaveID() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              _modbus.reportSlaveID(function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue(result.len() == 2);
                      resolve(PASS_MESSAGE);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }


  function testReadExceptionStatus() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              _modbus.readExceptionStatus(function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      resolve(PASS_MESSAGE);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }

  function testReadExceptionStatus() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              _modbus.readExceptionStatus(function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue((result == 0 || result == 0xFF)? true : false);
                      resolve(PASS_MESSAGE);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }

  function testDiagnostics() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local data = blob();
              data.writen(0xFF00,'w');
              _modbus.diagnostics(0x0000,data ,function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue(data.tostring() == result.tostring());
                      resolve(PASS_MESSAGE);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }

  function testMaskWriteRegister() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              _modbus.maskWriteRegister(0x0A,0xFFFF,0x0000,function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue(result);
                      resolve(PASS_MESSAGE);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }

  function testReadWriteMultipleRegisters() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local writeValues = [8,18];
              local quantity = writeValues.len();
              local address = 0x0A;
              _modbus.readWriteMultipleRegisters(address,quantity,address,quantity, writeValues,function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue(result.len() == quantity);
                      local message = "Index : Value\n";
                      foreach (index, value in result) {
                          message += index + " : " + value + "\n";
                      }
                      resolve(message);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }


  function testReadDeviceIdentification() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              _modbus.readDeviceIdentification(MODBUSRTU_READ_DEVICE_CODE.BASIC, MODBUSRTU_OBJECT_ID.VENDOR_NAME,function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue(result.len() == 3);
                      local message = "Key : Value\n";
                      foreach (key, value in result) {
                          message += key + " : " + value + "\n";
                      }
                      resolve(message);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }


  function testWriteSingleCoilBoolean() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local address = 0x0A;
              local value = false;
              local quantity = 1;
              _modbus.write(MODBUSRTU_TARGET_TYPE.COIL,address, quantity, value,function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue(result);
                      resolve(PASS_MESSAGE);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }


  function testWriteSingleCoilInteger() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local address = 0x0A;
              local value = 0xFF00;
              local quantity = 1;
              _modbus.write(MODBUSRTU_TARGET_TYPE.COIL,address, quantity, value,function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue(result);
                      resolve(PASS_MESSAGE);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }

  function testWriteMultipleCoilsBoolean() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local address = 0x0A;
              local value = [true,false];
              local quantity = value.len();
              _modbus.write(MODBUSRTU_TARGET_TYPE.COIL,address, quantity, value,function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue(result);
                      resolve(PASS_MESSAGE);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }


  function testWriteMultipleCoilsInteger() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local address = 0x0A;
              local value = [0xFF00,0x0000];
              local quantity = value.len();
              _modbus.write(MODBUSRTU_TARGET_TYPE.COIL,address, quantity, value,function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue(result);
                      resolve(PASS_MESSAGE);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }


  function testWriteCoilsBlob() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local address = 0x0A;
              local value = blob(1);
              local quantity = 2;
              _modbus.write(MODBUSRTU_TARGET_TYPE.COIL,address, quantity, value,function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue(result);
                      resolve(PASS_MESSAGE);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }



  function testWriteSingleRegister() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local address = 0x0A;
              local value = 88;
              local quantity = 1;
              _modbus.write(MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER,address, quantity, value,function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue(result);
                      resolve(PASS_MESSAGE);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }

  function testWriteMultipleRegisters() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local address = 0x0A;
              local value = [28,88];
              local quantity = value.len();
              _modbus.write(MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER,address, quantity, value,function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue(result);
                      resolve(PASS_MESSAGE);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }

  function testWriteRegistersBlob() {
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local address = 0x0A;
              local value = blob(4);
              value.writen(swap2(888),'w');
              value.writen(swap2(188),'w');
              local quantity = value.len() / 2;
              _modbus.write(MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER,address, quantity, value,function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      this.assertTrue(result);
                      resolve(PASS_MESSAGE);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }



  function testReadCoil(){
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local address = 0x0A;
              local quantity = 3;
              _modbus.read(MODBUSRTU_TARGET_TYPE.COIL,address, quantity, function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      local message = "Index : Status\n";
                      foreach (key,value in result) {
                          message += key + " : " + value + "\n";
                      }
                      this.assertTrue(result.len() == quantity);
                      resolve(message);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }



  function testReadDiscreteInput(){
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local address = 0x0A;
              local quantity = 3;
              _modbus.read(MODBUSRTU_TARGET_TYPE.DISCRETE_INPUT,address, quantity, function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      local message = "Index : Status\n";
                      foreach (key,value in result) {
                          message += key + " : " + value + "\n";
                      }
                      this.assertTrue(result.len() == quantity);
                      resolve(message);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }

  function testReadHoldingRegister(){
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local address = 0x0A;
              local quantity = 3;
              _modbus.read(MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER,address, quantity, function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      local message = "Index : Value\n";
                      foreach (key,value in result) {
                          message += key + " : " + value + "\n";
                      }
                      this.assertTrue(result.len() == quantity);
                      resolve(message);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }

  function testReadInputRegister(){
      return Promise(function(resolve, reject){
          _connection.then(function(value){
              local address = 0x0A;
              local quantity = 3;
              _modbus.read(MODBUSRTU_TARGET_TYPE.INPUT_REGISTER,address, quantity, function(error,result){
                  if (error) {
                      errorMessage(error,resolve, reject);
                  } else {
                      local message = "Index : Value\n";
                      foreach (key,value in result) {
                          message += key + " : " + value + "\n";
                      }
                      this.assertTrue(result.len() == quantity);
                      resolve(message);
                  }
              }.bindenv(this));
          }.bindenv(this));
      }.bindenv(this));
  }

  function tearDown() {
    _modbus.disconnect();
    return "Connection closed";
  }

}

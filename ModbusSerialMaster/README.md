# ModbusSerialMaster

This library allows an imp to communicate with other devices via the Modbus-RS485 or Modbus-RS232 protocol.

**To use this library, add the following statements to the top of your device code:**

```
#require "CRC16.class.nut:1.0.0"
#require "ModbusRTU.device.lib.nut:1.0.1"
#require "ModbusMaster.device.lib.nut:1.0.1"
#require "ModbusSerialMaster.device.lib.nut:2.0.0"
```

## Hardware Setup ##

The following instructions are applicable to Electric Imp’s [impAccelerator&trade; Fieldbus Gateway](https://developer.electricimp.com/hardware/resources/reference-designs/fieldbusgateway).

1. Connect the antenna to the Fieldbus Gateway
2. Wire RS485 A on the Fieldbus Gateway to port A / positive(+) on the other device
3. Wire RS485 B on the Fieldbus Gateway to port B / negative(-) on the other device
4. Wire both devices’ ground ports together
5. Fit [jumper J2](https://developer.electricimp.com/hardware/resources/reference-designs/fieldbusgateway#rs-485) on the Fieldbus Gateway motherboard to enable RS485
6. Power up the Fieldbus Gateway
7. Configure the Fieldbus Gateway for Internet access using BlinkUp&trade;

## ModbusSerialMaster Class Usage ##

This is the main library class. It implements most of the functions listed in the [Modbus specification](http://www.modbus.org/docs/Modbus_over_serial_line_V1_02.pdf).

### Constructor: ModbusSerialMaster(*uart[, rts][, params]*) ###

Instantiates a new ModbusSerialMaster object and configures the UART bus over which it operates. The *uart* parameter is an imp UART object. The optional *rts* parameter should be used for RS485 communications when you are using an imp GPIO pin for control flow. The *params* parameter is optional and takes a table containing the following keys:

| Key | Default | Notes |
| --- | --- | --- |
| *baudRate* | 19200 | The baud rate of the UART connection |
| *dataBits* | 8 | The word size on the UART connection in bits (7 or 8 bits) |
| *parity* | *PARITY_NONE* | Parity configuration of the UART connection |
| *stopBits* | 1 | Number of stop bits (1 or 2) on the UART connection |
| *timeout* | 1.0 | The maximum time allowed for one request |
| *debug* | `false` | If enabled, the outgoing and incoming ADU will be printed for debugging purpose |

#### Example ####

```squirrel
modbus <- ModbusSerialMaster(hardware.uart2, hardware.pinL);
```

## ModbusSerialMaster Class Methods ##

### read(*deviceAddress, targetType, startingAddress, quantity[, callback]*) ###

Function Codes: 01, 02, 03, 04

This is a generic method used to read values from a single coil, register, or multiple coils and registers. It takes the following parameters:

| Parameter | Data Type | Required | Default Value | Description |
| --- | --- | --- | --- | --- |
| *deviceAddress* | Integer | Yes | N/A | The unique address that identifies a device |
| *targetType* | Constant | Yes | N/A | Refer to the ‘Target Type’ table, below |
| *startingAddress* | Integer | Yes | N/A | The address from which it begins reading values |
| *quantity* | Integer | Yes | N/A  | The number of consecutive addresses the values are read from |
| *callback* | Function | No | `null` | The function to be fired when it receives response regarding this request. It takes two parameters, *error* and *result* |

| Target Type | Value | Access |
| --- | --- | --- |
| Coil | *MODBUSRTU_TARGET_TYPE.COIL* | Read-Write |
| Discrete Input | *MODBUSRTU_TARGET_TYPE.DISCRETE_INPUT* | Read-Only |
| Input Register | *MODBUSRTU_TARGET_TYPE.INPUT_REGISTER* | Read-Only |
| Holding Register | *MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER* | Read-Write |

#### Example ####

```squirrel
// Read from a single coil
modbus.read(0x01, MODBUSRTU_TARGET_TYPE.COIL, 0x0001, 1, function(error, result) {
  if (error) {
    server.error(error);
  } else {
    server.log(result);
  }
}.bindenv(this));

// Read from multiple registers
modbus.read(0x01, MODBUSRTU_TARGET_TYPE.INPUT_REGISTER, 0x7000 , 2, function(error, results) {
  if (error) {
    server.error(error);
  } else {
    foreach(key, value in results) {
      server.log(key + " : " + value);
    }
  }
}.bindenv(this));
```

### write(*deviceAddress, targetType, startingAddress, quantity, values[, callback]*) ###

Function Codes: 05, 06, 15, 16

This is a generic method used to write values to multiple coils and registers. It takes the following parameters:

#### Parameters ####

| Parameter | Data Type | Required | Default Value | Description |
| --- | --- | --- | --- | --- |
| *deviceAddress* | Integer| Yes | N/A | The unique address that identifies a device |
| *targetType* | Constant | Yes | N/A | Refer to the ‘Target Type’ table, above |
| *startingAddress* | Integer | Yes | N/A | The address from which it begins writing values |
| *quantity* | Integer | Yes | N/A | The number of consecutive addresses the values are written into |
| *values* | Integer, array of integers, bool, blob | Yes | N/A | The values written into Coils or Registers. Please view Notes below |
| *callback*  | Function | No  | `null` | The function to be fired when it receives response regarding this request. It takes two parameters, *error* and *result* |

#### Notes ####

1. Integer, blob and array[integer] are applicable to *MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER*. Use an array[integer] only applicable when *quantity* is greater than one.
2. Integer, bool, blob and array[integer, bool] are applicable to *MODBUSRTU_TARGET_TYPE.COIL*. Use array[integer, bool] only applicable when *quantity* is greater than one. The integer value set to coils can be either 0x0000 or 0xFF00. Other values are ignored.

#### Example ####

```squirrel
// Write to a single coil
modbus.write(0x01, MODBUSRTU_TARGET_TYPE.COIL, 8192, 1, true, function(error, result) {
  if (error) {
    server.error(error);
  } else {
    server.log(result);
  }
}.bindenv(this));

// Write to multiple registers
modbus.write(0x01, MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER, 9, 3, [188, 80, 18], function(error, result) {
  if (error) {
    server.error(error);
  } else {
    server.log(result);
  }
}.bindenv(this));
```

### readExceptionStatus(*deviceAddress[, callback]*) ###

Function Code: 07

This method reads the contents of eight Exception Status outputs in a remote device (address passed into the first parameter. If a callback is supplied, it will be triggered when a response regarding this request is received. The callback takes two parameters: *error* and *result*.

#### Example ####

```squirrel
modbus.readExceptionStatus(0x01, function(error, result) {
  if (error) {
    server.error(error);
  } else {
    server.log(result);
  }
}.bindenv(this));
```

### diagnostics(*deviceAddress, subFunctionCode, data[, callback]*) ###

Function Code: 08

This method provides a series of tests for checking the communication system between a client (Master) device and a server (Slave), or for checking various internal error conditions within a server. It takes the following parameters:

| Parameter | Data Type | Required | Default Value | Description |
| --- | --- | --- | --- | --- |
| *deviceAddress* | Integer| Yes | N/A | The unique address that identifies a device |
| *subFunctionCode* | Constant | Yes | N/A | Refer to the ‘Sub-function Code’ table, below |
| *data* | Blob | Yes | N/A | The data field required by Modbus request |
| *callback* | Function | No | `null` | The function to be fired when it receives response regarding this request. It takes two parameters, *error* and *result* |

| Sub-function Code | Value (Hex) |
| --- | --- |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_QUERY_DATA* | 0x0000 |
| *MODBUSRTU_SUB_FUNCTION_CODE.RESTART_COMMUNICATION_OPTION* | 0x0001 |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_DIAGNOSTICS_REGISTER* | 0x0002 |
| *MODBUSRTU_SUB_FUNCTION_CODE.CHANGE_ASCII_INPUT_DELIMITER* | 0x0003 |
| *MODBUSRTU_SUB_FUNCTION_CODE.FORCE_LISTEN_ONLY_MODE* | 0x0004 |
| *MODBUSRTU_SUB_FUNCTION_CODE.CLEAR_COUNTERS_AND_DIAGNOSTICS_REGISTER* | 0x000A |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_BUS_MESSAGE_COUNT* | 0x000B |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_BUS_COMMUNICATION_ERROR_COUNT* | 0x000C |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_BUS_EXCEPTION_ERROR_COUNT* | 0x000D |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_SLAVE_MESSAGE_COUNT* | 0x000E |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_SLAVE_NO_RESPONSE_COUNT* | 0x000F |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_SLAVE_NAK_COUNT* | 0x0010 |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_SLAVE_BUSY_COUNT* | 0x0011 |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_BUS_CHARACTER_OVERRUN_COUNT* | 0x0012 |
| *MODBUSRTU_SUB_FUNCTION_CODE.CLEAR_OVERRUN_COUNTER_AND_FLAG* | 0x0014 |

#### Example ####

```squirrel
local data = blob(2);
data.writen(0xFF00, 'w');
data.swap2();

modbus.diagnostics(0x01, MODBUSRTU_SUB_FUNCTION_CODE.RESTART_COMMUNICATION_OPTION, data, function(error, result) {
  if (error) {
    server.error(error);
  } else {
    server.log(result);
  }
}.bindenv(this));
```

### reportSlaveID(*deviceAddress[, callback]*) ###

Function Code: 17

This method reads the description of the type, the current status and other information specific to a remote device whose address is specified in the method’s first parameter. The second, optional parameter is a function that will be fired when a response regarding this request is received. It takes two parameters, *error* and *result*.

#### Example ####

```squirrel
modbus.reportSlaveID(0x01, function(error, result) {
  if (error) {
    server.error(error);
  } else {
    server.log("Run indicator : " + result.runIndicator);
    server.log(result.slaveId);
  }
}.bindenv(this));
```

### maskWriteRegister(*deviceAddress, referenceAddress, AND_Mask, OR_Mask[, callback]*) ###

Function Code: 22

This method modifies the contents of a specified holding register using a combination of an AND mask, an OR mask and the register’s current contents. The function can be used to set or clear individual bits in the register. It takes the following parameters:

| Parameter | Data Type | Required | Default Value | Description |
| --- | --- | --- | --- | --- |
| *deviceAddress* | Integer | Yes | N/A | The unique address that identifies a device |
| *referenceAddress* | Integer | Yes | N/A | The address of the holding register the value is written into |
| *AND_mask* | Integer | Yes | N/A | The AND mask |
| *OR_mask* | Integer | Yes | N/A | The OR mask |
| *callback* | Function | No | `null` | The function to be fired when it receives response regarding this request. It takes two parameters, *error* and *result* |

#### Example ####

```squirrel
modbus.maskWriteRegister(0x01, 0x10, 0xFFFF, 0x0000, function(error, result) {
  if (error) {
    server.error(error);
  } else {
    server.log(result);
  }
}.bindenv(this));
```

### readWriteMultipleRegisters(*deviceAddress, readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue[, callback]*) ###

Function Code: 23

This method performs a combination of one read operation and one write operation in a single Modbus transaction. The write operation is performed before the read. It takes the following parameters:

| Parameter | Data Type | Required | Default Value | Description |
| --- | --- | --- | --- | --- |
| *deviceAddress* | Integer | Yes | N/A | The unique address that identifies a device |
| *readingStartAddress* | Integer | Yes | N/A | The address from which it begins reading values |
| *readQuantity* | Integer | Yes | N/A | The number of consecutive addresses values are read from |
| *writeStartAddress* | Integer | Yes | N/A | The address from which it begins writing values |
| *writeQuantity* | Integer | Yes | N/A | The number of consecutive addresses values are written into |
| *writeValue* | Blob | Yes | N/A | The value written into the holding register |
| *callback* | Function | No | `null` | The function to be fired when it receives response regarding this request. It takes two parameters, *error* and *result* |

**Note** The actual order of operation is determined by the implementation of user's device.

#### Example ####

```squirrel
modbus.readWriteMultipleRegisters(0x01, 9, 3, 9, 3, [188, 80, 18], function(error, result) {
  if (error) {
    errorMessage(error, resolve, reject);
  } else {
    foreach(key, value in results) {
      server.log(key + " : " + value);
    }
  }
}.bindenv(this));
```

### readDeviceIdentification(*deviceAddress, readDeviceIdCode, objectId[, callback]*) ###

Function Code: 43/14

This method lets you read the identification and additional information relative to the physical and functional description of a remote device. It takes the following parameters:

| Parameter | Data Type | Required | Default Value | Description |
| --- | --- | --- | --- | --- |
| *deviceAddress* | Integer | Yes | N/A | The unique address that identifies a device |
| *readDeviceIdCode* | Constant| Yes | N/A | Refer to the ‘Read Device ID Code’ table, below |
| *objectId* | Constant | Yes | N/A | Refer to the ‘Object ID’ table, below |
| *callback* | Function | No | `null` | The function to be fired when it receives response regarding this request. It takes two parameters, *error* and *result* |

| Read Device ID Code | Description |
| --- | --- |
| *MODBUSRTU_READ_DEVICE_CODE.BASIC* | Get the basic device identification (stream access) |
| *MODBUSRTU_READ_DEVICE_CODE.REGULAR* | Get the regular device identification (stream access) |
| *MODBUSRTU_READ_DEVICE_CODE.EXTENDED* | Get the extended device identification (stream access) |
| *MODBUSRTU_READ_DEVICE_CODE.SPECIFIC* | Get one specific identification object (individual access) |

| Object ID | Category  |
| --- | --- |
| *MODBUSRTU_OBJECT_ID.VENDOR_NAME* | Basic |
| *MODBUSRTU_OBJECT_ID.PRODUCT_CODE* | Basic |
| *MODBUSRTU_OBJECT_ID.MAJOR_MINOR_REVISION* | Basic |
| *MODBUSRTU_OBJECT_ID.VENDOR_URL* | Regular |
| *MODBUSRTU_OBJECT_ID.PRODUCT_NAME* | Regular |
| *MODBUSRTU_OBJECT_ID.MODEL_NAME* | Regular |
| *MODBUSRTU_OBJECT_ID.USER_APPLICATION_NAME* | Regular |

#### Example ####

```squirrel
modbus.readDeviceIdentification(0x01, MODBUSRTU_READ_DEVICE_CODE.BASIC, MODBUSRTU_OBJECT_ID.VENDOR_NAME, function(error, objects) {
  if (error) {
    server.error("Error: " + error + ", Objects: " + objects);
  } else {
    local info = "DeviceId: ";
    foreach (id, val in objects) {
      info += format("[%d] %s, ", id, val.tostring());
    }
    server.log(info);
  }
}.bindenv(this));
```

## Exception Codes ##

The table below enumerates all the exception codes that can be possibly encountered. Refer to [Modbus specification](http://www.modbus.org/docs/Modbus_over_serial_line_V1_02.pdf) for more detailed description on Modbus-specific exceptions.

| Value (Dec) | Description |
| --- | --- |
| 1 | Illegal Function |
| 2 | Illegal Data Address |
| 3 | Illegal Data Value |
| 4 | Slave Device Fail |
| 5 | Acknowledge |
| 6 | Slave Device Busy |
| 7 | Negative Acknowledge |
| 8 | Memory Parity Error |
| 80 | Response Timeout |
| 81 | Invalid CRC |
| 82 | Invalid Argument Length |
| 83 | Invalid Device Address |
| 87 | Invalid Target Type |
| 88 | Invalid Values |
| 89 | Invalid Quantity |

## License ##

The ModbusSerialMaster library is licensed under the [MIT License](../LICENSE).

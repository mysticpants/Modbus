# ModbusTCPMaster

This library enables an imp to communicate with other devices via TCP/IP. It requires the use of [Wiznet](https://github.com/electricimp/Wiznet_5500) to transmit the packets between devices via Ethernet.

**To use this library, add `#require "ModbusRTU.class.nut:1.0.0"` , `#require "W5500.class.nut"`  and `#require "ModbusTCPMaster.class.nut:1.0.0"` to the top of your device code.**


## Hardware Setup

The following instructions are applicable to [impAccelerator™ Fieldbus Gateway](https://electricimp.com/docs/hardware/fieldbusgateway/ide/).

1. Screw the antenna onto the Imp

2. Connect the Imp to a switch with an Ethernet cable

3. Connect the other device (e.g. PLC) to a switch with another Ethernet cable

4. Configure the network settings on your device

5. Power up the device

6. Power up the Imp

7. Blink up the Imp


## Class ModbusTCPMaster

This is the main library class. It implements most of the functions listed in the [Modbus specification](http://www.modbus.org/docs/Modbus_over_serial_line_V1_02.pdf).

### Constructor: ModbusTCPMaster(*params*)

Instantiate a new ModbusTCPMaster object and set the configuration of spi .

#### Parameters

The constructor expects a `table` which contains the following items :

| Key          | Default     | Notes                                                                                                                       |
| ------------ | ----------- | --------------------------------------------------------------------------------------------------------------------------- |
| spi          | N/A         | The spi object Wiznet uses                                                                                                  |
| interruptPin | N/A         | The interrupt pin. It can be any digital input that supports a callback on pin state change                                 |
| csPin        | N/A         | The Chip Select pin. If you are not using the Imp005, you must pass in the digital output pin to be used as the chip select |
| resetPin     | N/A         | The reset pin                                                                                                               |
| autoRetry    | false       | If enabled, it will reconnect automatically                                                                                 |
| debug        | false       | If enabled, the outgoing and incoming ADU will be printed for debugging purpose                                             |



#### Example

```squirrel
// configure spi
spi <- hardware.spi0;
spi.configure(CLOCK_IDLE_LOW | MSB_FIRST | USE_CS_L, 1000);

// instantiate a modbus object
modbus <- ModbusTCPMaster(spi, hardware.pinXC, null, hardware.pinXA);

```


### connect(*networkSettings, connectionSettings, [callback]*)

This function configures the network and opens a TCP connection with the device. It will try to reconnect when the connection is not closed intentionally

#### Parameters

| Key                  | Data Type   | Required | Default Value | Description                                                  |
| -------------------- | ----------- | -------- | ------------- | ------------------------------------------------------------ |
| *networkSettings*    | `table`     | No       | Null          | The network settings. It entails gatewayIP, subnet, sourceIP |
| *connectionSettings* | `table`     | No       | Null          | The connection settings. It entails the device IP and port   |
| *callback*           | `function`  | No       | Null          | The function to be fired when the connection is established  |

#### Example

```squirrel
// the network setting
local networkSettings = {
    "gatewayIP"  : [192, 168, 201, 1],
    "subnet"     : [255, 255, 255, 0],
    "sourceIP"   : [192, 168, 1, 30]
};

// the device address and port
local connectionSettings = {
    "destIP"     : [192, 168, 1, 90],
    "destPort"   : [0x01, 0xF6]
};


// open the connection
modbus.connect(networkSettings, connectionSettings, function(error, conn){
    if (error) {
        server.log(error);
    } else {
        // do something here
    }
});

```


### disconnect(callback)

This function closes the existing TCP connection.

#### Parameters

| Key                  | Data Type   | Required | Default Value | Description                                                  |
| -------------------- | ----------- | -------- | ------------- | ------------------------------------------------------------ |
| *callback*           | `function`  | No       | Null          | The function to be fired when the connection is dropped      |

#### Example

```squirrel

modbus.disconnect();

```



### read(*targetType, startingAddress, quantity, values, [callback]*)

Function Code : 01, 02, 03, 04

This is the generic function to read values from a single coil, register or multiple coils and registers .

#### Parameters

| Key               | Data Type | Required | Default Value | Description                                                               |
| ----------------- | --------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *targetType*      | `enum`    | Yes      | N/A           | Refer to **<a href='#target-type'>Target Type</a>**                       |
| *startingAddress* | `integer` | Yes      | N/A           | The address from which it begins reading values                           |
| *quantity*        | `integer` | Yes      | N/A           | The number of consecutive addresses the values are read from              |
| *callback*        | `function`| No       | Null          | The function to be fired when it receives response regarding this request. It takes two parameters, error and result respectively |


<h4 id='target-type'>Target Type</h4>

| Type               | Value                                  | Access        |
| ------------------ | -------------------------------------- | ------------- |
| Coil               | MODBUSRTU_TARGET_TYPE.COIL             | Read-Write    |
| Discrete Input     | MODBUSRTU_TARGET_TYPE.DISCRETE_INPUT   | Read-Only     |
| Input Register     | MODBUSRTU_TARGET_TYPE.INPUT_REGISTER   | Read-Only     |
| Holding Register   | MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER | Read-Write    |


#### Example

```squirrel
// read from a single coil
modbus.read(MODBUSRTU_TARGET_TYPE.DISCRETE_INPUT, 0x01, 1, function(error, result) {
    if (error) {
        server.error(error);
    } else {
        server.log(result);
    }
}.bindenv(this));

// read from multiple registers
modbus.read(MODBUSRTU_TARGET_TYPE.INPUT_REGISTER, 0x01 , 5, function(error, results) {
    if (error) {
        server.error(error);
    } else {
        foreach(key, value in results) {
          server.log(key + " : " + value);
        }
    }
}.bindenv(this));
```


### write(*targetType, startingAddress, quantity, values, [callback]*)

Function Code : 05, 06, 15, 16

This is the generic function to write values into coils or holding registers .

#### Parameters

| Key               | Data Type                         | Required | Default Value | Description                                                               |
| ----------------- | --------------------------------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *targetType*      | `enum`                            | Yes      | N/A           | Refer to **<a href='#target-type'>Target Type</a>**                       |
| *startingAddress* | `integer`                         | Yes      | N/A           | The address from which it begins writing values                           |
| *quantity*        | `integer`                         | Yes      | N/A           | The number of consecutive addresses the values are written into           |
| *values*          | `integer`, `array`, `bool`, `blob`| Yes      | N/A           | The values written into Coils or Registers. Please view Notes below       |
| *callback*        | `function`                        | No       | Null          | The function to be fired when it receives response regarding this request. It takes two parameters, error and result respectively |

##### Notes :

1.  `integer`, `blob`, `array[integer]` are applicable to MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER. `array[integer]` is only applicable when quantity is greater than 1.

2.  `integer`, `bool`, `blob`, `array[integer, bool]` are applicable to MODBUSRTU_TARGET_TYPE.COIL. `array[integer, bool]` is only applicable when quantity is greater than 1. Int value set to coils can be either 0x0000 or 0xFF00. Other values would be ignored.

#### Example

```squirrel
// write to a single coil
modbus.write(MODBUSRTU_TARGET_TYPE.COIL, 0x01, 1, true, function(error, result) {
    if (error){
        server.error(error);
    } else {
        server.log(result);
    }
}.bindenv(this));

// write to multiple registers
modbus.write(MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER, 0x01, 5, [false, true, false, true, true], function(error, results) {
    if (error) {
        server.error(error);
    } else {
        foreach(key, value in results) {
            server.log(key + " : " + value);
        }
    }
}.bindenv(this));

```

### readExceptionStatus(*[callback]*)

Function Code : 07

This function reads the contents of eight Exception Status outputs in a remote device

#### Parameters

| Key             | Data Type   | Required | Default Value | Description                                                               |
| --------------- | ----------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *callback*      | `function`  | No       | Null          | The function to be fired when it receives response regarding this request. It takes two parameters, error and result respectively |

#### Example

```squirrel
modbus.readExceptionStatus(function(error, result) {
    if (error) {
        server.error(error);
    } else {
        server.log(result);
    }
}.bindenv(this));

```



### diagnostics(*subFunctionCode, data, [callback]*)

Function Code : 08

This function provides a series of tests for checking the communication system between a client ( Master) device and a server ( Slave), or for checking various internal error conditions within a server.

#### Parameters


| Key               | Data Type   | Required | Default Value | Description                                                               |
| ----------------- | ----------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *subFunctionCode* | `enum`      | Yes      | N/A           | Refer to **Sub-function Code**                                            |
| *data*            | `blob`      | Yes      | N/A           | The data field required by Modbus request                                 |
| *callback*        | `function`  | No       | Null          | The function to be fired when it receives response regarding this request. It takes two parameters, error and result respectively |


### Sub-function Codes

| Code (Hex)         | Value                                                             |
| ------------------ | ----------------------------------------------------------------- |
| 0x0000             | MODBUSRTU_SUB_FUNCTION_CODE.RETURN_QUERY_DATA                        |
| 0x0001             | MODBUSRTU_SUB_FUNCTION_CODE.RESTART_COMMUNICATION_OPTION             |
| 0x0002             | MODBUSRTU_SUB_FUNCTION_CODE.RETURN_DIAGNOSTICS_REGISTER              |
| 0x0003             | MODBUSRTU_SUB_FUNCTION_CODE.CHANGE_ASCII_INPUT_DELIMITER             |
| 0x0004             | MODBUSRTU_SUB_FUNCTION_CODE.FORCE_LISTEN_ONLY_MODE                   |
| 0x000A             | MODBUSRTU_SUB_FUNCTION_CODE.CLEAR_COUNTERS_AND_DIAGNOSTICS_REGISTER  |
| 0x000B             | MODBUSRTU_SUB_FUNCTION_CODE.RETURN_BUS_MESSAGE_COUNT                 |
| 0x000C             | MODBUSRTU_SUB_FUNCTION_CODE.RETURN_BUS_COMMUNICATION_ERROR_COUNT     |
| 0x000D             | MODBUSRTU_SUB_FUNCTION_CODE.RETURN_BUS_EXCEPTION_ERROR_COUNT         |
| 0x000E             | MODBUSRTU_SUB_FUNCTION_CODE.RETURN_SLAVE_MESSAGE_COUNT               |
| 0x000F             | MODBUSRTU_SUB_FUNCTION_CODE.RETURN_SLAVE_NO_RESPONSE_COUNT           |
| 0x0010             | MODBUSRTU_SUB_FUNCTION_CODE.RETURN_SLAVE_NAK_COUNT                   |
| 0x0011             | MODBUSRTU_SUB_FUNCTION_CODE.RETURN_SLAVE_BUSY_COUNT                  |
| 0x0012             | MODBUSRTU_SUB_FUNCTION_CODE.RETURN_BUS_CHARACTER_OVERRUN_COUNT       |
| 0x0014             | MODBUSRTU_SUB_FUNCTION_CODE.CLEAR_OVERRUN_COUNTER_AND_FLAG           |

#### Example

```squirrel
local data = blob(2);
data.writen(0xFF00, 'w');
data.swap2();

modbus.diagnostics(MODBUSRTU_SUB_FUNCTION_CODE.RESTART_COMMUNICATION_OPTION, data, function(error, result) {
    if (error) {
        server.error(error);
    } else {
        server.log(result);
    }
}.bindenv(this));


```


### reportSlaveID(*[callback]*)

Function Code : 17

This function reads the description of the type, the current status, and other information specific to a remote device.

#### Parameters

| Key             | Data Type   | Required | Default Value | Description                                                               |
| --------------- | ----------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *callback*      | `function`  | No       | Null          | The function to be fired when it receives response regarding this request. It takes two parameters, error and result respectively |

#### Example

```squirrel
modbus.reportSlaveID(function(error, result) {
    if (error) {
        server.error(error);
    } else {
        server.log("Run indicator : " + result.runIndicator);
        server.log(result.slaveId);
    }        
}.bindenv(this));


```



### maskWriteRegister(*referenceAddress, AND_Mask , OR_Mask, [callback]*)

Function Code : 22

This function modifies the contents of a specified holding register using a combination of an AND mask, an OR mask, and the register's current contents. The function can be used to set or clear individual bits in the register.

#### Parameters

| Key                | Data Type | Required | Default Value | Description                                                               |
| ------------------ | --------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *referenceAddress* | `integer` | Yes      | N/A           | The address of the holding register the value is written into             |
| *AND_mask*         | `integer` | Yes      | N/A           | The AND mask                                                              |
| *OR_mask*          | `integer` | Yes      | N/A           | The OR mask                                                               |
| *callback*         | `function`| No       | Null          | The function to be fired when it receives response regarding this request. It takes two parameters, error and result respectively |

#### Example

```squirrel
modbus.maskWriteRegister(0x10, 0xFFFF, 0x0000, function(error, result) {
    if (error) {
        server.error(error);
    } else {
        server.log(result);
    }        
}.bindenv(this));


```


### readWriteMultipleRegisters(*readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue, [callback]*)

Function Code : 23

This function performs a combination of one read operation and one write operation in a single MODBUS transaction. The write operation is performed before the read.

#### Parameters

| Key                   | Data Type | Required | Default Value | Description |
| --------------------- | --------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *readingStartAddress* | `integer` | Yes      | N/A           | The address from which it begins reading values                           |
| *readQuantity*        | `integer` | Yes      | N/A           | The number of consecutive addresses values are read from                  |
| *writeStartAddress*   | `integer` | Yes      | N/A           | The address from which it begins writing values                           |
| *writeQuantity*       | `integer` | Yes      | N/A           | The number of consecutive addresses values are written into               |
| *writeValue*          | `blob`    | Yes      | N/A           | The value written into the holding register                               |
| *callback*            | `function`| No       | Null          | The function to be fired when it receives response regarding this request. It takes two parameters, error and result respectively |

#### Example

```squirrel
modbus.readWriteMultipleRegisters(0x10, 0xFFFF, 0x0000, function(error, result) {
    if (error) {
        server.error(error);
    } else {
        server.log(result);
    }        
}.bindenv(this));

```



### readDeviceIdentification(*readDeviceIdCode, objectId, [callback]*)

Function Code : 43/14

This function allows reading the identification and additional information relative to the physical and functional description of a remote device only.

#### Parameters

| Key                | Data Type | Required | Default Value | Description                                                               |
| ------------------ | --------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *readDeviceIdCode* | `enum`    | Yes      | N/A           | Refer to **Read Device ID Code**                                          |
| *objectId*         | `enum`    | Yes      | N/A           | Refer to **Object ID**                                                    |
| *callback*         | `function`| No       | Null          | The function to be fired when it receives response regarding this request. It takes two parameters, error and result respectively |


##### Read Device ID Codes

| Value                              | Description                                                |
| ---------------------------------- | ---------------------------------------------------------- |
| MODBUSRTU_READ_DEVICE_CODE.BASIC      | Get the basic device identification (stream access)        |
| MODBUSRTU_READ_DEVICE_CODE.REGULAR    | Get the regular device identification (stream access)      |
| MODBUSRTU_READ_DEVICE_CODE.EXTENDED   | Get the extended device identification (stream access)     |
| MODBUSRTU_READ_DEVICE_CODE.SPECIFIC   | Get one specific identification object (individual access) |


##### Object ID

| Value                                  | Category  |
| -------------------------------------- | --------- |
| MODBUSRTU_OBJECT_ID.VENDOR_NAME           | Basic     |
| MODBUSRTU_OBJECT_ID.PRODUCT_CODE          | Basic     |
| MODBUSRTU_OBJECT_ID.MAJOR_MINOR_REVISION  | Basic     |
| MODBUSRTU_OBJECT_ID.VENDOR_URL            | Regular   |
| MODBUSRTU_OBJECT_ID.PRODUCT_NAME          | Regular   |
| MODBUSRTU_OBJECT_ID.MODEL_NAME            | Regular   |
| MODBUSRTU_OBJECT_ID.USER_APPLICATION_NAME | Regular   |

#### Example

```squirrel
modbus.readDeviceIdentification(MODBUSRTU_READ_DEVICE_CODE.BASIC, MODBUSRTU_OBJECT_ID.VENDOR_NAME, function(error, objects) {
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

## Exception Codes

The table below enumerates all the exception codes that can be possibly encountered. Refer to [Modbus specification](http://www.modbus.org/docs/Modbus_over_serial_line_V1_02.pdf) for more detailed description on Modbus-specific exceptions.

| Value (Dec)   | Description             |
| ------------- | ----------------------- |
| 1             | Illegal Function        |
| 2             | Illegal Data Address    |
| 3             | Illegal Data Value      |
| 4             | Slave Device Fail       |
| 5             | Acknowledge             |
| 6             | Slave Device Busy       |
| 7             | Negative Acknowledge    |
| 8             | Memory Parity Error     |
| 80            | Response Timeout        |
| 81            | Invalid CRC             |
| 82            | Invalid Argument Length |
| 83            | Invalid Device Address  |
| 84            | Invalid Address         |
| 85            | Invalid Address Range   |
| 86            | Invalid Address Type    |
| 87            | Invalid Target Type     |
| 88            | Invalid Values          |
| 89            | Invalid Quantity        |

# License

The ModbusTCPMaster library is licensed under the [MIT License](https://github.com/electricimp/thethingsapi/tree/master/LICENSE).

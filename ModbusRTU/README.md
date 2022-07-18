# ModbusRTU

This library creates and parses Modbus Protocol Data Units (PDU). It depends on Electric Imp's [CRC16 library](https://github.com/electricimp/CRC16) to calculate the [CRC-16](https://en.wikipedia.org/wiki/Cyclic_redundancy_check) value of a string or blob.

**Note** You will not usually work with this library directly, but load it as a dependency for one of our other Modbus libraries, which target specific use cases:

* [ModbusSerialMaster](../ModbusMaster)
* [ModbusTCPMaster](../ModbusSerialMaster)

We recommend you work with one of these libraries unless your use case very specifically needs to perform PDU operations not provided by them. 

**To use this library, add the following statements to the top of your device code:**

```
#require "CRC16.class.nut:1.0.0"
#require "ModbusRTU.device.lib.nut:1.0.1"
```

## ModbusRTU Class Usage

This is the main library class. All methods and variables inside this class are static.

### createReadPDU(*targetType, startingAddress, quantity*)

This method creates a PDU for *readData* operations. It takes the following parameters:

| Parameter | Data Type | Required | Default Value | Description |
| --- | --- | --- | --- | --- |
| *targetType* | Constant | Yes | N/A | Refer to the Target Type table, below |
| *startingAddress* | Integer | Yes | N/A | The address from which it begins reading values |
| *quantity* | Integer | Yes | N/A | The number of consecutive addresses the values are read from |

| Type | Value | Access |
| --- | --- | --- |
| Coil | *MODBUSRTU_TARGET_TYPE.COIL* | Read-Write |
| Discrete Input | *MODBUSRTU_TARGET_TYPE.DISCRETE_INPUT* | Read Only |
| Input Register | *MODBUSRTU_TARGET_TYPE.INPUT_REGISTER* | Read Only |
| Holding Register | *MODBUSRTU_TARGET_TYPE.HOLDING_REGISTER* | Read-Write |

#### Example

```squirrel
local targetType = MODBUSRTU_TARGET_TYPE.COIL;
local startingAddress = 0x01;
local quantity = 1;

local pdu = ModbusRTU.createReadPDU(targetType, startingAddress, quantity);
server.log(pdu);
```

### createWritePDU(*targetType, startingAddress, quantity, values*)

This method creates a PDU for *writeData* operations. It takes the following parameters:

| Parameter | Data Type | Required | Default Value | Description |
| --- | --- | --- | --- | --- |
| *targetType* | Constant | Yes | N/A | Refer to the Target Type table, below |
| *startingAddress* | Integer | Yes | N/A | The address from which it begins writing values |
| *quantity* | Integer | Yes | N/A | The number of consecutive addresses the values are written into |
| *values* | Integer, array ([integer, boolean]), boolean, blob | Yes | N/A | The values written into Coils or Registers |

#### Example

```squirrel
local targetType = MODBUSRTU_TARGET_TYPE.COIL;
local startingAddress = 0x01;
local values = false;
local quantity = 1;

local pdu = ModbusRTU.createWritePDU(targetType, startingAddress, quantity, values);
server.log(pdu);
```

### createReadExceptionStatusPDU()

This method creates a PDU for *readExceptionStatus* operations. It takes no parameters.

#### Example

```squirrel
local pdu = ModbusRTU.createReadExceptionStatusPDU();
server.log(pdu);
```

### createDiagnosticsPDU(*subFunctionCode, data*)

This method creates a PDU for diagnostics operations. It takes the following parameters:

| Parameter | Data Type | Required | Default Value | Description |
| --- | --- | --- | --- | --- |
| *subFunctionCode* | Constant | Yes | N/A | Refer to the ‘Sub-function Code’ table, below |
| *data* | Blob | Yes | N/A | The data field required by Modbus request |

| Sub-function Code | Value (Hex) |
| --- | --- |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_QUERY_DATA*                        | 0x0000 |
| *MODBUSRTU_SUB_FUNCTION_CODE.RESTART_COMMUNICATION_OPTION*             | 0x0001 |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_DIAGNOSTICS_REGISTER*              | 0x0002 |
| *MODBUSRTU_SUB_FUNCTION_CODE.CHANGE_ASCII_INPUT_DELIMITER*             | 0x0003 |
| *MODBUSRTU_SUB_FUNCTION_CODE.FORCE_LISTEN_ONLY_MODE*                   | 0x0004 |
| *MODBUSRTU_SUB_FUNCTION_CODE.CLEAR_COUNTERS_AND_DIAGNOSTICS_REGISTER*  | 0x000A |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_BUS_MESSAGE_COUNT*                 | 0x000B |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_BUS_COMMUNICATION_ERROR_COUNT*     | 0x000C |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_BUS_EXCEPTION_ERROR_COUNT*         | 0x000D |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_SLAVE_MESSAGE_COUNT*               | 0x000E |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_SLAVE_NO_RESPONSE_COUNT*           | 0x000F |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_SLAVE_NAK_COUNT*                   | 0x0010 |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_SLAVE_BUSY_COUNT*                  | 0x0011 |
| *MODBUSRTU_SUB_FUNCTION_CODE.RETURN_BUS_CHARACTER_OVERRUN_COUNT *      | 0x0012 |
| *MODBUSRTU_SUB_FUNCTION_CODE.CLEAR_OVERRUN_COUNTER_AND_FLAG*           | 0x0014 |

#### Example

```squirrel
local data = blob();
data.writen(swap2(0xFF00),'w');
local pdu = ModbusRTU.createDiagnosticsPDU(MODBUSRTU_SUB_FUNCTION_CODE.RETURN_QUERY_DATA, data);
server.log(pdu);
```

### createReportSlaveIdPDU()

This method creates a PDU for *reportSlaveId* operations. It has no parameters.

#### Example

```squirrel
local pdu = ModbusRTU.createReportSlaveIdPDU();
server.log(pdu);
```

### createMaskWriteRegisterPDU(*referenceAddress, AND_Mask, OR_Mask*)

This method creates a PDU for *maskWriteRegister* operations. It takes the following parameters:

| Parameter | Data Type | Required | Default Value | Description |
| --- | --- | --- | --- | --- |
| *referenceAddress* | Integer | Yes | N/A | The address of the holding register the value is written into |
| *AND_mask* | Integer | Yes | N/A | The AND mask|
| *OR_mask* | Integer | Yes | N/A | The OR mask |

#### Example

```squirrel
local referenceAddress = 0x0A;
local AND_mask = 0xFFFF;
local OR_mask = 0x0000;
local pdu = ModbusRTU.createMaskWriteRegisterPDU(referenceAddress, AND_mask, OR_mask);
server.log(pdu);
```

### createReadWriteMultipleRegistersPDU(*readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue*)

This method creates a PDU for *readWriteMultipleRegisters* operations. It takes the following parameters:

| Parameter | Data Type | Required | Default Value | Description |
| --- | --- | --- | --- | --- |
| *readingStartAddress* | Integer | Yes | N/A | The address from which it begins reading values |
| *readQuantity* | Integer | Yes | N/A | The number of consecutive addresses values are read from |
| *writeStartAddress* | Integer | Yes | N/A | The address from which it begins writing values |
| *writeQuantity* | Integer | Yes | N/A | The number of consecutive addresses values are written into |
| *writeValue* | Blob| Yes | N/A | The value written into the holding register |

#### Example

```squirrel
local readingStartAddress = 0x01;
local readQuantity = 1;
local writeStartAddress = 0x0A;
local writeValue = blob();
writeValue.writen(swap2(28),'w');
local writeQuantity = writeValue.len() / 2 ;
local pdu = ModbusRTU.createReadWriteMultipleRegistersPDU(readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue);
server.log(pdu);
```

### createReadDeviceIdentificationPDU(*readDeviceIdCode, objectId*)

This method creates a PDU for *readDeviceIdentificationPDU* operations. It takes the following parameters:

| Key | Data Type | Required | Default Value | Description |
| --- | --- | --- | --- | --- |
| *readDeviceIdCode* | Constant | Yes | N/A | Refer to the ‘Read Device ID Code’ table, below |
| *objectId* | Constant | Yes | N/A | Refer to the ‘Object ID’ Code table, below |

| Read Device ID Code | Description |
| --- | --- |
| *MODBUSRTU_READ_DEVICE_CODE.BASIC* | Get the basic device identification (stream access) |
| *MODBUSRTU_READ_DEVICE_CODE.REGULAR* | Get the regular device identification (stream access) |
| *MODBUSRTU_READ_DEVICE_CODE.EXTENDED* | Get the extended device identification (stream access) |
| *MODBUSRTU_READ_DEVICE_CODE.SPECIFIC* | Get one specific identification object (individual access) |

| Object ID | Category |
| --- | --- |
| *MODBUSRTU_OBJECT_ID.VENDOR_NAME*           | Basic |
| *MODBUSRTU_OBJECT_ID.PRODUCT_CODE*          | Basic |
| *MODBUSRTU_OBJECT_ID.MAJOR_MINOR_REVISION*  | Basic |
| *MODBUSRTU_OBJECT_ID.VENDOR_URL*            | Regular |
| *MODBUSRTU_OBJECT_ID.PRODUCT_NAME*          | Regular |
| *MODBUSRTU_OBJECT_ID.MODEL_NAME*            | Regular |
| *MODBUSRTU_OBJECT_ID.USER_APPLICATION_NAME* | Regular |

#### Example

```squirrel
local readDeviceIdCode = MODBUSRTU_READ_DEVICE_CODE.BASIC;
local objectId = MODBUSRTU_OBJECT_ID.VENDOR_NAME;
local pdu = ModbusRTU.createReadDeviceIdentificationPDU(readDeviceIdCode, objectId);
server.log(pdu);
```

### parse(*params*)

This method parses the Modbus PDU and returns the result. The value passed into the parameter, *params*, is a table composed of the following keys:

| Key | Data Type | Required | Default Value | Description |
| --- | --- | --- | --- | --- |
| *quantity* | Integer | No | N/A | The number of coils/register to read from or write into |
| *PDU* | Blob | Yes | N/A | The PDU to be parsed |
| *expectedResType* | Constant | Yes | N/A | The expected response type |
| *expectedResLen* | Integer | Yes | N/A | The expected response length |

#### Example

```squirrel
local quantity = 1;
local pdu = blob();
local expectedResType = ModbusRTU.FUNCTION_CODES.readCoils.fcode;
local expectedResLen = ModbusRTU.FUNCTION_CODES.readCoils.resLen(quantity);
local result = parse({
    "quantity"        : quantity,
    "PDU"             : pdu,
    "expectedResLen"  : expectedResLen,
    "expectedResType" : expectedResType
  });
```

## License

The ModbusRTU library is licensed under the [MIT License](../LICENSE).

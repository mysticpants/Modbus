# ModbusRTU

This library creates and parses Modbus Protocol Data Unit (PDU).

**To use this library, add `#require "CRC16.class.nut:1.0.0"` and `#require "ModbusRTU.class.nut:1.0.0"` to the top of your device code.**



## Class ModbusRTU

This is the main library class. All functions and variables inside this class are static.


### createReadPDU(*targetType, startingAddress, quantity*)

The function creates a <a href="#PDU">PDU</a> for readData.


#### Parameters

| Key               | Data Type | Required | Default Value | Description                                                               |
| ----------------- | --------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *targetType*      | Enum      | Yes      | N/A           | Refer to **<a href='#target-type'>Target Type</a>**                       |
| *startingAddress* | Int       | Yes      | N/A           | The address from which it begins reading values                           |
| *quantity*        | Int       | Yes      | N/A           | The number of consecutive addresses the values are read from              |


<h4 id='target-type'>Target Type</h4>

| Type               | Value                               | Access        |
| ------------------ | ----------------------------------- | ------------- |
| Coil               | MODBUS_TARGET_TYPE.COIL             | Read-Write    |
| Discrete Input     | MODBUS_TARGET_TYPE.DISCRETE_INPUT   | Read-Only     |
| Input Register     | MODBUS_TARGET_TYPE.INPUT_REGISTER   | Read-Only     |
| Holding Register   | MODBUS_TARGET_TYPE.HOLDING_REGISTER | Read-Write    |


#### Example

```squirrel
local targetType = MODBUS_TARGET_TYPE.COIL;
local startingAddress = 0x01;
local quantity = 1;

local PDU = ModbusRTU.createReadPDU(targetType, startingAddress, quantity);
server.log(PDU);

```

### createWritePDU(*targetType, startingAddress, quantity, values*)

The function creates a <a href="#PDU">PDU</a> for writeData.


#### Parameters

| Key               | Data Type                         | Required | Default Value | Description                                                               |
| ----------------- | --------------------------------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *targetType*      | Enum                              | Yes      | N/A           | Refer to **<a href='#target-type'>Target Type</a>**                       |
| *startingAddress* | Int                               | Yes      | N/A           | The address from which it begins writing values                           |
| *quantity*        | Int                               | Yes      | N/A           | The number of consecutive addresses the values are written into           |
| *values*          | Int, Array[Int, Bool], Bool, Blob | Yes      | N/A           | The values written into Coils or Registers                                |


#### Example

```squirrel
local targetType = MODBUS_TARGET_TYPE.COIL;
local startingAddress = 0x01;
local values = false;
local quantity = 1;

local PDU = ModbusRTU.createWritePDU(targetType, startingAddress, quantity, values);
server.log(PDU);

```

### createReadExceptionStatusPDU()

The function creates a <a href="#PDU">PDU</a> for readExceptionStatus.


#### Parameters

None

#### Example

```squirrel
local PDU = ModbusRTU.createReadExceptionStatusPDU();
server.log(PDU);
```



### createDiagnosticsPDU(*subFunctionCode, data*)

The function creates a <a href="#PDU">PDU</a> for diagnostics.


#### Parameters


| Key               | Data Type | Required | Default Value | Description                                                               |
| ----------------- | --------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *deviceAddress*   | Int       | Yes      | N/A           | The unique address that identifies a device                               |
| *subFunctionCode* | Enum      | Yes      | N/A           | Refer to **Sub-function Code**                                            |
| *data*            | Blob      | Yes      | N/A           | The data field required by Modbus request                                 |
| *callback*        | Function  | No       | Null          | The function to be fired when it receives response regarding this request |


### Sub-function Codes

| Code (Hex)         | Value                                                             |
| ------------------ | ----------------------------------------------------------------- |
| 0x0000             | MODBUS_SUB_FUNCTION_CODE.RETURN_QUERY_DATA                        |
| 0x0001             | MODBUS_SUB_FUNCTION_CODE.RESTART_COMMUNICATION_OPTION             |
| 0x0002             | MODBUS_SUB_FUNCTION_CODE.RETURN_DIAGNOSTICS_REGISTER              |
| 0x0003             | MODBUS_SUB_FUNCTION_CODE.CHANGE_ASCII_INPUT_DELIMITER             |
| 0x0004             | MODBUS_SUB_FUNCTION_CODE.FORCE_LISTEN_ONLY_MODE                   |
| 0x000A             | MODBUS_SUB_FUNCTION_CODE.CLEAR_COUNTERS_AND_DIAGNOSTICS_REGISTER  |
| 0x000B             | MODBUS_SUB_FUNCTION_CODE.RETURN_BUS_MESSAGE_COUNT                 |
| 0x000C             | MODBUS_SUB_FUNCTION_CODE.RETURN_BUS_COMMUNICATION_ERROR_COUNT     |
| 0x000D             | MODBUS_SUB_FUNCTION_CODE.RETURN_BUS_EXCEPTION_ERROR_COUNT         |
| 0x000E             | MODBUS_SUB_FUNCTION_CODE.RETURN_SLAVE_MESSAGE_COUNT               |
| 0x000F             | MODBUS_SUB_FUNCTION_CODE.RETURN_SLAVE_NO_RESPONSE_COUNT           |
| 0x0010             | MODBUS_SUB_FUNCTION_CODE.RETURN_SLAVE_NAK_COUNT                   |
| 0x0011             | MODBUS_SUB_FUNCTION_CODE.RETURN_SLAVE_BUSY_COUNT                  |
| 0x0012             | MODBUS_SUB_FUNCTION_CODE.RETURN_BUS_CHARACTER_OVERRUN_COUNT       |
| 0x0014             | MODBUS_SUB_FUNCTION_CODE.CLEAR_OVERRUN_COUNTER_AND_FLAG           |


#### Example

```squirrel
local data = blob();
data.writen(swap2(0xFF00),'w');
local PDU = ModbusRTU.createDiagnosticsPDU(MODBUS_SUB_FUNCTION_CODE.RETURN_QUERY_DATA, data);
server.log(PDU);

```


### createReportSlaveIdPDU()

The function creates a <a href="#PDU">PDU</a> for reportSlaveId.



#### Parameters

None

#### Example

```squirrel
local PDU = ModbusRTU.createReportSlaveIdPDU();
server.log(PDU);

```



### createMaskWriteRegisterPDU(*referenceAddress, AND_Mask, OR_Mask*)

The function creates a <a href="#PDU">PDU</a> for maskWriteRegister.


#### Parameters

| Key                | Data Type | Required | Default Value | Description                                                               |
| ------------------ | --------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *referenceAddress* | Int       | Yes      | N/A           | The address of the holding register the value is written into             |
| *AND_mask*         | Int       | Yes      | N/A           | The AND mask                                                              |
| *OR_mask*          | Int       | Yes      | N/A           | The OR mask                                                               |

#### Example

```squirrel
local referenceAddress = 0x0A;
local AND_mask = 0xFFFF;
local OR_mask = 0x0000;
local PDU = ModbusRTU.createMaskWriteRegisterPDU(referenceAddress, AND_mask, OR_mask);
server.log(PDU);
```


### createReadWriteMultipleRegistersPDU(*readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue*)

The function creates a <a href="#PDU">PDU</a> for readWriteMultipleRegisters.

#### Parameters

| Key                   | Data Type | Required | Default Value | Description |
| --------------------- | --------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *readingStartAddress* | Int       | Yes      | N/A           | The address from which it begins reading values                           |
| *readQuantity*        | Int       | Yes      | N/A           | The number of consecutive addresses values are read from                  |
| *writeStartAddress*   | Int       | Yes      | N/A           | The address from which it begins writing values                           |
| *writeQuantity*       | Int       | Yes      | N/A           | The number of consecutive addresses values are written into               |
| *writeValue*          | Blob      | Yes      | N/A           | The value written into the holding register                               |

#### Example

```squirrel
local readingStartAddress = 0x01;
local readQuantity = 1;
local writeStartAddress = 0x0A;
local writeValue = blob();
writeValue.writen(swap2(28),'w');
local writeQuantity = writeValue.len() / 2 ;
local PDU = ModbusRTU.createReadWriteMultipleRegistersPDU(readingStartAddress, readQuantity, writeStartAddress, writeQuantity, writeValue);
server.log(PDU);

```



### createReadDeviceIdentificationPDU(*readDeviceIdCode, objectId*)

The function creates a <a href="#PDU">PDU</a> for readDeviceIdentificationPDU.


#### Parameters

| Key                | Data Type | Required | Default Value | Description                                                               |
| ------------------ | --------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *readDeviceIdCode* | Enum      | Yes      | N/A           | Refer to **Read Device ID Code**                                          |
| *objectId*         | Enum      | Yes      | N/A           | Refer to **Object ID**                                                    |


##### Read Device ID Codes

| Value                              | Description                                                |
| ---------------------------------- | ---------------------------------------------------------- |
| MODBUS_READ_DEVICE_CODE.BASIC      | Get the basic device identification (stream access)        |
| MODBUS_READ_DEVICE_CODE.REGULAR    | Get the regular device identification (stream access)      |
| MODBUS_READ_DEVICE_CODE.EXTENDED   | Get the extended device identification (stream access)     |
| MODBUS_READ_DEVICE_CODE.SPECIFIC   | Get one specific identification object (individual access) |


##### Object ID

| Value                                  | Category  |
| -------------------------------------- | --------- |
| MODBUS_OBJECT_ID.VENDOR_NAME           | Basic     |
| MODBUS_OBJECT_ID.PRODUCT_CODE          | Basic     |
| MODBUS_OBJECT_ID.MAJOR_MINOR_REVISION  | Basic     |
| MODBUS_OBJECT_ID.VENDOR_URL            | Regular   |
| MODBUS_OBJECT_ID.PRODUCT_NAME          | Regular   |
| MODBUS_OBJECT_ID.MODEL_NAME            | Regular   |
| MODBUS_OBJECT_ID.USER_APPLICATION_NAME | Regular   |

#### Example

```squirrel
local readDeviceIdCode = MODBUS_READ_DEVICE_CODE.BASIC;
local objectId = MODBUS_OBJECT_ID.VENDOR_NAME;
local PDU = ModbusRTU.createReadDeviceIdentificationPDU(readDeviceIdCode, objectId);
server.log(PDU);

```


# Abbreviations

1. <p id="PDU">PDU : Protocol Data Unit</p>

2. <p id="ADU">ADU : Application Data Unit</p>

# License

The ModbusRTU library is licensed under the [MIT License](https://github.com/electricimp/thethingsapi/tree/master/LICENSE).

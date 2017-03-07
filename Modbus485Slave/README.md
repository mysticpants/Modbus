# Modbus485Slave

This library empowers an imp to communicate the Modbus Master via the RS485 protocol.

**To use this library, add `#require "CRC16.class.nut:1.0.0"`, `#require "ModbusSlave.class.nut:1.0.0"`  and `#require "Modbus485Slave.class.nut:1.0.0"` to the top of your device code.**


## Hardware Setup

The following instructions are applicable to [impAccelerator™ Fieldbus Gateway](https://electricimp.com/docs/hardware/fieldbusgateway/ide/).

1. Screw the antenna onto the Imp

2. Wire RS485 A on Imp to port A / positive(+) on the other device

3. Wire RS485 B on Imp to port B / negative(-) on the other device

4. Wire ground ports together between the two devices

5. Fit a jumper to enable RS485 chip on the Imp

6. Power up the Imp

7. Blink up the Imp


## Class Modbus485Slave

This is the main library class.

### Constructor: Modbus485Slave(*uart, rts, slaveID, [params]*)

Instantiate a new Modbus485Slave object and set the configuration of UART .

#### Parameters

| Key      | Default     | Notes                                                                           |
| ------   | ----------- | ------------------------------------------------------------------------------- |
| uart     | N/A         | The UART object connected to the Modbus Master                                  |
| rts      | N/A         | A pin to be used for flow control                                               |
| slaveID  | N/A         | An ID by which the master identifies this slave                                 |
| params   | {}          | A table consists of the following <a href="#items">items</a>                    |

<h5 id="items">Items</h5>

| Key      | Default     | Notes                                                                           |
| ------   | ----------- | ------------------------------------------------------------------------------- |
| baudRate | 19200       | The baud rate of the UART connection                                            |
| dataBits | 8           | The word size on the UART connection in bits (7 or 8 bits)                      |
| parity   | PARITY_NONE | Parity configuration of the UART connection                                     |
| stopBits | 1           | Number of stop bits (1 or 2) on the UART connection                             |
| debug    | false       | If enabled, the outgoing and incoming ADU will be printed for debugging purpose |



#### Example

```squirrel
modbus <- Modbus485Slave(hardware.uart2, hardware.pinL, 1);
```


### setSlaveID(*slaveID*)

It changes the slave ID

#### Parameters

| Key             | Data Type | Required | Default Value | Description                                                               |
| --------------- | --------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *slaveID*       | `integer` | Yes      | Null          | The new slave ID                                                          |


#### Example

```squirrel
modbus.setSlaveID(2);

```

### onWrite(*callback*)

It sets the callback function for when there is a write request

#### Parameters

| Key             | Data Type | Required | Default Value | Description                                                               |
| --------------- | --------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *callback*      | `function`| Yes      | Null          | The function to be fired on the receipt of a write request                |

#### Callback Parameters

| Key                | Data Type | Description                                                                                |
| ------------------ | --------- | ------------------------------------------------------------------------------------------ |
| *slaveID*          | `integer `| The ID of the slave the request is addressed to                                            |
| *functionCode*     | `integer `| The function code. Please refer to the <a href="#functionCode">Supported Function Code</a> |
| *startingAddress*  | `integer `| The address at which it starts writing values                                              |
| *quantity*         | `integer `| The quantity of the values                                                                 |
| *values*           | `array `, `bool`, `integer`| The values to be written                                                  |


#### Accepted Return Value Type

The callback function can return a value, which will be processed and sent back to the Master as a response

| Type               | Description                                                                                                                            |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| `bool`             | If true is returned, it will give a positive response. Otherwise, it will give an exception response back to the Master (Error code 1) |
| `null`             | If null is returned, it is the same as returning true                                                                                  |
| `integer`          | Any acceptable Modbus Exception Code can be returned                                                                                   |


#### Example

```squirrel
// accept this write request
modbus.onWrite(function(slaveID, functionCode, startingAddress, quantity, values) {
    server.log("slaveID : " + slaveID);
    server.log("functionCode : " + functionCode);
    server.log("startingAddress : " + startingAddress);
    server.log("Quantity : " + quantity);
    server.log("Values : \n");
    foreach (index, value in values) {
    	server.log("\t" + index + " : " + value);
    }
    return true;
}.bindenv(this));



// decline this write request
modbus.onWrite(function(slaveID, functionCode, startingAddress, quantity, values) {
    server.log("slaveID : " + slaveID);
    server.log("functionCode : " + functionCode);
    server.log("startingAddress : " + startingAddress);
    server.log("Quantity : " + quantity);
    server.log("Values : \n");
    foreach (index, value in values) {
    	server.log("\t" + index + " : " + value);
    }
    // reject this request with the exception code of 2
    return 2;
}.bindenv(this));

```


### onRead(*callback*)

It sets the callback function for when there is a read request

#### Parameters

| Key             | Data Type | Required | Default Value | Description                                                               |
| --------------- | --------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *callback*      | `function`| Yes      | Null          | The function to be fired on the receipt of a read request                 |

#### Callback Parameters

| Key                | Data Type | Description                                                                                |
| ------------------ | --------- | ------------------------------------------------------------------------------------------ |
| *slaveID*          | `integer `| The ID of the slave the request is addressed to                                            |
| *functionCode*     | `integer `| The function code. Please refer to the <a href="#functionCode">Supported Function Code</a> |
| *startingAddress*  | `integer `| The address at which it starts writing values                                              |
| *quantity*         | `integer `| The quantity of the values                                                                 |


#### Accepted Return Value Type

The callback function can return a value, which will be processed and sent back to the Master as a response

| Type               | Description                                                                                                                            |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| `bool`             | Only accepted when it is a coil or discrete input read                                                                                 |
| `null`             | If null is returned, the value to be read will be 0                                                                                    |
| `integer`          | 1 or 0 when it is a coil or discrete input read. Any number when it is a holding register or input register read                       |
| `array`            | Array of 1, 0, true, false when it is a coil or discrete input read. Array of integers when it is a holding register or input register read |


#### Example

```squirrel
// a coil read example
modbus.onRead(function(slaveID, functionCode, startingAddress, quantity){
    server.log("slaveID : " + slaveID);
    server.log("functionCode : " + functionCode);
    server.log("startingAddress : " + startingAddress);
    server.log("Quantity : " + quantity);
	return [true,false,false,true,true];
}.bindenv(this));

// a holding register read example
modbus.onRead(function(slaveID, functionCode, startingAddress, quantity){
    server.log("slaveID : " + slaveID);
    server.log("functionCode : " + functionCode);
    server.log("startingAddress : " + startingAddress);
    server.log("Quantity : " + quantity);
	return [18,29,30, 59, 47];
}.bindenv(this));

```



### onError(*callback*)

It sets the callback function for when there is an error

#### Parameters

| Key             | Data Type | Required | Default Value | Description                                                               |
| --------------- | --------- | -------- | ------------- | ------------------------------------------------------------------------- |
| *callback*      | `function`| Yes      | Null          | The function to be fired when there is an error                           |

#### Callback Parameters

| Key                | Data Type | Description                                                                       |
| ------------------ | --------- | --------------------------------------------------------------------------------- |
| *error*            | `string`  | The error message                                                                 |


#### Example

```squirrel
modbus.onError(function(error){
    server.error(error);
}.bindenv(this));

```


<h2 id="functionCode"> Supported Function Codes </h2>

The following table presents a list of function codes the slave can support and process. Other requests with unsupported function codes will be rejected with the exception code of 1.

| Code          | Name                     |
| ------------- | ------------------------ |
| 0x01          | Read Coils               |
| 0x02          | Read Discrete Inputs     |
| 0x03          | Read Holding Registers   |
| 0x04          | Read Input Registers     |
| 0x05          | Write Single Coil        |
| 0x06          | Write Single Register    |
| 0x0F          | Write Multiple Coils     |
| 0x10          | Write Multiple Registers |




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

# License

The Modbus485Slave library is licensed under the [MIT License](https://github.com/electricimp/thethingsapi/tree/master/LICENSE).

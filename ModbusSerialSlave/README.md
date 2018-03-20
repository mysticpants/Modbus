# ModbusSerialSlave

This library empowers an imp to communicate with the Modbus Master via the RS485 or RS232 protocol.

**To use this library, add the following statements to the top of your device code:**

```squirrel
#require "CRC16.class.nut:1.0.0"
#require "ModbusSlave.device.lib.nut:1.0.1"
#require "ModbusSerialSlave.device.lib.nut:2.0.0"
```

## Hardware Setup

The following instructions are applicable to Electric Imp’s [impAccelerator&trade; Fieldbus Gateway](https://electricimp.com/docs/hardware/resources/reference-designs/fieldbusgateway/).

1. Connect the antenna to the Fieldbus Gateway
2. Wire RS485 A on the Fieldbus Gateway to port A / positive(+) on the other device
3. Wire RS485 B on the Fieldbus Gateway to port B / negative(-) on the other device
4. Wire both devices’ ground ports together
5. Fit [jumper J2](https://electricimp.com/docs/hardware/resources/reference-designs/fieldbusgateway/#rs-485) on the Fieldbus Gateway motherboard to enable RS485
6. Power up the Fieldbus Gateway
7. Configure the Fieldbus Gateway for Internet access using BlinkUp&trade;

## ModbusSerialSlave Class Usage

This is the main library class.

### Constructor: ModbusSerialSlave(*slaveID, uart[, rts][, params]*)

Instantiates a new ModbusSerialSlave object and configures the UART bus over which it operates. The *slaveID* parameter takes an ID by which the master identifies this slave. The *uart* parameter is an imp UART object. The optional *rts* parameter should be used for RS485 communications when you are using an imp GPIO pin for control flow. The *params* parameter is optional and takes a table containing the following keys:

| Key | Default | Notes |
| --- | --- | --- |
| baudRate | 19200 | The baud rate of the UART connection |
| dataBits | 8 | The word size on the UART connection in bits (7 or 8 bits) |
| parity | *PARITY_NONE* | Parity configuration of the UART connection |
| stopBits | 1 | Number of stop bits (1 or 2) on the UART connection |
| debug | `false` | If enabled, the outgoing and incoming ADU will be printed for debugging purpose |

#### Example

```squirrel
modbus <- Modbus485Slave(1, hardware.uart2, hardware.pinL);
```

### setSlaveID(*slaveID*)

This method changes the slave ID. Its single parameter takes the new slave ID.

#### Example

```squirrel
modbus.setSlaveID(2);
```

### onWrite(*callback*)

This method sets the callback function that will be triggered when there is a write request. The callback takes the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *slaveID* | Integer | The ID of the slave the request is addressed to |
| *functionCode* | Integer | The function code. Please refer to ‘<a href="#functionCode">Supported Function Codes</a>’ |
| *startingAddress* | Integer | The address at which it starts writing values |
| *quantity* | Integer | The quantity of the values |
| *values* | Integer, bool, array | The values to be written |

#### Accepted Return Value Types

The callback function can return a value, which will be processed and sent back to the Master as a response.

| Type | Description |
| --- | --- |
| Bool | If `true` is returned, it will give a positive response. Otherwise, it will give an exception response back to the Master (Error code 1) |
| `null` | If `null` is returned, it is the same as returning `true` |
| Integer | Any acceptable Modbus Exception Code can be returned |

#### Example

```squirrel
// Accept this write request
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

// Decline this write request
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

This method sets the callback function that will be called when there is a read request. The callback takes the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *slaveID* | Integer | The ID of the slave the request is addressed to |
| *functionCode* | Integer | The function code. Please refer to the <a href="#functionCode">Supported Function Code</a> |
| *startingAddress* | Integer | The address at which it starts writing values |
| *quantity* | Integer | The quantity of the values |

#### Accepted Return Value Type

The callback function can return a value, which will be processed and sent back to the Master as a response.

| Type | Description |
| --- | --- |
| Bool | Only accepted when it is a coil or discrete input read |
| `null` | If `null` is returned, the value to be read will be 0 |
| Integer | 1 or 0 when it is a coil or discrete input read. Any number when it is a holding register or input register read |
| Array | Array of 1, 0, `true`, `false` when it is a coil or discrete input read. Array of integers when it is a holding register or input register read |

#### Example

```squirrel
// A coil read example
modbus.onRead(function(slaveID, functionCode, startingAddress, quantity){
    server.log("slaveID : " + slaveID);
    server.log("functionCode : " + functionCode);
    server.log("startingAddress : " + startingAddress);
    server.log("Quantity : " + quantity);
	return [true,false,false,true,true];
}.bindenv(this));

// A holding register read example
modbus.onRead(function(slaveID, functionCode, startingAddress, quantity){
    server.log("slaveID : " + slaveID);
    server.log("functionCode : " + functionCode);
    server.log("startingAddress : " + startingAddress);
    server.log("Quantity : " + quantity);
	return [18,29,30, 59, 47];
}.bindenv(this));
```

### onError(*callback*)

This method sets the callback function that will be called when there is an error. The callback takes a single parameter into which a description of the error is passed.

#### Example

```squirrel
modbus.onError(function(error){
    server.error(error);
}.bindenv(this));
```

<h2 id="functionCode">Supported Function Codes</h2>

The following table lists the function codes that the slave can support and process. Other requests with unsupported function codes will be rejected with the exception code of 1 (see below).

| Code | Name |
| --- | --- |
| 0x01 | Read Coils |
| 0x02 | Read Discrete Inputs |
| 0x03 | Read Holding Registers |
| 0x04 | Read Input Registers |
| 0x05 | Write Single Coil |
| 0x06 | Write Single Register |
| 0x0F | Write Multiple Coils |
| 0x10 | Write Multiple Registers |

## Exception Codes

The table below enumerates all the exception codes that can be possibly encountered. Refer to the [Modbus specification](http://www.modbus.org/docs/Modbus_over_serial_line_V1_02.pdf) for more detailed description on Modbus-specific exceptions.

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

# License

The ModbusSerialSlave library is licensed under the [MIT License](../LICENSE).

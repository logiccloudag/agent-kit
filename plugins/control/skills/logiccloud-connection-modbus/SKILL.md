---
name: logiccloud-connection-modbus
description: Use when setting up or changing a Modbus TCP or Modbus RTU (serial RS-485) connection of a logiccloud runtime - IP/port or baud rate/parity, poll periods, units (slave IDs), byte and word order, and mapping Inputs/Outputs to coils, discrete inputs, holding and input registers.
---

# Modbus TCP and RTU connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to types `ModbusTCP` and `ModbusRTU`. The runtime is
the Modbus master (client). Test: not supported; check with the runtime log
and `lc vars` (logiccloud-devices skill).

## Three levels

1. **Connection** - where and how often.
   - TCP (`ModbusTcpConnectionInput`): `ip`, `port` (502).
   - RTU (`ModbusRtuConnectionInput`): `baudRate` (`BaudRate9600`,
     `BaudRate19200`, `BaudRate115200`, ...), `dataBits` (`Seven`, `Eight`),
     `stopBits` (`One`, `Two`), `parity` (`None`, `Even`, `Odd`). The serial
     port itself is not part of the definition; the device must pass it to the
     runtime (logiccloud device skills).
   - Both, optional: `pollPeriod` (ms, 500), `waitBetweenCalls` (10),
     `connectTimeout` (3000), `requestTimeout`, `readChunkSize`/`writeChunkSize`
     (1), `useReadMultiple`/`useWriteMultiple` (false; turn on if the device
     supports function codes 3/16 with several registers, it saves round trips).
2. **Units** (sub-object `ModbusUnit`), one per slave: `name`, `address`
   (the unit/slave ID), `byteOrder` (`BigEndian`, `LittleEndian`),
   `byteSwap`, `wordSwap`, `reverseRegisters`, `pollPeriod` (ms), and the four
   blocks `coils`, `discreteInputs`, `holdingRegisters`, `inputRegisters`,
   each `{"registerType": "Coil"}` etc. with an optional own `pollPeriod`.
3. **Mappings** per unit and register type (`ModbusMappings`):
   `{variableName, dataType, address}`.

A connection definition alone creates no units and no mappings: create the
units, then their mappings (or copy a working connection).

    lc connection create -runtime <rt> -type ModbusTCP -f conn.json
    lc connection object create -kind ModbusUnit -connection <connId> -f unit.json
    lc connection mappings -kind ModbusMappings -target <unitId> -arg registerType=HoldingRegister -f hr.json

    conn.json  {"name": "Meter", "ip": "192.0.2.10", "port": 502, "pollPeriod": 500}
    unit.json  {"name": "Meter 1", "address": 1, "byteOrder": "BigEndian",
                "coils": {"registerType": "Coil"}, "discreteInputs": {"registerType": "DiscreteInput"},
                "holdingRegisters": {"registerType": "HoldingRegister"},
                "inputRegisters": {"registerType": "InputRegister"}}
    hr.json    [{"variableName": "Power", "dataType": "UInt32", "address": 100},
                {"variableName": "Setpoint", "dataType": "Float", "address": 110}]

With the tools: `create_connection`, `connection_object` (`create`, kind
`ModbusUnit`), `set_connection_mappings` (`args: {"registerType": "HoldingRegister"}`).
Each call replaces the whole list of that register type.

## Register types and variables

| registerType | Access | Data types | Variable |
|---|---|---|---|
| `Coil` | read/write bit | `Boolean` | `{IN}` to read, `{OUT}` to write |
| `DiscreteInput` | read-only bit | `Boolean` | `{IN}` |
| `HoldingRegister` | read/write 16-bit | `Int16`, `UInt16`, `Int32`, `UInt32`, `Int64`, `UInt64`, `Float`, `Double` | `{IN}` or `{OUT}` |
| `InputRegister` | read-only 16-bit | as holding registers | `{IN}` |

- 32-bit values take two registers, 64-bit four: leave room between
  addresses. INT = `Int16`, UINT/WORD = `UInt16`, DINT = `Int32`, REAL =
  `Float`, LREAL = `Double`.
- If 32-bit values come out garbled, the device uses another word order:
  try `wordSwap` (then `byteSwap`) on the unit.
- Device manuals count addresses from 0, from 1 or as 40001-style numbers.
  Use the register address as the device documents it for the protocol; if
  values come out shifted by one register, the base is off by one.

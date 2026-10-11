---
name: logiccloud-connection-revpi
description: Use when a logiccloud runtime on a KUNBUS Revolution Pi should read or write the process image (onboard and expansion module I/O configured in PiCtory) - poll interval, signal names, directions and data types.
---

# Revolution Pi connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to type `Revpi`, for the KUNBUS Revolution Pi device
types (Connect 4/5/S, Core S, Flat S; platform `Arm64`). Test: not
supported; check with `lc vars` and the runtime log.

With a `Revpi` connection, the deploy also installs a RevPi connector
process on the device (`lc health` lists it; its log with
`lc logs -device <id> -target <process>`). The device's RevPi browsing
service reads the PiCtory configuration, so the portal can list the signal
names.

## Definition

The mappings are part of the definition:

    {"name": "RevPi I/O", "pollInterval": 50,
     "ioMappings": [
       {"variable": "StartButton", "revpiVarName": "I_1", "direction": "Input", "dataType": "Bool"},
       {"variable": "Lamp", "revpiVarName": "O_1", "direction": "Output", "dataType": "Bool"},
       {"variable": "CoreTemp", "revpiVarName": "Core_Temperature", "direction": "Input", "dataType": "USInt"}]}

- `pollInterval`: ms (50 is the default).
- `revpiVarName`: the signal name from PiCtory, case-sensitive, max 31
  characters. Take the names from the user's PiCtory configuration; do not
  guess them.
- `direction`: `Input` (RevPi to PLC, an `{IN}` variable) or `Output` (PLC
  to RevPi, an `{OUT}` variable). For an `{IN_OUT}` variable map
  `<var>_IN` as Input and `<var>_OUT` as Output.
- `dataType`: `Bool`, `Byte`, `SInt`, `USInt`, `Word`, `Int`, `UInt`,
  `DWord`, `DInt`, `UDInt`, `Real` - the IEC type of the signal (BOOL for
  digital I/O, INT/WORD for analog values, as PiCtory shows).

## Gotchas

- An update replaces the whole definition. A definition without
  `ioMappings` deletes all mappings: always send the complete list.
- The device needs the piControl driver and a saved PiCtory configuration.
  After changing PiCtory, piControl has to be reset (in the RevPi web UI)
  and the runtime restarted.

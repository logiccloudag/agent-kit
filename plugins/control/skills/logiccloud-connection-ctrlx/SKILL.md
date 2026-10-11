---
name: logiccloud-connection-ctrlx
description: Use when a logiccloud runtime should exchange data with the Bosch Rexroth ctrlX data layer - local or remote ctrlX CORE, providers that create nodes, clients that read or write existing nodes (axes, I/O, other apps), and mapping Inputs/Outputs to data layer paths.
---

# ctrlX data layer connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to type `Ctrlx`. The device side is in the
logiccloud-device-ctrlx skill. Test: supported.

## Connection

- On the ctrlX CORE the runtime runs on: `{"name": "Data layer", "useLocalDataLayer": true}`.
  No credentials needed.
- Another ctrlX CORE: `{"name": "CORE 2", "useLocalDataLayer": false,
  "ip": "192.0.2.10", "sslPort": 443, "user": "<user>", "password": "<password>"}`.

## Providers and clients

Two kinds of sub-objects, each with its own mapping list:

| Sub-object | What it does | Mapping kind | `address` in a mapping |
|---|---|---|---|
| `CtrlxProvider` (`{name, address}`) | creates nodes under `address` (e.g. `logiccloud-control/line1`) that other apps and the ctrlX UI can see | `CtrlxProviderMappings` | relative to the provider: `GripperOpen` |
| `CtrlxClient` (`{name}`) | reads or writes nodes that exist already (motion, fieldbus I/O, other apps) | `CtrlxClientMappings` | absolute: `motion/axs/Axis_X/state/values/actual/pos/mm` |

Mapping item:

    {"variableName": "AxisPos", "address": "motion/axs/Axis_X/state/values/actual/pos/mm",
     "type": "DataTypeFloat64", "mode": "DirectionFromDataLayer"}

- `mode`: `DirectionFromDataLayer` fills an `{IN}` variable;
  `DirectionToDataLayer` writes an `{OUT}` variable to the data layer.
- `type`: `DataTypeBool`, `DataTypeInt8`..`DataTypeInt64`,
  `DataTypeUint8`..`DataTypeUint64`, `DataTypeFloat32`, `DataTypeFloat64`,
  `DataTypeString`, `DataTypeTimestamp`. It must match the node's type
  (REAL = Float32, LREAL = Float64, INT = Int16, DINT = Int32).
- Paths use `/`, as in the ctrlX data layer browser. Take them from there
  (or from the user); do not guess.

Workflow: create the connection, then a provider or client
(`lc connection object create -kind CtrlxClient -connection <id> -f c.json`),
then its mappings
(`lc connection mappings -kind CtrlxClientMappings -target <clientId> -f m.json`).

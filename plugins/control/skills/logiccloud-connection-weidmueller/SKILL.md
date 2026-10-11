---
name: logiccloud-connection-weidmueller
description: Use when a logiccloud runtime on a Weidmüller u-OS device (u-control UC20) should exchange data with the u-OS Data Hub - the OAuth client from u-OS Control Center, providers that publish PLC variables, consumers that read hub variables, addresses, folders, quality and timestamp variables.
---

# Weidmüller u-OS Data Hub connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to type `Weidmueller`. The device side is in the
logiccloud-device-weidmueller skill. Test: supported.

## Connection

The runtime logs in to the Data Hub with an OAuth client created in u-OS
Control Center (Identity & access > Clients), with access to the Data Hub.

    {"name": "Data Hub", "clientId": "<client id>", "clientName": "<client name>",
     "clientSecret": "<secret>"}

- `clientName` must be the client's name exactly as u-OS shows it
  (letters, digits, `_`, `-`). It is the NATS connection name and the ID of
  the hub provider. A wrong name does not fail: every request times out
  silently, just like an unreachable hub. Never put the client ID there.
- `tokenUrl` is normally detected; set it only if the user gives one.
- `deviceEditorProject` belongs to the portal's device editor: keep whatever
  is there when updating.

## Providers and consumers

| Sub-object | Direction | Mapping kind | `mode` |
|---|---|---|---|
| `WeidmuellerProvider` (`{name, folder}`) | PLC to hub: `{OUT}` variables become hub variables | `WeidmuellerProviderMappings` | `ToHub` |
| `WeidmuellerConsumer` (`{name, folder}`) | hub to PLC: `{IN}` variables | `WeidmuellerConsumerMappings` | `FromHub` |

Mapping item:

    {"variableName": "Temperature", "address": "sensors.temperature",
     "type": "Float64", "mode": "FromHub", "provider": "<hub provider ID>",
     "qualityVariableName": "", "timestampVariableName": ""}

- `address`: dotted u-OS variable name; each part starts with a letter or
  `_`, then letters, digits, `_` (max 63). No `/`, no `-`. A provider's
  `folder` is put in front: `folder.address`.
- Every consumer mapping needs `provider`: the ID of the hub provider that
  owns the variable (another app, the I/O, or another logiccloud runtime's
  `clientName`). On provider mappings leave it out.
- `type`: `Boolean`, `Int`, `Float64`, `String`, `Duration`, `Timestamp`
  (for BOOL, integers, LREAL/REAL, STRING, TIME, DT); it must match the hub
  variable's type.
- All providers of one connection form one hub provider, so `folder.address`
  must be unique across them; the API rejects duplicates.
- `qualityVariableName` / `timestampVariableName`: optional variables that
  receive the hub's quality and timestamp of the value.

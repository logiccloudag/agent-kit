---
name: logiccloud-device-ctrlx
description: Use when a logiccloud project should run on Bosch Rexroth ctrlX OS (ctrlX CORE, ctrlX CORE virtual) - installing the logiccloud Control app, ctrlX licensing, platform, the HMI path, and the ctrlX data layer.
---

# Bosch Rexroth ctrlX CORE

| Device type | Platform | Package |
|---|---|---|
| ctrlX CORE | `Arm64` | ctrlX app (snap) |
| ctrlX CORE virtual | `x86_64` | ctrlX app (snap) |

Device services: **ctrlX license service** (the license comes from the
ctrlX license manager, bought through the ctrlX Store), **ctrlX data layer
browsing service** (lists data layer nodes for mappings), debugging
service.

## Onboarding (the user does it)

1. Portal: add the device (type ctrlX CORE or ctrlX CORE virtual) and bind
   it to get the device token.
2. ctrlX OS web UI: install the logiccloud Control app ("Install an app",
   from the ctrlX Store or an app file); it then appears in the left
   navigation.
3. Open it and connect it with the device token. Activate the license in
   the ctrlX license manager.

## Deploying

- `lc build -platform Arm64` (CORE) or `x86_64` (CORE virtual). Not
  `Amd64`; `lc deploy` refuses a build without the device's platform.
- `lc deploy -device <id>`, `lc health -device <id>` (logiccloud-devices
  skill). `licenseNotActivated` means the license is missing in the ctrlX
  license manager.
- The HMI is served under `/ctrlx-logiccloud-control/hmi` on the CORE
  (through the ctrlX reverse proxy, HTTPS), not `/hmi`.

## I/O

Everything on the CORE (fieldbus I/O via EtherCAT, motion axes, other
apps) is in the ctrlX data layer: use a `Ctrlx` connection with
`useLocalDataLayer: true` (logiccloud-connection-ctrlx skill). Clients read
and write existing nodes, providers publish PLC variables as new nodes. A
remote ctrlX CORE's data layer works too, with IP, port and login.

---
name: logiccloud-device-plcnext
description: Use when a logiccloud project should run on a Phoenix Contact PLCnext controller (AXC F 2152) - the PLCnext Store app, PLCnext licensing, the Arm/V7 platform, and how to reach the controller's I/O.
---

# Phoenix Contact PLCnext (AXC F 2152)

Device type PLCnext AXC F 2152, platform `Arm/V7`. Device services:
**PLCnext license service** (uses the controller's own licensing),
debugging service, OPC UA browsing service.

## Onboarding and license (the user does it)

- logiccloud control is installed as an app from the PLCnext Store; the
  device is added and bound in the logiccloud portal and connected with the
  device token.
- The license is a PLCnext license: activated on the controller with the
  activation code (PLCnext Engineer or the controller's web-based
  management), not with a logiccloud key. It is bound to that controller and
  cannot be moved. Without it the runtime runs in demo mode.

## Deploying

- `lc build -platform Arm/V7`, then `lc deploy -device <id>`
  (logiccloud-devices skill). A build without `Arm/V7` is refused.
- `notStartedReason: licenseNotActivated` points to the PLCnext license.

## I/O

There is no PLCnext-specific connection type. The local Axioline I/O
belongs to the controller's own PLCnext runtime; to use it from
logiccloud, the user exposes it there (for example through the
controller's OPC UA server) and logiccloud reads and writes it with an OPC
UA client connection (logiccloud-connection-opcua-client skill), the OPC UA
browsing service helps to find the node IDs. Other devices: Modbus TCP,
MQTT and the other network connections.

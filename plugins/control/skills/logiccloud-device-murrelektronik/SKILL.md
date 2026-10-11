---
name: logiccloud-device-murrelektronik
description: Use when a logiccloud project should run on a Murrelektronik device - Xelity 4TX, 6TX, 8TX M GE managed switches (also PN, PROFINET variants), or an MVK Pro as a generic ARM v7 device - LXC installation, the Arm/V7 platform, the watchlist service and network I/O.
---

# Murrelektronik Xelity switches

Device types Xelity 4TX / 6TX / 8TX M GE and their PN (PROFINET) variants:
managed switches that run logiccloud control in an LXC container, platform
`Arm/V7`. The 4TX PN, 8TX and 8TX PN types also offer a **watchlist
service**. An MVK Pro fieldbus module with Docker runs as a Generic ARM v7
device (logiccloud-device-linux skill).

## Onboarding (the user does it)

The device is added and bound in the logiccloud portal; the logiccloud
control container is installed through the switch's own web UI (LXC), then
connected with the device token. Follow Murrelektronik's and logiccloud's
instructions for the firmware at hand; `lc` cannot do this.

## Deploying

- `lc build -platform Arm/V7`, then `lc deploy -device <id>`
  (logiccloud-devices skill). A build without `Arm/V7` is refused.
- A switch has less CPU and memory to spare than an edge PC: keep cycle
  times and connections modest, and watch `lc health`.
- License: assigned in the portal and activated by the device's license
  service; demo mode stops after two hours.

## I/O

No onboard process I/O: the switch sits in the machine network, so use
Modbus TCP, OPC UA client, MQTT and the other network connections to reach
devices and controllers on its ports.

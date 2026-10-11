---
name: logiccloud-device-perimica
description: Use when a logiccloud project should run on a Perinet periMICA edge computer - the LXC container, the Arm/V7 platform, the HMI path /logiccloud-control/hmi, and reading periNODE sensors over the local MQTT broker.
---

# Perinet periMICA

Device type periMICA, platform `Arm/V7`, logiccloud control as an LXC
container.

## Onboarding (the user does it)

Add and bind the device in the logiccloud portal, install the logiccloud
control container (a logiccloud download) through the periMICA web UI, then
open `<container address>/control/` and connect it with the device token.

## Deploying

- `lc build -platform Arm/V7` (ARM v7, 32 bit), then
  `lc deploy -device <id>` (logiccloud-devices skill). A build without
  `Arm/V7` is refused.
- The HMI is served under `/logiccloud-control/hmi`, not `/hmi`.
- License: assigned in the portal and activated by the device's license
  service; demo mode stops after two hours.

## I/O

Perinet periNODE sensors and actuators publish over MQTT to the broker on
the periMICA. Use an MQTT connection to that local broker (not `isCloud`)
with consumers for the sensor topics (logiccloud-connection-mqtt skill);
the topic names and payload shape come from the periNODE's documentation or
from watching the broker. Other devices: network connections.

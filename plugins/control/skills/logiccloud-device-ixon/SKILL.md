---
name: logiccloud-device-ixon
description: Use when a logiccloud project should run on an IXON SecureEdge Pro gateway - installation through the IXON marketplace or Docker, the Arm64 platform, license, and remote access next to the IXON VPN.
---

# IXON SecureEdge Pro

Device type SecureEdge Pro, platform `Arm64`, Docker.

## Onboarding (the user does it)

- logiccloud control is listed in the IXON marketplace; installation there
  goes through logiccloud (the listing says to contact logiccloud sales).
- Otherwise the container is run with Docker as on a Generic ARM 64 device
  (logiccloud-device-linux skill): add and bind the device in the portal,
  start the container, connect it with the device token.

## Deploying

- `lc build -platform Arm64`, then `lc deploy -device <id>`
  (logiccloud-devices skill). A build without `Arm64` is refused.
- License: assigned in the portal and activated by the license service on
  the device; without it the runtime runs in demo mode (two hours).

## I/O

Network connections to the machine network behind the gateway (Modbus TCP,
OPC UA client, MQTT, ...). The IXON VPN and the logiccloud connection are
independent: the runtime needs outbound internet access to logiccloud
either way.

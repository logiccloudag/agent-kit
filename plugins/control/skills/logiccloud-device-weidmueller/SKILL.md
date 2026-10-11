---
name: logiccloud-device-weidmueller
description: Use when a logiccloud project should run on a Weidmüller u-OS controller (u-control 2000 UC20-M3000, UC20-M4000, UC20-WL2000) - platform, the Weidmüller license and device management services, and exchanging data with the u-OS Data Hub and the local I/O.
---

# Weidmüller u-control (u-OS)

| Device type | Platform |
|---|---|
| UC20-M3000, UC20-M4000 | `Arm64` |
| UC20-WL2000 | `Arm/V7` |

The runtime runs as a container on u-OS. Device services on these types:
**Weidmüller license service** (license through the Weidmüller licensing on
the device), **Weidmüller device management service**, and the debugging
service. There is no OPC UA browsing service.

## Onboarding

The device is added and bound in the portal (type UC20-...) by the user,
and logiccloud control installed on the u-OS device; the user does both.
`lc devices` then lists it.

## Deploying

- Build for the device's platform: `lc build -platform Arm64` (M3000,
  M4000) or `Arm/V7` (WL2000). `lc deploy` refuses other builds.
- `lc deploy -device <id>`, `lc health -device <id>` (logiccloud-devices
  skill). `notStartedReason: licenseNotActivated` means the Weidmüller
  license is missing on the device.

## I/O

The local u-remote I/O and other u-OS apps are reached through the u-OS
Data Hub with a `Weidmueller` connection
(logiccloud-connection-weidmueller skill): an OAuth client from u-OS
Control Center, providers that publish PLC variables, consumers that read
hub variables (I/O modules, other apps). Network connections (MQTT, OPC UA,
Modbus TCP, ...) work as on any device.

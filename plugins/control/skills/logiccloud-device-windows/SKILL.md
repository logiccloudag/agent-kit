---
name: logiccloud-device-windows
description: Use when a logiccloud project should run on a Windows PC or server (device types Windows 10/11, Windows Server, and their ARM64 variants) - Docker on Windows, onboarding, platform, license and ports.
---

# Windows devices

| Device type | Platform |
|---|---|
| Windows 10/11, Windows Server | `x86_64` |
| Windows 10/11 (ARM64), Windows Server (ARM64) | `Arm64` |

The runtime is a Linux container: Windows needs Docker (Docker Desktop with
the WSL 2 backend, installed as Docker describes it). Then the setup is as
on a Linux device (logiccloud-device-linux skill): add and bind the device
in the portal, run the logiccloud control container, open
`http://localhost:8080/` and paste the device token. The user does this;
`lc` cannot add a device.

## Deploying

- Build for `x86_64` (or `Arm64`): `lc build -platform x86_64`. Not
  `Amd64`, which is for cloud vPLCs; `lc deploy` refuses a build without the
  device's platform.
- `lc deploy -device <id>`, `lc health -device <id>` (logiccloud-devices
  skill).
- The PC must be running with Docker started; a sleeping laptop shows an
  old `LAST SEEN` and actions time out.
- License: a key assigned to the runtime in the portal, activated by the
  license service on the device. Without it the runtime stops after two
  hours.

## Connections

Network connections only. Ports a connection opens (OPC UA server 42010,
Node-RED 42011, or what is configured) must be published by the container
and allowed by Windows Defender Firewall to be reachable from other
machines. Serial ports (Modbus RTU) are not available to Docker Desktop
containers without extra tooling (usbipd); prefer Modbus TCP gateways.

---
name: logiccloud-device-linux
description: Use when a logiccloud project should run on a Linux edge device or gateway with Docker - Generic ARM 64, Generic ARM v7, Generic X86/64, Hilscher netFIELD (Compact X8M, Quantum, OnPremise, Unity) and sensorEDGE FIELD, Kontron AL Pi-Tron CM4, FESTO CEPE, NXTGN CM007 - onboarding, platform, license, ports, serial devices and troubleshooting.
---

# Linux edge devices (Docker)

These device types all run the logiccloud control runtime as a Docker (or
Podman) container. Device-specific skills exist for Raspberry Pi, RevPi,
Weidmüller, ctrlX, PLCnext, WAGO, Murrelektronik, INSYS, Perinet, IXON,
Belden/Hirschmann OpEdge and Windows.

| Device type | Vendor | Platform |
|---|---|---|
| Generic ARM 64 | - | `Arm64` |
| Generic ARM v7 | - | `Arm/V7` |
| Generic X86/64 | - | `x86_64` |
| netFIELD Compact X8M, netFIELD Quantum, sensorEDGE FIELD | Hilscher | `Arm64` |
| netFIELD OnPremise, netFIELD Unity | Hilscher | `x86_64` |
| AL Pi-Tron CM4 | Kontron | `Arm64` |
| CEPE H8GB 128GB M1 | FESTO | `x86_64` |
| CM007 HK | NXTGN | `Arm64` |

Minimum: 700 MHz CPU, 500 MB RAM, 1.5 GB disk, Docker or Podman.

## Onboarding (the user does it)

`lc` cannot add a physical device; a person does it in the portal and on
the device:

1. Portal: add a device (vendor, type), then "bind device". It offers a
   quick-install command (curl/wget script, uses sudo, Docker or Podman)
   and a device token.
2. Device: run the script. Or by hand: image `logiccloud/logiccloud-control`
   (Docker Hub, current tag), a volume on `/app/storage`, port 8080 to the
   container's 80 (the device web UI), restart policy `always`.
3. Device web UI (`http://<device>:8080/`): paste the device token, connect,
   and change the default login.

Afterwards `lc devices` shows it with a `LAST SEEN` time. Help with the
commands if asked, but the user runs them on the device.

## Deploying

- Build for the device's platform: `lc build -platform Arm64` (or
  `Arm/V7`, `x86_64`). `x86_64` (edge PCs) is not `Amd64` (cloud vPLCs);
  `lc deploy` refuses a build without the device's exact platform.
  Several at once: `-platform Amd64,x86_64,Arm64`.
- `lc deploy -device <id>`, `lc health -device <id>`, `lc logs -device <id>`
  (logiccloud-devices skill). Remote actions need "allow remote control" on
  the device.
- License: without a key the runtime stops after two hours (demo). The key
  is assigned to the runtime in the portal; the device's license service
  activates it (`lc health` lists it among the processes).
- HMI: served by the device under `/hmi`.

## I/O

No onboard I/O connection: use network connections (Modbus TCP, OPC UA
client/server, MQTT, Sparkplug B, InfluxDB, Kafka, REST-RPC, IO-Link
masters, Node-RED). Modbus RTU needs the serial device (e.g.
`/dev/ttyUSB0`) passed into the container when it is installed (the setup
script asks for devices to pass). IO-Link masters that offer the IO-Link
JSON REST API: the logiccloud-connection-io-link skill.

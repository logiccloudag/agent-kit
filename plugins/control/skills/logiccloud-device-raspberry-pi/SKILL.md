---
name: logiccloud-device-raspberry-pi
description: Use when a logiccloud project should run on a Raspberry Pi (4B 4GB, 4B 8GB, 5, or a Raspberry Pi cluster) - onboarding with Docker, the Arm64 platform, GPIO, the serial port for Modbus RTU, license and HMI path.
---

# Raspberry Pi

| Device type | Platform | HMI path |
|---|---|---|
| Raspberry Pi 4B 4GB, 4B 8GB, Raspberry Pi 5 | `Arm64` | `/hmi` |
| Raspberry Pi Cluster | `Arm64` | `/control/hmi` |

A 64-bit Raspberry Pi OS is needed (platform `Arm64`).

## Onboarding (the user does it)

As on any Linux device (logiccloud-device-linux skill): add and bind the
device in the portal, run the install script with sudo on the Pi (it asks
before changing Docker's log settings, which spares the SD card), open `http://<pi>:8080/` and paste the device
token.

## Deploying

- `lc build -platform Arm64`, then `lc deploy -device <id>`
  (logiccloud-devices skill). A build for `Amd64` only is refused.
- License: assigned to the runtime in the portal, activated by the license
  service on the Pi; demo mode stops after two hours.

## I/O

- GPIO: a `RaspberryPi` connection (logiccloud-connection-raspberry-pi
  skill): pins as BOOL inputs and outputs.
- Serial port (Modbus RTU over a USB or HAT RS-485 adapter): enable the
  serial port with `raspi-config` (no login shell over serial), then pass the
  device (`/dev/ttyS0`, `/dev/ttyUSB0`, ...) into the container through the
  setup script's "passed devices" option. Then a `ModbusRTU` connection
  (logiccloud-connection-modbus skill).
- Everything else over the network (MQTT, Modbus TCP, OPC UA, ...).

Use a proper power supply: under-voltage on a Pi causes random restarts and
corrupted SD cards, which look like runtime problems.

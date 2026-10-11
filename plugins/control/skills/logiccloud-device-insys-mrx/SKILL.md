---
name: logiccloud-device-insys-mrx
description: Use when a logiccloud project should run on an INSYS icom MRX router - the LXC container from the logiccloud downloads, network bridge and IP, the INSYS license activation service, and the Arm/V7 platform.
---

# INSYS icom MRX

Device type MRX, platform `Arm/V7`, logiccloud control as an LXC container
on the router. Besides the usual services the type has a **license
activation service** for INSYS (licenses are also sold through the INSYS
in.hub store).

## Onboarding (the user does it)

1. Add and bind the device in the logiccloud portal (type MRX).
2. Download the logiccloud control container for INSYS (logiccloud
   downloads) and upload it in the MRX web UI as a container.
3. Give it a network bridge and a static IP, then open the container's IP
   in a browser and connect it with the device token.

## Deploying

- `lc build -platform Arm/V7`, then `lc deploy -device <id>`
  (logiccloud-devices skill). A build without `Arm/V7` is refused.
- `licenseNotActivated` in `lc health`: the license still has to be
  activated (through the activation service, with the key from the portal
  or in.hub).
- The router has limited resources: modest cycle times and connections.

## I/O

Network connections (Modbus TCP, MQTT, OPC UA, ...) to devices in the
networks the router connects. Router I/O and serial ports are only usable
if they are passed into the container on the MRX side.

---
name: logiccloud-device-opedge
description: Use when a logiccloud project should run on a Belden / Hirschmann OpEdge-8D edge gateway - running the logiccloud control container from the OpEdge UI, the port conflict on 8080, the x86_64 platform and license.
---

# Hirschmann (Belden) OpEdge-8D

Device type OpEdge-8D, platform `x86_64`, Docker.

## Onboarding (the user does it)

1. Add and bind the device in the logiccloud portal (type OpEdge-8D).
2. In the OpEdge web UI, add a container: image
   `docker.io/logiccloud/logiccloud-control` (the current tag on Docker Hub),
   a volume on `/app/storage`, restart policy always, and the container's
   port 80 published on host port **8090** - 8080 is already the OpEdge
   UI.
3. Open `http://<device>:8090/` and connect it with the device token.

## Deploying

- `lc build -platform x86_64` (not `Amd64`, which is for cloud vPLCs),
  then `lc deploy -device <id>` (logiccloud-devices skill).
- License: assigned in the portal and activated by the license service on
  the device; demo mode stops after two hours.

## I/O

Network connections to the machines on the gateway's ports (Modbus TCP,
OPC UA client, MQTT, Sparkplug B, ...). Ports a connection opens (OPC UA
server, Node-RED) must be published in the container settings too.

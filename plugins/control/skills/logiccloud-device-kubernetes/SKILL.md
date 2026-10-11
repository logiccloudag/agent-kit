---
name: logiccloud-device-kubernetes
description: Use when a logiccloud runtime should run in a self-hosted Kubernetes cluster (device types Kubernetes vPLC S1 ARM64 and x86_64) - how it gets there with Helm or logiccloud orchestrate, its platform and limits, and deploying a project to it.
---

# Kubernetes vPLCs

Device types `Kubernetes vPLC S1 x86_64` (platform `x86_64`) and
`Kubernetes vPLC S1 ARM64` (`Arm64`): the logiccloud control runtime as a
Helm deployment in the user's own cluster (a Margo-style workload). Limits
as for a cloud S1: one task, cycle time at least 500 ms.

## Getting it running

`lc` does not install anything in a cluster. The steps are:

1. The device is created in the logiccloud control portal (type
   Kubernetes vPLC ...), which gives its credentials/token.
2. The runtime container is installed into the cluster with Helm - by hand,
   or as an application deployment in logiccloud orchestrate
   (logiccloud-orchestrate-deployments skill) when the cluster is an
   orchestrate device.
3. Once it is connected, `lc devices` lists it with a `LAST SEEN` time.

Ask the user which of these is done; do not install Helm releases unless
asked.

## Deploying a project

- Build for the device's platform: `lc build -platform x86_64` (or
  `Arm64`), not the default `Amd64` (that one is for cloud vPLCs). `lc deploy`
  refuses a build without the device's platform.
- Then `lc deploy -device <id>`, `lc health -device <id>` (logiccloud-devices
  skill).
- `notStartedReason: licenseExpired` / `licenseNotActivated`: the runtime
  needs a license; the user assigns it in the portal.

Connections: network ones (MQTT, OPC UA, Modbus TCP, InfluxDB, Kafka,
REST-RPC, Sparkplug B). Ports a connection opens (OPC UA server, Node-RED)
must also be exposed by the Kubernetes service.

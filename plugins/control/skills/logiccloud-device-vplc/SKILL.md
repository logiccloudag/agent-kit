---
name: logiccloud-device-vplc
description: Use when a logiccloud project should run on a cloud vPLC (vPLC Cloud Development, S1, S2, S3, S4) - choosing a size, its cycle time and task limits, creating and deleting one, the demo license, provisioning states, and which connections make sense for a PLC that runs in the cloud.
---

# Cloud vPLCs

A cloud vPLC is a runtime the installation hosts itself: no hardware, ready
in about half a minute. Commands are in the logiccloud-devices skill.

| Type (`-type`) | Platform | Cores | Min. cycle time | Tasks |
|---|---|---|---|---|
| `Development` | `Amd64` | 1 | 500 ms | 1 |
| `S1` | `Amd64` | 1 | 500 ms | 1 |
| `S2` | `Amd64` | 2 | 250 ms | 2 |
| `S3` | `Amd64` | 4 | 250 ms | 4 |
| `S4` | `Amd64` | 4 | 100 ms | 4 |

`lc device types` / `device_types` lists the types the organization may
create. Pick the smallest that fits the project's task configuration
(`configuration/*.json`): a project with two tasks or a 100 ms task does
not run on S1.

## Create, use, delete

    lc device create -name "Pump test" -type S1     # waits until Ready
    lc deploy -device <id>                          # in the workspace
    lc health -device <id>
    lc device delete <id> -name "Pump test"

With the tools: `create_vplc`, `deploy`, `device_health`, `delete_device`.

- Create one only when the user wants a new device (or every device runs
  another project). Delete only the ones the user named.
- Provisioning goes Provisioning, Installing, Installed, Ready. `Failed`
  means the installation could not set it up: tell the user, do not
  retry in a loop.
- Builds for a cloud vPLC need the `Amd64` platform, the default of
  `lc init`. A project for edge devices may target only `x86_64` or
  `Arm64`: build it with `lc build -platform Amd64` (several:
  `-platform Amd64,Arm64`) before deploying.
- Without a license key the runtime runs in demo mode and stops after two
  hours (`notStartedReason` in `lc health`); the countdown survives a
  restart. For longer, the user assigns a license in the portal.

## Connections

A cloud vPLC has no I/O of its own and runs outside the user's network.
What works: the cloud MQTT broker (`isCloud`) and Sparkplug B Cloud,
connections out to public services (MQTT/Sparkplug brokers, InfluxDB,
Kafka, REST-RPC, SAP, Tibber), and an OPC UA client or Modbus TCP only to
addresses reachable from the internet. Hardware connections (RevPi,
Raspberry Pi GPIO, ctrlX local data layer, Weidmüller, Modbus RTU) do not.

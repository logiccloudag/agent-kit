---
name: logiccloud-devices
description: Use when a logiccloud project should run on a device - deploying a build, starting or stopping a runtime, checking a runtime's health or logs, or setting up connections (MQTT, Modbus, OPC UA, InfluxDB, Kafka, REST-RPC, ...) that map Inputs/Outputs to the outside world. Covers both the lc CLI and the logiccloud MCP server (logiccloud-control).
---

# logiccloud devices, runtimes and connections

Everything here changes what runs on real machines or reads from them. Deploy,
start, stop, restart and delete only when the user asked for it. Reading
(health, logs, listing) is always fine.

Use the `lc` CLI or the MCP server `logiccloud-control`, whichever is there
(see the logiccloud skill).

## Deploy and run

| Task | lc | MCP tool |
|---|---|---|
| Find the device | `lc devices` (`-project <id>`: those running it) | `list_devices` (`projectId`) |
| Show one | `lc device <id>` | `get_device` |
| Install or update, then start | `lc deploy -device <id>` (in the workspace) | `deploy` |
| Stop, start | `lc stop -device <id>`, `lc start -device <id>` | `stop_runtime`, `start_runtime` |
| Restart on the latest build | `lc runtime restart <runtimeId>` | `restart_runtime` |
| Cancel a running build | `lc build cancel <id>` | `cancel_build` |

A deploy uses the latest successful build (build first: the logiccloud skill)
and waits for the device's result. Never pass `-replace` to `lc deploy`
(`replace` to `deploy`) unless the user said so: it replaces another
project's runtime on the device. If every device runs another project and the
user wants a new one, create a cloud vPLC:

| Task | lc | MCP tool |
|---|---|---|
| Sizes | `lc device types` | `device_types` |
| Create one, wait until it is ready | `lc device create -name "<Name>"` (`-type S1`) | `create_vplc` |
| Delete it when no longer needed | `lc device delete <id> -name "<Name>"` | `delete_device` |

A vPLC on a demo license stops after two hours (the runtime log and the
health check say when).

## When something does not work

| Task | lc | MCP tool |
|---|---|---|
| Runtime state, why it is not started, installed build | `lc health -device <id>` | `device_health` |
| The runtime's log | `lc logs -device <id> -level warn` | `device_logs` (`level: "warn"`) |
| Another process's log | `lc logs -device <id> -target <process>` | `device_logs` (`target`) |

The health check lists the log targets. A runtime that is not started usually
says why (`notStartedReason`), and the log says the rest. Two messages are
normal on healthy runtimes: "Metrics unavailable" in the health check, and a
"broken pipe" error in the runtime log when the HMI connects.

## Connections

Connections belong to a runtime and bind its Inputs/Outputs to MQTT topics,
Modbus registers, OPC UA nodes and so on.

| Task | lc | MCP tool |
|---|---|---|
| List | `lc connections` (the workspace's project; `-runtime <id>`) | `list_connections` |
| Show, with sub-objects and mappings | `lc connection <id>` | `get_connection` |
| As a definition to edit | `lc connection <id> -definition > c.json` | `get_connection` with `definition: true` |
| Replace it | `lc connection update <id> -f c.json` | `update_connection` |
| Create | `lc connection create -runtime <id> -type Mqtt -f c.json` | `create_connection` |
| Types | `lc connection types` | `connection_types` |
| Try it (the runtime must be running) | `lc connection test <id>` | `test_connection` |
| Delete (name as confirmation) | `lc connection delete <id> -name "<Name>"` | `delete_connection` |

An update replaces the whole connection: read the definition, change it,
send all of it back. To set one up, copy the definition of a similar
connection (from any project) and change `name`, `runtimeId` and the
settings. Bind variables by their Inputs/Outputs name. A test only says
whether it worked, not why. Only delete what the user asked for.

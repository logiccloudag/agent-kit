---
name: logiccloud-devices
description: Use when a logiccloud project should run on a device or already runs on one - deploying a build, starting, stopping or restarting a runtime, finding runtimes and their state, checking a device's health or logs, reading or writing live variable values, or maintenance actions (reset retained values, restart a device process, log level, uninstall the runtime), and cloud vPLCs. Covers both the lc CLI and the logiccloud MCP server (logiccloud-control).
---

# logiccloud devices and runtimes

Everything here changes what runs on real machines or reads from them.
Deploy, start, stop, restart, write values, run device actions and delete
only when the user asked for it. Reading (health, logs, values, listing) is
always fine.

Use the `lc` CLI or the MCP server `logiccloud-control`, whichever is there
(see the logiccloud skill). Connections are in the logiccloud-connections
skill, alarms in logiccloud-alarms.

## Find the device and runtime

| Task | lc | MCP tool |
|---|---|---|
| Devices (`-project <id>`: those running it) | `lc devices` | `list_devices` (`projectId`) |
| One device and its runtime | `lc device <id>` | `get_device` |
| Runtimes with their device and state | `lc runtimes -project <id> -status started` (`-platform`, `-tag`) | `list_runtimes` (`states`, `platforms`, `tags`) |
| One runtime: build, state on the device, pending changes, connections | `lc runtime <id>` | `get_runtime` |

## Deploy and run

| Task | lc | MCP tool |
|---|---|---|
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
| Runtime state, why it is not started, installed build, processes and what the device installs | `lc health -device <id>` | `device_health` |
| The runtime's log | `lc logs -device <id> -level warn` | `device_logs` (`level: "warn"`) |
| Another process's log | `lc logs -device <id> -target <process>` | `device_logs` (`target`) |

The health check lists the processes (log targets). A runtime that is not
started usually says why (`notStartedReason`), and the log says the rest. Two
messages are normal on healthy runtimes: "Metrics unavailable" in the health
check, and a "broken pipe" error in the runtime log when the HMI connects.

## Live values

The runtime must be started. Variables are named as the device reports them.

| Task | lc | MCP tool |
|---|---|---|
| Read all, or some by name | `lc vars -device <id> [name...]` | `read_variables` (`names`) |
| Write one (then read back) | `lc write -device <id> <variable> <value>` | `write_variable` |

Writing changes a running machine: only with the variable and value the user
named. `lc write` takes the value as JSON (`true`, `12`, `1.5`, `"text"`).

## Device actions

| Task | lc | MCP tool (`device_action`) |
|---|---|---|
| Reset the runtime's retained values | `lc device reset-retained <id>` | `resetRetainedValues` |
| Restart a device process | `lc device restart-process <id> -target <process>` | `restartProcess` (`target`) |
| Show or set a log level | `lc device log-level <id> [-target <process>] [-set Debug]` | `getLogLevel`, `setLogLevel` (`logLevel`) |
| Uninstall the runtime (stop it first) | `lc device uninstall <id>` | `uninstall` |

All but reading the log level change the device: only when the user asked.
Never force an uninstall of a started runtime (`-force`, `force`) unless the
user said so. The device must allow remote control.

---
name: logiccloud-devices
description: Use when a logiccloud project should run on a device - deploying a build, starting or stopping a runtime, checking a runtime's health or logs, or setting up connections (MQTT, Modbus, OPC UA, InfluxDB, Kafka, REST-RPC, ...) that map Inputs/Outputs to the outside world.
---

# logiccloud devices, runtimes and connections

Everything here changes what runs on real machines or reads from them. Deploy,
start, stop, restart and delete only when the user asked for it. Reading
(health, logs, listing) is always fine.

## Deploy and run

    lc devices                          # find the device (-project <id>: those running a project)
    lc check                            # in the workspace: deploy uses the latest successful build
    lc deploy -device <id>              # install or update, then start; waits for the device
    lc stop -device <id>; lc start -device <id>
    lc runtime restart <runtimeId>      # restart on the project's latest build

Never pass `-replace` to `lc deploy` (it replaces another project's runtime on
the device) unless the user said so. If every device runs another project and
the user wants a new one, create a cloud vPLC:

    lc device types                     # Development, S1 ... S4
    lc device create -name "<Name>"     # -type S1; waits until provisioned, prints the ID
    lc device delete <id> -name "<Name>"   # when it is no longer needed

A vPLC on a demo license stops after two hours (the runtime log and
`lc health` say when).

## When something does not work

    lc health -device <id>              # runtime state, why it is not started, installed build
    lc logs -device <id> -level warn    # the runtime's log; -target <process> for others

`health` lists the log targets. A runtime that is not started usually says why
(`notStartedReason`), and the log says the rest. Two messages are normal on
healthy runtimes: "Metrics unavailable" in `health` (the server's metrics
queries fail on dev), and a "broken pipe" error in the runtime log when the HMI
connects.

## Connections

Connections belong to a runtime and bind its Inputs/Outputs to MQTT topics,
Modbus registers, OPC UA nodes and so on.

    lc connections                      # of the workspace's project
    lc connection <id>                  # all settings, with units/payloads/subscriptions and mappings
    lc connection <id> -definition > c.json
    lc connection update <id> -f c.json # replaces the whole connection: send it all back
    lc connection create -runtime <id> -type Mqtt -f c.json
    lc connection test <id>             # the runtime must be running

To set one up, copy the definition of a similar connection (`lc connections`
across projects, `lc connection <id> -definition`) and change `name`,
`runtimeId` and the settings. Bind variables by their Inputs/Outputs name.
`lc connection delete` wants the connection's name with `-name`; only delete
what the user asked for.

---
name: logiccloud-orchestrate-deployments
description: Use when deploying an application (e.g. the logiccloud Control runtime or Node-RED) to edge devices with logiccloud orchestrate, or when watching, promoting, pausing, stopping or rolling back a deployment. Covers both the lco CLI and the orchestrate MCP server (logiccloud-orchestrate).
---

# Deployments in orchestrate

A deployment installs one application _version_ on the devices its selector
matches, using a rollout strategy. Everything here changes what runs on real
machines: create, start, stop, roll back or delete only when the user asked
for it. Reading is always fine.

Use the `lco` CLI or the MCP server `logiccloud-orchestrate`, whichever is
there (see the logiccloud-orchestrate skill).

## See what runs

| Task | lco | MCP tool |
|---|---|---|
| App, version, status, strategy, phase, running/total | `lco deployments` (`-status FAILED`, `-device <id>`, `-version <versionId>`, `-search`) | `list_deployments` |
| Selector, parameters, rollout, per-device instances | `lco deployment <id>` (`-json`: the full object) | `get_deployment` |

Status: PENDING, INSTALLING, INSTALLED, FAILED; removal goes REMOVING,
REMOVED. An instance's `lastError` and the device's log
(`lco logs <deviceId> -severity ERROR`, or `device_logs`) say why one failed.

## Deploy

1. Find the version: `lco apps` and `lco app <appId>`, or
   `list_applications` and `get_application`. Deployments take the
   **version ID** from that list, not the application ID.
2. Pick targets: device IDs (`lco devices`, `list_devices`) and/or labels.
3. Show the user the request first (a dry run), then create it:

       lco deploy -name "<Name>" -version <versionId> -device <id> -param httpPort=28080 -dry-run
       lco deploy -name "<Name>" -version <versionId> -device <id> -param httpPort=28080

   With the tools: `create_deployment` with `dryRun: true`, show the body,
   then the same call without `dryRun`.

Parameters (`-param k=v`, or the tool's parameters) override the version's
parameters. The version's manifest lists them, and an earlier deployment of
the same app (`lco deployment <id>`, `get_deployment`) shows the usual ones.
Strategies:

    IMMEDIATE                      default: all targets at once
    CANARY, canary 1-50 %          first that share, then promote (or auto-promote)
    ROLLING, batch size n          n devices at a time (optionally approved one by one)
    rollback threshold 20% or 3    roll back automatically above that many failures

With `lco`: `-strategy CANARY -canary 10 [-auto-promote]`,
`-strategy ROLLING -batch 2`, `-rollback-threshold 20%`.

Targeting a label (`-label k=v`) reaches every device with that label, now
and later. Prefer explicit device IDs unless the user asked for a label
rollout.

## Control a rollout

| Task | lco | MCP tool |
|---|---|---|
| Start a PENDING one | `lco deployment start <id>` | `deployment_action` start |
| Canary phase done: everyone | `lco deployment promote <id>` | `deployment_action` promote |
| Rolling with manual approval: next batch | `lco deployment approve-batch <id>` | `deployment_action` approve-batch |
| Pause, resume | `lco deployment pause <id>`, `lco deployment resume <id>` | `deployment_action` pause, resume |
| Stop | `lco deployment stop <id>` | `deployment_action` stop |
| Abort the in-flight rollout | `lco deployment rollback <id> -reason "..."` | `deployment_action` rollback |
| Delete (the name is a confirmation) | `lco deployment delete <id> -name "<Name>"` | `delete_deployment` |

`rollback` only aborts a rollout; it does not reinstall the previous version.
For that there are device-level operations (`rollbackDeviceVersion`,
`rollbackDevicesBySelector`): `lco ops rollback`, or `search_operations`.

To change a deployment, use `lco deployment update <id> -f body.json` or
`update_deployment`. The API does not document that body, so start from the
full object (`lco deployment <id> -json`, `get_deployment`) and change only
what is needed.

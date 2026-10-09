---
name: logiccloud-orchestrate-deployments
description: Use when deploying an application (e.g. the logiccloud Control runtime or Node-RED) to edge devices with logiccloud orchestrate - choosing targets (device IDs, labels, device groups) and previewing them, canary or rolling rollouts, watching, starting, promoting, pausing, stopping or deleting a deployment, changing its parameters or version (redeploy), removing it from some devices, or rolling a device back to its previous version. Covers both the lco CLI and the orchestrate MCP server (logiccloud-orchestrate).
---

# Deployments in orchestrate

A deployment installs one application _version_ on its target devices, using
a rollout strategy. Everything here changes what runs on real machines:
create, change, start, stop, roll back or delete only when the user asked
for it. Reading is always fine.

Use the `lco` CLI or the MCP server `logiccloud-orchestrate`, whichever is
there (see the logiccloud-orchestrate skill).

## See what runs

| Task | lco | MCP tool |
|---|---|---|
| App, version, status, strategy, phase, running/total | `lco deployments` (`-status FAILED`, `-name`, `-device <id>`, `-version <versionId>`, `-search`) | `list_deployments` |
| Selector, parameters, rollout, per-device instances | `lco deployment <id>` (`-json`: the full object) | `get_deployment` |
| Where an application or version is deployed | `lco app deployments <appId> [-version 1.2.3]` | `application_deployments` |

Status: PENDING, INSTALLING, INSTALLED, FAILED; removal goes REMOVING,
REMOVED. An instance's `lastError` and the device's log
(`lco logs <deviceId> -severity ERROR`, or `device_logs`) say why one failed.

## Deploy

1. Find the version: `lco apps` and `lco app <appId>`, or
   `list_applications` and `get_application`. Deployments take the
   **version ID** from that list, not the application ID.
2. Pick targets, one way or the other, plus device groups if wanted:
   - device IDs (`-device <id>`, `deviceIds`), or
   - labels (`-label k=v`, `labels`) and label expressions
     (`-expr "env In prod,stage"`, `-expr "site Exists"`; `expressions`
     with `In`, `NotIn`, `Exists`, `DoesNotExist`);
   - device groups (`-group <id>`, `deviceGroupIds`; `lco groups`,
     `device_groups`) combine with either.

   The API ignores labels next to device IDs, so both are refused. Labels
   select only the devices that are ONLINE when the deployment is created,
   and the target set is then fixed: devices that get the label later, or
   come online later, do not join. Prefer device IDs unless the user asked
   for a label rollout.
3. Show the user the request and the devices it reaches (a dry run), then
   create it:

       lco deploy -name "<Name>" -version <versionId> -device <id> -param httpPort=28080 -dry-run
       lco deploy -name "<Name>" -version <versionId> -device <id> -param httpPort=28080

   With the tools: `create_deployment` with `dryRun: true` (body and
   devices), then the same call without it. `preview_deployment_targets`
   lists the devices targets reach without a body.

Parameters (`-param k=v`, `parameters`) override the version's manifest
parameters; an earlier deployment of the same app (`lco deployment <id>`,
`get_deployment`) shows the usual ones. More options: `-namespace`
(`targetNamespace`, helm), `-priority 0-100`, `-at <ISO time>`
(`scheduledAt`). Strategies:

| Strategy | lco | MCP fields |
|---|---|---|
| IMMEDIATE (default): all at once | | |
| CANARY: a share first, then promote | `-strategy CANARY -canary 10` or `-canary-count 2`, `-auto-promote -promote-delay 30`, `-canary-window 60` | `canaryPercentage` or `canaryCount`, `autoPromote`, `autoPromoteDelayMinutes`, `canarySuccessWindowMinutes` |
| ROLLING: batches or waves | `-strategy ROLLING -batch 2` or `-waves 10,30,60`, `-auto-progress -progress-delay 15` | `batchSize` or `wavePercentages`, `autoProgress`, `autoProgressDelayMinutes` |
| Auto-rollback above n failures | `-rollback-threshold 20%` or `3` | `rollbackThreshold` |

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

## Change a deployment

| Task | lco | MCP tool |
|---|---|---|
| Another version and/or parameters, in place (no uninstall) | `lco deployment redeploy <id> -version <versionId> -param k=v -unparam old -dry-run` | `redeploy_deployment` |
| Name, parameters, targets, namespace, desired state, priority, schedule | `lco deployment update <id> -param k=v -unparam old -dry-run` | `update_deployment` |
| Only on one device (split off unless it is the only target) | `lco deployment update <id> -on-device <deviceId> ...` | `update_deployment_on_device` |
| Remove it from devices or a label group (uninstalls there) | `lco deployment targets remove <id> -name "<Name>" -device <id>` (or `-group k=v`) | `deployment_targets` remove (`confirmName`) |
| Include removed devices again, split devices off | `lco deployment targets include <id> -device <id>`, `... split ...` | `deployment_targets` include, split |

Parameters given are merged into the current ones (`-unparam`,
`unsetParameters` remove one). New targets replace the selector: devices
that no longer match lose the deployment. A new version goes through
redeploy, not update.

## Roll back a device

`deployment rollback` only aborts a rollout; it does not reinstall the
previous version. To reinstall the previous revision:

| Task | lco | MCP tool |
|---|---|---|
| The device's history and the revision a rollback returns to | `lco device versions <id>` | `device_versions` |
| Roll back one device | `lco device rollback <id> -reason "..." -dry-run` | `rollback_device` (`deviceId`, `dryRun`) |
| Roll back the online devices with some labels | `lco device rollback -label k=v -dry-run` | `rollback_device` (`labels`) |

`-app <appId>` (`applicationPackageId`) picks the application when a device
runs several.

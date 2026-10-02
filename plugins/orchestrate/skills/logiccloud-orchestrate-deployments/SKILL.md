---
name: logiccloud-orchestrate-deployments
description: Use when deploying an application (e.g. the logiccloud Control runtime or Node-RED) to edge devices with logiccloud orchestrate and lco, or when watching, promoting, pausing, stopping or rolling back a deployment.
---

# Deployments with lco

A deployment installs one application _version_ on the devices its selector
matches, with a rollout strategy. Everything here changes what runs on real
machines: create, start, stop, roll back or delete only when the user asked
for it. Reading is always fine.

## See what runs

    lco deployments                      # app, version, status, strategy, phase, running/total
    lco deployments -status FAILED       # -device <id>, -version <versionId>, -search
    lco deployment <id>                  # selector, parameters, rollout, per-device instances
    lco deployment <id> -json            # the full object

Status: PENDING, INSTALLING, INSTALLED, FAILED; removal goes REMOVING,
REMOVED. An instance's `lastError` and the device's log
(`lco logs <deviceId> -severity ERROR`) say why one failed.

## Deploy

1. Find the version: `lco apps`, then `lco app <appId>`. Deployments take the
   **version ID** from that list, not the application ID.
2. Pick targets: device IDs (`lco devices`) and/or labels.
3. Show the user the body first, then create:

   lco deploy -name "<Name>" -version <versionId> -device <id> -param httpPort=28080 -dry-run
   lco deploy -name "<Name>" -version <versionId> -device <id> -param httpPort=28080

`-param k=v` overrides the version's parameters (see the version's manifest,
or `lco deployment <id>` of an earlier deployment of the same app for the
usual ones). Strategies:

    -strategy IMMEDIATE                  # default: all targets at once
    -strategy CANARY -canary 10 [-auto-promote]   # 1-50 % first, then promote
    -strategy ROLLING -batch 2           # batches of 2 devices
    -rollback-threshold 20%              # auto-rollback above 20 % (or a count: 3) failures

`-label k=v` targets every device with that label, now and later: prefer
explicit `-device` unless the user asked for a label rollout.

## Control a rollout

    lco deployment start <id>            # a PENDING one
    lco deployment promote <id>          # canary phase done -> everyone
    lco deployment approve-batch <id>    # rolling with manual approval: next batch
    lco deployment pause <id>; lco deployment resume <id>
    lco deployment stop <id>
    lco deployment rollback <id> -reason "..."   # aborts the in-flight rollout
    lco deployment delete <id> -name "<Name>"

`rollback` only aborts a rollout; it does not reinstall the previous version.
For that, `lco ops rollback` lists the device-level operations
(`rollbackDeviceVersion`, `rollbackDevicesBySelector`).

`lco deployment update <id> -f body.json` changes a deployment; the API does
not document that body, so start from `lco deployment <id> -json` and change
only what is needed.

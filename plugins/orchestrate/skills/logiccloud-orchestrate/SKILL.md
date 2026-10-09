---
name: logiccloud-orchestrate
description: Use when working with logiccloud orchestrate (formerly Fleet Manager) - edge devices and their status, labels and device groups, logs, telemetry and activity, fleet health, the application catalog and its registries, certificates, the audit log, users, API keys, or any other call to the orchestrate REST API. Covers both the lco CLI and the orchestrate MCP server (logiccloud-orchestrate).
---

# logiccloud orchestrate

orchestrate manages a fleet of edge devices (Margo) and deploys container
applications to them, among them the logiccloud Control runtime. It is not
logiccloud control: `lc` and the `logiccloud-control` server edit and build
PLC projects; orchestrate manages devices and what runs on them.

There are two ways in. Both act as the logged-in user (OAuth) or with an
API key. Use whichever is there:

- **The `lco` CLI.** If it says it is not logged in, or the login expired,
  ask the user to run `lco login -domain <domain>` (the root domain of their
  orchestrate installation; it opens the browser), or `lco login -api-key`,
  or to set `LCO_API_KEY`.
- **The MCP server `logiccloud-orchestrate`.** The user logs in through
  their agent (Claude Code: `/mcp`), or an API key is set where the server
  is configured. A 401 means the login is missing or expired, or the key is
  wrong; ask the user to log in again or fix the key.

Never ask for a password or a key in the chat. A 403 names the permission
the user or key lacks (e.g. `telemetry:read`, `groups:read`). Tell the user;
do not look for other credentials.

Deployments are in the logiccloud-orchestrate-deployments skill, alert rules
and notification targets in logiccloud-orchestrate-alerts.

## Look around

| Task | lco | MCP tool |
|---|---|---|
| Online/offline/error counts, averages, hot spots | `lco fleet` | `fleet_health` |
| Devices: status, last seen, CPU/mem/disk, workloads, labels | `lco devices` (`-status ONLINE -label k=v -label-key k -unlabeled -search x -app-version 1.2.3`) | `list_devices` |
| One device: capabilities, labels, latest telemetry | `lco device <id>` | `get_device` |
| The application catalog | `lco apps` (`-search`, `-lifecycle DEPRECATED`) | `list_applications` |
| An application's versions (version ID, profile, lifecycle) | `lco app <id>` | `get_application` |
| Where an application or version is deployed | `lco app deployments <id> [-version 1.2.3]` | `application_deployments` |

Lists are paged: with `lco`, `-all` fetches everything and `-json` gives the
raw objects; the tools take `limit` and return `nextCursor` while `hasMore`
is true.

## A device misbehaves

| Task | lco | MCP tool |
|---|---|---|
| ONLINE? Last seen? Running workloads? | `lco device <id>` | `get_device` |
| Errors in its log (oldest first) | `lco logs <id> -severity ERROR` (`-source <container>`, `-q <text>`, `-lines 500`) | `device_logs` (`severity`, `source`, `q`) |
| Older lines | `lco logs <id> -before <time>` (the value it printed) | `device_logs` (`before` from the last answer) |
| Which containers and services log | `lco logs <id> -sources` | `device_logs` (`sources: true`) |
| Follow the log | `lco logs <id> -f` (Ctrl-C ends it) | (call `device_logs` again) |
| Metrics, latest or as a series | `lco telemetry <id>` (`-from/-to/-interval`) | `device_telemetry` |
| Recent deployment and certificate events | `lco device activity <id>` | `device_activity` |
| What ran there before | `lco device versions <id>` | `device_versions` |
| What should run there | `lco deployments -device <id>` | `list_deployments` (`deviceId`) |

## Labels and device groups

Labels (key=value) and device groups (explicit device sets) decide what a
deployment reaches. Changing them can install or remove workloads, so change
them only when the user asks.

| Task | lco | MCP tool |
|---|---|---|
| Label keys in use, values of a key | `lco labels [key]` | `labels` (`key`) |
| Rename a device, change its labels (others are kept) | `lco device update <id> -name "<Name>" -label env=prod -unlabel old` | `update_device` |
| Set or remove labels on every device with some labels | `lco labels set -where site=a -label env=prod -dry-run` (`labels unset -where k=v -key k`) | `label_devices` set, unset (`where`, `dryRun`) |
| Rename a key or value everywhere (devices, selectors, alert rules) | `lco labels rename env stage`, `lco labels rename env=prod production` | `label_devices` rename-key, rename-value |
| Device groups, one with its members | `lco groups`, `lco group <id>` | `device_groups` (`id`) |
| Create, change, add or remove members, delete | `lco group create -name n`, `group update`, `group add <id> <deviceId>...`, `group remove <id> -name n <deviceId>...`, `group delete <id> -name n` | `manage_device_group` |
| Delete a device (the name is a confirmation) | `lco device delete <id> -name "<Name>"` | `delete_device` |

Run bulk label changes with `-dry-run` / `dryRun` first and show the user the
devices.

## Certificates, audit log, registries

| Task | lco | MCP tool |
|---|---|---|
| Certificates (a device's, expiring, by status or type) | `lco certs -device <id>`, `lco certs -expiring 30` | `certificates` |
| Revoke a device certificate (cannot be undone) | `lco cert revoke <deviceId> <certId> -reason "Superseded"` | `revoke_certificate` |
| Who changed what, an object's history | `lco audit -search x`, `lco audit -entity deployment/<id>` | `audit_log` (`entityType`, `entityId`) |
| Where the catalog comes from, last sync | `lco registries`, `lco registry oci <id> -history` | `registries` |
| Sync a registry now | `lco registry sync git <id>` | `sync_registry` |

Renewing a certificate is disabled in the API; there is no command for it.

## Anything else: the whole API

Everything else (users, roles, organization members, API keys, invitations,
CA certificates, ...) is reachable through the API's operations, taken from
the server's own OpenAPI spec. Look an operation up, read its parameters,
then call it:

| Task | lco | MCP tool |
|---|---|---|
| 1. Find operations by words (`-tags` lists the areas) | `lco ops api key` (`-tag Devices`) | `search_operations` (`query`, `tag`) |
| 2. Parameters and body schema | `lco op getExpiringCertificates -describe` | `describe_operation` |
| 3. Call it | `lco op getExpiringCertificates days=30` | `call_operation` (`params`) |
| ... with a body | `lco op updateOciRegistry id=<id> -d '{"name":"x"}'` | `call_operation` (`params`, `body`) |
| Raw request, not checked | `lco call GET /api/v1/...` | (none) |
| The spec in use | `lco spec` (`-refresh`) | (none) |

Unknown parameter names are refused, so a typo does not silently drop a
filter. Calls other than reads (POST, PUT, PATCH, DELETE) change the
organization: make them only when the user asked for that change. A server
started read-only only offers GET operations.

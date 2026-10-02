---
name: logiccloud-orchestrate
description: Use when working with logiccloud orchestrate (formerly Fleet Manager) - edge devices and their status, labels, logs and telemetry, fleet health, the application catalog, certificates, registries, users, API keys, audit logs, or any call to the orchestrate REST API. Covers both the lco CLI and the orchestrate MCP server (logiccloud-orchestrate).
---

# logiccloud orchestrate

orchestrate manages a fleet of edge devices (Margo) and deploys container
applications to them, among them the logiccloud Control runtime. It is not
logiccloud control: `lc` and the `logiccloud-control` server edit and build
PLC projects; orchestrate manages devices and what runs on them.

There are two ways in, and both use an API key. Use whichever is there:

- **The `lco` CLI.** If it says there is no API key, ask the user to run
  `lco login -domain <domain>` (the root domain of their orchestrate
  installation) or to set `LCO_API_KEY`.
- **The MCP server `logiccloud-orchestrate`.** The key is set where the
  server is configured. A 401 means it is missing or wrong; ask the user to
  fix it in their agent's configuration.

A 403 names the permission the key lacks (e.g. `telemetry:read`,
`fleet:read`). Tell the user; do not look for another key.

## Look around

| Task | lco | MCP tool |
|---|---|---|
| Online/offline/error counts, averages, hot spots | `lco fleet` | `fleet_health` |
| Devices: status, last seen, CPU/mem/disk, workloads, labels | `lco devices` (`-status ONLINE -label k=v -search x`) | `list_devices` |
| One device: capabilities, labels, latest telemetry | `lco device <id>` | `get_device` |
| The application catalog (synced from Git/OCI registries) | `lco apps` | `list_applications` |
| An application's versions (version ID, profile) | `lco app <id>` | `get_application` |
| What is deployed where | `lco deployments` | `list_deployments` (see the deployments skill) |

Lists are paged: with `lco`, `-all` fetches everything and `-json` gives the
raw objects; the tools take `limit` and return `nextCursor` while `hasMore`
is true.

## A device misbehaves

| Task | lco | MCP tool |
|---|---|---|
| ONLINE? Last seen? Running workloads? | `lco device <id>` | `get_device` |
| Errors in its log (oldest first) | `lco logs <id> -severity ERROR` (`-source <container>`, `-q <text>`, `-lines 500`) | `device_logs` (severity, source) |
| Which containers and services log | `lco logs <id> -sources` | (the `source` of the lines `device_logs` returns) |
| Follow the log | `lco logs <id> -f` (Ctrl-C ends it) | (call `device_logs` again) |
| Metrics, latest or as a series | `lco telemetry <id>` (`-from/-to/-interval`) | `device_telemetry` |
| What should run there | `lco deployments -device <id>` | `list_deployments` (device) |

## Change a device

| Task | lco | MCP tool |
|---|---|---|
| Rename | `lco device update <id> -name "<Name>"` | `update_device` |
| Labels (other labels are kept) | `lco device update <id> -label env=prod -unlabel old` | `update_device` |
| Delete (the name is a confirmation) | `lco device delete <id> -name "<Name>"` | `delete_device` |

Labels decide which devices a label-targeted deployment reaches, so changing
them can install or remove workloads. Change or delete devices only when the
user asks for it.

## Everything else: the whole API

The API has 206 operations: groups and label queries, device and CA
certificates, Git/OCI registries and their sync, users, roles, organization
members, API keys, invitations, audit logs, activity.

| Task | lco | MCP tool |
|---|---|---|
| Find operations by words | `lco ops certificate` (`lco ops -tags` lists the areas) | `search_operations` |
| Parameters and body schema | `lco op getExpiringCertificates -describe` | `describe_operation` |
| Call one | `lco op getExpiringCertificates days=30` | `call_operation` (params) |
| With a body | `lco op updateOciRegistry id=<id> -d '{"name":"x"}'` | `call_operation` (params, body) |
| Raw request | `lco call GET /api/v1/...` | `call_operation` |

Unknown parameter names are refused, so a typo does not silently drop a
filter. Calls other than reads (POST, PUT, PATCH, DELETE) change the
organization: make them only when the user asked for that change. A server
started read-only only offers GET operations.

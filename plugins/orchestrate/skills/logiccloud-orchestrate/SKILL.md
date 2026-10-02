---
name: logiccloud-orchestrate
description: Use when working with logiccloud orchestrate (formerly Fleet Manager) through the lco CLI - edge devices and their status, labels, logs and telemetry, fleet health, the application catalog, certificates, registries, users, API keys, audit logs, or any call to the orchestrate REST API.
---

# logiccloud orchestrate with lco

orchestrate manages a fleet of edge devices (Margo) and deploys container
applications to them, among them the logiccloud Control runtime. `lco` talks to
its REST API with an API key. It is not `lc`: `lc` edits and builds PLC
projects in logiccloud control; `lco` manages devices and what runs on them.

If a command says there is no API key, ask the user to run
`lco login -domain <domain>` (the root domain of their orchestrate
installation) or to set `LCO_API_KEY`. A 403 names the permission the key
lacks (e.g. `telemetry:read`, `fleet:read`); tell the user, do not look for
another key.

Without `lco`, the orchestrate MCP server (`logiccloud-orchestrate`) offers
the same as tools (`list_devices`, `device_logs`, `fleet_health`,
`create_deployment`, `search_operations`/`call_operation` for the whole API,
...). The rules below apply to both.

## Look around

    lco devices                          # status, last seen, CPU/mem/disk, workloads, labels
    lco devices -status ONLINE -label location=Sibiu -search rpi
    lco device <id>                      # capabilities, labels, latest telemetry
    lco fleet                            # online/offline/error counts, averages, hot spots
    lco apps                             # the catalog (synced from Git/OCI registries)
    lco app <id>                         # its versions: version ID, profile (DOCKER_COMPOSE, HELM)
    lco deployments                      # what is deployed where; see the deployments skill

Lists are paged: `-all` fetches everything, `-json` gives the raw objects.

## A device misbehaves

    lco device <id>                      # ONLINE? last seen? running workloads?
    lco logs <id> -severity ERROR        # oldest first; -source <container>, -q <text>, -lines 500
    lco logs <id> -sources               # which containers/services log
    lco logs <id> -f                     # follow (Ctrl-C ends it)
    lco telemetry <id>                   # latest metrics; -from/-to/-interval for a series
    lco deployments -device <id>         # what should run there, per-instance status

## Change a device

    lco device update <id> -name "<Name>"
    lco device update <id> -label env=prod -unlabel old   # other labels are kept

Labels decide which devices a label-targeted deployment reaches, so changing
them can install or remove workloads. Only on the user's request, as with
`lco device delete <id> -name "<Name>"` (the name is a confirmation).

## Everything else: the whole API

`lco` embeds the API's OpenAPI spec (206 operations): groups and label
queries, device and CA certificates, Git/OCI registries and their sync, users,
roles, organization members, API keys, invitations, audit logs, activity.

    lco ops certificate                  # search by words; lco ops -tags lists the areas
    lco op getExpiringCertificates -describe   # parameters and body schema
    lco op getExpiringCertificates days=30     # name=value: path and query parameters
    lco op updateOciRegistry id=<id> -d '{"name":"x"}'   # -d JSON, @file or - (stdin)

`op` refuses parameter names the spec does not know, so a typo does not
silently drop a filter. Calls other than reads (POST, PUT, PATCH, DELETE)
change the organization: make them only when the user asked for that change.
`lco call GET /api/v1/...` is the raw escape hatch.

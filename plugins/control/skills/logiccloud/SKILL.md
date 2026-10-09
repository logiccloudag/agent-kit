---
name: logiccloud
description: Use when working on a logiccloud PLC project - finding, creating or pulling a project, writing IEC 61131-3 Structured Text, building it in the cloud (and finding failed builds), tasks and program configurations, Inputs/Outputs pragmas, libraries, or anything else in the logiccloud GraphQL API (schema lookup, raw queries). Covers both the lc CLI and the logiccloud MCP server (logiccloud-control).
---

# logiccloud projects

There are two ways to work on a project. Use whichever is available; if both
are, prefer `lc`, because the files stay in a local directory under version
control.

- **The `lc` CLI** keeps a project in a local directory (a workspace) and
  builds it in the cloud. It is logged in once per machine
  (`lc login -domain <domain>`, with the root domain of the user's
  installation). If a command says there is no token, ask the user to run
  `lc login`.
- **The MCP server `logiccloud-control`** offers the same as tools, working
  directly on the project in the cloud. If the tools are missing or say the
  user is not logged in, ask the user to log in through their agent (`/mcp`
  in Claude Code, `codex mcp login logiccloud-control`,
  `opencode mcp auth logiccloud-control`).

| Task | lc | MCP tool |
|---|---|---|
| Find a project | `lc projects -keyword <word>` | `list_projects` |
| Show one | `lc project <id>` | `get_project` |
| New project | `lc init -name "<Name>" -dir <dir>` | `create_project` |
| New library | `lc init -name "<Name>" -type plcLibrary -dir <dir>` | `create_project` with type `plcLibrary` |
| Get the sources | `lc pull <projectId>` in an empty directory | `list_files`, `read_files` |
| Change and build | edit the files, then `lc check` | `write_files` with `build: true` |
| Only build | `lc build` | `build` |
| Earlier builds (e.g. the failed ones) | `lc builds -project <id> -status failed` | `list_builds` (`statuses`) |
| Libraries | `lc libraries`, `lc library add/remove <name>` | `list_libraries`, `add_library`, `remove_library` |

Paths are the same both ways: `pous/<folders>/<Name>.st` (one PROGRAM,
FUNCTION_BLOCK or FUNCTION per file, file name = POU name),
`dataTypes/<Name>.st`, `globalVariables/<Name>.st`,
`configuration/<Name>.json` (tasks and program configurations),
`alarming/<Name>.json` (alarm settings), `libraries/...` (read-only) and
`hmi/<Name>.page.json`. The full rules
(layout, pragmas, configuration format, HMI format) are in the workspace's
AGENTS.md (CLAUDE.md for Claude Code) with `lc`, and in the MCP server's
instructions with the tools. Read them before editing, and follow them.

## The loop

1. Write Structured Text, and `configuration/<Name>.json` for tasks and
   program configurations.
2. Build. `lc check` pushes and builds; `write_files` with `build: true`
   writes and builds. Both report `file:line:col: message`; `lc check` exits
   1 on errors. Fix and repeat until the build passes (3-15 s per build).
3. With `lc`, `lc status` shows local changes without network access. With
   the tools, `write_files` takes complete files, and refuses to overwrite a
   file someone changed in the portal meanwhile: read it again and redo the
   change.

## Rules that matter

- A PROGRAM only runs when a program configuration assigns it to a task
  (`configuration/<Name>.json`).
- Variables become Inputs/Outputs through pragmas: `speed : REAL {IN HMI};`,
  `running : BOOL {OUT HMI};`, `mode : INT {IN_OUT HMI};` (named `mode_OUT`
  under Inputs/Outputs). `HMI` makes them usable in HMI pages.
- `libraries/` is read-only: those function blocks can be used, not changed.
  To change a library, open the library project itself. A library cannot be
  built on its own: with `lc`, run `lc check -with <dir or ID of a project
  that uses it>` in its workspace; with the tools, `write_files` with
  `buildProjectId` set to such a project.
- A passing build does not check mixed-type arithmetic or numbers assigned to
  BOOL; write explicit conversions.
- The project is shared. Unless the user asked for exactly that, never:
  use `-force` or `-prune` (`prune` in the tools), add or remove libraries,
  delete files, or delete a project or runtime (`lc project delete`,
  `lc runtime delete`, `delete_project`, `delete_runtime`).

## Anything else: the GraphQL API

Use the commands and tools above where they fit. For anything else, run a
raw query, but look the names up first instead of guessing them:

| Task | lc | MCP tool |
|---|---|---|
| Find fields, types, enum values by words | `lc schema -search "modbus unit"` | `search_schema` |
| One type or root field: arguments, input types, enums | `lc schema -type Mutation.createRuntime` | `describe_schema` |
| Run a query or mutation | `lc query '<GraphQL>'` (`-vars '{...}'`, or `@file`) | `graphql` (`variables`) |

An error about an unknown field, argument or type names the type to look
at: describe it and fix the query. A mutation changes the shared
organization: only for what the user asked.

## Other skills

- logiccloud-hmi: HMI pages.
- logiccloud-devices: deploying, starting and stopping runtimes, health,
  logs, live variable values, device maintenance actions.
- logiccloud-connections: MQTT, Modbus, OPC UA and other connections and
  their variable mappings.
- logiccloud-alarms: alarm settings, acknowledging or shelving alarms on a
  device, alarm e-mail notifications.

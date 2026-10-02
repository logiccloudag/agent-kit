---
name: logiccloud
description: Use when working on a logiccloud PLC project with the lc CLI - finding, creating or pulling a project, writing IEC 61131-3 Structured Text, building it in the cloud, tasks and program configurations, Inputs/Outputs pragmas, libraries.
---

# logiccloud projects with lc

`lc` edits a logiccloud project in a local directory and compiles it in the
cloud. It is logged in once per machine (`lc login -domain <domain>`, with
the root domain of the user's installation); if a command says there is no
token, ask the user to run `lc login`.

Without `lc`, the logiccloud MCP server (`logiccloud-control`) offers the same
as tools (`list_projects`, `read_files`, `write_files` with a build, `deploy`,
...); its instructions say how. Use the CLI when both are there: a local
workspace keeps the files under version control.

## Get a workspace

    lc projects -keyword <word>        # find a project, note its ID
    mkdir <name> && cd <name>
    lc pull <projectId>                # sources, configuration, HMI pages, libraries

    lc init -name "<Name>" -dir <dir>  # or: a new project from the portal's template
    lc init -name "<Name>" -type plcLibrary -dir <dir>   # a library for other projects

A workspace has its own AGENTS.md (CLAUDE.md for Claude Code) with the full
rules (layout, pragmas, configuration, HMI format). Read it before editing, and
follow it.

## The loop

1. Edit `.st` files under `pous/`, `dataTypes/`, `globalVariables/`, and
   `configuration/<Name>.json` for tasks and program configurations.
2. `lc check` pushes and builds; it prints `file:line:col: message` and exits 1
   on errors. Fix and repeat until it passes (3-15 s per build).
3. `lc status` shows local changes without network access.

## Rules that matter

- A PROGRAM only runs when a program configuration assigns it to a task
  (`configuration/<Name>.json`).
- Variables become Inputs/Outputs through pragmas: `speed : REAL {IN HMI};`,
  `running : BOOL {OUT HMI};`, `mode : INT {IN_OUT HMI};` (named `mode_OUT`
  under Inputs/Outputs). `HMI` makes them usable in HMI pages.
- `libraries/` is read-only: those function blocks can be used, not changed.
  To change a library, pull the library project itself. A library cannot be
  built on its own: in its workspace, `lc check -with <dir or ID of a project
  that uses it>`.
- A passing build does not check mixed-type arithmetic or numbers assigned to
  BOOL; write explicit conversions.
- The project is shared. Never use `-force` or `-prune`, and never
  `lc library add/remove`, `lc project delete` or `lc runtime delete`, unless the
  user asked for exactly that.

For HMI pages use the logiccloud-hmi skill; for devices, deploying, logs and
connections the logiccloud-devices skill.

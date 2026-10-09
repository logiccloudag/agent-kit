# logiccloud ST project

This directory is a local checkout of a logiccloud PLC project, synced with the
`lc` CLI. Write IEC 61131-3 Structured Text here and compile it in the cloud.

## Layout

- `pous/<folders>/<Name>.st` — one PROGRAM, FUNCTION_BLOCK or FUNCTION per file.
  The file name must equal the POU name. Subfolders become folders in the project.
- `dataTypes/<Name>.st` — `TYPE ... END_TYPE` blocks. A file may hold several
  related types; the file name does not have to match a type name.
- `globalVariables/<Name>.st` — `VAR_GLOBAL ... END_VAR`. Use them from a POU
  via `VAR_EXTERNAL`.
- `configuration/<Name>.json` — tasks, program configurations and config
  variables (see below).
- `alarming/<Name>.json` — the project's alarm settings, if it has any, e.g.
  `{"enabled": true, "maxAlarms": 100, "maxHistory": 500}`. The alarms
  themselves are ST (`ST_Alarm` values passed to `RPC_CALL('alarm', 'set', ...)`).
- `libraries/<Library>/...` — sources of the libraries the project uses,
  read-only. Their function blocks and functions can be used directly.
- `.lc.json` — sync state. Do not edit it.

## Inputs/Outputs and HMI variables

A variable becomes an input or output of the runtime (listed under
Inputs/Outputs in the portal, usable by connections and the HMI) through a
pragma after its type:

    VAR_INPUT
        temperature : REAL {IN HMI};         (* written from outside, shown in HMI *)
    END_VAR
    VAR_OUTPUT
        pumpOn : BOOL {OUT HMI};             (* read from outside, shown in HMI *)
        total : INT {OUT HMI RESET_TO 0};    (* reset value 0 *)
    END_VAR
    VAR
        mode : INT := 1 {IN_OUT HMI};        (* read and written *)
        tuning : REAL {IN INTERNAL HMI};     (* internal, not for connections *)
    END_VAR

- Direction: `IN`, `OUT` or `IN_OUT`. Add `HMI` to make it available in the HMI.
- Works in PROGRAMs, and in FUNCTION_BLOCKs for each instance declared in a program.
- `lc push`/`lc check` update the Inputs/Outputs list from these pragmas.
  Entries are added and updated, and only removed when their program
  configuration is gone.

## HMI pages

If the project has an HMI (project type plcHmi), pages live in `hmi/`:

- `hmi/<Name>.page.json` — a page you can edit. `lc push`/`lc check` turn it
  into the portal's page format; do not write that format yourself.
- `hmi/<Name>.portal.json`, `hmi/<Name>.template.json` — made in the portal,
  read-only. Use them as examples. To change one, write a new `.page.json`.
- `hmi/COMPONENTS.md` — all component types with their properties, the
  properties that bind variables, and typical sizes. Read it before writing a page.
- `DESIGN.md` — how pages look here: colors, type sizes, spacing, status
  colors, which component to use for what, and an example page. Follow it.

A page:

    {
      "name": "Overview",                 (* must equal the file name *)
      "default": true,                    (* start page *)
      "background": "#f4f6f8",
      "components": [
        {"type": "LcLabel", "x": 40, "y": 30, "w": 600, "h": 40,
         "props": {"text": "Tank control", "fontSize": 28}},
        {"type": "LcGauge", "x": 40, "y": 100, "w": 260, "h": 270,
         "props": {"label": "Level", "unit": "%", "min": 0, "max": 100, "valueVariable": "level"}},
        {"type": "LcNumericInput", "x": 600, "y": 100, "w": 220, "h": 79,
         "props": {"label": "Setpoint", "targetVariable": "setpoint"}},
        {"type": "LcPanel", "x": 40, "y": 400, "w": 400, "h": 200, "props": {"text": "Details"},
         "children": [ ... positioned relative to the panel ... ]}
      ]
    }

- Positions and sizes are pixels on the Desktop breakpoint (1920×1080).
  Override them per breakpoint with `"layouts": {"Mobile": {"x": 0, "w": 375}}`.
- Only set the properties you need; unset ones use the component's defaults.
- Bind variables by their name under Inputs/Outputs, i.e. the ST variable
  name (`<instance>_<member>` for FB members, `<var>_OUT` for IN_OUT). The
  variable needs `HMI` in its pragma. Displays (`valueVariable`, `textVariable`,
  `stateVariable`) read `{OUT HMI}` variables; inputs (`targetVariable`) write
  `{IN HMI}` variables.
- LcStateIndicator, LcShape, LcButton, LcLabel and other components with a
  `states` property only change their look with their `stateVariable`
  through `states`; without states they never change (`lc check` warns).
  LcToggleButton (on/off colors, `toggleStates`), LcStateImage, LcSvg and
  lines have their own state properties and need no `states`. The first entry without `value` is the default
  (for BOOL: FALSE); BOOL TRUE is `1`:

      "props": {"stateVariable": "pumpOn",
                "states": [{"color": "#b8b7b8"},
                           {"value": 1, "color": "#8bc34a"}]}

  Keys per state: `value`, `color` (background), `textColor`, `borderColor`,
  `opacity`, `blink`, `image`. lc writes the portal's full state format.
- Leave out `id` and `wrapperId`: lc assigns them on the first push and writes
  them back into the file. Keep them after that.
- `lc check` reports unknown variables, variables without `HMI`, duplicate
  IDs and missing sizes as `hmi/<Name>.page.json: error: ...`. It cannot show
  you the page: tell the user to look at it in the portal.

## Library projects

If this workspace is a library (project type plcLibrary, made with
`lc init -type plcLibrary`), it holds function blocks, functions and types
for other projects: no programs, no configuration, no HMI. The backend cannot
build a library on its own, so check its code by building a project that uses
it: `lc check -with <workspace dir or project ID>` pushes the library and
builds that project (as it is on the server). A project uses a library after
`lc library add "<library name>"` in its workspace.

## Tasks and program configurations

A PROGRAM only runs if a program configuration assigns it to a task.
`configuration/<Name>.json` holds them, per resource:

    {
      "resources": [
        {
          "name": "my_app",
          "processorType": "Nano",
          "tasks": [
            {"name": "my_task", "interval": 500, "priority": 1},
            {"name": "fast", "interval": 10, "priority": 0}
          ],
          "programs": [
            {"name": "my_program_config", "taskName": "my_task", "programName": "my_program"},
            {"name": "fast_config", "taskName": "fast", "programName": "fast_program"}
          ]
        }
      ],
      "configVariables": [
        {"path": "my_app.my_program_config.LIMIT", "type": "INT", "initialValue": "10"}
      ]
    }

- `interval` is in milliseconds. Tasks are cyclic; event tasks (`single`)
  are not used in any project so far, so set them up in the portal.
- A program configuration names its task and the PROGRAM it runs. The same
  PROGRAM can run in several program configurations (separate instances).
- `configVariables` set initial values of program variables, by path
  `<resource>.<program configuration>.<variable>`; `initialValue` is ST
  (`"'text'"` for STRING).
- `lc push`/`lc check` check the file first (task names, the PROGRAM exists,
  paths) and push nothing if it has errors. Removing a task, program
  configuration, resource or config variable only takes effect with
  `lc push -prune`; only do that if the user asked for it.
- Build errors in `configurations/<Name>.st` are about this file.
- Function blocks and functions need no configuration.

## Edit, compile, repeat

After every change, run:

    lc check

This uploads changed and new `.st` files, builds the project, and prints
diagnostics in the form `file:line:col: message`, with paths relative to this
directory. Exit code 0 means the build succeeded. Fix the reported errors and
run `lc check` again until it passes. A build takes about 3–15 seconds.

- `lc status` lists local changes (no network).
- `lc check -json` prints the result as JSON.
- Ignore `TypeError: Cannot read properties of undefined (...)` errors.
  They are follow-up crashes of the transpiler after a real error. Fix the
  other errors first.

## What the build does NOT catch

A passing build means the code transpiles and compiles, not that it is correct.
The checker accepts:

- mixed-type arithmetic, e.g. `intVar := intVar + 1.5;`
- assigning numbers to BOOL, e.g. `boolVar := 7;` or `boolVar := intVar;`

So write explicit conversions (`INT_TO_REAL`, `REAL_TO_INT`, `x <> 0`, ...) and
keep types consistent yourself.

## Deploying to a device

Only when the user asks for it:

    lc devices                 # find the device
    lc deploy -device <id>     # install/update the latest successful build and start it
    lc stop -device <id>       # / lc start -device <id>

To see how a deployed runtime is doing (read-only, any time):

    lc health -device <id>                # runtime state, why it is not started, installed build
    lc logs -device <id> -level warn      # the runtime's log (-target <process> for others)

Connections (MQTT, Modbus, OPC UA, ...) map Inputs/Outputs to the outside. They
belong to a runtime, not to this directory:

    lc connections                        # of this project's runtimes
    lc connection <id>                    # settings, units/payloads/subscriptions, mappings
    lc connection <id> -definition > c.json   # edit it, then:
    lc connection update <id> -f c.json   # replaces the whole connection
    lc connection copy <id> -runtime <id> -name <n>   # with sub-objects and mappings

Most types keep their mappings outside the definition, in sub-objects
(`lc connection object`) or lists (`lc connection mappings`); `lc connection
types` says which.

Live values of the running program: `lc vars -device <id>` (read-only);
`lc write -device <id> <variable> <value>` changes a running machine, so only
when the user asks for it.

`lc connection delete` and `lc runtime delete`/`lc project delete` want the
object's name with `-name`, and delete for good. Only for what the user asked.

Run `lc check` first; deploy uses the latest successful build. Never pass
`-replace` (it replaces another project's runtime on the device) unless the
user said so.

## Safety

This project is shared. `lc check` never overwrites files that someone changed
in the portal since the last sync; it stops and asks for `lc pull`. Do not use
`lc push -force`, `lc pull -force` or `lc push -prune` (deletes project files
and configuration entries) unless the user asked for it. `lc library add` and
`lc library remove` change the project for everyone; ask first.

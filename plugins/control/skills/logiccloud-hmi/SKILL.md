---
name: logiccloud-hmi
description: Use when creating or changing HMI pages of a logiccloud project (hmi/*.page.json) - layout, colors, styles, which component to use, variable bindings and states. Covers both the lc CLI and the logiccloud MCP server (logiccloud-control).
---

# logiccloud HMI pages

Pages are `hmi/<Name>.page.json` files of a project (see the logiccloud
skill). With `lc` they are files in the workspace and `lc check` uploads
them. With the MCP server `logiccloud-control` you write them with
`write_files`. Either way they are validated, turned into the portal's format
and uploaded. You cannot see the result: tell the user to look at the page in
the portal.

## Before you write a page

1. Read the design guide: [DESIGN.md](DESIGN.md), or the `hmi_design` tool.
   It covers colors, type sizes, spacing, status colors and which component
   to use for what. Follow it, so the page fits the other pages.
2. Look up the components you use: [COMPONENTS.md](COMPONENTS.md), or the
   `hmi_components` tool. It lists their properties, the properties that bind
   variables, and typical sizes.
3. Check the page format: in the workspace's AGENTS.md or CLAUDE.md
   ("HMI pages") with `lc`, in the server's instructions with the tools.
4. Make sure every variable you bind is declared with `HMI` in its pragma
   (`{OUT HMI}` for displays, `{IN HMI}` for inputs, `{IN_OUT HMI}` for both)
   and is built into the project. Bind it by its Inputs/Outputs name: the ST
   name, but `<instance>_<member>` for function block members and
   `<var>_OUT` for IN_OUT variables. The checks list the valid names when one
   is wrong.

## Writing it

- Start from the example in the design guide and change it; do not invent
  properties.
- Positions in px on the Desktop breakpoint (1920×1080), on a 10 px grid.
- Status lamps and other components with a `stateVariable` need `states`;
  LcToggleButton, LcStateImage, LcSvg and lines have their own state
  properties instead.
- Leave out `id` and `wrapperId` on new components. The first upload adds
  them: `lc check` writes them back into the file; `write_files` returns the
  page under `updatedFiles`. Keep them after that.
- `hmi/*.portal.json` pages were made in the portal and are read-only. Use
  them as examples of what the user's HMI already looks like, and match their
  style where they differ from the design guide.
- Upload and fix every `hmi/<Name>.page.json: error: ...`: `lc check`, or
  `write_files` with `build: true`.

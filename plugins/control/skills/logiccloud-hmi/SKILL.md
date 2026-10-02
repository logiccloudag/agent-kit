---
name: logiccloud-hmi
description: Use when creating or changing HMI pages of a logiccloud project (hmi/*.page.json) - layout, colors, styles, which component to use, variable bindings and states.
---

# logiccloud HMI pages

Pages are `hmi/<Name>.page.json` files in an lc workspace (see the logiccloud
skill). `lc check` validates them, turns them into the portal's format and
uploads them. You cannot see the result: tell the user to look at the page in
the portal.

## Before you write a page

1. Read [DESIGN.md](DESIGN.md): colors, type sizes, spacing, status colors and
   which component to use for what. Follow it, so the page fits the other pages.
2. Look up the components you use in [COMPONENTS.md](COMPONENTS.md): their
   properties, the properties that bind variables, and typical sizes.
3. Check the page format in the workspace's AGENTS.md or CLAUDE.md ("HMI pages").
4. Make sure every variable you bind is declared with `HMI` in its pragma
   (`{OUT HMI}` for displays, `{IN HMI}` for inputs, `{IN_OUT HMI}` for both)
   and pushed. Bind it by its Inputs/Outputs name: the ST name, but
   `<instance>_<member>` for function block members and `<var>_OUT` for
   IN_OUT variables. `lc check` lists the valid names when one is wrong.

## Writing it

- Start from the example in DESIGN.md and change it; do not invent properties.
- Positions in px on the Desktop breakpoint (1920×1080), on a 10 px grid.
- Status lamps and other components with a `stateVariable` need `states`;
  LcToggleButton, LcStateImage, LcSvg and lines have their own state
  properties instead.
- Leave out `id` and `wrapperId` on new components; `lc check` adds them and
  writes them back into the file. Keep them after that.
- `hmi/*.portal.json` pages were made in the portal and are read-only; use them
  as examples of what the user's HMI already looks like, and match their style
  when they differ from DESIGN.md.
- Run `lc check` and fix every `hmi/<Name>.page.json: error: ...`.

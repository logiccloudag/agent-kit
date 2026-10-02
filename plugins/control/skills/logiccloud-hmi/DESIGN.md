# logiccloud HMI design

How HMI pages on logiccloud look, so new pages fit in: colors, type, spacing,
states and which component to use for what. The palette is the portal's default
theme ("Light"); the other values are what the 742 HMI pages on dev (11,763
components) use most. Component properties and sizes are in COMPONENTS.md; the
page format is in the workspace's AGENTS.md (or CLAUDE.md).

## Canvas and layout

- Design on the Desktop breakpoint, 1920×1080. Tablet (768×1024) and Mobile
  (375×812) inherit it; override with `"layouts": {"Mobile": {...}}` where the
  Desktop layout does not fit.
- Positions and sizes on a 10 px grid. Keep 20 px from the page edges and 20 px
  between groups, 10 px between controls inside a group.
- A page has one purpose (overview, one machine, settings, alarms). Title or
  header at the top, the most important values top left, commands at the right or
  bottom.
- Put a header across the top for multi-page HMIs: `LcHeader` at 0,0, 1920×60,
  with `LcNavigationItem`s in it (or an `LcSideBar` on the left). Content starts
  at y = 80.
- Group what belongs together in an `LcPanel`; children are positioned relative
  to the panel. Align controls in a group to the same left edge and the same
  width.
- Leave room: a page that fills every pixel is hard to read on a machine.

## Colors

Light (default; page background `#f7f8fa`, panels white):

| Role | Color | Use |
|---|---|---|
| Primary | `#0f5978` | header, navigation, primary buttons, panel headers |
| Accent | `#0fa6e5` | active navigation item, checked toggles, gauge fill, focus |
| Page background | `#f7f8fa` | `"background"` of the page |
| Surface | `#ffffff` | panels, outputs, inputs |
| Subtle surface | `#f5f5f5` | input buttons, off toggles, indicator background |
| Border | `#cccccc` | 1 px borders of controls; `#ebebeb` for dividers |
| Text | `#424242` | values and labels on light surfaces |
| Text on primary | `#ffffff` | anything on `#0f5978` or on dark pages |
| Muted text | `#77919d` | units, secondary labels, disabled |
| Success | `#8bc34a` | running, OK, on |
| Warning | `#ff871f` | attention, limit reached |
| Danger | `#cf252c` | fault, alarm, emergency stop |
| Info | `#29b6f6` | notes, maintenance |

Dark (the portal's "Dark" theme; the most common custom page background on dev):

| Role | Color |
|---|---|
| Page background | `#07344f` |
| Surface | `#022f49` (panels), `#003857` (raised) |
| Border | `#ffffff73` |
| Text | `#ffffff` |
| Primary, accent | `#0f5978`, `#0fa6e5` |
| Success, warning, danger | `#5ca90d`, `#d78201`, `#b53209` |

Use one scheme per HMI. Transparent is `#ffffff00` (labels on panels).

## Status colors

Machines are read by color first, so use them the same way everywhere:

| State | Color | Notes |
|---|---|---|
| Off, idle, unknown | `#b8b7b8` (dark: `#9e9e9e`) | the default state entry |
| Running, on, OK | `#8bc34a` | |
| Attention, warning | `#ff871f` | yellow `#fce742` is common for "standby" lamps |
| Fault, alarm | `#cf252c` | add `"blink": true` only for alarms that need action |

Never show a state by color alone: put a label next to the indicator ("Pump",
"Heater") or text in it. Indicators, shapes, buttons and labels with a
`stateVariable` need `states` (toggle buttons, state images and lines have
their own state properties; see AGENTS.md), e.g.

    "states": [{"color": "#b8b7b8"},
               {"value": 1, "color": "#8bc34a"}]

## Type

No custom fonts; sizes in px (`fontSize`, `labelFontSize`, `valueFontSize`):

| Use | Size |
|---|---|
| Page title | 24 (32 for a single-machine overview) |
| Group title, panel header | 18 |
| Labels, values, buttons (default) | 16 |
| Secondary text, units, navigation | 14 |
| Key value on an overview (tank level, speed) | 32 to 48 |

Text `#424242` on light surfaces, `#ffffff` on primary or dark. Labels left
aligned, values right aligned or centered, units in `unit`, not in the label.

## Shape

- Border radius: 3 px for controls (default), 10 px for panels and cards, 0 for
  headers and full-width bars, 20 px for pills.
- Borders: 1 px `#cccccc` on controls; none on labels (`"borderWidth": "0px"`).
- Padding: 10 px inside panels (`"padding": "10px 10px 10px 10px"`).
- No shadows except to lift a popup.

## Which component

| Need | Component | Binds |
|---|---|---|
| Title, static text, label | `LcLabel` | `textVariable` for dynamic text |
| Number from the PLC | `LcOutput` (with `label`, `unit`, `precision`) | `valueVariable` |
| Level, speed, a key value | `LcGauge`, `LcVerticalGauge`, `LcLinearGauge`, `LcThermometer` | `valueVariable`, `min`/`max` |
| Setpoint | `LcNumericInput` (`min`, `max`, `step`) | `targetVariable` |
| Text input | `LcStringInput` | `targetVariable` |
| Choice | `LcDropdown`, `LcCheckbox` | `targetVariable` |
| Start, stop, reset (momentary) | `LcButton` | `targetVariable` |
| On/off (latching) | `LcToggleButton` | `targetVariable`, `stateVariable` |
| Status lamp | `LcStateIndicator` | `stateVariable` + `states` |
| Tank, machine drawing | `LcShape`, `LcStateImage`, `LcImage` | `stateVariable` |
| Pipes, flow lines | `LcLine`, `LcPipe`, `LcVerticalPipe`, `LcPolyline` | `stateVariable` |
| Grouping | `LcPanel` (`hasHeader`, `text` for a titled group) | |
| Navigation | `LcHeader` + `LcNavigationItem`, or `LcSideBar`, `LcNavigation` | `targetPage` |
| Alarms | `LcAlarmBanner`, `LcAlarmList`, `LcAlarmIndicator`, `LcAlarmCountBadge` | |
| Trends | `LcGrafanaChart` | |
| Date and time | `LcClock`, `LcDateTimeOutput` | |

Displays read `{OUT HMI}` variables, inputs write `{IN HMI}` variables. Bind by
the Inputs/Outputs name: `<var>_OUT` for an `{IN_OUT HMI}` variable,
`<instance>_<member>` for a function block member.
Prefer one `LcOutput` with `label` and `unit` over a separate label and value.

## Example

A light overview page with a header, a value group and commands:

    {
      "name": "Overview",
      "default": true,
      "background": "#f7f8fa",
      "components": [
        {"type": "LcHeader", "x": 0, "y": 0, "w": 1920, "h": 60,
         "props": {"backgroundColor": "#0f5978", "borderRadius": "0px"}},
        {"type": "LcLabel", "x": 20, "y": 10, "w": 600, "h": 40,
         "props": {"text": "Tank 1", "fontSize": 24, "color": "#ffffff", "borderWidth": "0px"}},
        {"type": "LcPanel", "x": 20, "y": 80, "w": 400, "h": 300,
         "props": {"backgroundColor": "#ffffff", "borderColor": "#cccccc", "borderRadius": "10px",
                   "hasHeader": true, "headerBackgroundColor": "#0f5978", "text": "Process"},
         "children": [
           {"type": "LcOutput", "x": 10, "y": 50, "w": 380, "h": 40,
            "props": {"label": "Level", "unit": "%", "precision": 1, "valueVariable": "level"}},
           {"type": "LcOutput", "x": 10, "y": 100, "w": 380, "h": 40,
            "props": {"label": "Temperature", "unit": "°C", "precision": 1, "valueVariable": "temperature"}},
           {"type": "LcNumericInput", "x": 10, "y": 150, "w": 380, "h": 79,
            "props": {"label": "Setpoint", "min": 0, "max": 90, "targetVariable": "setpoint"}}]},
        {"type": "LcStateIndicator", "x": 440, "y": 80, "w": 60, "h": 60,
         "props": {"stateVariable": "pumpOn",
                   "states": [{"color": "#b8b7b8"}, {"value": 1, "color": "#8bc34a"}]}},
        {"type": "LcLabel", "x": 510, "y": 95, "w": 200, "h": 30,
         "props": {"text": "Pump", "color": "#424242", "borderWidth": "0px"}},
        {"type": "LcButton", "x": 440, "y": 160, "w": 120, "h": 40,
         "props": {"text": "Start", "backgroundColor": "#0f5978", "color": "#ffffff", "targetVariable": "start"}},
        {"type": "LcButton", "x": 580, "y": 160, "w": 120, "h": 40,
         "props": {"text": "Stop", "backgroundColor": "#cf252c", "color": "#ffffff", "targetVariable": "stop"}}
      ]
    }

## Before writing a page

- Every bound variable exists under Inputs/Outputs with `HMI` in its pragma.
- Positions on the 10 px grid, 20 px margins, groups aligned.
- Colors from the tables above; one scheme for the whole HMI.
- Every status lamp has `states` and a label.
- Values have a `unit` and a sensible `precision`.
- Nothing overlaps unless it is a child of a panel.

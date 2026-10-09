---
name: logiccloud-alarms
description: Use when working with alarms of a logiccloud PLC project - raising them in Structured Text (ST_Alarm), the project's alarm settings (alarming/*.json), acknowledging, shelving, unshelving or closing an alarm on a device, or the alarm e-mail notification configurations of a runtime (recipients, priorities, transitions, templates, SMTP, test e-mail). Covers both the lc CLI and the logiccloud MCP server (logiccloud-control).
---

# logiccloud alarms

Use the `lc` CLI or the MCP server `logiccloud-control`, whichever is there
(see the logiccloud skill).

## Alarms are Structured Text

The PLC program raises alarms: an `ST_Alarm` value with a `Uid`, passed to
`RPC_CALL('alarm', 'set', ...)`. Write and build them like any other ST (the
logiccloud skill). The alarms then live on the device; the API cannot list
them, so take the uid from the program.

The project's alarm settings are one file, `alarming/<Name>.json` (the
portal names it `Alarming`), e.g.
`{"enabled": true, "maxAlarms": 100, "maxHistory": 500}`. Edit it in the
workspace and `lc check`, or with `read_files` / `write_files`. Writing it
creates it if the project has none. `enabled` is a boolean, `maxAlarms` and
`maxHistory` whole numbers; other keys are kept.

## Act on an alarm on a device

| Task | lc | MCP tool (`alarm_action`) |
|---|---|---|
| Acknowledge | `lc alarm ack -device <id> -uid <uid>` | `ack` |
| Shelve for a while | `lc alarm shelve -device <id> -uid <uid> -for 30m` | `shelve` (`shelveFor: "30m"`) |
| Unshelve, close | `lc alarm unshelve ...`, `lc alarm close ...` (same flags) | `unshelve`, `close` |
| Send a test e-mail of a notification configuration | `lc alarm test-email -device <id> [-notification <id>]` | `test-email` (`notificationId`) |

These change the alarm for everyone watching the machine: only when the user
asks. They wait for the device's result. They apply to the current
occurrence (`-occurrence n`, `occurrence` for another); the device refuses
an action for an occurrence that is no longer current.

## E-mail notifications

A runtime has alarm e-mail notification configurations: `recipients`,
`uidPatterns` (globs), `minPriority` (1 Critical ... 4 Low), `transitions`,
`templates`, `allowedActions` (links in the e-mail) and the `smtp` settings.

| Task | lc | MCP tool (`alarm_notifications`) |
|---|---|---|
| List | `lc alarm notifications -runtime <id>` (`-json`: complete) | `list` (`runtimeId`) |
| Create | `lc alarm notification create -runtime <id> -f config.json` | `create` (`runtimeId`, `config`) |
| Change (only the fields sent) | `lc alarm notification update <configId> -f changes.json` | `update` (`configId`, `config`) |
| Delete (name as confirmation) | `lc alarm notification delete <configId> -runtime <id> -name "<Name>"` | `delete` (`runtimeId`, `configId`, `name`) |

- The SMTP password is never shown (`smtp.hasPassword`). `smtp` replaces all
  SMTP settings; leave `smtp.password` out to keep the stored one, `null`
  removes it.
- Never put a password into a configuration unless the user gave it to you
  for that, and never ask for one in the chat.
- The fields: `lc schema -type CreateAlarmNotificationConfigInput`, or
  `describe_schema`.

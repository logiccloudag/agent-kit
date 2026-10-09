---
name: logiccloud-orchestrate-alerts
description: Use when working with alerts in logiccloud orchestrate - alert rules for offline devices, metric thresholds (CPU, memory, disk, ...) or crashing workloads, their scope, severity and suppression, the notification targets they notify (e-mail, webhook), test notifications, the delivery history of fired alerts, or the metric catalog of rule expressions. Covers both the lco CLI and the orchestrate MCP server (logiccloud-orchestrate).
---

# Alerts in orchestrate

Alert rules fire on a condition and notify notification targets. Use the
`lco` CLI or the MCP server `logiccloud-orchestrate`, whichever is there
(see the logiccloud-orchestrate skill). Reading is always fine; create,
change, delete or test-fire only when the user asked for it.

## See what is there

| Task | lco | MCP tool |
|---|---|---|
| Alert rules, one rule | `lco alerts`, `lco alert <id>` | `alert_rules` (`id`) |
| Fired alerts and their delivery | `lco alert deliveries` (`-rule <id>`, `-device <id>`) | `alert_rules` with `deliveries: true` (`id`, `deviceId`) |
| Fields, units and operators of expressions | `lco alert catalog` | `alert_rules` with `catalog: true` |
| Notification targets, one target | `lco notifications`, `lco notification <id>` | `notification_targets` (`id`) |

## Rules

Types (fixed once created):

- `DEVICE_OFFLINE`: minutes without a heartbeat (`-minutes 10`,
  `thresholdMinutes`, default 5).
- `METRIC_THRESHOLD` and `WORKLOAD_CRASH`: an expression,
  `field op value [AND ...] [for 5m]`, e.g. `cpu > 80 for 5m`
  (`-expr`, `expression`). Take the fields from the catalog.

Scope: `GLOBAL` (every device, default), `LABEL` (the devices with all the
labels: `-label k=v`, `targetLabels`) or `DEVICE` (`-device <id>`,
`targetId`). Severity: `INFO`, `WARNING` (default), `CRITICAL`.

| Task | lco | MCP tool (`manage_alert_rule`) |
|---|---|---|
| Create | `lco alert create -name "<Name>" -type METRIC_THRESHOLD -expr "cpu > 80 for 5m" -scope LABEL -label site=a -severity CRITICAL -target <targetId>` | `create` (`ruleType`, ...) |
| Change only the given fields | `lco alert update <id> -severity WARNING`, `-enabled false`, `-no-targets` | `update` |
| Send a test notification to its targets | `lco alert test <id>` | `test-fire` |
| Delete (the name is a confirmation) | `lco alert delete <id> -name "<Name>"` | `delete` (`confirmName`) |

Targets given on update (`-target`, `notificationTargetIds`) replace the
rule's targets. Suppression limits notifications: `-suppress '<json>'` or
`suppression`, with `trigger` AFTER_FIRST (default) or RATE
(`maxNotifications` within `intervalSeconds`), and when it lifts
(`liftSchedule`, `liftTimezone`, `liftMode` DIGEST, REPEAT or SILENT); it is
replaced as a whole. `-no-suppression` (`clearSuppression`) notifies every
occurrence.

## Notification targets

| Task | lco | MCP tool (`manage_notification_target`) |
|---|---|---|
| E-mail | `lco notification create -name "<Name>" -channel EMAIL -email ops@example.com` | `create` (`channel`, `email`) |
| Webhook | `lco notification create -name "<Name>" -channel WEBHOOK -url https://hooks.example.com/x [-header k=v]` | `create` (`url`, `headers`, `secret`) |
| Change (the channel is fixed) | `lco notification update <id> -enabled false` | `update` |
| Delete (the name is a confirmation) | `lco notification delete <id> -name "<Name>"` | `delete` (`confirmName`) |

A webhook's secret signs every delivery (HMAC-SHA256 in
`X-Webhook-Signature`). Left out, it is generated and shown once: tell the
user to keep it. Never ask for a secret in the chat.

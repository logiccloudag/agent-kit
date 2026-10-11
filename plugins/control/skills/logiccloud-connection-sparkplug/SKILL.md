---
name: logiccloud-connection-sparkplug
description: Use when a logiccloud runtime should publish or consume Sparkplug B 2.2 data - over the installation's cloud broker (SparkplugB22Cloud) or an own MQTT broker (SparkplugB22External) - topic namespaces with group, edge node and device IDs, owner and consumer roles, metrics and their mappings to Inputs/Outputs.
---

# Sparkplug B connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to `SparkplugB22Cloud` and `SparkplugB22External`.
Test: supported for both.

## Connection

- Cloud (the installation's broker; host, port and credentials are
  generated): `{"name": "Sparkplug", "clientId": "<unique>", "reconnectPeriod": 1000, "clean": true}`.
- External: the same plus `hostname`, `port`, `protocol` (`mqtt` or
  `mqtts`), `username`, `password` (required), optional `certificateCa`,
  `certificateClient`, `certificateKey` (PEM contents) and
  `rejectUnauthorized` (keep true).
- `clientId` must be unique per connection and device; two clients with the
  same ID throw each other off the broker. A UUID is a good choice.
- `useAliasOnMetrics`: send metric aliases instead of names after the birth.

## Topic namespaces

Sub-object `SparkplugB22TopicNamespace`:
`{name, groupId, nodeId, deviceId, type, rebirthMetric}`. Topics are
`spBv1.0/<groupId>/<message type>/<nodeId>[/<deviceId>]`.

- `type: "Owner"`: this runtime is the edge node. It publishes NBIRTH/DBIRTH,
  NDATA/DDATA and NDEATH/DDEATH for the mapped `{OUT}` variables. With
  `deviceId` empty, metrics are node metrics.
- `type: "Consumer"`: subscribes to another edge node's messages and writes
  the metrics to `{IN}` variables. The variables must have exactly the names
  of the metrics; aliases and tag names are not supported for consumers.

## Metrics

`SparkplugB22Mappings` per namespace (target: namespace ID):

    [{"variableName": "Speed", "tagName": "Line1/Speed", "dataType": "Float"}]

`tagName` is the metric name (empty: the variable name). `dataType`:
`Int8`..`Int64`, `UInt8`..`UInt64`, `Float`, `Double`, `Boolean`, `String`
(REAL = Float, LREAL = Double, INT = Int16, DINT = Int32).

## Gotchas

- With raw GraphQL, the cloud delete mutation is spelled
  `deleteSparklugB22CloudConnection` (sic); `lc` and the tools handle it.
- A primary host application (SCADA) that misses a birth can request a
  rebirth through the `rebirthMetric`.

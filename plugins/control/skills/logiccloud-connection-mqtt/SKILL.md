---
name: logiccloud-connection-mqtt
description: Use when setting up or changing an MQTT connection of a logiccloud runtime - the logiccloud cloud broker or an own broker, TLS and client certificates, producers and consumers, topics, QoS, retain, payload types (raw, JSON value, JSON dictionary, JSON object with key) and the mappings of Inputs/Outputs to topics and JSON paths.
---

# MQTT connections

The commands (`lc connection ...`, the `*_connection` tools) and the general
rules are in the logiccloud-connections skill; this adds what is specific to
type `Mqtt`. Test: supported.

## Definition

`MqttConnectionDefinitionInput` (`lc schema -type MqttConnectionDefinitionInput`).
Nearly every field is required, so start from an existing connection
(`lc connection <id> -definition`) or copy one rather than writing it from
scratch.

- `isCloud: true` uses the installation's own broker: it generates broker,
  user and password, and topics get a generated prefix. `false` uses
  `broker`, a URL such as `mqtts://broker.example.com:8883`, with
  `username`/`password`.
- Certificates (`rootCACert`, `clientCert`, `clientKey`, `clientCACert`) are
  the PEM contents, not paths; empty strings when unused. `clientAuth` is
  `NoClientCert` unless the broker wants a client certificate.
  `skipServerCertCheck` only when the user accepts it.
- `protocolVersion`: `Mqtt_3_1_1` (or `Mqtt_3_1`). No MQTT 5.
- Times are milliseconds. What the portal stores: keepAlive 30000,
  pingTimeout 10000, connectTimeout 30000, connectRetryInterval 30000,
  maxReconnectInterval 300000, disconnectTimeout 250, writeTimeout 0,
  cleanSession, order, autoReconnect and connectRetry true.
- Last will: `willEnabled`, `willTopic`, `willPayload`, `willQos`, `willRetained`.

## Producers, consumers, mappings

They are part of the definition (`producers[]`, `consumers[]`), so an update
with the whole definition changes them. Each needs an `_id` (24 hex digits,
a new ObjectId for a new one; keep existing ones).

- Producer: publishes `{OUT}` variables. `topic`, `qos` 0/1/2, `retain`,
  `payloadType`, `payloadFormat` (JSON template, `"{}"`), `trigger`
  (`OnChange`, `GroupChanges` = all mapped values when one changes,
  `GroupAll` = all, every `triggerInterval` ms), `mappings`.
- Consumer: subscribes and writes `{IN}` variables. Same, without trigger,
  plus `outboundOnVariable` (`""` if unused).
- Mapping: `{variable, type, subTopic, path, valuePath, keyPath, keyName}`,
  all strings (`""` when unused). `type`: `Boolean`, `Int8`..`Int64`,
  `Uint8`..`Uint64`, `Float32`, `Float64`, `String`, `Object` (JSON only).

| payloadType | Message | Mapping fields used |
|---|---|---|
| `RawPlainText`, `RawBinary` | the bare value, one topic per variable | `subTopic` (appended to `topic`) |
| `JsonValue` | a JSON value, one topic per variable | `subTopic`, `valuePath` |
| `JsonDictionary` | one object, a key per variable | `valuePath` = key or path (`data.temp`); `keyName` = variable name |
| `JsonObjectWithKey` | array/objects identified by a key field | `path`, `keyPath`, `keyName`, `valuePath` |

Triggers only apply to the JSON types.

Example producer (inside `producers`):

    {"_id": "<new ObjectId>", "name": "State", "description": "",
     "topic": "plant/line1/state", "qos": 1, "retain": false,
     "payloadType": "JsonDictionary", "payloadFormat": "{}",
     "trigger": "OnChange", "triggerInterval": 500,
     "mappings": [{"variable": "Speed", "type": "Float32", "valuePath": "speed",
                   "keyName": "Speed", "subTopic": "", "path": "", "keyPath": ""}]}

## Gotchas

- Do not use `replaceMappings` for MQTT: the API ignores it. Change mappings
  through `lc connection update` / `update_connection`.
- If `lc connection <id>` warns that the API cannot return a field (it has
  happened with `producers`), an update from that definition loses it. Stop
  and tell the user instead of updating.
- Map REAL to `Float32`, LREAL to `Float64`, INT to `Int16`, DINT to `Int32`,
  BOOL to `Boolean`, STRING to `String`.
- Nothing arrives? Check the topic (cloud topics carry the generated prefix),
  `lc connection test`, then the runtime log (logiccloud-devices skill).

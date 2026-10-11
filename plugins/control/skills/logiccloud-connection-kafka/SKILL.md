---
name: logiccloud-connection-kafka
description: Use when a logiccloud runtime should produce to or consume from Apache Kafka - brokers, TLS, SASL (plain, SCRAM, OAuth, Kerberos), producers and consumers, payloads with topics, partition keys, triggers and JSON formats, and mapping Inputs/Outputs into messages.
---

# Kafka connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to type `Kafka`. Test: not supported; check the
runtime log and `lc vars` (logiccloud-devices skill).

## Structure

1. **Connection**: `brokers` (comma-separated `host:port`, e.g.
   `kafka.example.com:9093`), `enableLowLevelLogging`, and the lists
   `producers[]` and `consumers[]`.
2. **Producers and consumers** live in the definition. Each has about 45
   required fields and an `_id` (a new ObjectId for a new one). Copy an
   existing one and change:
   - TLS: `enableTls` (client certificates are not configurable).
   - SASL: `enableSasl`, `saslMechanism` (`SaslPlaintext`, `SaslScramSHA256`,
     `SaslScramSHA512`, `SaslOAuth` with `saslToken {TenantId, ClientId,
     ClientSecret}`, `SaslGssAapi` = Kerberos with the `krb*` fields),
     `saslUser`, `saslPassword`.
   - `clientId`, `version` (the Kafka protocol version, e.g. `2.1.0`).
   - Producer: `acknowledgements` (`NoResponse`, `WaitForLocal`,
     `WaitForAll`), `compression` (`None`, `Gzip`, `Snappy`, `Lz4`, `Zstd`),
     `partitioner` (`Hash`, `RoundRobin`, `Random`, `Manual`,
     `ConsistentCRCHash`), `idempotent`, `retryMax`.
   - Consumer: `offsetType` (`OffsetNewest`, `OffsetOldest`), `readType`
     (`Uncommitted`, `Committed`), `enableOffsetsAutoCommit`.
3. **Payloads** (sub-object `KafkaPayload`), one per topic and message shape:
   `parentId` (the `_id` of its producer or consumer), `name`, `topic`,
   `partitionKey`, `type`, `format`, `trigger`, `triggerInterval` (ms).
   lc gives a new payload its own `_id` and links it to the parent.
4. **Mappings** per payload (`KafkaMappings`, target: payload ID), items as
   for MQTT: `{variable, type, path, valuePath, keyPath, keyName}`.

- Producers send `{OUT}` variables, consumers write `{IN}` variables.
- Payload `type`: `RawPlainText`, `RawBinary`, `JsonValue`, `JsonDictionary`,
  `JsonObjectWithKey`. `format` is a JSON template, e.g. `{"d":[]}` with
  `valuePath` `d[0].CurrentL1`.
- `trigger`: `Individual` (each changed value on its own), `GroupChanges`,
  `GroupAll` (every `triggerInterval` ms). Not the MQTT names.
- Mapping `type`: `Boolean`, `Int8`..`Int64`, `Uint8`..`Uint64`, `Float32`,
  `Float64`, `String`.

## Gotchas

- Duplicate a Kafka connection with `lc connection copy` / `copy_connection`.
  A definition taken from one connection still lists the original's payloads;
  creating from it does not copy them.
- An update replaces producers and consumers: keep their `_id`s, or their
  payloads lose their parent.

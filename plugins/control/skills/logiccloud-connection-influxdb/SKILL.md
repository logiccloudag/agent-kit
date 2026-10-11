---
name: logiccloud-connection-influxdb
description: Use when a logiccloud runtime should log variable values to InfluxDB (v2) - URL, organization, bucket and token, log on change or time-triggered, batching and retries, default tags, and which variables are logged under which names.
---

# InfluxDB connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to type `Influxdb`. Logging only goes out of the PLC,
so any Inputs/Outputs variable can be logged. Test: supported.

## Definition

InfluxDB 2 (and InfluxDB Cloud) only: there are no v1 fields (database,
user). For a v1 server, use its v2 compatibility API with a token.

    {"name": "Historian", "url": "https://influx.example.com:8086",
     "organization": "my-org", "bucket": "plc", "token": "<token>",
     "logMode": "LogOnChange", "logInterval": 500,
     "enableVariable": "", "timestampVariable": "",
     "writeOptions": {"batchSize": 5000, "flushInterval": 1000, "retryInterval": 5000,
                      "maxRetries": 5, "retryBufferCountLimit": 5,
                      "maxRetryInterval": 125000, "maxRetryTime": 180000}}

- `logMode`: `LogOnChange` (a point when a value changes),
  `LogTimeTriggered` (all values every `logInterval` ms),
  `LogBufferedOnChange` (changes, written in batches).
- `enableVariable`: a BOOL variable that switches logging on and off;
  `timestampVariable`: a variable whose value is used as the timestamp.
  Empty when not used.
- `writeOptions` times are ms. The token needs write access to the bucket.

## What is logged

- `InfluxdbMappings` (target: the connection):
  `[{"variableName": "Temperature", "tagName": "temperature", "dataType": "Float"}]`.
  `tagName` is the name it is logged under (empty: the variable name).
  `dataType`: `Float`, `Int`, `UInt`, `Boolean`, `String`.
- `InfluxdbTags` (target: the connection), tags added to every point:
  `[{"name": "line", "value": "1"}]`. Stored as `writeOptions.defaultTags`.

Both lists are replaced as a whole and are not created from the definition:
set them after creating the connection.

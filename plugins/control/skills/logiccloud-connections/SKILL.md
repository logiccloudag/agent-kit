---
name: logiccloud-connections
description: Use when setting up, changing, copying or testing the connections of a logiccloud runtime (MQTT, Modbus TCP/RTU, OPC UA client/server, InfluxDB, Kafka, Sparkplug B, ctrlX, REST-RPC, Node-RED, SAP, IO-Link, ...) - their settings, sub-objects such as Modbus units, OPC UA subscriptions and Kafka payloads, and the mappings that bind Inputs/Outputs to registers, topics or nodes. Covers both the lc CLI and the logiccloud MCP server (logiccloud-control).
---

# logiccloud connections

Connections belong to a runtime (not to the project sources) and bind its
Inputs/Outputs to MQTT topics, Modbus registers, OPC UA nodes and so on.
Changing them changes what a running machine reads and writes: create,
update, copy and delete only what the user asked for. Reading is always fine.

Use the `lc` CLI or the MCP server `logiccloud-control`, whichever is there
(see the logiccloud skill). `lc runtimes` / `list_runtimes` find the runtime
(logiccloud-devices skill).

| Task | lc | MCP tool |
|---|---|---|
| List (the workspace's project, or one runtime) | `lc connections` (`-runtime <id>`, `-project <id>`) | `list_connections` |
| Show, with sub-objects and mappings | `lc connection <id>` | `get_connection` |
| Types, their sub-objects and mapping kinds | `lc connection types` | `connection_types` |
| As a definition to edit | `lc connection <id> -definition > c.json` | `get_connection` with `definition: true` |
| Replace the settings | `lc connection update <id> -f c.json` | `update_connection` |
| Create | `lc connection create -runtime <id> -type Mqtt -f c.json` | `create_connection` |
| Copy completely (sub-objects, mappings) | `lc connection copy <id> -runtime <id> -name "<Name>"` | `copy_connection` |
| Try it (the runtime must be running) | `lc connection test <id>` | `test_connection` |
| Delete (name as confirmation) | `lc connection delete <id> -name "<Name>"` | `delete_connection` |

## Settings, sub-objects and mappings

- An update replaces the whole connection: read the definition, change it,
  send all of it back. Anything left out is lost.
- Only MQTT, REST-RPC, Revolution Pi and Tibber keep their mappings in the
  definition. The others keep them in sub-objects or lists of their own
  (`lc connection types` / `connection_types` says which type has which),
  so a definition alone creates a connection without them.
- To set one up like an existing one, copy it (`lc connection copy`,
  `copy_connection`) to the runtime under a new name, then change the
  settings. That copies everything; creating from a definition does not.

Sub-objects (Modbus units, OPC UA client subscriptions, Sparkplug
namespaces, ctrlX providers/clients, IO-Link resources, Weidmüller
providers/consumers, Kafka payloads):

| Task | lc | MCP tool (`connection_object`) |
|---|---|---|
| Show one (as a definition) | `lc connection object <id> -definition` | `get` (`asDefinition`) |
| Create | `lc connection object create -kind ModbusUnit -connection <id> -f u.json` | `create` (`kind`, `connectionId`) |
| Change (the fields given) | `lc connection object update <id> -f u.json` | `update` |
| Delete (name as confirmation) | `lc connection object delete <id> -name "<Name>"` | `delete` (`name`) |

A Kafka payload needs `parentId`, the `_id` of its producer or consumer.

Mapping lists (the mappings of a sub-object, e.g. a Modbus unit per register
type; of InfluxDB, OPC UA server, Node-RED, SAP and Raspberry Pi
connections; InfluxDB tags, OPC UA server profiles and locale IDs) are
replaced as a whole:

    lc connection mappings -kind ModbusMappings -target <unitId> -arg registerType=Coil -f items.json

With the tools: `set_connection_mappings` with `kind`, `targetId`, `args`
(`{"registerType": "Coil"}`) and `items`. Send the complete list (`[]`
clears it); items as `lc connection <id>` / `get_connection` show them are
accepted. Modbus mappings appear there on each unit under `mappings`, by
register type.

## Rules

- Bind variables by their Inputs/Outputs name (the names the HMI uses):
  declared with `{IN}`, `{OUT}` or `{IN_OUT}` and built into the project.
- The input type of a definition, sub-object or mapping item is in the
  schema: `lc schema -type ModbusUnitInput`, or `describe_schema`.
- A test only says whether it worked, not why; the runtime's log
  (logiccloud-devices skill) may say more.
- Deleting a connection or sub-object needs its name; only delete what the
  user asked for.

---
name: logiccloud-connection-node-red
description: Use when Node-RED flows should read or write the Inputs/Outputs of a logiccloud runtime - the Node-RED connection's port, which variables it exposes, and the logiccloud control nodes in Node-RED.
---

# Node-RED connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to type `NodeRED`. Test: supported.

The runtime opens a connector port; Node-RED (on the same device as a device
service, or elsewhere in the network) connects to it with the "logiccloud
control" nodes.

## Definition and mappings

    {"name": "Node-RED", "port": 42011}

Only mapped variables are reachable from Node-RED. `NodeRedMappings`
(target: the connection, replaced as a whole):

    [{"variableName": "Speed", "dataType": "DataTypeFloat"},
     {"variableName": "Start", "dataType": "DataTypeBoolean"}]

`dataType`: `DataTypeBoolean`, `DataTypeInt8`..`DataTypeInt64`,
`DataTypeUInt8`..`DataTypeUInt64`, `DataTypeFloat`, `DataTypeDouble`,
`DataTypeString`, `DataTypeDateTime`, `DataTypeDuration`. Every item needs a
`variableName`; the API does not reject empty ones.

## In Node-RED

- A config node with the device's host and the port above.
- "input" nodes write to the PLC: use them for `{IN}` variables.
- "output" nodes deliver values from the PLC: `{OUT}` variables.
- After changing the mappings, restart the flow and open the config node
  again before browsing for variables.

Node-RED flows themselves are not part of the logiccloud project; the user
edits them in Node-RED.

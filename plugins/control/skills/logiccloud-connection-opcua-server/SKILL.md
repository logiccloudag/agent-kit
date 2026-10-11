---
name: logiccloud-connection-opcua-server
description: Use when a logiccloud runtime should offer its Inputs/Outputs as an OPC UA server - port, users and anonymous access, certificates, profiles and locale IDs, and the address space (node names, data types, read-only or read-write access).
---

# OPC UA server connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to type `OpcUaServer`: the runtime itself serves an
address space that SCADA systems or other clients connect to. Test: not
supported; connect with an OPC UA client to check.

## Definition

`OpcUaServerConnectionDefinitionInput` has about 40 required fields (limits,
certificate paths). Do not write it from scratch: copy an existing server
connection (`lc connection copy`, `copy_connection`) or take
`-definition` from one and change only:

- `port` (42010 in the portal; must be free on the device and reachable
  from the clients - firewall, Docker port mapping).
- `user`, `password`; `allowAnonymousUsers`, `allowWriteAnonymously`,
  `allowPolicyNone` (unencrypted access; default false). Turning on anonymous
  or unencrypted access exposes the machine: only when the user asks.
- `autoGenerateCertificate`, `validMonths`, `keySize`, and the `./pki/...`
  paths (files on the device).
- `enableDiagnostics`, `traceRequestsResponses` for debugging only.

The endpoint clients use is `opc.tcp://<device address>:<port>`.

## Address space

Three lists, each replaced as a whole (`lc connection mappings -kind ... -target <connId>`,
`set_connection_mappings`), and also part of the definition:

- `OpcUaServerMappings`: `[{"variableName": "Speed", "address": "outputs.speed",
  "dataType": "Float", "accessLevel": "ReadOnly"}]`. `address` is the dotted
  node path below the server's root folder. `dataType`: `Boolean`,
  `Int8`..`UInt64`, `Float`, `Double`, `String`, `ByteString`.
  `accessLevel`: `ReadOnly` for `{OUT}` variables (clients read them),
  `ReadWrite` for `{IN}` variables (clients write them).
- `OpcUaServerProfiles`: `[{"profile": "http://opcfoundation.org/UA-Profile/Server/StandardUA2017"}]`.
- `OpcUaServerLocaleIds`: `[{"id": "en"}]`.

Only mapped variables are visible to clients.

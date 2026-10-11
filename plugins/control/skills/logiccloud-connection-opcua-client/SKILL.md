---
name: logiccloud-connection-opcua-client
description: Use when a logiccloud runtime should read from or write to an OPC UA server as a client - endpoint URL, security mode and policy, anonymous/user/certificate login, subscriptions with publishing intervals, and mapping Inputs/Outputs to node IDs.
---

# OPC UA client connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to type `OpcUaClient`. Test: supported.

## Connection

`OpcUaClientConnectionDefinitionInput`:

    {"name": "Machine OPC UA", "endpointUrl": "opc.tcp://opcua.example.com:4840",
     "securityMode": "None", "securityPolicy": "None",
     "authentication": "Anonymous", "autoGenerateOwnCertificate": true}

- `securityMode`: `None`, `Sign`, `SignAndEncrypt`. `securityPolicy`:
  `None`, `Basic256Sha256` (the usual one with security), `Aes128Sha256RsaOaep`,
  `Aes256Sha256RsaPss`, and the deprecated `Basic128Rsa15`, `Basic256`.
  Mode and policy must match an endpoint the server offers.
- `authentication`: `Anonymous`; `Credentials` with `user`, `password`;
  `Certificate` with `authCertificatePath`, `authKeyPath`; `Token` with `tokenData`.
- Certificates are files on the device (`./pki/...` paths, the portal's
  defaults), not contents. `autoGenerateOwnCertificate: true` makes the
  runtime create its own. With security on, the server usually has to trust
  that certificate first (on the server side); until then connecting fails.
- `skipServerCertCheck` only when the user accepts it.
- Optional times in ms: sessionTimeout 120000, connectTimeout 15000,
  requestTimeout 15000, writeRetryInterval 500.

## Subscriptions and mappings

Nodes are grouped in subscriptions (sub-object `OpcUaClientSubscription`):
`{name, publishingInterval: 100, lifetimeCount: 1000, maxKeepAliveCount: 10,
maxNotificationsPerPublish: 10000, publishingEnabled: true, priority: 0}`.
`lifetimeCount` must be at least three times `maxKeepAliveCount`.

Mappings per subscription (`OpcUaClientMappings`, target: subscription ID):

    [{"variableName": "Temperature", "nodeId": "ns=3;i=1043",
      "tagDisplayName": "Temperature", "tagBrowseName": "3:Temperature",
      "samplingInterval": 100, "queueSize": 10, "discardOldest": true,
      "monitoringMode": "Reporting", "dataType": "Double"}]

- `nodeId` in standard notation: `ns=<n>;i=<number>`, `ns=<n>;s=<string>`,
  `ns=<n>;g=<guid>`. Take it from the server's address space (a browser such
  as UaExpert, or the server's documentation); do not guess.
- `dataType`: `Boolean`, `Int8`..`Int64`, `UInt8`..`UInt64`, `Float`,
  `Double`, `String`, `ByteString`; it must match the node's type
  (Float = REAL, Double = LREAL, Int16 = INT, Int32 = DINT).
- `{IN}` variables receive the node's value; `{OUT}` variables are written to
  the node (the node must be writable).
- `monitoringMode`: `Reporting` (normal), `Sampling`, `Disabled`.

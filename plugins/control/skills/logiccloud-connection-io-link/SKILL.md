---
name: logiccloud-connection-io-link
description: Use when a logiccloud runtime should read or write IO-Link sensors and actuators through an IO-Link master's REST/JSON API - master URL and login, resources per device and port, process data, parameters (ISDU), IODD values, write modes and JSON path mappings.
---

# IO-Link connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to type `IoLink`: the runtime talks to an IO-Link
master that offers the IO-Link JSON REST API. Test: supported.

## Connection

    {"name": "IO-Link master", "url": "http://iolink-master.example.com/",
     "username": "<user>", "password": "<password>"}

All three are required (empty strings if the master has no login).

## Resources

One sub-object `IoLinkResource` per value group to read or write. All fields
are required; send `""` for those that do not apply:

    {"name": "Sensor port 1", "runtimeId": "<rt>", "connectionId": "<conn>",
     "type": "Device", "masterNumber": "1", "deviceAlias": "master1port1",
     "masterPorts": false, "portNumber": "1",
     "resourcePath": "/iolink/v1/devices/{deviceAlias}/processdata/value",
     "url": "/iolink/v1/devices/master1port1/processdata/value",
     "parameterNameOrIndex": "", "subParameterNameOrIndex": "",
     "useIODD": false, "pollInterval": 500,
     "payload": "", "writeMode": "OnChange", "writeInterval": 0}

- `type`: `Device` (a sensor/actuator on a port), `Master`, `Gateway`.
- `resourcePath` is the API path template, `url` the same path with the
  placeholders filled in. A path starting with `POST:` is a write resource:
  `POST:/iolink/v1/devices/{deviceAlias}/processdata/value`.
- Read resources are polled every `pollInterval` ms and fill `{IN}`
  variables. Write resources send `{OUT}` variables: `payload` is a JSON
  template whose values are JSON paths to the mapped variables, e.g.
  `{"iolink": {"valid": true, "value": "$.iolink.value"}}`; `writeMode`
  `OnChange`, `TimeTriggered` (every `writeInterval` ms) or `BufferedOnChange`.
- Parameters (ISDU): `parameterNameOrIndex`, `subParameterNameOrIndex`.
- `useIODD: true` uses the device's IODD to decode values by name.

## Mappings

Per resource (`IoLinkMappings`, target: resource ID):

    [{"variableName": "Distance", "jsonPath": "$.iolink.value", "valuePath": "$", "dataType": "DataTypeFloat"}]

`jsonPath` selects the value in the master's response; `valuePath` the
part of it within the IODD structure (`$` when it is the value itself).
`dataType`: `DataTypeBoolean`, `DataTypeInteger`, `DataTypeUInteger`,
`DataTypeFloat`, `DataTypeString`, `DataTypeTimeSpan`, `DataTypeTimeT`,
`DataTypeByteArray`.

The master's paths, device aliases and the response shape are in its
manual or its API explorer; read a resource once before mapping it.

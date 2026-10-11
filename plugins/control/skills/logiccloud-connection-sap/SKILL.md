---
name: logiccloud-connection-sap
description: Use when a logiccloud runtime should send process values to an SAP web service - service URL, no/basic/bearer authentication, enable variable, log interval and which variables are sent how often.
---

# SAP connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to type `Sap`. Values only go from the PLC to SAP.
Test: supported.

## Definition

    {"name": "SAP", "url": "https://sap.example.com/<service path>",
     "authType": "Basic", "basicCredentials": {"username": "<user>", "password": "<password>"},
     "enableVariable": "", "logInterval": 500}

- `authType`: `None`, `Basic` (with `basicCredentials`), `Bearer` (with
  `bearerCredentials: {"token": "..."}`).
- `enableVariable`: a BOOL variable that switches sending on (`""`: always on).
- `logInterval`: ms.
- The URL and the expected format come from the SAP side (the user's SAP
  team); do not guess service paths.

## Mappings

`SapMappings` (target: the connection), replaced as a whole:

    [{"variableName": "Counter", "pollingInterval": 1000}]

Map `{OUT}` variables; `pollingInterval` (ms) is how often each is read.

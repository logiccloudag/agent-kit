---
name: logiccloud-connection-rest-rpc
description: Use when a logiccloud runtime should call HTTP/REST APIs - base URL, headers, authentication (basic, bearer, API key), TLS, endpoints with method and path, triggers (on change, on demand, periodic), JSON request and response payloads mapped to Inputs/Outputs, and RPC_CALL from Structured Text.
---

# REST-RPC connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to type `RestRpc`: the runtime is an HTTP client that
calls endpoints of another service. Test: not supported.

## Definition

Everything, including the mappings, is in the definition:

- `baseURL` (`https://api.example.com/v1`), `headers` (JSON object, `{}`).
- `auth`: `{type, username, password, token, apiKey, apiKeyName, apiKeyLocation}`
  with `type` `None`, `Basic`, `Bearer`, `APIKey` and `apiKeyLocation`
  `APIKeyLocationHeader`, `APIKeyLocationQuery`, `APIKeyLocationCookie`.
  Unused fields `""`.
- `tls`: `{insecureSkipVerify: false, serverName: ""}`.
- Transport, ms: idleConnTimeout 90000, tlsHandshakeTimeout 10000,
  responseHeaderTimeout 1000 (raise it for slow APIs), expectContinueTimeout
  1000, maxIdleConns 100, maxIdleConnsPerHost 100, followRedirects true,
  maxRedirects 10.
- `endpoints[]`, each with an `_id` (new ObjectId for a new one):
  `name`, `path` (appended to `baseURL`), `method` (`GET`, `POST`, `PUT`,
  `PATCH`, `DELETE`), `headers`, `timeout` (ms, 15000),
  `sendPayloadType`/`sendPayloadFormat`, `receivePayloadType`/`receivePayloadFormat`
  (`JsonDictionary` or `JsonObjectWithKey`; formats are JSON templates),
  `trigger`, `triggerInterval`, `triggerVariable`, `enableVariable`,
  `outboundOnVariable`, `mappings`.

## Triggers and mappings

- `trigger`: `OnChange` (a mapped send value changed), `GroupChanges`,
  `GroupAll` (every `triggerInterval` ms - polling), `OnDemand` (when
  `triggerVariable`, a BOOL, is set by the program).
- Mapping: `{variable, type, path, valuePath, keyPath, keyName}`. Variables in
  the send payload (`{OUT}`) go out with the request; variables in the
  receive payload (`{IN}`) are filled from the response. `valuePath` is the
  JSON path in the payload, e.g. `temperature_2m` with `path` `current`, or
  `[0].id`. `type` as for MQTT (`Float32`, `Int32`, `Boolean`, `String`, ...).
- From Structured Text, an endpoint can also be called with `RPC_CALL`, with
  the connection name as TOPIC and baseURL + path as COMMAND.

## Gotchas

- Change endpoints and mappings through `update` with the whole definition;
  there is no separate mapping list for REST-RPC.
- If `lc connection <id>` warns that the API cannot return `auth`, an update
  from that definition loses the credentials: ask the user for them first.

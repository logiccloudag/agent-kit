---
name: logiccloud-device-wago
description: Use when a logiccloud project should run on a WAGO controller (Compact Controller CC100; also PFC200 as a generic ARM v7 device) - turning off CODESYS, Docker on the controller, the Arm/V7 platform, license, and the CC100 onboard I/O variables.
---

# WAGO CC100 (and PFC200)

Device type CC 100, platform `Arm/V7`. The type installs an extra process,
the **WAGO CC100 connector**, which links the onboard I/O to the runtime.
A PFC200 runs as a Generic ARM v7 device (logiccloud-device-linux skill).

## Onboarding (the user does it)

1. In the controller's web-based management: stop and disable the CODESYS
   runtime, enable Docker (current firmware ships it; older firmware needs
   the Docker package installed), and set DNS and the gateway so the
   controller reaches the internet.
2. Add and bind the device in the logiccloud portal (type CC 100), then run
   the install script on the controller and connect it with the device
   token (logiccloud-device-linux skill).

## Deploying

- `lc build -platform Arm/V7`, then `lc deploy -device <id>`
  (logiccloud-devices skill). A build without `Arm/V7` is refused.
- License: assigned in the portal and activated on the controller; demo
  mode stops after two hours.
- `lc health` lists the CC100 connector process; its log:
  `lc logs -device <id> -target <connector process>`.

## Onboard I/O (CC100)

There is no connection to set up: the connector maps the onboard I/O to
Inputs/Outputs with fixed names. Declare variables with exactly these names:

| I/O | Names | Direction |
|---|---|---|
| Digital inputs | `DI1` .. `DI8` | `{IN}` |
| Digital outputs | `DO1` .. `DO4` | `{OUT}` |
| Analog inputs | `AI1`, `AI2` | `{IN}` |
| Analog outputs | `AO1`, `AO2` | `{OUT}` |
| Temperature inputs (PT) | `PT1`, `PT2` | `{IN}` |

    DI1 : BOOL {IN HMI};
    DO1 : BOOL {OUT HMI};

The digital ones are BOOL; check the value types and scaling of the analog
and PT channels with the user (logiccloud docs for the CC100) before
writing code that depends on them. PFC200 I/O (K-Bus) is reached through
WAGO's K-Bus MQTT container and a local MQTT broker, mapped with an MQTT
connection (logiccloud-connection-mqtt skill).

---
name: logiccloud-device-revpi
description: Use when a logiccloud project should run on a KUNBUS Revolution Pi (RevPi Connect 4, Connect 5, Connect S, Core S, Flat S) - onboarding, the Arm64 platform, PiCtory and piControl, the RevPi browsing service and mapping the process image.
---

# Revolution Pi

Device types RevPi Connect 4 (2/4/8 GB), RevPi Connect 5 (4/8 GB), RevPi
Connect S, RevPi Core S, RevPi Flat S: industrial Raspberry Pi based
controllers, platform `Arm64`, Docker. Besides the usual device services
they offer the **RevPi browsing service**, which reads the PiCtory
configuration so the portal can list the I/O signals.

## Onboarding (the user does it)

As on a Linux device (logiccloud-device-linux skill): add and bind it in
the portal, run the install script on the RevPi, paste the device token.
The RevPi image needs piControl (part of the official RevPi OS) and a
PiCtory configuration of the modules actually attached, saved as the start
configuration.

## Deploying

- `lc build -platform Arm64`, then `lc deploy -device <id>`
  (logiccloud-devices skill). A build without `Arm64` is refused.
- When the project has a `Revpi` connection, the deploy also installs a
  RevPi connector process on the device; `lc health` lists it, and
  `lc logs -device <id> -target <that process>` shows its log.
- License as on other edge devices: assigned in the portal, demo mode stops
  after two hours.

## I/O

The onboard and expansion module I/O (DIO, DI, DO, AIO, gateways) is the
process image, mapped with a `Revpi` connection
(logiccloud-connection-revpi skill), by PiCtory signal names. Ask the user
for the names (PiCtory, or the RevPi browsing service in the portal) rather
than guessing `I_1`/`O_1`; they depend on the modules and their order.

After changing PiCtory: reset piControl (RevPi web UI or
`sudo piTest -x` on the device) and restart the runtime
(`lc runtime restart`), otherwise the connector sees the old layout.

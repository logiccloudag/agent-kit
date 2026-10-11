---
name: logiccloud-connection-raspberry-pi
description: Use when a logiccloud runtime on a Raspberry Pi should read or switch GPIO pins - poll interval, pin numbers, input or output, pull-up and pull-down.
---

# Raspberry Pi GPIO connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to type `RaspberryPi` (device types Raspberry Pi 4B,
5 and Cluster, platform `Arm64`, 64-bit Raspberry Pi OS). Test: supported.

## Definition and mappings

    lc connection create -runtime <rt> -type RaspberryPi -f gpio.json
    gpio.json  {"name": "GPIO", "pollInterval": 100}

The pins are a mapping list on the connection (`RaspberryPiGPIOMappings`,
target: the connection ID), replaced as a whole:

    lc connection mappings -kind RaspberryPiGPIOMappings -target <connId> -f pins.json
    pins.json  [{"variable": "Button", "pin": 11, "pinMode": "Input", "pullMode": "PullUp"},
                {"variable": "Led", "pin": 40, "pinMode": "Output", "pullMode": "PullNoChange"}]

- `pollInterval`: ms, how often inputs are read.
- `pin`: the pin on the 40-pin header. Confirm the numbering with the user's
  wiring, and never use power or ground pins.
- `pinMode`: `Input` fills a BOOL `{IN}` variable; `Output` drives a BOOL
  `{OUT}` variable.
- `pullMode`: `PullUp`, `PullDown`, `Float`, `PullNoChange`. A button to
  ground needs `PullUp` (pressed = FALSE).
- GPIO is 3.3 V and a few mA: relays and loads need a driver stage.

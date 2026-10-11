---
name: logiccloud-connection-tibber
description: Use when a logiccloud program should use Tibber electricity prices (current, today, tomorrow) - the Tibber API token, home ID, poll period, and the variable that receives the prices.
---

# Tibber connections

The commands and general rules are in the logiccloud-connections skill; this
adds what is specific to type `Tibber`: the runtime polls the Tibber API and
writes the prices into one variable, for example to switch loads when power
is cheap. Test: not supported.

## Definition

    {"name": "Tibber", "url": "https://api.tibber.com/v1-beta/gql",
     "token": "<personal access token>", "homeId": "",
     "pollPeriod": 60, "connectTimeout": 30, "variableName": "Prices"}

- `token`: the user's Tibber personal access token (developer.tibber.com).
- `homeId`: empty if the account has one home, otherwise the home's ID.
- `pollPeriod`, `connectTimeout`: seconds (not ms), at least 3.
- `variableName`: the one `{IN}` variable that receives the data. There are
  no other mappings.

## The variable

Use a structure like this (if the organization has a library for Tibber,
`lc libraries` shows it; use that instead):

    TYPE PRICE_VALUE : STRUCT
        Total : REAL; Energy : REAL; Tax : REAL; StartsAt : DT;
    END_STRUCT END_TYPE
    TYPE PRICE_DATA : STRUCT
        Current : PRICE_VALUE;
        Today : ARRAY[0..23] OF PRICE_VALUE;
        Tomorrow : ARRAY[0..23] OF PRICE_VALUE;
    END_STRUCT END_TYPE

    Prices : PRICE_DATA {IN};

Tomorrow's prices are published in the early afternoon; until then
`Tomorrow` is empty (zero).

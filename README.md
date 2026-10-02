# logiccloud agent kit

Connect coding agents (Claude Code, Codex, opencode) to **logiccloud control**
and **logiccloud orchestrate**: the MCP servers of your installation, skills
that teach the agent how to work with them, and the `lc` and `lco` command line
tools.

| | logiccloud control | logiccloud orchestrate |
|---|---|---|
| What | PLC projects in IEC 61131-3 Structured Text, cloud builds, HMI pages, devices, runtimes and connections | Edge devices (Margo), logs, telemetry, the application catalog and rollouts |
| MCP server | `https://mcp.<domain>/mcp` | `https://mcp.<domain>/mcp` |
| Login | OAuth at `https://auth.<domain>` (Keycloak client `lc-mcp`) | API key (orchestrate: Settings > Security > API Keys) |
| CLI | `lc` | `lco` |
| Skills | `logiccloud`, `logiccloud-hmi`, `logiccloud-devices` | `logiccloud-orchestrate`, `logiccloud-orchestrate-deployments` |
| Plugin | `control@logiccloud` | `orchestrate@logiccloud` |

Every installation of logiccloud runs on its own domain, and everything else
follows from it. You only need the **root domain** of each product, e.g.
`logiccloud.example.com` (control) and `orchestrate.example.com`
(orchestrate); the examples below use these placeholders. The MCP server is
always on the `mcp.` subdomain, the login on `auth.`.

## Quick start

On macOS or Linux, with any of `claude`, `codex` or `opencode` installed:

```sh
curl -fsSL https://raw.githubusercontent.com/logiccloudag/agent-kit/main/setup.sh | bash -s -- \
  --control logiccloud.example.com --orchestrate orchestrate.example.com
```

Use your installation's domains, and leave out the product you don't use.
Without options the script asks for both. It sets up every agent it finds
(`--agents claude,codex` limits that), asks for the orchestrate API key when
Claude Code is one of them, starts the control login for Codex and opencode,
and prints what is left to do. Run it again to update or to change a domain;
`--remove` takes everything out again; `--dry-run` only shows what it would do.

### Or let your agent do it

Paste this into your agent, with your domains:

> Set up logiccloud for me as described in
> https://github.com/logiccloudag/agent-kit/blob/main/INSTALL.md —
> control domain: `logiccloud.example.com`, orchestrate domain: `orchestrate.example.com`

The agent follows [INSTALL.md](INSTALL.md). It will not ask for the API key in
the chat; you enter it yourself.

## Claude Code

Inside Claude Code, without the script:

```
/plugin marketplace add logiccloudag/agent-kit
/plugin install control@logiccloud
/plugin install orchestrate@logiccloud
```

Claude Code asks for the domain (and for orchestrate the API key, which it keeps
in the system's secure storage). Then `/mcp` and pick
`plugin:control:logiccloud-control` to log in. From a shell, the same is:

```sh
claude plugin marketplace add logiccloudag/agent-kit
claude plugin install control@logiccloud --config domain=logiccloud.example.com
claude plugin install orchestrate@logiccloud --config domain=orchestrate.example.com
echo '{"api_key":"<key>"}' | claude plugin configure orchestrate@logiccloud --values-stdin
```

`/plugin configure control@logiccloud` changes the domain later. The plugins
update with `/plugin marketplace update logiccloud`.

## Codex

The skills come as plugins:

```sh
codex plugin marketplace add logiccloudag/agent-kit
codex plugin add control@logiccloud
codex plugin add orchestrate@logiccloud
```

The MCP servers go into `~/.codex/config.toml` (Codex plugins cannot ask for a
domain). `setup.sh` writes this for you:

```toml
[mcp_servers.logiccloud-control]
url = "https://mcp.logiccloud.example.com/mcp"
scopes = ["openid", "profile", "email", "offline_access"]

[mcp_servers.logiccloud-control.oauth]
client_id = "lc-mcp"
callback_url = "http://localhost:33418/callback"

[mcp_servers.logiccloud-orchestrate]
url = "https://mcp.orchestrate.example.com/mcp"
env_http_headers = { "X-API-Key" = "LCO_API_KEY" }
```

Then `codex mcp login logiccloud-control`, and start Codex with the API key in
`LCO_API_KEY` (e.g. `export LCO_API_KEY=...` in your shell profile). The
`scopes` matter: without them Codex asks Keycloak for every scope the realm
offers, and Keycloak refuses the login.

## opencode

opencode has no plugin marketplace for skills. `setup.sh` copies them into
`~/.config/opencode/skills` (marked, so it updates and removes only its own) and
adds the servers to `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "logiccloud-control": {
      "type": "remote",
      "url": "https://mcp.logiccloud.example.com/mcp",
      "oauth": {
        "clientId": "lc-mcp",
        "redirectUri": "http://localhost:33418/callback",
        "scope": "openid profile email offline_access"
      }
    },
    "logiccloud-orchestrate": {
      "type": "remote",
      "url": "https://mcp.orchestrate.example.com/mcp",
      "headers": { "X-API-Key": "{env:LCO_API_KEY}" },
      "oauth": false
    }
  }
}
```

Then `opencode mcp auth logiccloud-control`, and start opencode with
`LCO_API_KEY` set. To copy the skills by hand, take the folders under
`plugins/*/skills/` into `~/.config/opencode/skills/` (or `~/.agents/skills/`).

## Other agents

Any agent that speaks MCP over streamable HTTP works: point it at
`https://mcp.<domain>/mcp`. For control it needs OAuth with the client ID
`lc-mcp`, the redirect `http://localhost:33418/callback` (the Keycloak client
allows `localhost:<port>/callback` for the ports it was set up with, 33418 by
default) and the scopes `openid profile email offline_access`; for
orchestrate the header `X-API-Key: <key>`. Agents that read `SKILL.md`
folders can use `plugins/*/skills/` as they are.

Or paste this into the agent and let it configure itself:

> Connect yourself to logiccloud, following section 4b ("Any other agent") of
> https://github.com/logiccloudag/agent-kit/blob/main/INSTALL.md.
> Control domain: `logiccloud.example.com`, orchestrate domain:
> `orchestrate.example.com`. Add both MCP servers to your own MCP
> configuration and install the skills from the repository where you load
> skills from. Don't ask me for the API key in the chat; tell me where to put it.

## Command line tools

The skills work best with the CLIs: `lc` keeps a project in a local directory
under version control, and `lco` covers the whole orchestrate API. Both come
as one archive per platform (`lc_<version>_<os>_<arch>.tar.gz`,
`lco_<version>_<os>_<arch>.tar.gz`, with `SHA256SUMS`) from the
[releases](https://github.com/logiccloudag/agent-kit/releases) of this
repository. Put the binaries on your `PATH`, then log in once per machine:

```sh
lc login -domain logiccloud.example.com                  # browser login at auth.<domain>
lco login -domain orchestrate.example.com   # paste an API key
```

`lc` and `lco` take their skills from this repository: `lc pull` and
`lc agent install` (or `lco agent install`) write the current ones for Claude
Code, so the CLIs and the plugins never disagree. `lc-mcp` and `lco-mcp`, the
MCP servers, also run locally (`lco-mcp` over stdio, `lc-mcp` on
`http://127.0.0.1:8080/mcp`) when no hosted server is reachable.

## What is in here

```
.claude-plugin/marketplace.json    the marketplace for Claude Code (and Codex)
.agents/plugins/marketplace.json   the marketplace for Codex
plugins/control/                   plugin control: .claude-plugin/plugin.json (Claude Code,
                                   with the MCP server), plugin.json (Codex), skills/
plugins/orchestrate/               plugin orchestrate, the same way
workspace/control/AGENTS.md        the rules lc writes into every project workspace
setup.sh                           connects Claude Code, Codex and opencode
INSTALL.md                         setup instructions for an agent
```

## Changing the skills

This repository is where the skills live; `lc` and `lco` download them from
here. Change them here, by pull request:

- Keep each skill short and about the task; details belong in the files next
  to it (`logiccloud-hmi` links `DESIGN.md` and `COMPONENTS.md`).
  `COMPONENTS.md` is generated from the HMI catalog in `lc` (`lc agent install
  -dir <tmp>` writes the current one).
- Bump `version` in both `plugin.json` files of the plugin you changed
  (`plugins/<name>/plugin.json` and `plugins/<name>/.claude-plugin/plugin.json`),
  so Claude Code and Codex users get the update. CI checks that the two agree.
- Check with `claude plugin validate .` and `claude plugin validate plugins/<name>`.

## License

[Apache License 2.0](LICENSE), copyright logiccloud AG. The license covers the
skills, configuration and scripts in this repository; it does not grant use of
the logiccloud name or logo ([NOTICE](NOTICE)).

# Setting up logiccloud for a coding agent

These instructions are for you, the coding agent: the user asked you to connect
their agents to logiccloud. Follow them step by step and tell the user what you
did and what is left for them.

## 1. Find out the domains

logiccloud has two products. Each installation has a root domain per product;
everything else is derived from it:

- **control** (PLC projects, `lc`): e.g. `logiccloud.example.com`. The MCP server is
  `https://mcp.<domain>/mcp`; the login is OAuth at `https://auth.<domain>`.
- **orchestrate** (edge devices, `lco`): e.g. `orchestrate.example.com`.
  The MCP server is `https://mcp.<domain>/mcp`; it needs an API key.

If the user did not say which domains, ask them. A URL they copied from the
browser is fine (`https://logiccloud.example.com/projects` means `logiccloud.example.com`).
Set up only the products they want.

## 2. Never handle the API key yourself

Do not ask the user to paste the orchestrate API key into the chat, and do not
write it into any file. Either the user enters it in their own terminal (step
3), or it is already in their environment as `LCO_API_KEY`.

## 3. Run setup.sh (macOS, Linux, WSL)

Check that `bash` and `curl` exist (and `jq` if opencode is used). Then run,
with the user's domains (leave out a product they don't use):

```sh
curl -fsSL https://raw.githubusercontent.com/logiccloudag/agent-kit/main/setup.sh | bash -s -- \
  --control <control domain> --orchestrate <orchestrate domain> --no-login
```

It sets up every agent it finds: Claude Code (plugins from the marketplace
`logiccloudag/agent-kit`, with the domain), Codex (plugins, plus the servers in
`~/.codex/config.toml`) and opencode (skills and servers in
`~/.config/opencode`). `--agents claude,codex,opencode` limits it. Add
`--dry-run` first if the user wants to see the changes. It is safe to run
again.

You have no terminal for the user's input, so the script cannot ask for the
API key or open the login. At the end it prints "Still to do"; pass every line
of that on to the user. Typically:

- Claude Code: `/plugin configure orchestrate@logiccloud` to enter the API key,
  and `/mcp` → `plugin:control:logiccloud-control` to log in.
- Codex: `codex mcp login logiccloud-control`; start Codex with `LCO_API_KEY`
  set.
- opencode: `opencode mcp auth logiccloud-control`; start opencode with
  `LCO_API_KEY` set.

Alternatively the user can run the command above in their own terminal without
`--no-login`; then the script asks for the key and opens the logins itself.

## 4. Without bash (Windows)

- **Claude Code**: run `claude plugin marketplace add logiccloudag/agent-kit`,
  then `claude plugin install control@logiccloud --config domain=<control domain>`
  and `claude plugin install orchestrate@logiccloud --config domain=<orchestrate domain>`.
  The user enters the API key with `/plugin configure orchestrate@logiccloud`.
- **Codex**: `codex plugin marketplace add logiccloudag/agent-kit`,
  `codex plugin add control@logiccloud`, `codex plugin add orchestrate@logiccloud`,
  then add the `[mcp_servers...]` entries from the README's Codex section to
  `%USERPROFILE%\.codex\config.toml`, with the user's domains.
- **opencode**: add the `mcp` entries from the README's opencode section to
  `%USERPROFILE%\.config\opencode\opencode.json` (merge, do not replace the
  file), and copy the folders under `plugins/*/skills/` of
  https://github.com/logiccloudag/agent-kit into
  `%USERPROFILE%\.config\opencode\skills\`.

## 4b. Any other agent (configure yourself)

If you are not Claude Code, Codex or opencode, set yourself up from your own
documentation on MCP servers and skills:

1. Add two MCP servers (streamable HTTP) to your own configuration, user-wide
   if you have that:
   - `logiccloud-control`: `https://mcp.<control domain>/mcp`, OAuth 2.1 with
     PKCE. Use the pre-registered public client `lc-mcp` (no secret), the
     redirect URI `http://localhost:33418/callback` and the scopes
     `openid profile email offline_access`. The server's
     `/.well-known/oauth-protected-resource/mcp` names the authorization
     server (`https://auth.<control domain>/realms/<control domain>`).
     Use this client rather than dynamic client registration. If your client
     can only use another redirect URI, tell the user: an administrator has to
     allow it for `lc-mcp` in Keycloak.
   - `logiccloud-orchestrate`: `https://mcp.<orchestrate domain>/mcp`, no
     OAuth; every request sends the header `X-API-Key: <API key>`. Take the key
     from the environment variable `LCO_API_KEY` if your configuration can
     reference one; otherwise tell the user where to enter it.
2. Install the skills: download https://github.com/logiccloudag/agent-kit
   (`https://codeload.github.com/logiccloudag/agent-kit/tar.gz/main`) and copy
   the folders under `plugins/control/skills/` and
   `plugins/orchestrate/skills/` (each with a `SKILL.md`) to where you load
   skills from (often `~/.agents/skills/`). If you have no skills, put a short
   note into your instructions file that the skills exist, and read the
   `SKILL.md` files when the user works with logiccloud.
3. Tell the user how to log in to the control server with you, and to restart
   you.

## 5. The command line tools (optional)

The skills prefer `lc` and `lco` when they are installed. If the user wants
them, download the archive for their platform from
https://github.com/logiccloudag/agent-kit/releases, put the binaries on the
`PATH`, and have the user run `lc login -domain <control domain>` and
`lco login -domain <orchestrate domain>` in their terminal (both are
interactive).

## 6. Check

Agents load new plugins, skills and servers only when they start, so ask the
user to restart theirs. After that, `claude mcp list`, `codex mcp list` or
`opencode mcp list` show the servers `logiccloud-control` and
`logiccloud-orchestrate`. A control server that says it needs authentication
just needs the login from step 3.

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
  The MCP server is `https://mcp.<domain>/mcp`; the login is OAuth at
  `https://keycloak.<domain>`.

If the user did not say which domains, ask them. A URL they copied from the
browser is fine (`https://logiccloud.example.com/projects` means `logiccloud.example.com`).
Set up only the products they want.

## 2. Never handle credentials yourself

Both products log the user in with OAuth in the browser. Do not ask the user
for a password or an API key in the chat, and do not write one into any file.
If the user wants an orchestrate API key instead of the login, they put it in
their agent's configuration themselves (README, "With an orchestrate API key").

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

You have no terminal for the user's input, so the script cannot open the
logins. At the end it prints "Still to do"; pass every line of that on to the
user. Typically:

- Claude Code: `/mcp` → `plugin:control:logiccloud-control` and
  `plugin:orchestrate:logiccloud-orchestrate` to log in.
- Codex: `codex mcp login logiccloud-control` and
  `codex mcp login logiccloud-orchestrate`.
- opencode: `opencode mcp auth logiccloud-control` and
  `opencode mcp auth logiccloud-orchestrate`.

Alternatively the user can run the command above in their own terminal without
`--no-login`; then the script opens the logins itself.

## 4. Without bash (Windows)

- **Claude Code**: run `claude plugin marketplace add logiccloudag/agent-kit`,
  then `claude plugin install control@logiccloud --config domain=<control domain>`
  and `claude plugin install orchestrate@logiccloud --config domain=<orchestrate domain>`.
  The user logs in with `/mcp`.
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
   - `logiccloud-orchestrate`: `https://mcp.<orchestrate domain>/mcp`, the
     same way with the public client `lco-mcp` (redirect
     `http://localhost:33418/callback`, the same scopes); the authorization
     server is `https://keycloak.<orchestrate domain>/realms/fleet-manager`.
     If the user prefers an API key, the server also takes the header
     `X-API-Key: <API key>` instead; tell the user where to enter it.
2. Install the skills: download https://github.com/logiccloudag/agent-kit
   (`https://codeload.github.com/logiccloudag/agent-kit/tar.gz/main`) and copy
   the folders under `plugins/control/skills/` and
   `plugins/orchestrate/skills/` (each with a `SKILL.md`) to where you load
   skills from (often `~/.agents/skills/`). If you have no skills, put a short
   note into your instructions file that the skills exist, and read the
   `SKILL.md` files when the user works with logiccloud.
3. Tell the user how to log in to both servers with you, and to restart you.

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
`logiccloud-orchestrate`. A server that says it needs authentication just
needs the login from step 3.

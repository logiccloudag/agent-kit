#!/usr/bin/env bash
# setup.sh connects coding agents (Claude Code, Codex, opencode) to logiccloud
# control and logiccloud orchestrate: it installs the skills and adds the MCP
# servers of your installation, which it finds from the installation's root
# domain:
#
#   control      https://mcp.<domain>/mcp   login at https://auth.<domain> (OAuth, client lc-mcp)
#   orchestrate  https://mcp.<domain>/mcp   API key in the X-API-Key header
#
#   curl -fsSL https://raw.githubusercontent.com/logiccloudag/agent-kit/main/setup.sh | bash -s -- \
#     --control logiccloud.example.com --orchestrate orchestrate.example.com
#
# Run it again to update; --remove takes everything out again. See README.md.
# jq programs are in single quotes on purpose:
# shellcheck disable=SC2016
set -euo pipefail

REPO=logiccloudag/agent-kit
MARKETPLACE=logiccloud
CONTROL_SERVER=logiccloud-control
ORCH_SERVER=logiccloud-orchestrate
CLIENT_ID=lc-mcp
CALLBACK_PORT=33418
SCOPES="openid profile email offline_access"
KEY_VAR=LCO_API_KEY

SOURCE=${AGENT_KIT_SOURCE:-$REPO} # owner/repo on GitHub, or a local checkout
REF=${AGENT_KIT_REF:-main}
CONTROL=
ORCH=
AGENTS=
DRY=
REMOVE=
LOGIN=1

usage() {
	cat <<EOF
Usage: setup.sh [--control DOMAIN] [--orchestrate DOMAIN] [options]

Connects Claude Code, Codex and opencode to logiccloud. DOMAIN is the root
domain of the installation, e.g. logiccloud.example.com (control) or
orchestrate.example.com (orchestrate); a URL works too. Without either
option it asks for both.

Options:
  --control DOMAIN       logiccloud control: MCP server https://mcp.DOMAIN/mcp, skills for lc
  --orchestrate DOMAIN   logiccloud orchestrate: MCP server https://mcp.DOMAIN/mcp, skills for lco
  --agents LIST          comma-separated: claude,codex,opencode (default: those installed)
  --no-login             do not start the control OAuth login for Codex and opencode
  --remove               remove what setup.sh installed (with --control/--orchestrate: only that)
  --dry-run              only print what would be done
  -h, --help             this help

The orchestrate API key: Claude Code keeps it in its secure storage (asked here,
or taken from \$$KEY_VAR); Codex and opencode read \$$KEY_VAR when they start.

Environment: AGENT_KIT_SOURCE (default $REPO, or a local checkout),
AGENT_KIT_REF (default main).
EOF
}

die() { printf 'setup.sh: %s\n' "$*" >&2; exit 1; }
say() { printf '%s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }
tty_ok() { [[ -r /dev/tty && -w /dev/tty ]] && { : </dev/tty; } 2>/dev/null; }

# run prints a command and runs it (only prints it with --dry-run).
# Commands get no stdin: with `curl ... | bash` it is the rest of this script.
run() {
	printf '+ %s\n' "$*"
	[[ -n $DRY ]] || "$@" </dev/null
}

while [[ $# -gt 0 ]]; do
	case $1 in
	--control) CONTROL=${2:?--control needs a domain}; shift 2 ;;
	--control=*) CONTROL=${1#*=}; shift ;;
	--orchestrate) ORCH=${2:?--orchestrate needs a domain}; shift 2 ;;
	--orchestrate=*) ORCH=${1#*=}; shift ;;
	--agents) AGENTS=${2:?--agents needs a list}; shift 2 ;;
	--agents=*) AGENTS=${1#*=}; shift ;;
	--no-login) LOGIN=; shift ;;
	--remove) REMOVE=1; shift ;;
	--dry-run) DRY=1; shift ;;
	-h | --help) usage; exit 0 ;;
	*) usage >&2; die "unknown option $1" ;;
	esac
done

# domain turns what the user typed (a domain or a URL of the installation)
# into the root domain: no scheme, path or port, lower case, and without the
# mcp./auth./api. host the user may have copied.
domain() {
	local d=$1
	d=${d#*://}
	d=${d%%/*}
	d=${d%%:*}
	d=${d%.}
	d=$(printf '%s' "$d" | tr '[:upper:]' '[:lower:]')
	case $d in mcp.* | auth.* | api.*) d=${d#*.} ;; esac
	[[ $d =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$ ]] ||
		die "not a domain: '$1' (expected e.g. logiccloud.example.com)"
	printf '%s' "$d"
}

ask() { # ask PROMPT -> answer on stdout ("" without a terminal)
	local a=
	tty_ok || return 0
	printf '%s' "$1" >/dev/tty
	IFS= read -r a </dev/tty || true
	printf '%s' "$a"
}

ask_secret() {
	local a=
	tty_ok || return 0
	stty -echo </dev/tty 2>/dev/null || true # before the prompt, or early typing shows
	printf '%s' "$1" >/dev/tty
	IFS= read -r a </dev/tty || true
	stty echo </dev/tty 2>/dev/null || true
	printf '\n' >/dev/tty
	printf '%s' "$a"
}

json_str() { # a JSON string literal
	local s=$1
	s=${s//\\/\\\\}
	s=${s//\"/\\\"}
	printf '"%s"' "$s"
}

if [[ -z $CONTROL && -z $ORCH && -z $REMOVE ]]; then
	tty_ok || die "no terminal to ask on: pass --control DOMAIN and/or --orchestrate DOMAIN"
	CONTROL=$(ask "logiccloud control domain, e.g. logiccloud.example.com (empty: skip): ")
	ORCH=$(ask "logiccloud orchestrate domain, e.g. orchestrate.example.com (empty: skip): ")
	[[ -n $CONTROL || -n $ORCH ]] || die "nothing to set up"
fi
[[ -z $CONTROL || $CONTROL == - ]] || CONTROL=$(domain "$CONTROL")
[[ -z $ORCH || $ORCH == - ]] || ORCH=$(domain "$ORCH")
# --remove without a product removes both
if [[ -n $REMOVE && -z $CONTROL && -z $ORCH ]]; then CONTROL=- ORCH=-; fi

if [[ -z $AGENTS ]]; then
	for a in claude codex opencode; do have "$a" && AGENTS+="${AGENTS:+,}$a"; done
	[[ -n $AGENTS ]] || die "none of claude, codex, opencode is installed (or on PATH)"
fi
IFS=, read -r -a AGENT_LIST <<<"$AGENTS"
for a in "${AGENT_LIST[@]}"; do
	case $a in claude | codex | opencode) have "$a" || die "$a is not installed (or not on PATH)" ;;
	*) die "unknown agent '$a' (claude, codex, opencode)" ;; esac
done

local_source() { [[ -d $SOURCE ]]; }

# The orchestrate API key, for Claude Code (the others read $LCO_API_KEY).
API_KEY=${!KEY_VAR:-}
want_key() {
	[[ -n $API_KEY || -n $DRY ]] && return 0
	API_KEY=$(ask_secret "orchestrate API key (Settings > Security > API Keys; empty: set it later): ")
}

# ---------------------------------------------------------------- Claude Code

claude_installed() { claude plugin list 2>/dev/null | grep -q "$1@$MARKETPLACE"; }

claude_setup() {
	step "Claude Code"
	if claude plugin marketplace list 2>/dev/null | grep -qw "$MARKETPLACE"; then
		run claude plugin marketplace update "$MARKETPLACE"
	elif local_source; then
		run claude plugin marketplace add "$SOURCE"
	else
		run claude plugin marketplace add "$SOURCE@$REF"
	fi
	if [[ -n $CONTROL ]]; then
		if claude_installed control; then
			say "+ claude plugin configure control@$MARKETPLACE --values-stdin   # domain=$CONTROL"
			[[ -n $DRY ]] || printf '{"domain":%s}' "$(json_str "$CONTROL")" |
				claude plugin configure "control@$MARKETPLACE" --values-stdin >/dev/null
		else
			run claude plugin install "control@$MARKETPLACE" --config "domain=$CONTROL"
		fi
	fi
	if [[ -n $ORCH ]]; then
		if claude_installed orchestrate; then
			say "+ claude plugin configure orchestrate@$MARKETPLACE --values-stdin   # domain=$ORCH"
			[[ -n $DRY ]] || printf '{"domain":%s}' "$(json_str "$ORCH")" |
				claude plugin configure "orchestrate@$MARKETPLACE" --values-stdin >/dev/null
		else
			run claude plugin install "orchestrate@$MARKETPLACE" --config "domain=$ORCH"
		fi
		want_key
		if [[ -n $API_KEY ]]; then
			say "+ claude plugin configure orchestrate@$MARKETPLACE --values-stdin   # api_key (secure storage)"
			[[ -n $DRY ]] || printf '{"api_key":%s}' "$(json_str "$API_KEY")" |
				claude plugin configure "orchestrate@$MARKETPLACE" --values-stdin >/dev/null
		else
			NOTES+=("Claude Code: set the orchestrate API key with /plugin configure orchestrate@$MARKETPLACE")
		fi
	fi
	[[ -z $CONTROL ]] || NOTES+=("Claude Code: log in to logiccloud control with /mcp (server plugin:control:$CONTROL_SERVER)")
}

claude_remove() {
	step "Claude Code"
	local p
	for p in control orchestrate; do
		[[ $p == control && -z $CONTROL ]] && continue
		[[ $p == orchestrate && -z $ORCH ]] && continue
		if claude_installed "$p"; then run claude plugin uninstall "$p@$MARKETPLACE"; fi
	done
	if [[ -n $CONTROL && -n $ORCH ]] && claude plugin marketplace list 2>/dev/null | grep -qw "$MARKETPLACE"; then
		run claude plugin marketplace remove "$MARKETPLACE"
	fi
}

# ---------------------------------------------------------------------- Codex

CODEX_CONFIG=${CODEX_HOME:-$HOME/.codex}/config.toml

codex_q() { codex "$@" </dev/null 2>&1 | grep -v -E 'UNDICI|trace-warnings|PATH aliases' || true; }

codex_has_server() { [[ -f $CODEX_CONFIG ]] && grep -q "^\[mcp_servers\.$1\]" "$CODEX_CONFIG"; }

codex_setup() {
	step "Codex"
	if codex_q plugin marketplace list | grep -qw "$MARKETPLACE"; then
		local_source || run codex plugin marketplace upgrade "$MARKETPLACE"
	elif local_source; then
		run codex plugin marketplace add "$SOURCE"
	else
		run codex plugin marketplace add "$SOURCE" --ref "$REF"
	fi
	[[ -z $CONTROL ]] || run codex plugin add "control@$MARKETPLACE"
	[[ -z $ORCH ]] || run codex plugin add "orchestrate@$MARKETPLACE"

	# `codex mcp add` cannot set headers, scopes or the callback URL (and starts
	# a login right away), so the servers go into config.toml directly.
	local block=
	if [[ -n $CONTROL ]]; then
		block+="
[mcp_servers.$CONTROL_SERVER]
url = \"https://mcp.$CONTROL/mcp\"
scopes = [\"${SCOPES// /\", \"}\"]

[mcp_servers.$CONTROL_SERVER.oauth]
client_id = \"$CLIENT_ID\"
callback_url = \"http://localhost:$CALLBACK_PORT/callback\"
"
	fi
	if [[ -n $ORCH ]]; then
		block+="
[mcp_servers.$ORCH_SERVER]
url = \"https://mcp.$ORCH/mcp\"
env_http_headers = { \"X-API-Key\" = \"$KEY_VAR\" }
"
	fi
	local s
	for s in $([[ -z $CONTROL ]] || echo $CONTROL_SERVER) $([[ -z $ORCH ]] || echo $ORCH_SERVER); do
		if codex_has_server "$s"; then run codex mcp remove "$s" >/dev/null; fi
	done
	say "+ append to $CODEX_CONFIG:"
	printf '%s' "$block" | sed 's/^/    /'
	if [[ -z $DRY ]]; then
		mkdir -p "$(dirname "$CODEX_CONFIG")"
		printf '%s' "$block" >>"$CODEX_CONFIG"
	fi
	[[ -z $ORCH ]] || NOTES+=("Codex: export $KEY_VAR=<orchestrate API key> in the shell that starts codex")
	if [[ -n $CONTROL ]]; then
		if [[ -n $LOGIN && -z $DRY ]] && tty_ok; then
			say "+ codex mcp login $CONTROL_SERVER"
			codex mcp login "$CONTROL_SERVER" </dev/tty 2>&1 | grep -v -E 'UNDICI|trace-warnings|PATH aliases' ||
				NOTES+=("Codex: log in to logiccloud control with: codex mcp login $CONTROL_SERVER")
		else
			NOTES+=("Codex: log in to logiccloud control with: codex mcp login $CONTROL_SERVER")
		fi
	fi
}

codex_remove() {
	step "Codex"
	local p s
	for p in control orchestrate; do
		[[ $p == control && -z $CONTROL ]] && continue
		[[ $p == orchestrate && -z $ORCH ]] && continue
		if codex_q plugin list | grep -q "^$p@$MARKETPLACE .*installed" &&
			! codex_q plugin list | grep -q "^$p@$MARKETPLACE  *not installed"; then
			run codex plugin remove "$p@$MARKETPLACE"
		fi
	done
	for s in $([[ -z $CONTROL ]] || echo $CONTROL_SERVER) $([[ -z $ORCH ]] || echo $ORCH_SERVER); do
		if codex_has_server "$s"; then run codex mcp remove "$s"; fi
	done
	if [[ -n $CONTROL && -n $ORCH ]] && codex_q plugin marketplace list | grep -qw "$MARKETPLACE"; then
		run codex plugin marketplace remove "$MARKETPLACE"
	fi
}

# ------------------------------------------------------------------- opencode

OPENCODE_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/opencode
MARKER=.agent-kit # in every skill directory setup.sh wrote

# fetch_source puts the repository (at $REF) into $SRC.
SRC=
fetch_source() {
	[[ -z $SRC ]] || return 0
	if local_source; then
		SRC=$SOURCE
		return
	fi
	TMP=$(mktemp -d)
	trap 'rm -rf "$TMP"' EXIT
	say "+ download https://github.com/$SOURCE ($REF)"
	curl -fsSL "https://codeload.github.com/$SOURCE/tar.gz/$REF" | tar -xz -C "$TMP" ||
		die "could not download https://codeload.github.com/$SOURCE/tar.gz/$REF"
	SRC=$(echo "$TMP"/*)
}

# opencode_json edits opencode.json with jq. $1 describes the change, the
# rest are jq's arguments.
opencode_json() {
	local f=$OPENCODE_DIR/opencode.json desc=$1
	shift
	if [[ ! -f $f && -f $OPENCODE_DIR/opencode.jsonc ]]; then
		NOTES+=("opencode: $OPENCODE_DIR/opencode.jsonc is not edited automatically; add the \"mcp\" entries from README.md")
		return
	fi
	say "+ $desc in $f"
	[[ -n $DRY ]] && return
	mkdir -p "$OPENCODE_DIR"
	[[ -s $f ]] || printf '{\n  "$schema": "https://opencode.ai/config.json"\n}\n' >"$f"
	have jq || die "opencode needs jq to edit $f; install jq and run setup.sh again"
	local out
	out=$(jq "$@" "$f") || die "could not edit $f (comments in it? jq reads plain JSON only)"
	printf '%s\n' "$out" >"$f"
}

opencode_skills() { # install|remove
	local dir=$OPENCODE_DIR/skills p s name
	for p in control orchestrate; do
		[[ $p == control && -z $CONTROL ]] && continue
		[[ $p == orchestrate && -z $ORCH ]] && continue
		if [[ $1 == remove ]]; then
			for s in "$dir"/*/"$MARKER"; do
				[[ -f $s ]] || continue
				grep -qx "$p" "$s" || continue
				run rm -rf "$(dirname "$s")"
			done
			continue
		fi
		fetch_source
		for s in "$SRC/plugins/$p/skills"/*/; do
			name=$(basename "$s")
			if [[ -d $dir/$name && ! -f $dir/$name/$MARKER ]]; then
				warn "$dir/$name was not written by setup.sh; left alone"
				continue
			fi
			say "+ skill $name -> $dir/$name"
			[[ -n $DRY ]] && continue
			rm -rf "${dir:?}/$name"
			mkdir -p "$dir"
			cp -R "$s" "$dir/$name"
			printf '%s\n' "$p" >"$dir/$name/$MARKER"
		done
	done
}

opencode_setup() {
	step "opencode"
	opencode_skills install
	if [[ -n $CONTROL ]]; then
		opencode_json "MCP server $CONTROL_SERVER" \
			--arg name "$CONTROL_SERVER" --arg url "https://mcp.$CONTROL/mcp" --arg client "$CLIENT_ID" \
			--arg redirect "http://localhost:$CALLBACK_PORT/callback" --arg scope "$SCOPES" \
			'.mcp[$name] = {type: "remote", url: $url, oauth: {clientId: $client, redirectUri: $redirect, scope: $scope}}'
	fi
	if [[ -n $ORCH ]]; then
		opencode_json "MCP server $ORCH_SERVER" \
			--arg name "$ORCH_SERVER" --arg url "https://mcp.$ORCH/mcp" --arg key "{env:$KEY_VAR}" \
			'.mcp[$name] = {type: "remote", url: $url, headers: {"X-API-Key": $key}, oauth: false}'
		NOTES+=("opencode: export $KEY_VAR=<orchestrate API key> in the shell that starts opencode")
	fi
	if [[ -n $CONTROL ]]; then
		if [[ -n $LOGIN && -z $DRY ]] && tty_ok; then
			say "+ opencode mcp auth $CONTROL_SERVER"
			opencode mcp auth "$CONTROL_SERVER" </dev/tty ||
				NOTES+=("opencode: log in to logiccloud control with: opencode mcp auth $CONTROL_SERVER")
		else
			NOTES+=("opencode: log in to logiccloud control with: opencode mcp auth $CONTROL_SERVER")
		fi
	fi
}

opencode_remove() {
	step "opencode"
	opencode_skills remove
	local f=$OPENCODE_DIR/opencode.json s
	[[ -f $f ]] || return 0
	for s in $([[ -z $CONTROL ]] || echo $CONTROL_SERVER) $([[ -z $ORCH ]] || echo $ORCH_SERVER); do
		if have jq && jq -e --arg n "$s" '.mcp[$n]' "$f" >/dev/null 2>&1; then
			opencode_json "remove MCP server $s" --arg n "$s" 'del(.mcp[$n])'
		fi
	done
}

# ----------------------------------------------------------------------- main

NOTES=()
main() {
if [[ -n $REMOVE ]]; then
	for a in "${AGENT_LIST[@]}"; do "${a}_remove"; done
	say ""
	say "Done."
	return
fi

say "Setting up for: ${AGENT_LIST[*]}"
[[ -z $CONTROL ]] || say "  control      https://mcp.$CONTROL/mcp (login https://auth.$CONTROL)"
[[ -z $ORCH ]] || say "  orchestrate  https://mcp.$ORCH/mcp (API key)"
for a in "${AGENT_LIST[@]}"; do "${a}_setup"; done

say ""
say "Done. Restart your agents so they load the skills and servers."
if [[ ${#NOTES[@]} -gt 0 ]]; then
	say ""
	say "Still to do:"
	for n in "${NOTES[@]}"; do say "  - $n"; done
fi
cat <<EOF

The CLIs (optional, the skills prefer them when present):
  lc  login -domain ${CONTROL:-<control domain>}
  lco login -domain ${ORCH:-<orchestrate domain>}
  (downloads: https://github.com/$REPO#command-line-tools)
EOF
}

# main is called only after bash has read the whole file (see run).
main

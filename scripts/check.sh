#!/usr/bin/env bash
# check.sh checks the repository: JSON parses, both manifests of a plugin
# agree, every skill has a name and description matching its folder, and
# setup.sh passes shellcheck (if installed). CI runs it; so can you.
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
err() { printf 'error: %s\n' "$*" >&2; fail=1; }

for f in .claude-plugin/marketplace.json .agents/plugins/marketplace.json plugins/*/plugin.json plugins/*/.claude-plugin/plugin.json; do
	jq empty "$f" 2>/dev/null || err "$f is not valid JSON"
done

for d in plugins/*/; do
	p=$(basename "$d")
	for k in name version description; do
		a=$(jq -r ".$k" "$d/plugin.json")
		b=$(jq -r ".$k" "$d/.claude-plugin/plugin.json")
		[[ $a == "$b" ]] || err "$p: $k differs: plugin.json '$a', .claude-plugin/plugin.json '$b'"
	done
	[[ $(jq -r .name "$d/plugin.json") == "$p" ]] || err "$p: name in plugin.json is not the folder name"
	for m in .claude-plugin/marketplace.json .agents/plugins/marketplace.json; do
		jq -e --arg p "$p" '.plugins[] | select(.name == $p)' "$m" >/dev/null || err "$p is missing in $m"
	done
	for s in "$d"skills/*/SKILL.md; do
		dir=$(basename "$(dirname "$s")")
		head -1 "$s" | grep -qx -- --- || err "$s: no front matter"
		name=$(sed -n '2,/^---$/{s/^name: *//p;}' "$s")
		[[ $name == "$dir" ]] || err "$s: name '$name' is not the folder name '$dir'"
		sed -n '2,/^---$/p' "$s" | grep -q '^description: .\{20,\}' || err "$s: no description"
	done
done

if command -v shellcheck >/dev/null; then
	shellcheck setup.sh scripts/*.sh || fail=1
else
	echo "shellcheck not installed; skipped" >&2
fi
[[ $fail == 0 ]] && echo ok
exit $fail

#!/usr/bin/env bash
# The qwen38 SessionStart hook injects the whole `using-qwen38` router into a Qwen
# session, and says so out loud when the skill is not installed (2026-09-06).
#
# Anchors are lines the router actually carries (THINK:, the brief table rule) and the
# hook's own JSON envelope; the negative proves the fallback names the missing skill.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
HOOK="$ROOT/skills/qwen38/using-qwen38/hooks/session-start"
pass=0; fail=0
ok()  { pass=$((pass+1)); }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }
has()   { printf '%s' "$2" | grep -qF -- "$1" && ok || bad "missing: $1"; }
hasnt() { printf '%s' "$2" | grep -qF -- "$1" && bad "present: $1" || ok; }

[ -f "$HOOK" ] && ok || bad "hook missing: $HOOK"

# positive: installed copy resolves through CLAUDE_CONFIG_DIR
tmp="$(mktemp -d)"
mkdir -p "$tmp/skills/using-qwen38"
cp "$ROOT/skills/qwen38/using-qwen38/SKILL.md" "$tmp/skills/using-qwen38/SKILL.md"
out="$(printf '{"session_id":"t"}' | CLAUDE_CONFIG_DIR="$tmp" bash "$HOOK")"
has '"hookEventName":"SessionStart"' "$out"
has 'THINK:' "$out"
has 'brief table' "$out"
has 'qwen38-code-gate' "$out"
has 'EXTREMELY_IMPORTANT' "$out"
hasnt 'target-model:' "$out"        # frontmatter is dropped
python -c 'import json,sys; json.loads(sys.stdin.read())' <<<"$out" && ok || bad "output is not valid JSON"

# negative: no installed skill and no checkout copy -> the fallback names the skill
empty="$(mktemp -d)"
copy="$(mktemp -d)/hooks"; mkdir -p "$copy"; cp "$HOOK" "$copy/session-start"
out2="$(printf '{}' | CLAUDE_CONFIG_DIR="$empty" bash "$copy/session-start")"
has 'using-qwen38' "$out2"
has 'not installed' "$out2"
hasnt 'THINK:' "$out2"

rm -rf "$tmp" "$empty" "$(dirname "$copy")"
echo "qwen38-session-start: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

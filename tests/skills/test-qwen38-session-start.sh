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

# #409: the hook serves every Qwen3.8 profile (27B and Flash-Next), so it names no single
# model, and it states this session's own turn cap and context from the profile's env --
# the skill used to carry 12,288 and 262,144 by hand and both went stale.
hasnt 'Qwen3.8-27B' "$out"
hasnt 'Qwen3.8-27B' "$out2"
has 'You are Qwen3.8 running Claude Code' "$out"
env_out() { printf '{}' | env -u CLAUDE_CODE_MAX_OUTPUT_TOKENS -u CLAUDE_CODE_MAX_CONTEXT_TOKENS \
  -u CLAUDE_AUTOCOMPACT_PCT_OVERRIDE "$@" CLAUDE_CONFIG_DIR="$tmp2" bash "$HOOK"; }
tmp2="$(mktemp -d)"; mkdir -p "$tmp2/skills/using-qwen38"
cp "$ROOT/skills/qwen38/using-qwen38/SKILL.md" "$tmp2/skills/using-qwen38/SKILL.md"
s="$(env_out CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000 CLAUDE_CODE_MAX_CONTEXT_TOKENS=262144 CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=95)"
has 'at most 128000 output tokens, thinking included' "$s"
has 'context is 262144 tokens' "$s"
has 'compacts at 95 %' "$s"
s="$(env_out CLAUDE_CODE_MAX_OUTPUT_TOKENS=12288 CLAUDE_CODE_MAX_CONTEXT_TOKENS=131072)"
has 'at most 12288 output tokens' "$s"
has 'context is 131072 tokens' "$s"
s="$(env_out CLAUDE_CODE_MAX_OUTPUT_TOKENS=262144)"     # Claude Code sends at most 128000 (2.1.290, captured)
has 'at most 128000 output tokens' "$s"
hasnt 'at most 262144' "$s"
s="$(env_out)"
has 'turn cap is not set in this profile' "$s"
has 'context is not set in this profile' "$s"
python -c 'import json,sys; json.loads(sys.stdin.read())' <<<"$s" && ok || bad "env-less output is not valid JSON"
s="$(printf '{}' | CLAUDE_CODE_MAX_OUTPUT_TOKENS=12288 CLAUDE_CONFIG_DIR="$empty" bash "$copy/session-start")"
has 'at most 12288 output tokens' "$s"          # the not-installed fallback carries it too
rm -rf "$tmp2"

rm -rf "$tmp" "$empty" "$(dirname "$copy")"
echo "qwen38-session-start: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

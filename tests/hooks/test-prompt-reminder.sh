#!/usr/bin/env bash
# Contract tests for hooks/t4-prompt-reminder
# Seam: stdin (UserPromptSubmit JSON) + cwd -> stdout (rails reminder JSON or empty)
# Unlike session-start, this fires EVERY turn (no per-session dedup).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-prompt-reminder"

pass=0 fail=0
ok()   { echo "  PASS: $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL: $1"; fail=$((fail+1)); }
has()  { case "$1" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
empty(){ if [ -z "$1" ]; then ok "$2"; else bad "$2 (got: ${1:0:60}...)"; fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/repo/.claude"; printf '{"t4":true}\n' > "$TMP/repo/.claude/t4.json"
mkdir -p "$TMP/plain"
export T4_HOOK_LOCK_DIR="$TMP/locks"

run() { # cwd
  ( cd "$1" && printf '{"session_id":"s1","prompt":"add a feature","hook_event_name":"UserPromptSubmit"}' \
      | bash "$HOOK" )
}

echo "Test 1: injects a rails reminder in a T4 repo"
out="$(run "$TMP/repo")"
has "$out" '"additionalContext"' "emits additionalContext"
has "$out" 'using-t4'            "points at using-t4"
has "$out" 't4-dev-workflow'     "points at t4-dev-workflow for build/PR work"

echo "Test 2: fires again on the next turn (no dedup)"
out2="$(run "$TMP/repo")"
has "$out2" '"additionalContext"' "still injects on a second turn"

echo "Test 3: non-T4 repo is silent"
out3="$(run "$TMP/plain")"
empty "$out3" "no reminder without .claude/t4.json marker"

echo ""
echo "prompt-reminder: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# Contract tests for hooks/t4-session-start
# Seam: stdin (hook JSON) + cwd + env -> stdout (SessionStart injection JSON or empty)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-session-start"

pass=0 fail=0
ok()   { echo "  PASS: $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL: $1"; fail=$((fail+1)); }
has()  { case "$1" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
empty(){ if [ -z "$1" ]; then ok "$2"; else bad "$2 (got: ${1:0:60}...)"; fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/repo/.claude"; printf '{"t4":true}\n' > "$TMP/repo/.claude/t4.json"
mkdir -p "$TMP/plain"
export T4_HOOK_LOCK_DIR="$TMP/locks"

run() { # session_id cwd  (hook reads the repo from its own cwd, like Claude Code does)
  ( cd "$2" && printf '{"session_id":"%s","hook_event_name":"SessionStart","source":"startup"}' "$1" \
      | CLAUDE_PLUGIN_ROOT="$REPO_ROOT" bash "$HOOK" )
}

echo "Test 1: injects using-t4 content in a T4 repo (fresh session)"
out="$(run s1 "$TMP/repo")"
has "$out" '"additionalContext"' "emits additionalContext"
has "$out" 'Using T4'            "includes using-t4 skill content"
has "$out" 'EXTREMELY_IMPORTANT' "wraps in EXTREMELY_IMPORTANT"

echo "Test 2: an immediate second firing is silent (concurrent A+B dedup, within window)"
out2="$(run s1 "$TMP/repo")"
empty "$out2" "no double-injection for the same event"

echo "Test 2b: same session RE-injects on a later event past the window (compaction survival)"
mkdir -p "$T4_HOOK_LOCK_DIR"
printf '%s' "$(( $(date +%s) - 3600 ))" > "$T4_HOOK_LOCK_DIR/s1.session-start"
out2b="$(run s1 "$TMP/repo")"
has "$out2b" '"additionalContext"' "a stale lock (past the dedup window) re-injects"

echo "Test 3: a fresh session_id still injects (lock is per-session)"
out3="$(run s2 "$TMP/repo")"
has "$out3" '"additionalContext"' "new session re-injects"

echo "Test 4: non-T4 repo (no marker) is silent"
out4="$(run s3 "$TMP/plain")"
empty "$out4" "no injection without .claude/t4.json marker"

echo ""
echo "session-start: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

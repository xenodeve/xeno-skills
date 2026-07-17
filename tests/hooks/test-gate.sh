#!/usr/bin/env bash
# Contract tests for hooks/t4-gate (PreToolUse)
# Seam: stdin (PreToolUse JSON) + cwd -> deny-decision JSON (block) OR empty (allow).
# The gate only ever BLOCKS; it never auto-approves (silence = normal flow).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-gate"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
denied()  { case "$1" in *'"permissionDecision":"deny"'*) ok "$2";; *) bad "$2 (expected deny, got: ${1:0:50})";; esac; }
allowed() { if [ -z "$1" ]; then ok "$2"; else bad "$2 (expected allow/silent, got: ${1:0:50})"; fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude"; printf '{"t4":true}\n' > "$REPO/.claude/t4.json"
PLAIN="$TMP/plain"; mkdir -p "$PLAIN"
printf 'PR body\nCloses #7\n' > "$TMP/withref.md"
printf 'PR body\njust some text\n'   > "$TMP/noref.md"

bashj() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"cwd":"x"}' "$1"; }
run()  { ( cd "$1" && printf '%s' "$2" | bash "$HOOK" ); }

echo "PR-needs-issue:"
allowed "$(run "$REPO" "$(bashj 'gh pr create --title x --body Closes #12')")"        "allow: PR with #12 inline"
denied  "$(run "$REPO" "$(bashj 'gh pr create --title x --body just-some-text')")"     "deny:  PR with no issue ref"
allowed "$(run "$REPO" "$(bashj "gh pr create --title x --body-file $TMP/withref.md")")" "allow: PR whose --body-file references #7"
denied  "$(run "$REPO" "$(bashj "gh pr create --title x --body-file $TMP/noref.md")")"   "deny:  PR whose --body-file has no ref"

echo "dangerous git:"
denied  "$(run "$REPO" "$(bashj 'git reset --hard HEAD~1')")"              "deny:  git reset --hard"
denied  "$(run "$REPO" "$(bashj 'git push --force origin main')")"         "deny:  git push --force"
allowed "$(run "$REPO" "$(bashj 'git push --force-with-lease origin main')")" "allow: git push --force-with-lease"
denied  "$(run "$REPO" "$(bashj 'git clean -fd')")"                        "deny:  git clean -fd"
denied  "$(run "$REPO" "$(bashj 'git branch -D feature')")"                "deny:  git branch -D"
allowed "$(run "$REPO" "$(bashj 'git commit -m wip')")"                    "allow: ordinary git commit"
allowed "$(run "$REPO" "$(bashj 'git commit -m \"fix: reset --hard was risky\"')")" "allow: 'reset --hard' only inside a commit message"
allowed "$(run "$REPO" "$(bashj 'git commit -m \"document git push --force\"')")"   "allow: 'push --force' only inside a commit message"

echo "scope:"
allowed "$(run "$REPO" '{"tool_name":"Edit","tool_input":{"file_path":"x"},"cwd":"x"}')" "allow: non-Bash tool"
allowed "$(run "$PLAIN" "$(bashj 'git reset --hard HEAD~1')")"             "allow: dangerous git in a NON-T4 repo (guard)"

echo ""
echo "gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

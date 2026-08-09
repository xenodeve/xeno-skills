#!/usr/bin/env bash
# This repo ships the T4 operating standard — so its own install is a contract.
# The existing suite tests the TEMPLATES (references/, skills/) against throwaway
# repos; nothing reads this repo's own .claude/, .githooks/ or CLAUDE.md. That is
# the #81 failure class: a repo can LOOK bootstrapped while the marker, the hooks,
# the guards or the CLAUDE.md wiring is absent, and nothing fails.
#
# Seam: the repo root is the system under test. Each assertion anchors on a phrase
# that states the CLAIM (the wiring that makes it work), not on a bare path that a
# one-line file would vacuously satisfy.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()   { echo "  PASS: $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL: $1"; fail=$((fail+1)); }
has()  { if grep -qF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "the marker exists and arms the local ship gate:"
if [ -f "$REPO_ROOT/.claude/t4.json" ]; then
  ok ".claude/t4.json exists"
else
  bad ".claude/t4.json missing — the hooks never fire without it"
fi
has "$REPO_ROOT/.claude/t4.json" '"t4": true'          "the marker flags the repo as T4"
has "$REPO_ROOT/.claude/t4.json" '"verify": "bash tests/hooks/run-all.sh"' \
    "the local ship gate is armed to the contract suite (the fast prefix of CI job 'tests')"

echo "the committed settings register the three hooks via the project dir:"
has "$REPO_ROOT/.claude/settings.json" '${CLAUDE_PROJECT_DIR}/.claude/hooks/run-hook.cmd' \
    "settings.json registers hooks via \${CLAUDE_PROJECT_DIR}"
has "$REPO_ROOT/.claude/settings.json" "t4-session-start"    "SessionStart hook registered"
has "$REPO_ROOT/.claude/settings.json" "t4-prompt-reminder"  "UserPromptSubmit hook registered"
has "$REPO_ROOT/.claude/settings.json" "t4-gate"             "PreToolUse hook registered"

echo "the repo's own .claude/hooks copies stay byte-identical to the canonical hooks/:"
for f in t4-session-start t4-prompt-reminder t4-gate run-hook.cmd; do
  if cmp -s "$REPO_ROOT/hooks/$f" "$REPO_ROOT/.claude/hooks/$f"; then
    ok ".claude/hooks/$f in sync with hooks/$f"
  else
    bad ".claude/hooks/$f DRIFTED from hooks/$f (re-copy)"
  fi
done
[ -f "$REPO_ROOT/.claude/hooks/using-t4.snapshot.md" ] \
  && ok "using-t4.snapshot.md present (plugin-less session-start fallback)" \
  || bad "using-t4.snapshot.md missing"

echo "the guards layer is installed so every agent/human meets it, not just Claude:"
for f in pre-push check-issue-ref check-tree-budget check-gate-ledger; do
  [ -f "$REPO_ROOT/.githooks/$f" ] \
    && ok ".githooks/$f present" \
    || bad ".githooks/$f missing"
done

echo "the CI gate runs the same guard scripts on PRs (can't be --no-verify'd):"
has "$REPO_ROOT/.github/workflows/t4-verify.yml" "sh .githooks/check-tree-budget"  "CI runs check-tree-budget"
has "$REPO_ROOT/.github/workflows/t4-verify.yml" "sh .githooks/check-gate-ledger"  "CI runs check-gate-ledger"
has "$REPO_ROOT/.github/workflows/t4-verify.yml" "sh .githooks/check-issue-ref"    "CI runs check-issue-ref"
has "$REPO_ROOT/.github/workflows/t4-verify.yml" "github.event_name == 'pull_request'" \
    "the guards are scoped to PRs (a push-to-main run has an empty ledger range)"

echo "CLAUDE.md is the agent operating manual, not a pointer:"
has "$REPO_ROOT/CLAUDE.md" "standing default"           "using-t4 is a standing default, re-routed at phase boundaries"
has "$REPO_ROOT/CLAUDE.md" "discharge a later trigger"  "the read-once failure is foreclosed in this repo's own CLAUDE.md"
has "$REPO_ROOT/CLAUDE.md" "docs/OPEN-WORK-LEDGER.md"   "the session-start protocol points at the ledger"
has "$REPO_ROOT/CLAUDE.md" "Obsidian-xeno-skills/Home.md" "and at the memory vault"

echo ""
echo "repo-self-bootstrap: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

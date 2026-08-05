#!/usr/bin/env bash
# A repo can receive the T4 docs while step 6 silently never installs the hooks
# layer, and nothing ever looks (#81). Verified on pal-mcp-server 2026-08-03: it
# had CLAUDE.md, docs/agents/*, the ledger, DONE.md and the memory vault — and
# no .claude/hooks/, no .claude/t4.json, no `hooks` key in settings.json. The
# repo LOOKED bootstrapped, so nobody checked.
#
# Note on anchors, because a delegated attempt at this test was rejected for
# getting it wrong: asserting a bare path like `.claude/t4.json` passes
# VACUOUSLY here — step 6 already names all three artifacts, for INSTALLING
# them. So each assertion below is anchored on a phrase that states the new
# CLAIM (verify it, retrofit it, tell the two faults apart), not on a token the
# existing text already satisfies. Every anchor contains a space, and the two
# withdrawn statements are pinned with `hasnt` so a partial edit cannot pass.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BOOT="$REPO_ROOT/skills/t4/t4-project-bootstrap/SKILL.md"
HOOKS="$REPO_ROOT/skills/t4/t4-project-bootstrap/references/hooks-layer.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }
hasnt() { if grep -qiF -- "$2" "$1"; then bad "$3"; else ok "$3"; fi; }

echo "the bootstrap verifies the hooks layer landed, not just that placeholders are gone:"
has "$BOOT" "Verify the hooks layer is actually installed" "a verification step exists"
has "$BOOT" "list all three and report which are missing" "it lists the artifacts rather than assuming"
has "$BOOT" "a repo with the docs and no hooks looks bootstrapped" "and states why the check is needed at all"

echo
echo "a repo that already has the docs has somewhere to go:"
has "$BOOT" "Retrofitting a repo that already has the docs" "the retrofit path is documented"
has "$BOOT" "steps 6 to 8 in order and nothing else" "and says which steps to re-run"

echo
echo "troubleshooting tells a missing MARKER apart from a missing LAYER:"
has "$HOOKS" "The layer was never installed at all" "the never-installed row exists"
has "$HOOKS" "there is no .claude/hooks/ for a marker to point at" "and distinguishes it from the marker case"

echo
echo "the generated CLAUDE.md carries the delegation default and its two hard rules:"
has "$BOOT" "clink-subagents" "clink-subagents is named"
has "$BOOT" "verify everything a subagent returns" "the verify rule is carried"
has "$BOOT" "never delegate the final verification" "and the do-not-delegate rule"

echo
echo "the superseded statements are gone, not left beside the new ones:"
hasnt "$BOOT" "Verify placeholders are gone** — grep the new files" "step 11 no longer verifies only placeholders"
# The marker row's ADVICE is still correct and is deliberately kept — what was
# withdrawn is its bare heading, which absorbed both faults into one row and so
# sent a missing-layer repo to add a marker for scripts that are not there.
hasnt "$HOOKS" "| **No hook fires at all** |" "the marker row no longer claims both faults"

echo
if [ "$fail" -gt 0 ]; then echo "FAILED: $fail, passed: $pass"; exit 1; fi
echo "OK: $pass passed"

#!/usr/bin/env bash
# The exemption rules bind the AGENT's reasoning — urgency is not a proof,
# uncertainty resolves toward compliance. The move that routes around both is to
# hand the choice to the developer: their "yes" is not a checkable fact about the
# change, but it looks like authorisation and the skip proceeds looking approved.
# Observed 2026-08-03; the review that was nearly skipped found a real defect.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WF="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"
MAP="$REPO_ROOT/skills/t4/using-t4/SKILL.md"
AFK="$REPO_ROOT/skills/t4/t4-afk/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "offering the choice is itself a skip:"
has "$WF" "Offering the developer a choice to skip a gate is itself a skip" "t4-dev-workflow states the rule"
has "$WF" "does not transfer by asking" "the burden of proof does not move to the developer"

echo
echo "the allowed form is stated, so this is not 'never mention cost':"
has "$WF" "report the cost, then comply" "reporting the cost and complying is allowed"
has "$WF" "developer-initiated waiver" "a developer-initiated waiver remains valid"

echo
echo "it does not collapse into 'never ask anything':"
has "$WF" "genuinely ambiguous in scope" "asking about genuine scope ambiguity is still allowed"

echo
echo "the dispatcher carries the thought that precedes the failure:"
has "$MAP" "let them decide whether it's worth it" "the red-flag table names the thought"

echo
echo "an unattended run has nobody to ask, and that is not licence:"
has "$AFK" "nobody to ask is not licence" "t4-afk cross-references it"

echo
if [ "$fail" -gt 0 ]; then echo "FAILED: $fail, passed: $pass"; exit 1; fi
echo "OK: $pass passed"

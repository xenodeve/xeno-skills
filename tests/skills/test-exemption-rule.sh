#!/usr/bin/env bash
# The exemption meta-rule protects every other rule, so it's the one whose loss
# would be quietest — nothing breaks, the agent just gets more permissive.
# It also lives in the dispatcher, which is AT its byte ceiling and therefore
# under constant pressure to shed a line.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MAP="$REPO_ROOT/skills/t4/using-t4/SKILL.md"
WF="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"
AFK="$REPO_ROOT/skills/t4/t4-afk/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "the injected map carries the meta-rule:"
has "$MAP" "Skipping a rule requires proof"  "using-t4 states that skipping needs proof, not judgment"
has "$MAP" "No proof → follow the skill"     "using-t4 states the default: no proof means comply"

echo "the workflow skill carries the discipline:"
has "$WF" "Skipping a rule requires proof"   "t4-dev-workflow has the exemption section"
has "$WF" "checkable fact about this specific change" "an exemption must be a checkable fact, not an opinion"
has "$WF" "without redoing your reasoning"   "the fact must be verifiable by a reviewer independently"
has "$WF" "Uncertainty resolves toward compliance" "uncertainty resolves toward compliance"
# A rule with no worked examples is a slogan; the table is what makes it usable.
has "$WF" "Cost is not evidence"             "rejects 'it's slow' as a proof"
has "$WF" "Urgency changes priority, not truth" "rejects urgency as a proof"
has "$WF" "Never exemptable by argument"     "names the classes that can't be argued away"
has "$WF" "including the one below"          "the meta-rule explicitly governs the other exception clauses"

echo "AFK raises the bar rather than lowering it:"
has "$AFK" "the bar goes **up** here"        "t4-afk states the exemption bar rises when unattended"

echo ""
echo "exemption-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

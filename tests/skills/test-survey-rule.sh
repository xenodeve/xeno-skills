#!/usr/bin/env bash
# The change-site survey is a pipeline STEP, so it rots differently from a rule:
# not by being deleted, but by one of the several places that list the pipeline
# falling out of sync — which is the exact failure the rule is about.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WF="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"
ART="$REPO_ROOT/skills/t4/t4-dev-workflow/references/workflow-artifacts.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "the rule itself:"
has "$WF" "Survey the change sites before writing the plan" "t4-dev-workflow has the survey section"
has "$WF" "Duplicates are the classic miss"      "warns about the same content living in two files"
has "$WF" "Both sides of every mirror"           "covers bilingual pairs / mirrored copies"
has "$WF" "Say what the survey couldn't reach"   "requires stating the search boundary"
has "$WF" "change inventory"                     "names the output artifact"

echo "every pipeline listing includes the step (this is what drifts):"
for f in "$WF" "$ART"; do
  n="$(basename "$(dirname "$f")")/$(basename "$f")"
  if grep -qiF "Survey the change sites" "$f"; then ok "$n lists the survey step"; else bad "$n pipeline is missing the survey step"; fi
done
for d in development-workflow.md development-workflow.en.md; do
  if grep -qF "Survey[" "$REPO_ROOT/docs/$d"; then ok "docs/$d diagram has the survey node"; else bad "docs/$d diagram is missing the survey node"; fi
done

echo "the PRD template carries the inventory block:"
has "$ART" "## Change Inventory"  "PRD template has a Change Inventory section"
has "$ART" "Search boundary:"     "PRD template asks for the search boundary"

echo ""
echo "survey-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

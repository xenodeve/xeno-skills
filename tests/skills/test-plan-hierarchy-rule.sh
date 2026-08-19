#!/usr/bin/env bash
# plan -> PRD -> slice, as a NATIVE sub-issue tree rather than prose (#248).
#
# A documentation-integrity suite, and labelled one: it detects deletion and softening
# of the rule. It cannot detect an agent writing `## Parent` anyway.
#
# WHAT THE RULE REPLACES, measured rather than supposed. Parenthood was written as
# `## Parent xeno-skills#176` inside each child's body, and a plan had no tracker
# presence at all. So answering "what is left" on 2026-08-17 meant exporting 107 open
# issues, extracting numbers from 54 commit subjects, and taking a set difference in a
# shell pipeline -- to recover a fact (53 of 107 already implemented) that GitHub
# already held and could not report, because nothing had told it.
#
# The mechanism was probed against this repo before the rule was written: sub-issues
# add/read/DELETE cleanly, nest to at least three levels, and their rollup counts
# DIRECT CHILDREN ONLY -- `#129 -> #84 -> #83` reported `total: 1` at the top, not 2.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"
TRACKER="$REPO_ROOT/docs/agents/issue-tracker.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }
# Case-insensitive: the skill emphasises some of these phrases in capitals, and an
# assertion that breaks on emphasis is testing typography, not the rule.
hasi() { case "$(tr '[:upper:]' '[:lower:]' < "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

[ -f "$SKILL" ] && ok "t4-dev-workflow is present" || bad "the skill is missing"

echo ""
echo "the three levels are named, in order:"
has "$SKILL" "plan"  "plan is named as a level"
has "$SKILL" "sub-issue" "and sub-issues are named as the mechanism"
python - "$SKILL" <<'PY'
import sys
doc = open(sys.argv[1], encoding="utf-8").read()
# Order is the claim: a plan decomposes into PRDs, a PRD into slices. If the chain is
# written in another order the hierarchy it describes is a different one.
i = doc.find("plan → PRD → issues")
assert i != -1, "the chain 'plan -> PRD -> issues' is not stated"
PY
[ $? -eq 0 ] && ok "the chain plan -> PRD -> issues is stated as such" \
             || bad "the three-level chain is not stated in order"

echo ""
echo "THE MECHANISM IS THE API, NOT A HEADING — which is the whole point:"
has "$SKILL" "sub_issues" "the sub-issue endpoint is named, so the rule is actionable"
# THE NEGATIVE THAT CARRIES THE RULE. `## Parent` prose is what this replaces; if the
# skill still presents it as the way parenthood is expressed, nothing has changed.
hasnt "$SKILL" "parenthood is a \`## Parent\` heading" \
      "it does not present a prose heading as the mechanism"

echo ""
echo "the two facts a reader would otherwise get wrong:"
hasi "$SKILL" "direct children" "the rollup counts direct children only — a plan at 0% may have thirty slices done"
hasi "$SKILL" "one parent" "a child has exactly one parent, which GitHub enforces"

echo ""
echo "DECOMPOSITION IS NOT ORDERING — blocked-by must stay prose:"
has "$SKILL" "Blocked by" "blocked-by is still named"
python - "$SKILL" <<'PY'
import sys
doc = open(sys.argv[1], encoding="utf-8").read()
i = doc.find("Blocked by")
assert i != -1
window = doc[max(0, i - 500): i + 500]
assert "sub-issue" in window or "decomposition" in window or "ordering" in window, \
    "blocked-by is mentioned but never distinguished from the sub-issue tree"
PY
[ $? -eq 0 ] && ok "and it is explicitly distinguished from the sub-issue tree" \
             || bad "blocked-by is not distinguished — the two would be conflated"

echo ""
echo "the plan keeps BOTH homes, and each is given a job:"
has "$SKILL" "docs/plans" "the markdown home is named"
has "$SKILL" "tracking issue" "and the tracker home is named"

echo ""
echo "the tracker doc carries it too, since that is where /to-issues conventions live:"
has "$TRACKER" "sub-issue" "issue-tracker.md knows about sub-issues"

echo ""
echo "plan-hierarchy-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

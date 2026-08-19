#!/usr/bin/env bash
# A verdict that recommends an ACTION needs the action's preconditions too (#233).
#
# A documentation-integrity suite, and labelled one. NO MECHANISM IS ADDED.
#
# WHY THIS IS NOT A RESTATEMENT OF THE RULE IT SITS UNDER. The rule was FOLLOWED and
# still produced three wrong statements in one session -- in all three the evidence was
# real, produced in-session, and correctly cited. What was wrong was its SCOPE: it
# supported a claim about the mechanism and was spent licensing a claim about what to do,
# which needed a different and larger read.
#
# THE THIRD ONE IS THE ONE TO REMEMBER. The live tool schema, ~/.claude.json,
# server.py:1511 and 15 references in skills/ were all read and all correct. Then the
# OTHER repository turned out to hold a test whose docstring already contained that
# analysis, a plan issue, and a deliberate exclusion. The mechanism claim was right and
# the recommendation was wrong.
#
# The registers -- verified / hypothesis / unknown -- attach to the CLAIM. Nothing
# attached them to the QUESTION THE EVIDENCE ANSWERS, and that is the gap.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WF="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

[ -f "$WF" ] && ok "t4-dev-workflow is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE GAP IS NAMED — the register attaches to the claim and not to the question:"
has "$WF" "the question the evidence answers" "the missing attachment is stated"
has "$WF" "therefore do Y" "with the shape of the move"

echo ""
echo "the rule it extends is named as FOLLOWED, not broken — that is the whole point:"
has "$WF" "can be *followed* and still produce a wrong statement" "the rule was obeyed"

echo ""
echo "ACTION VERDICTS CARRY THEIR PRECONDITIONS — the operative sentence:"
has "$WF" "recommends an ACTION rather than asserting a FACT" "the trigger is the kind of verdict"
has "$WF" "the other repository's tracker is one of them" "and the cross-repo precondition is named"

echo ""
echo "all three measurements are on the page, because one reads as bad luck:"
has "$WF" "First 14" "the truncated read"
has "$WF" "prior session's handoff note" "the carried-forward claim"
has "$WF" "four checks **on our side**, all correct" "and the one where every check passed"

echo ""
echo "AND THE TELL IS CHEAP, or nobody runs it:"
has "$WF" "name the read you did" "the check is one question"
has "$WF" "one command" "with what the misses actually cost"

echo ""
echo "evidence-scope-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

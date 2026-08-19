#!/usr/bin/env bash
# Ask what a number measures before you spend it (#210).
#
# A documentation-integrity suite, and labelled one. NO MECHANISM IS ADDED.
#
# WHAT HAPPENED, measured 2026-08-14. A cost-per-task figure from Artificial Analysis was
# used TWICE to argue against a model for a reviewer role. That figure measures a METERED
# API LANE. The lane in question was the developer's FLAT SUBSCRIPTION, where it buys
# nothing and predicts nothing -- and the harness's own default evaluator is the same
# model on the same lane. The developer had to say so twice.
#
# THE NUMBER WAS NOT WRONG. It described something else, which is why this failure looks
# identical to good evidence and why a rule about accuracy cannot catch it.
#
# WHY IT LIVES IN t4-dev-workflow AND NOT IN A DELEGATION SKILL. clink-subagents already
# carries it as a ROUTING rule. The 2026-08-14 failure was about a NATIVE HARNESS FEATURE
# with no clink in it, so no delegation skill was loaded and the rule was not in the room.
# #210 named two possible homes -- one level up, or t4-subagent -- and t4-subagent does
# not exist yet (#165, blocked), so by elimination there was one available answer.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WF="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"
SA="$REPO_ROOT/skills/multi-agent/clink-subagents/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

[ -f "$WF" ] && ok "t4-dev-workflow is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE RULE IS ABOUT THE UNIT, not about accuracy:"
has "$WF" "Ask what a number measures before you spend it" "the rule is stated"
has "$WF" "the wrong quantity" "and what goes wrong is named"
has "$WF" "the number really is right" "with why accuracy does not save you"

echo ""
echo "the measurement is on the page, including that it took two corrections:"
has "$WF" "metered API lane" "the unit the figure actually described"
has "$WF" "flat subscription" "and the lane it was applied to"
has "$WF" "twice" "with the number of corrections needed"

echo ""
echo "THE CHECK IS ONE QUESTION, or it is another thing to remember:"
has "$WF" "what unit, measured on what" "the question is given"

echo ""
echo "AND IT IS TIED TO ITS SIBLING RATHER THAN RESTATING IT:"
has "$WF" "wrong **unit**" "the distinction from the action-verdict rule"

echo ""
echo "the delegation-side rule is intact — this is a second home, not a move:"
has "$SA" "never by its token count" "clink-subagents still carries the routing rule"
has "$WF" "not specific to delegation" "and the reason it also lives here"

echo ""
echo "number-unit-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

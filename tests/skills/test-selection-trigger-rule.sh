#!/usr/bin/env bash
# The selection step has a moment, and tokens are the cost function (#130).
#
# A documentation-integrity suite, and labelled one. NO ENFORCEMENT HOOK IS ADDED and
# #130 asks for none.
#
# WHAT HAPPENED, measured. On 2026-08-11 an orchestrator implemented a whole clink
# client -- parser, agent, config, discovery, four doc files -- and delegated NONE of
# it, in a repo whose CLAUDE.md opens with "delegation is the default, not the
# optimisation". THE DEVELOPER HAD INVOKED /clink-subagents AND /clink-masteragent IN
# THE MESSAGE IMMEDIATELY BEFORE. Both were loaded and in context.
#
# So the gap is not knowledge. The selection step did not run and conclude keep; it
# NEVER RAN, because neither skill had a moment at which it fires. t4-dev-workflow had
# the same shape and #105 fixed it by giving the change-site survey a trigger.
#
# AND THE TWO COST STATEMENTS DISAGREED ON THE MOST COMMON CASE. "Never delegate
# something you'd finish correctly in less time" answers KEEP for four bulk doc files;
# the token formula answers DELEGATE. The docs were the largest mechanical leaf in that
# change, the orchestrator wrote them itself, and the reason offered afterwards was the
# latency one -- the bullet a reader hits first.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUB="$REPO_ROOT/skills/multi-agent/clink-subagents/SKILL.md"
MA="$REPO_ROOT/skills/multi-agent/clink-masteragent/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$SUB" ] && ok "clink-subagents is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE TRIGGER NAMES A MOMENT — a rule with no moment is a lookup table:"
has "$SUB" "before the first edit of any task with more than one leaf" "the moment is stated"
has "$SUB" "record delegate/keep with the reason" "and what it produces"

echo ""
echo "and the datum is on the page, because 'delegate more' is what already failed:"
has "$SUB" "delegated **none** of it" "the miss is quoted"
has "$SUB" "the gap is not knowledge" "with the inference that makes a trigger the fix"

echo ""
echo "TOKENS ARE THE COST FUNCTION, LATENCY IS A GATE — and the two skills agree:"
has "$SUB" "feasibility gate, not the cost function" "clink-subagents demotes latency"
has "$MA" "infeasibility, not latency" "and clink-masteragent already said so"
hasnt "$SUB" "Never delegate something you'd finish correctly in less time." \
      "the old wording that decided the common case wrongly is retired"

echo ""
echo "THE FORMULA IS WORKED, on both verdicts — an uncomputed formula reads as sentiment:"
has "$SUB" "a 2-line edit in a file already in your context" "the keep example"
has "$SUB" "four documentation files, bulk mechanical" "and the delegate example"
has "$SUB" "the case the old wording decided wrongly" "with the disagreement named"

echo ""
echo "AND NO ENFORCEMENT IS CLAIMED:"
hasnt "$SUB" "the gate blocks an undelegated" "no hook is claimed"

echo ""
echo "selection-trigger-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

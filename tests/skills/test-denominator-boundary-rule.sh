#!/usr/bin/env bash
# An absence in the skill-usage log is `unknown`, not `no` (#145).
#
# A documentation-integrity suite, and labelled one: it detects deletion and softening
# of the rule. It cannot stop anyone reading a rate out of a file with holes.
#
# WHAT IT REPLACES, measured. `hooks/t4-skill-log` is a TRACKED FILE, so a checkout can
# remove it. Of 52 Skill invocations in one session's transcript the log holds 11 --
# and three of the missing sit in a single contiguous window bracketed by
# `git switch -c <branch> main` and `git switch <feature-branch>`, because the hook did
# not exist on main until 4c4dbf3. A checkout removed the observer.
#
# THE PART WORTH PINNING IS NOT THE FIX, IT IS THE DISCIPLINE. Two mechanisms were
# proposed for that gap before the real one, and both were wrong: that the logger
# filtered non-library skills (security-review is not in skills/ and is logged twice),
# and that the ~32 KB argv cap ate them (every tool_result in the window is 110-124 B).
# A gap in a measurement invites a mechanism; check the observer was present first.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MEM="$REPO_ROOT/skills/t4/t4-agent-memory/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$MEM" ] && ok "t4-agent-memory is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "AN ABSENCE IS UNKNOWN, NOT NO — the sentence the rule turns on:"
has "$MEM" "is \`unknown\`, not \`no\`" "the register of an absence is stated"

echo ""
echo "and it says WHY a checkout can remove the observer:"
has "$MEM" "tracked file" "the hook being tracked is named as the cause"
has "$MEM" "predates it" "and a branch cut from an older base as the trigger"

echo ""
echo "THE PROCEDURE IS EXECUTABLE, not an instruction to be careful:"
has "$MEM" "diff-filter=A" "the command that finds where the denominator starts"

echo ""
echo "the two wrong mechanisms are recorded, because that is the reusable part:"
has "$MEM" "both were wrong" "the earlier explanations are marked as falsified"
has "$MEM" "check the observer was present" "and the discipline is stated as a rule"

echo ""
echo "AFK is named as the case that opens the hole:"
has "$MEM" "cuts branches constantly" "an AFK batch is the trigger, not an edge case"

echo ""
echo "and the rule does NOT claim the log is now complete:"
hasnt "$MEM" "the denominator is complete" "it makes no completeness claim"

echo ""
echo "denominator-boundary-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# /handoff does not discharge the session-end report (#211).
#
# A documentation-integrity suite, and labelled one.
#
# WHAT HAPPENED. On 2026-08-14 the work ran all the way to /handoff -- the explicit
# end-of-session step -- and NEITHER the local note NOR a single skill-feedback issue was
# written. The handoff document itself says "This is the second session in a row that
# owes them, and the five mistakes above are the material." The agent identified the
# debt, described it, wrote it into a handoff, and did not pay it.
#
# /handoff LOOKS LIKE THE END-OF-SESSION STEP AND IS NOT ONE. It produces a document, it
# feels terminal, and the report is not part of it.
#
# THE FIX IS IN THIS FILE AND NOT IN /handoff, by elimination rather than by preference:
# #211 offers two options and the first -- put the report inside /handoff -- edits a
# skill that ships from userSettings, outside this repository.
#
# AND ONE SENTENCE HERE WAS OVERSTATED. "No hook produces it, and none can" reads as the
# whole obligation being beyond mechanism. The DENOMINATOR half is a checkable action and
# hooks/t4-skill-log performs it. Only the judgement half is not, and two sessions stood
# behind the stronger reading.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MEM="$REPO_ROOT/skills/t4/t4-agent-memory/SKILL.md"
HOOK="$REPO_ROOT/hooks/t4-skill-log"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$MEM" ] && ok "t4-agent-memory is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "HANDOFF DOES NOT DISCHARGE THE REPORT — the sentence two sessions needed:"
has "$MEM" "does not discharge the session-end report" "the discharge is refused"
has "$MEM" "it feels terminal" "with why the mistake is natural"

echo ""
echo "THE OVERSTATEMENT IS RETIRED, not left beside the correction:"
hasnt "$MEM" "No hook produces it, and none can" "the whole-obligation claim is gone"
has "$MEM" "No hook produces the *findings*" "and is replaced by the accurate one"
has "$MEM" "Only the judgement half is beyond mechanism" "with the half that is not"

echo ""
echo "and the claim about the denominator is checked against the hook, not asserted:"
has "$MEM" "t4-skill-log" "the hook is named"
[ -f "$HOOK" ] && ok "and it exists" || bad "the skill cites a hook that is not there"
grep -q 'PostToolUse' "$HOOK" && ok "and really is a PostToolUse logger" \
                              || bad "the hook is not what the skill says it is"

echo ""
echo "THREE SESSIONS ARE TABULATED — this file's own threshold for a design problem:"
has "$MEM" "2026-08-14" "the first"
has "$MEM" "2026-08-17" "the second"
has "$MEM" "only because the session ran on past" "and the third, which is not a success"

echo ""
echo "handoff-discharge-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

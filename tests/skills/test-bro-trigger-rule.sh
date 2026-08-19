#!/usr/bin/env bash
# t4-bro has a moment at which it fires (#209).
#
# A documentation-integrity suite, and labelled one. NOTHING ENFORCES IT -- no hook sees
# a reply before it is written, which ADR 0001 already establishes.
#
# WHAT HAPPENED, measured. On 2026-08-14, with t4-bro ALREADY LOADED, a long design
# breakdown went out in English. The developer wrote  คุยเป็นภาษาไทย  twice and invoked
# /t4-bro a third time. Two explicit corrections for one rule in one session, and the
# rule was not skipped for a stated reason -- it was never applied, which is worse,
# because there is no decision to review.
#
# WHY A TRIGGER AND NOT MORE EXAMPLES. The 2026-08-12 session recorded a DIFFERENT
# t4-bro failure -- the shape rule -- and PR #140 fixed it by attaching three worked
# examples, on the theory that the rule failed for want of one. This was the language
# rule: the most explicit sentence in the file, with nothing subtle about it. A rule that
# is unambiguous and still not applied has a trigger problem, not a clarity problem.
#
# AND THE TRIGGER IS SPECIFIC. "Anything the developer reads" is every message and
# therefore no moment at all. The slip happened at a phase boundary -- a long analytical
# answer written straight out of a run of commands.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BRO="$REPO_ROOT/skills/t4/t4-bro/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

[ -f "$BRO" ] && ok "t4-bro is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE MOMENT IS NAMED — a rule for every message has no moment at all:"
has "$BRO" "first prose reply after a stretch of tool work" "the trigger is specific"
has "$BRO" "no moment at which it fires" "and the reason the old framing had none"

echo ""
echo "it is tied to the phase boundary using-t4 already names:"
has "$BRO" "tool work → prose is a phase boundary" "the boundary is identified"

echo ""
echo "THE MEASUREMENT IS ON THE PAGE — two corrections in one session:"
has "$BRO" "Two explicit corrections" "the count is stated"
has "$BRO" "never applied" "with the distinction from a stated skip"

echo ""
echo "AND WHY EXAMPLES WOULD NOT FIX IT, which is the argument for a trigger:"
has "$BRO" "PR #140" "the earlier fix is cited"
has "$BRO" "trigger problem, not a clarity problem" "and the diagnosis stated"

echo ""
echo "the check itself is answerable in one pass, or it is another thing to remember:"
has "$BRO" "is it Thai" "the first question"
has "$BRO" "too long before it is anything else" "and what a failure to answer means"

echo ""
echo "bro-trigger-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

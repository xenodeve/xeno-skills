#!/usr/bin/env bash
# A skill the agent cannot invoke is a HAND-OFF, not an absence (#242).
#
# A documentation-integrity suite, and labelled one: it detects deletion and softening
# of the rule. It cannot detect an agent improvising the output anyway -- which is the
# failure, and the reason the rule has to say what to do instead of only what not to.
#
# THE FAILURE, quoted from #242. Bootstrapping a repo on 2026-08-18 the agent reached a
# step naming /setup-matt-pocock-skills, did not find it in its skill listing, and told
# the developer the skill was "not installed on this machine" -- then wrote the files
# itself. The skill was installed the whole time. A `disable-model-invocation: true`
# skill is FILTERED OUT OF THE LISTING, so nothing distinguishes "not installed" from
# "installed, reserved for the developer".
#
# THE AUDIT #242 ASKED FOR FOUND MORE THAN #242 ASSUMED. Four of the six pipeline steps
# name a flagged skill -- /grill-me, /grill-with-docs, /to-prd, /to-issues -- so the
# workflow is unexecutable by an agent from step 1, not just at bootstrap step 5.
#
# WHAT THIS SUITE DELIBERATELY DOES NOT DO. It does not compute the flagged set: those
# skills live in ~/.claude/skills, outside this repository, so a check that read them
# would pass or fail by machine. Stated rather than silently skipped -- the derive rule
# (#268) applies to sets this repo can see, and this one it cannot.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WF="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$WF" ] && ok "t4-dev-workflow is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "ABSENCE FROM THE LISTING IS NOT EVIDENCE OF ABSENCE — the sentence that stops the wrong conclusion:"
has "$WF" "absent skill" "the agent's actual experience is named"
has "$WF" "not evidence of absence" "and the inference it must not draw"

echo ""
echo "the mechanism is named, so it reads as a property and not as bad luck:"
has "$WF" "disable-model-invocation" "the flag is named"
has "$WF" "filtered out of the available-skills listing" "and why the agent cannot see it"

echo ""
echo "IT SAYS WHAT TO DO, not only what not to do — the failure was improvising, not calling:"
has "$WF" "Ask the developer to run it" "the hand-off is an instruction"
has "$WF" "Do not improvise the output" "and substituting is forbidden explicitly"
has "$WF" "that is a park" "with a stated answer for when the developer is unavailable"

echo ""
echo "and the scale is on the page, because one instance reads as an edge case:"
has "$WF" "Four of the six steps" "the audit's count is stated"

echo ""
echo "THE OLD READING IS RETIRED — the pipeline no longer presents these as plain invocations:"
hasnt "$WF" "Ask the user to run /setup-matt-pocock-skills yourself" "no contradictory instruction was left beside the rule"

echo ""
echo "flagged-skill-handoff-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

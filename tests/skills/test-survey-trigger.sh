#!/usr/bin/env bash
# The change-site survey was mandatory in prose and triggered by nothing (#105).
# It fired when the agent happened to think of it, or when an issue body handed
# it over pre-done.
#
# The worked example is the evidence and belongs in the skill, because it rules
# out the "the agent forgot" reading: ONE session, minutes apart. On #78 the
# survey was skipped and the cost landed inside the same edit — one added clause
# took the injected dispatcher to 9033 B against a hard 9000 B cap. On #86 the
# same agent ran it first and budgeted the addition. The difference was that
# #86's issue body handed the survey over as a section.
#
# Anchors here are phrases containing a space, and the two figures (9033 / 9000)
# are measured facts a reader can check — not a wording somebody chose.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FLOW="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"
MAP="$REPO_ROOT/skills/t4/using-t4/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }
hasnt() { if grep -qiF -- "$2" "$1"; then bad "$3"; else ok "$3"; fi; }

echo "the survey has a trigger tied to an action, not a phase:"
has "$FLOW" "The trigger is an action, not a phase" "the trigger is stated as an action"
has "$FLOW" "about to write down what you will change" "and names the moment it fires"
has "$FLOW" "About to write down what you will change" "it is in the auto-triggered table too"

echo
echo "a sibling issue's inventory counts as survey input:"
has "$FLOW" "change inventory is survey input" "adjacent issues are named as an input"

echo
echo "the worked example is recorded, so 'the agent forgot' is ruled out:"
has "$FLOW" "9033 B" "the measured overrun is cited"
has "$FLOW" "The difference was not diligence" "and the conclusion drawn from it"

echo
echo "using-t4 warns whoever edits it about BOTH machine-enforced constraints:"
has "$MAP" "MACHINE-ENFORCED CONSTRAINTS" "the note exists"
has "$MAP" "test-dispatcher-content.sh" "it names the test that enforces them"
has "$MAP" "Twenty-nine bytes spare" "it states the measured headroom"
has "$MAP" "five exact phrases to survive every edit" "it names the content constraint, not only the size one"

echo
echo "the note must not be reachable by the session — it would spend the budget it warns about:"
hasnt "$FLOW" "MAINTAINERS — THIS FILE IS UNDER" "the maintainer note did not leak into a second skill"

echo
if [ "$fail" -gt 0 ]; then echo "FAILED: $fail, passed: $pass"; exit 1; fi
echo "OK: $pass passed"

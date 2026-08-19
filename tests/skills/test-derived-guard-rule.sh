#!/usr/bin/env bash
# A guard computes the set it checks; it does not list it (#268).
#
# A documentation-integrity suite, and labelled one: it detects deletion and softening
# of the rule. It cannot detect an agent writing a list anyway.
#
# WHAT THE RULE REPLACES, measured rather than supposed. Three guards in this repo were
# written as lists, each correct on the day it was written, and all three were still
# lists when the population they guarded had grown past them:
#
#   .gitattributes        4 filenames  -> 24 hooks   -> 20 files unpinned on one side
#   the argv check        5 variables  ->  8 hooks   -> missed two ON THE DAY IT LANDED
#   the .claude/ sync     4 filenames  -> 24 hooks   -> 19 copies compared by nothing
#
# The middle one is the argument. It was written to catch a class, listed the members
# it had just found, and was blind to two more in the same directory.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"
SYNC="$REPO_ROOT/tests/skills/test-repo-self-bootstrap.sh"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$SKILL" ] && ok "t4-dev-workflow is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "the rule is stated, and stated as an imperative rather than a preference:"
has "$SKILL" "Derive the set a guard checks" "the rule has its own section"
has "$SKILL" "cannot see the member added after it" "and says what a list cannot do"

echo ""
echo "THE TRIGGER IS NAMED — a rule with no trigger fires when someone remembers it:"
has "$SKILL" "writing the second name" "the trigger is the second name in a check"

echo ""
echo "the three measurements are on the page, because the rule is derived from them:"
has "$SKILL" "gitattributes" "the line-ending pin is cited"
has "$SKILL" "argv" "the argv check is cited"
has "$SKILL" "19" "and the sync loop's count"

echo ""
echo "THE TWO EXCEPTIONS ARE STATED — without them the rule reads as banning fixtures:"
has "$SKILL" "fixture" "a fixture may name what it uses"
has "$SKILL" "exclusions stated" "and a derived set must state its exclusions"

echo ""
echo "and the rule this one is the twin of is named, not left for the reader to find:"
has "$SKILL" "change-site survey" "it is tied to the survey it generalises"

echo ""
echo "THE REPO OBEYS ITS OWN RULE — the guard that motivated it is itself derived:"
# The negative that carries this: if the sync loop goes back to a filename list, the
# rule above is documentation of something the repo does not do.
# One line, deliberately: tests/audit-anchor-quality.sh extracts anchors with a
# single-line grep, so a call wrapped across lines is invisible to it and the suite
# is scored as positive-only. The audit was right about the shape and wrong about
# this suite for a formatting reason, which is worth not reproducing.
hasnt "$SYNC" "for f in t4-session-start t4-prompt-reminder t4-gate run-hook.cmd" "the .claude/hooks sync loop is not a filename list"
grep -q 'ls | grep -v' "$SYNC" \
  && ok "it derives the set from hooks/ instead" \
  || bad "the sync loop does not derive its set"

echo ""
echo "derived-guard-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

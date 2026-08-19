#!/usr/bin/env bash
# "When NOT to use" gives a route, not only a name (#249).
#
# A documentation-integrity suite, and labelled one.
#
# WHAT HAPPENED. `C:\AI`, 2026-08-18/19. The developer typed /using-t4 in a directory
# with no .git, no CLAUDE.md or AGENTS.md, and no docs/agents. Every T4 mechanism had
# nothing to operate on: no tracker for the PRD -> issues -> PR gate, no issue body for
# the bilingual rule, no vault or ledger for t4-agent-memory, no labels.
#
# THE SECTION NAMED THE CASE AND GAVE NO ROUTE. Session-protocol steps 1 and 4 apply
# anywhere; steps 2 and 3 have no referent. "Route first" says uncertainty is a reason to
# consult the map rather than skip it, and every row of that map is T4-specific, so
# consulting it returns nothing.
#
# AND THE RED-FLAG TABLE MAKES THE HONEST MOVE INDISTINGUISHABLE FROM THE FORBIDDEN ONE.
# "Small change, skip it" has a row; "this genuinely does not apply here" does not. An
# agent that correctly stops has to INFER the stop, which the table forbids.
#
# THIS FILE IS INJECTED ON EVERY SESSION START, including in repos that will never be T4,
# so the gap is not an edge case. Related but distinct: #244 covers the BOOTSTRAP session,
# where the repo is becoming T4; this is the case where it never will be.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
UT="$REPO_ROOT/skills/t4/using-t4/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

[ -f "$UT" ] && ok "using-t4 is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE CASE HAS A ROUTE, not only a name:"
has "$UT" "needs a route, not only a name" "the gap is named"
has "$UT" "hand off to \`ask-xeno\`" "and the destination is given"

echo ""
echo "the check that establishes it is concrete, not a judgement:"
has "$UT" "no \`.git\`" "the absent marker"
has "$UT" "no \`docs/agents\`" "and the absent agent docs"

echo ""
echo "WHICH PROTOCOL STEPS SURVIVE IS STATED — a partial escape is the whole point:"
has "$UT" "steps 1 and 4 still" "the two that apply anywhere"
has "$UT" "Steps 2 and 3 have no referent" "and the two that do not"

echo ""
echo "AND WHY THE ABSENCE OF A ROUTE WAS DANGEROUS, not merely untidy:"
has "$UT" "look identical from inside the red-flag table" "the honest and forbidden moves"
has "$UT" "every** session start" "and the reach of the file"

echo ""
echo "the original sentence is kept — this adds a route, it does not replace the case:"
has "$UT" "use the general skills directly" "the existing wording stands"

echo ""
echo "non-t4-route-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

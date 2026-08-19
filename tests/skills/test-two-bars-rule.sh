#!/usr/bin/env bash
# The guard's bar and the skill's bar differ, and passing one is not passing the other (#135).
#
# A documentation-integrity suite, and labelled one. NO CHANGE IS MADE TO THE GUARD --
# #135 offers three directions and picks none, and two of the three edit
# .githooks/check-gate-ledger, which t4-afk's boundary rule parks. What lands here is
# the direction-INDEPENDENT half: acceptance criterion 1 requires the relationship to be
# stated "whichever direction is chosen".
#
# THE MEASUREMENT. pal-mcp-server PR #86 carries
#   T4-Gates: simplify=not-run code-review=not-run scrutinize=not-run
#             security-review=not-run verify=ran
# Against check-gate-ledger that passes cleanly -- every gate stated, every value legal.
# Against the exemption rule it is FOUR VIOLATIONS, because not one carries a checkable
# fact. Its author believed the ledger had discharged the obligation.
#
# WHY THAT BELIEF IS THE PREDICTABLE ONE: the guard speaks at commit time and the skill
# is a document, so an agent optimising against the mechanism that talks back lands on a
# bare not-run. A permissive guard beside a strict rule relaxes the strict rule unless
# the difference is stated where the rule is.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WF="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"
GUARD="$REPO_ROOT/.githooks/check-gate-ledger"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$WF" ] && ok "t4-dev-workflow is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE TWO BARS ARE NAMED AS DIFFERENT — the sentence that stops the substitution:"
has "$WF" "passing the guard does not discharge this rule" "the guard is refused as a discharge"
has "$WF" "different bars" "and the difference is called what it is"

echo ""
echo "the measurement is on the page, or it reads as a caution:"
has "$WF" "PR #86" "the commit that passes one and violates the other"
has "$WF" "four violations" "with the count"

echo ""
echo "AND HOW TO READ A GREEN GUARD, which is the operational half:"
has "$WF" "nothing was silent" "what a green means"
has "$WF" "never as" "and what it does not mean"

echo ""
echo "the guard's own bar is quoted correctly — the claim is checked against the file:"
grep -q 'not-run' "$GUARD" \
  && ok "check-gate-ledger really does accept not-run" \
  || bad "the skill describes a guard that does not behave that way"
grep -q 'SILENCE\|silence' "$GUARD" \
  && ok "and really does forbid silence" \
  || bad "the guard does not forbid silence — the skill cites it wrongly"

echo ""
echo "AND THE GUARD IS UNCHANGED — #135 picks no direction, and two of three would edit it:"
# THE SAME ASSERTION AS A `hasnt`, deliberately: tests/audit-anchor-quality.sh reads
# anchors with a single-line grep, so an equivalent check written in python is invisible
# to it and this suite scores as positive-only. The permissive design is what #135 might
# later change; until a direction is chosen a reason token must not appear unattended.
hasnt "$GUARD" "not-run:" "no reason token was added to the guard unattended"

echo ""
echo "two-bars-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

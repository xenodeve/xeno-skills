#!/usr/bin/env bash
# A gate deferred to the end of the batch is a gate that did not run (#270).
#
# A documentation-integrity suite, and labelled one: it detects deletion and softening
# of the rule. It cannot detect an agent deferring anyway -- nothing can, which is the
# finding. #270 is a report of exactly that, from the session that wrote this file.
#
# WHAT HAPPENED, measured rather than supposed. t4-afk step 4 sits inside a loop that
# opens "For each independent item on the worklist", so the gates are per item.
# /simplify ran per item. /code-review and /scrutinize ran ONCE, at the end, against 62
# commits. That single late run found THREE defects, all already committed -- one of
# them written by the same session hours earlier, and two of the three fixes had to be
# written after the branch had merged.
#
# THE ASYMMETRY IS WHY THE RULE HAS TO BE WRITTEN DOWN. /verify leaves a green suite
# and /simplify leaves a diff; /code-review and /scrutinize leave NOTHING unless the
# reviewer writes it down. So deferring them costs nothing visible until something is
# found, and a deferred gate and a falsely-declared one produce the same record: none.
# That is #247 seen from the other side.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AFK="$REPO_ROOT/skills/t4/t4-afk/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$AFK" ] && ok "t4-afk is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "DEFERRED IS NOT RUN — the sentence the rule turns on:"
has "$AFK" "deferred" "the skill uses the word"
has "$AFK" "is a gate that did not run" "and says what deferring one amounts to"

echo ""
echo "the digest answer is PER ITEM, not per batch:"
# The digest rule already said "state every one as ran / not-run / n-a". A batch-level
# answer satisfies that wording completely, which is how 62 commits got one answer.
has "$AFK" "per item, not per batch" "the granularity is stated"

echo ""
echo "THE REASON IS ON THE PAGE, or a maintainer reads it as a restatement of step 4:"
has "$AFK" "leave nothing" "the two gates that leave no artifact are named as the risk"

echo ""
echo "and the failure is attached to a SHAPE CHANGE, not to indiscipline:"
# "Be more careful" is not a mechanism. The rule has to name when the loop stops being
# where you are: tracker items where the gates are legitimately n-a, then code.
has "$AFK" "n-a" "the legitimate n-a case is acknowledged"
has "$AFK" "shape" "and the shape change that ends the loop is named"

echo ""
echo "THE OLD WORDING IS RETIRED, not left beside the new one:"
hasnt "$AFK" "Run the gates unattended** — \`/simplify\`, then \`/verify\` (E2E for any frontend change — unit tests can't see real layout/hydration), \`/code-review\` + \`/scrutinize\`, and \`/security-review\` if a boundary was touched." "step 4 no longer stops at naming the gates"

echo ""
echo "deferred-gate-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

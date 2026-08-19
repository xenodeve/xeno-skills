#!/usr/bin/env bash
# "Then restore" names a mechanism, because the intuitive one deletes your work (#237).
#
# A documentation-integrity suite, and labelled one. NOTHING ENFORCES THIS -- no hook
# sees a revert, and #237 proposes none.
#
# WHAT HAPPENED, measured. On openclink 2026-08-16 the mutate-then-restore rule was
# FOLLOWED, ~30 times across ten slices, and it found real defects every time. The
# failure is in "then restore": `git checkout <path>` reads from THE INDEX, and the file
# had been written and not yet staged, so the revert went back to the last commit and
# took ~60 lines of new implementation with the mutation. Recoverable only because the
# code was still in context.
#
# THE RULE STEERS YOU INTO THE DESTRUCTIVE CASE. Mutation testing is most valuable right
# after writing the implementation and before the commit -- which is exactly when the
# standard revert is unsafe. That is why a named mechanism is not a nicety.
#
# AND THE APPLY STEP FAILS THE SAME WAY: a mutation the shell mangled produces the same
# zero-red as a mutation with no coverage gap, so a failed apply reads as a passing
# check.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUB="$REPO_ROOT/skills/multi-agent/clink-subagents/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

[ -f "$SUB" ] && ok "clink-subagents is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE FAILURE MODE IS NAMED — 'restore' alone is what caused it:"
has "$SUB" "read from **the index**" "where git checkout/restore actually read from"
has "$SUB" "not yet staged" "and the state in which that is destructive"

echo ""
echo "the measurement is on the page, or it reads as caution about a hypothetical:"
has "$SUB" "~60 lines" "the size of the loss"

echo ""
echo "AND THE MECHANISM IS GIVEN, not left as 'be careful':"
has "$SUB" "Stage first" "the primary answer"
has "$SUB" "keep-index" "with a named alternative"

echo ""
echo "the trap is explained as STRUCTURAL, which is why a clause was needed at all:"
has "$SUB" "most useful is exactly the moment your work is not yet in the index" \
    "the rule steers into the destructive case"

echo ""
echo "AND THE APPLY STEP, which fails silently in the same shape:"
has "$SUB" "confirm the mutation applied" "a mangled mutation is called out"
has "$SUB" "same zero-red" "with why it is invisible"

echo ""
echo "the original rule is intact — this adds a mechanism, it does not replace the check:"
has "$SUB" "A test you never saw fail is not evidence" "the mutation rule still stands"

echo ""
echo "restore-mechanism-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

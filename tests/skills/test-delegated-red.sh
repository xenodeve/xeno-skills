#!/usr/bin/env bash
# `clink-masteragent` already says a delegated GREEN is not a green. Measured
# 2026-08-05, the same is true of a delegated RED, and following the existing
# advice exactly was not enough to catch it (#113).
#
# The controlled comparison is the evidence, so the skills have to carry it: the
# SAME model at the SAME effort (gpt-5.6-luna, high), the SAME prompt shape, two
# leaves dispatched at the SAME moment. The code leaf returned a good test. The
# prose leaf returned 11 assertions that were each a grep for a sentence the
# worker had invented — it ran, exited 1, and REPRODUCED on the orchestrator's
# machine exactly as reported. The result was real and the test was worthless,
# because the fix it demanded was "paste these strings into the file".
#
# This test deliberately anchors on the MEASURED FIGURES rather than on the
# wording of the guidance, because a test that pinned invented prose would be
# the very defect #113 describes. `gpt-5.6-luna` and `11 assertions` are facts a
# reader can check; a sentence somebody just wrote is not.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUB="$REPO_ROOT/skills/multi-agent/clink-subagents/SKILL.md"
MASTER="$REPO_ROOT/skills/multi-agent/clink-masteragent/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }
hasnt() { if grep -qiF -- "$2" "$1"; then bad "$3"; else ok "$3"; fi; }

echo "the measurement is cited, so the claim can be checked rather than believed:"
has "$MASTER" "gpt-5.6-luna" "clink-masteragent names the model that produced both outcomes"
has "$MASTER" "11 assertions" "and the size of the worthless red"
has "$SUB"    "gpt-5.6-luna" "clink-subagents names it too"

echo
echo "the rule itself — reproducing is not the check:"
has "$MASTER" "is not a red" "clink-masteragent states the counterpart to its green rule"
has "$MASTER" "what the assertion is anchored to" "and says what to read for instead"

echo
echo "clink-subagents narrows what 'verifiable' is allowed to mean:"
has "$SUB" "observable behaviour" "verifiable is defined as observable behaviour"
has "$SUB" "asserting on its own invention" "and the prose-leaf failure is named as the mechanism"

echo
echo "the two secondary tells are named, since both shipped in the same file:"
has "$MASTER" "trivially true forever" "a control that can never fail is called out"
has "$MASTER" "no negative check" "positive-only assertions are called out"

echo
echo "the existing green rule is not replaced by the red one:"
has "$MASTER" "delegated green is not a green" "the green rule still stands"

echo
echo "the guidance must not claim the model was at fault — it was the leaf:"
hasnt "$SUB" "the small model cannot write tests" "no blanket claim about the model's ability"

echo
if [ "$fail" -gt 0 ]; then echo "FAILED: $fail, passed: $pass"; exit 1; fi
echo "OK: $pass passed"

#!/usr/bin/env bash
# clink-masteragent covers a delegated GREEN and (since #113) a delegated RED.
# Neither covers a returned DETECTOR — a linter, scanner, coverage report or
# audit — which fails in two ways a test does not (#118).
#
# Both halves were measured 2026-08-05 while building the #115 audit:
#
#   over-broad: the delegated draft called 30 of 32 suites defective. It flagged
#   suites with NO assertions, and every anchor containing no space — which
#   condemns `446`, a measured token count and one of the best anchors here.
#   Corrected, the real number was 11. Nothing it said was false; it was
#   USELESS, and that is not what the green/red rules test for.
#
#   unprobed zero: the corrected detector then reported 0 shadowed anchors.
#   Feeding it a temporary suite carrying a real defect moved the count 0 -> 1.
#
# Anchors below are the MEASURED FIGURES and phrases containing spaces — long
# enough not to be shadowed by another anchor in this file (#115).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MASTER="$REPO_ROOT/skills/multi-agent/clink-masteragent/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }
hasnt() { if grep -qiF -- "$2" "$1"; then bad "$3"; else ok "$3"; fi; }

echo "a returned detector is named as its own case, distinct from a test:"
has "$MASTER" "a delegated detector is neither" "the detector case is stated"
has "$MASTER" "30 of 32" "and cites the over-broad measurement"
has "$MASTER" "the real number was 11" "including the corrected figure"

echo
echo "the unprobed-zero half, stated as an action rather than a caution:"
has "$MASTER" "make it dirty on purpose" "the probe is named as an action"
has "$MASTER" "indistinguishable from a detector that stopped working" "and why a clean result proves nothing"

echo
echo "the self-inflicted repeat is recorded — 'a worker did it' is the forgettable reading:"
has "$MASTER" "does not respect who is writing" "the failure is not attributed to the worker alone"

echo
echo "false positives are not treated as the safe direction:"
has "$MASTER" "gets switched off" "the cost of crying wolf is stated"

echo
echo "the existing rules are extended, not replaced:"
has "$MASTER" "delegated green is not a green" "the green rule still stands"
has "$MASTER" "is not a red" "and the red rule still stands"

echo
echo "no blanket claim that detectors cannot be delegated:"
hasnt "$MASTER" "never delegate a detector" "delegation is still allowed, with verification"

echo
if [ "$fail" -gt 0 ]; then echo "FAILED: $fail, passed: $pass"; exit 1; fi
echo "OK: $pass passed"

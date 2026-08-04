#!/usr/bin/env bash
# The judgment gates have no hook, so until #104 the cost of skipping one was
# zero and the omission left no trace. `check-gate-ledger` is the mechanism;
# these assertions pin the prose that has to agree with it, because a guard
# whose rule is undocumented is a guard people route around.
#
# Deliberately stated: these are substring assertions over prose. They pin that
# a rule is written, not that an agent obeyed it. The behavioural half lives in
# tests/guards/test-check-gate-ledger.sh, which drives the real script.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AFK="$REPO_ROOT/skills/t4/t4-afk/SKILL.md"
REF="$REPO_ROOT/skills/t4/t4-afk/references/afk-artifacts.md"
WF="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"
LAYER="$REPO_ROOT/skills/t4/t4-project-bootstrap/references/guards-layer.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "the digest must enumerate, so an omission cannot be expressed as silence:"
has "$AFK" "ran / not-run / n-a"            "t4-afk states the three values a gate must be reported as"
has "$AFK" "cannot omit one by writing less" "and states why enumerating beats listing"
has "$REF" "T4-Gates:"                       "the landing-digest template carries the ledger line"
has "$REF" "not-run"                         "the template shows a not-run value rather than an all-clear"

echo
echo "the omission case is distinct from the unverified-verdict case:"
has "$AFK" "a true report with a hole in it" "t4-afk separates a false claim from a report that is silent"
has "$AFK" "listing what ran and not what did not" "the mistakes table names the omission move itself"

echo
echo "the artifact is named where the gates are, not only where the guard is:"
has "$WF" "T4-Gates:"                        "t4-dev-workflow names the trailer"
has "$WF" "not-run"                          "and says not-run is a legal answer, so the rule is not 'always run everything'"

echo
echo "the evidence survives — the batch that produced this rule is named:"
has "$LAYER" "nine PRs"                      "the guard's own doc names the incident"
has "$LAYER" "#100"                          "and cites the PRs so the claim is checkable"

# `not-run` being legal is the whole design; a future edit that quietly turns
# this into "every gate must have run" would invert it while every assertion
# above still passed on wording alone. Pin the permission explicitly.
echo
echo "the guard raises the cost of skipping without forbidding it:"
has "$AFK" "does not force a gate to run"    "t4-afk states the guard permits a declared skip"

echo
if [ "$fail" -gt 0 ]; then echo "FAILED: $fail, passed: $pass"; exit 1; fi
echo "OK: $pass passed"

#!/usr/bin/env bash
# The root-cause-before-fix rule has to survive future trims of the dispatcher.
# `using-t4` sits AT its 9000B budget, so the pressure to drop a line is real and
# constant — this test makes dropping this one a visible failure rather than a
# quiet one.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MAP="$REPO_ROOT/skills/t4/using-t4/SKILL.md"
WF="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "the injected map carries the rule:"
has "$MAP" "Root cause before fix"       "using-t4 non-negotiable rules include root-cause-before-fix"
has "$MAP" "Obvious ≠ traced"            "using-t4 red-flags rebut 'obviously it's X — just fix it'"

echo "the workflow skill carries the discipline:"
has "$WF" "Root cause before fix"        "t4-dev-workflow has the root-cause section"
has "$WF" "Reproduce"                    "step 1: reproduce"
has "$WF" "Falsify"                      "step 3: falsify the hypothesis"
has "$WF" "debug-mantra"                 "hands off to /debug-mantra for the technique"
# A rule with no stated exception gets ignored the first time it's inconvenient.
has "$WF" "exceptions are narrow"        "states the narrow exceptions instead of pretending there are none"

echo ""
echo "root-cause-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

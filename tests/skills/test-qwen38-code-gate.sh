#!/usr/bin/env bash
# `qwen38-code-gate` (#356, slice 1 of #355): the code-change done-gate for a
# small model. Its pair (with / without) runs in the tuning repo against
# fixtures/code-task-1; this test pins the skill's shape so a rewrite cannot
# turn it back into prose:
#
#   - the brief table comes first and ALWAYS has the test row, because the
#     omission seen most often is "no test run" — not a wrong test;
#   - six checks, each a command with a pass condition;
#   - RED before GREEN is a check with a named failure ("test written after
#     code"), not advice;
#   - the escape sentence and the boundary, as the family standard requires;
#   - the router's code row points here, not at prose alone.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GATE="$REPO_ROOT/skills/qwen38/qwen38-code-gate/SKILL.md"
ROUTER="$REPO_ROOT/skills/qwen38/using-qwen38/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if [ -f "$1" ] && grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "the skill exists, names its model, and is routed:"
[ -f "$GATE" ] && ok "skills/qwen38/qwen38-code-gate/SKILL.md exists" || bad "the gate is missing"
has "$GATE" "target-model: Qwen3.8-27B" "declares target-model"
has "$ROUTER" "qwen38-code-gate" "using-qwen38's code row finishes with the code gate"
hasnt() { if [ -f "$1" ] && ! grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }
# the row this gate REPLACED: a sentence-only finish ("run the tests and paste the last line").
# If it is still there beside the gate, the router offers two finishes and the model picks the cheaper.
hasnt "$ROUTER" "a change with no test run is not finished" "the old sentence-only finish is gone from the code row"

echo "the brief table comes first and carries the unnamed rows:"
first_table=$(grep -n "^## 0. Brief table" "$GATE" | head -1 | cut -d: -f1)
first_check=$(grep -n "^## 1" "$GATE" | head -1 | cut -d: -f1)
if [ -n "$first_table" ] && [ -n "$first_check" ] && [ "$first_table" -lt "$first_check" ]; then ok "section 0 precedes the checks"; else bad "brief table must precede the checks"; fi
has "$GATE" "always a row, even when the brief does not say" "the test row is unconditional"
has "$GATE" "the error path" "the error-path row"
has "$GATE" "new dependency" "the dependency row"
has "$GATE" "Edit only the files in the right-hand column" "scope is fixed by the table"

echo "six checks, each a command with a pass condition:"
for n in 1 2 3 4 5 6; do
  grep -qE "^\*\*$n\. " "$GATE" && ok "check $n is present" || bad "check $n is missing"
done
[ "$(grep -c '^```sh' "$GATE")" -ge 5 ] && ok "at least five fenced commands" || bad "fewer than five fenced commands"
has "$GATE" "git diff --name-only HEAD" "scope check is a command"
has "$GATE" "NotImplemented" "placeholder check names NotImplemented"
has "$GATE" "api[_-]?key" "secrets check names api keys"
has "$GATE" "do not invent one" "the test command is the repo's own"
has "$GATE" "test written after code" "RED-before-GREEN has a named failure"

echo "the report and the no-skip sentences:"
has "$GATE" "CODE GATE: n/6" "the report line"
has "$GATE" "THINK: assumptions" "the THINK line precedes the gate line (17:38: a gate-only report dropped a correct pushback)"
has "$GATE" "does not get a \`CODE GATE: 6/6\`" "an impossible brief cannot pass the code gate"
has "$GATE" "A check you did not run is a check that failed" "unrun = failed"
has "$GATE" "with no outputs is not a pass" "outputs must be pasted"
has "$GATE" "Never install a package or a tool to satisfy a check" "the escape sentence"

echo "boundary:"
has "$GATE" "What this does not touch" "the boundary section"
has "$GATE" "karpathy-guidelines" "design of the change is left to karpathy-guidelines"

echo
echo "qwen38-code-gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# The one precondition whose failure is invisible: whether the subagent's shell
# tools actually work. A broken tool chain returns exit 0 with a plausible answer
# produced by reasoning, so a good-looking result is not evidence anything ran.
# Observed on this machine twice — a removed PATH binary, and codex's rtk wrapper
# failing to resolve rg/grep/ls while its file reads succeeded.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUB="$REPO_ROOT/skills/multi-agent/clink-subagents/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "the precondition is in the delegate list, not in prose:"
has "$SUB" "Proven to have run" "the preflight list carries the named precondition"
has "$SUB" "it can only produce by running the thing" "the check is a command with an expected output, not 'verify your setup'"

echo
echo "the silent-failure mode is stated, because that is what makes it invisible:"
has "$SUB" "exit 0 with a plausible answer" "a broken tool chain looks like a successful run"
has "$SUB" "a plausible result is not evidence the tool ran" "so plausibility is not evidence"

echo
echo "what to do when it fails is stated, and it is not retry:"
has "$SUB" "not retry" "the failure response is named and it is not retry"

echo
echo "per-client jobs that client cannot do at all, each dated:"
has "$SUB" "cannot do at all" "the per-client table exists"

# The table's whole contract is "treat an old date as a prompt to re-probe", which
# an undated row silently exempts itself from. Asserting the header string only
# proves the COLUMN exists — so this counts the rows instead, and a new row added
# without a date fails. (The header assertion above claimed to check this and did
# not; that gap is the same shape as the one this PR is about.)
rows() { awk '/^### Jobs a given client cannot do at all/{f=1;next} f&&/^\*\*Never delegate\*\*/{exit} f&&/^\| `/' "$SUB"; }
total=$(rows | wc -l)
dated=$(rows | grep -cE '\| *20[0-9]{2}-[0-9]{2}-[0-9]{2} *\|')
if [ "$total" -gt 0 ] && [ "$total" -eq "$dated" ]; then
  ok "every one of the $total client rows carries a verification date"
else
  bad "$dated of $total client rows carry a verification date"
fi

echo
if [ "$fail" -gt 0 ]; then echo "FAILED: $fail, passed: $pass"; exit 1; fi
echo "OK: $pass passed"

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
has "$SUB" "sentinel" "the check is a command with an expected output, not 'verify your setup'"

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
has "$SUB" "last verified" "each claim carries the date it was last verified"

echo
if [ "$fail" -gt 0 ]; then echo "FAILED: $fail, passed: $pass"; exit 1; fi
echo "OK: $pass passed"

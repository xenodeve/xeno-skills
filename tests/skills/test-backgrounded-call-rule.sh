#!/usr/bin/env bash
# A clink call past two minutes is moved to a background task by Claude Code,
# which hands the agent the task id and says it can keep working. The agent does
# not always keep working — and that is the expensive half.
#
# Two observations of the same mechanism, opposite outcomes: a session on
# 2026-08-04 had a codex call backgrounded at 120s and picked up other work
# until the notification arrived at 188s; the developer's session showed
# "Waiting for task" with the call ALREADY in the background panel while the
# turn ran 3m4s -> 4m17s. Same host, same tool, different behaviour, so this is
# the model's choice and a skill can address it (#110).
#
# The block itself is fixed and unavoidable. The idle time after it is unbounded
# and, in the screenshot, larger than the block it follows.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUB="$REPO_ROOT/skills/multi-agent/clink-subagents/SKILL.md"
BRAIN="$REPO_ROOT/skills/multi-agent/clink-brainstorm/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "the latency budget names the backgrounding, not only the floor figures:"
has "$SUB" "moved to a background task" "clink-subagents states what happens past the threshold"
has "$SUB" "two minutes"                "and names the threshold"

echo
echo "it is written as an instruction, not as a description:"
has "$SUB" "is not a reason to wait"    "a backgrounded call does not license idling"
has "$SUB" "the notification will find you" "the agent is told the result comes back on its own"

echo
echo "the arithmetic that makes the fixed cost cheap:"
has "$SUB" "pay that block once"        "N parallel calls in one message pay the block once, not N times"
has "$SUB" "fire the batch last"        "local work first, delegation last in the turn"

echo
echo "the mirror does not drift — clink-brainstorm fires in parallel too:"
has "$BRAIN" "is not a reason to wait"  "clink-brainstorm carries the same consequence at its own parallel step"

echo
echo "the evidence is named, so this reads as measured rather than preferred:"
has "$SUB" "188s"                       "the session that kept working is cited"
has "$SUB" "Waiting for task"           "and the one that did not"

echo
if [ "$fail" -gt 0 ]; then echo "FAILED: $fail, passed: $pass"; exit 1; fi
echo "OK: $pass passed"

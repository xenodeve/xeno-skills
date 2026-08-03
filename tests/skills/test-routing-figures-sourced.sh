#!/usr/bin/env bash
# Every skill that routes on measured figures must carry a sourced figures block.
#
# `test-figures-sourced.sh` proves the CHECKER works, against fixtures. It cannot
# prove the checker is pointed at anything: `check-figures-sourced.sh` exits 0 on
# a skill with no block at all, which is indistinguishable from a skill whose
# figures all trace. So a suite that only runs the checker over the real skills
# would go green while guarding nothing.
#
# This test closes that gap with the assertion the checker cannot make: the block
# must EXIST. That assertion is the load-bearing one — the checker run below is a
# second line, not the first.
#
# ROSTER is hand-maintained on purpose. A skill that gains routing figures must be
# added here; nothing detects that automatically, because "carries routing figures"
# is the very property under test and deriving it from the file would be circular.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CHECKER="$REPO_ROOT/docs/research/scripts/check-figures-sourced.sh"

# Skills that route on measured figures.
ROSTER="
skills/multi-agent/clink-masteragent/SKILL.md
skills/multi-agent/clink-subagents/SKILL.md
skills/multi-agent/clink-brainstorm/SKILL.md
"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

# --- harness precondition ----------------------------------------------------
# Without this, a missing checker makes every case below "fail to run" and a
# careless reading of the exit code calls that a rule violation. Verified first.
if [ ! -x "$CHECKER" ]; then
  echo "cannot run: checker missing or not executable: $CHECKER" >&2
  exit 1
fi

echo "every skill that routes on figures carries a block naming its source:"
for rel in $ROSTER; do
  f="$REPO_ROOT/$rel"
  name="$(basename "$(dirname "$rel")")"

  if [ ! -f "$f" ]; then
    bad "$name: SKILL.md not found at $rel"
    continue
  fi

  if grep -q '<!--[[:space:]]*figures:start[[:space:]]\+source=' "$f"; then
    ok "$name declares a figures block with a source"
  else
    bad "$name has no <!-- figures:start source=... --> block — its figures are unguarded"
    continue
  fi

  if out="$("$CHECKER" "$f" "$REPO_ROOT" 2>&1)"; then
    ok "$name: every figure in the block traces to its source"
  else
    code=$?
    if [ "$code" -eq 2 ]; then
      bad "$name: a figure does not trace to its source"
      echo "$out" | sed 's/^/      /'
    else
      bad "$name: the check could not run (exit $code)"
      echo "$out" | sed 's/^/      /'
    fi
  fi
done

echo
echo "routing-figures-sourced: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

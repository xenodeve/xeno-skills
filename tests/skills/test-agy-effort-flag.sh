#!/usr/bin/env bash
# `agy --effort low|medium|high` is a real, three-rung, per-session flag. Both
# skills said antigravity had no separate effort knob, which tells a reader the
# knob does not exist — the part that misroutes (#98).
#
# The correction is not "the table was wrong" but "the table was incomplete":
# the label form exists too, and the interesting half is that the two are
# MUTUALLY EXCLUSIVE for every model agy serves. Measured 2026-08-04 against the
# real binary: an untiered id gives "--effort is not supported for model X", a
# tiered one gives "--model X conflicts with --effort=Y", and `--effort` alone
# with no `--model` succeeds. OpenClink refuses the pair before spawn (openclink#43, PR #45).
#
# And the flag is HONOURED, not merely accepted: same prompt, `low` produced 0
# thinking tokens and `high` produced 446. Argv shape proves nothing on this
# client — its history is a silently swallowed `--model` — so the token counts
# are the evidence and the skills have to say which is which.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUB="$REPO_ROOT/skills/multi-agent/clink-subagents/SKILL.md"
BRAIN="$REPO_ROOT/skills/multi-agent/clink-brainstorm/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }
hasnt() { if grep -qiF -- "$2" "$1"; then bad "$3"; else ok "$3"; fi; }

echo "neither skill still says antigravity has no separate effort flag:"
hasnt "$SUB"   "no separate flag — effort is **baked into the model label**" "clink-subagents no longer denies the flag"
hasnt "$BRAIN" "➖ baked into the model label"                               "clink-brainstorm no longer denies it either"

echo
echo "both name the real flag and its ladder:"
has "$SUB"   "--effort"     "clink-subagents names the flag"
has "$BRAIN" "--effort"     "clink-brainstorm names it too"
has "$SUB"   "low|medium|high" "and its three rungs"

echo
echo "the routing consequence — the two knobs cannot be combined:"
has "$SUB"   "mutually exclusive" "clink-subagents states the exclusion"
has "$BRAIN" "mutually exclusive" "clink-brainstorm states it as well"
has "$SUB"   "one or the other, not both" "and says what to do about it"

echo
echo "OpenClink refuses the pair before spawn, so this is not merely advice:"
has "$SUB" "refuses the pair before spawn" "the pre-spawn refusal is named"

echo
echo "the evidence is cited, and it is token counts rather than argv shape:"
has "$SUB" "446" "the honoured-not-merely-accepted measurement is quoted"

echo
if [ "$fail" -gt 0 ]; then echo "FAILED: $fail, passed: $pass"; exit 1; fi
echo "OK: $pass passed"

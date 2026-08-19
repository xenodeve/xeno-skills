#!/usr/bin/env bash
# ADR 0001 is the document every enforcement decision in this repo defers to, and
# one sentence in it was false and was cited as evidence in a real session (#155):
# a panel corrected a design question on the grounds that UserPromptSubmit cannot
# block, the orchestrator verified it against the ADR, found it stated there, and
# reported it as confirmed. The repo's own record was the thing that was wrong.
#
# A vendor capability cannot be asserted by a local test, and pretending otherwise
# is the theatre the ADR itself warns about. What IS checkable: the retired wording
# is gone, the constraints that bound every injection design are stated, and the
# claim carries the date it was last checked against the reference.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ADR="$REPO_ROOT/docs/adr/0001-hook-based-workflow-enforcement.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }
hasnt() { if grep -qiF -- "$2" "$1"; then bad "$3"; else ok "$3"; fi; }

echo "the retired claim is gone:"
hasnt "$ADR" "inject context, can't block" "the 'can't block' claim for UserPromptSubmit is retired"
hasnt "$ADR" "The only deterministic interception points are" "the 'only interception points' framing is retired"

echo ""
echo "what replaced it is stated, not implied:"
has "$ADR" "UserPromptSubmit" "UserPromptSubmit is still named"
has "$ADR" "erases the prompt" "its real blocking behaviour is stated in the vendor's own words"
has "$ADR" "31 documented events" "the real size of the event surface is stated"
has "$ADR" "10,000" "the hook-output cap is recorded, because it bounds every injection design"

echo ""
echo "the claim carries the date it was last checked, not inherited confidence:"
if grep -qE "verified against the reference on 20[0-9]{2}-[0-9]{2}-[0-9]{2}" "$ADR"; then
  ok "a dated verified-against line is present"
else
  bad "no dated verified-against line -- the next reader cannot tell inherited from checked"
fi

echo ""
echo "the correction is recorded rather than edited in silently:"
has "$ADR" "#155" "the ADR points at the issue that corrected it"

echo ""
echo "adr-0001-surface: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

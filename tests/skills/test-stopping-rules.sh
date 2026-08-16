#!/usr/bin/env bash
# The four stopping rules as checked gates (#224).
#
# The plan wrote them "now rather than after the work" and said why: a gate written
# after the effort has been spent is a gate nobody uses. None of them was a gate.
# The property this suite pins is the one that makes it a gate at all: AN UNMEASURED
# RULE DOES NOT PASS. A gate whose missing measurement reads as a pass is worse than
# no gate -- it produces the paperwork of having checked.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN="$REPO_ROOT/scripts/stopping-rules.py"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

[ -f "$GEN" ] && ok "the gate is committed" || bad "the gate is missing"

echo ""
echo "every rule reports a state, and the thresholds carry their reasoning:"
out="$(python "$GEN" 2>&1)"
for r in "1 routed-then-loaded" "2 false-positive rate" "3 traceable rules" "4 off switches"; do
  case "$out" in *"$r"*) ok "rule reported: $r";; *) bad "no state for: $r";; esac
done
grep -q "reasoning for the number rather than the number alone" "$GEN" \
  && ok "the thresholds are documented with why, not just what" || bad "a bare number with no reasoning"

echo ""
echo "UNKNOWN DOES NOT PASS -- the property that makes this a gate:"
python "$GEN" --gate 2 >/dev/null 2>&1
[ $? -ne 0 ] && ok "an unmeasured rule blocks the slice" || bad "an unmeasured rule passed the gate"
err="$(python "$GEN" --gate 2 2>&1 >/dev/null)"
case "$err" in *"unknown does not pass"*) ok "and the message says so";; *) bad "unhelpful: $err";; esac
case "$err" in *"#180"*) ok "and names who owns the missing number";; *) bad "the owner is not named";; esac

echo ""
echo "proceeding past an unknown is possible, and is then a recorded decision:"
python "$GEN" --gate 2 --allow-unmeasured >/dev/null 2>&1
[ $? -eq 0 ] && ok "--allow-unmeasured clears the gate" || bad "the escape hatch does not work"
out2="$(python "$GEN" --gate 2 --allow-unmeasured 2>&1)"
case "$out2" in *"explicitly allowed"*) ok "and it says the unknowns were allowed, not measured";;
  *) bad "proceeding past unknown was silent";; esac

echo ""
echo "rule 3 is answered from the census, which exists today:"
case "$out" in *"master-produced rules need a trace"*) ok "it reads a real number from the census";;
  *) bad "rule 3 is not evaluated";; esac

echo ""
echo "rule 4 finds a real off-switch assertion for every layer that gates or injects:"
case "$out" in *"4 off switches         pass"*) ok "every layer's off switch is asserted";;
  *) bad "rule 4 is not passing: $out";; esac

echo ""
echo "POSITIVE CONTROL -- rule 4 detects a missing off switch:"
probe="$REPO_ROOT/tests/hooks/test-sticky-debt.sh"
cp "$probe" "$probe.gatebak"
sed -i 's/with no stickyDebt setting it says nothing/OFF SWITCH ASSERTION REMOVED BY PROBE/' "$probe"
out3="$(python "$GEN" 2>&1)"
case "$out3" in *"4 off switches         STOP"*) ok "removing an off-switch assertion trips rule 4";;
  *) bad "rule 4 did not notice a removed assertion";; esac
mv "$probe.gatebak" "$probe"
out4="$(python "$GEN" 2>&1)"
case "$out4" in *"4 off switches         pass"*) ok "restoring it clears rule 4 again";; *) bad "rule 4 stayed red";; esac

echo ""
echo "stopping-rules: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

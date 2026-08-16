#!/usr/bin/env bash
# The baseline is measured and every count carries its denominator (#180).
#
# This repository has already recorded a figure it could not use, because only the
# failures were counted and nobody knew how many chances there had been. The point
# of this suite is that the same cannot be true of these numbers.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN="$REPO_ROOT/scripts/measure-baseline.py"
DATA="$REPO_ROOT/docs/research/data/compliance-baseline.json"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

[ -f "$GEN" ]  && ok "the measurement script is committed, so it can be re-run" || bad "no script"
[ -f "$DATA" ] && ok "the measurement is committed, not quoted in a comment" || bad "no data file"

echo ""
echo "every count carries the number it divides by:"
python - "$DATA" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
for k in ("sessions","user_records","routed_turns","routed_then_loaded","routed_then_loaded_rate"):
    assert k in d, "missing %s" % k
assert d["routed_turns"] > 0, "nothing routed -- the rate would be meaningless"
r = d["routed_then_loaded"] / d["routed_turns"]
assert abs(r - d["routed_then_loaded_rate"]) < 1e-9, "the published rate is not its own numerator over its denominator"
print("    %d sessions, %d user records, %d routed, %d loaded, rate %.3f"
      % (d["sessions"], d["user_records"], d["routed_turns"], d["routed_then_loaded"], d["routed_then_loaded_rate"]))
PY
[ $? -eq 0 ] && ok "the rate equals its own numerator over its denominator" || bad "the numbers do not reconcile"

echo ""
echo "what the method cannot see is stated, so the number is not read as more than it is:"
grep -q "OPTIMISTIC" "$GEN" && ok "the optimism of the rate is declared" || bad "no optimism note"
grep -q "not a sample of anything" "$GEN" && ok "and that the sessions are not a sample" || bad "no sampling caveat"
python - "$DATA" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
assert "Optimistic" in d.get("note",""), "the caveat did not travel with the data"
assert "false_positive_rate" not in d, "an unmeasured figure was written as though measured"
PY
[ $? -eq 0 ] && ok "the caveat travels with the data, and no unmeasured figure was invented" \
             || bad "the data file overclaims"

echo ""
echo "#224 now reads a real number for rule 1, and still refuses on rule 2:"
out="$(python "$REPO_ROOT/scripts/stopping-rules.py" 2>&1)"
case "$out" in *"1 routed-then-loaded   pass"*) ok "rule 1 passes on measured evidence";; *) bad "rule 1 is not passing: $out";; esac
case "$out" in *"2 false-positive rate  unknown"*) ok "rule 2 is still unknown, and unknown does not pass";;
  *) bad "rule 2 changed without being measured";; esac

echo ""
echo "baseline-measured: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

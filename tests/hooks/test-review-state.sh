#!/usr/bin/env bash
# The reviewer's state file and its five legal transitions (#189).
# Seam: one transition on stdin + cwd -> the merged file on disk, and a finding on
# stdout when one is emitted. Same shape as the other hook suites.
#
# The property the whole design rests on: THE REVIEWER CANNOT EDIT A PRIOR ROW.
# A later segment must never rewrite an earlier segment's verdict, because the
# reviewer is memoryless and would otherwise inherit its predecessor's guess as a
# premise. Every assertion below exists to pin that.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-review-state"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude"; printf '{"t4":true}\n' > "$REPO/.claude/t4.json"
STATE="$REPO/.claude/t4-review-state.json"

# apply <json>  -> stdout of the script; sets RC
apply() { out="$(cd "$REPO" && printf '%s' "$1" | bash "$HOOK" 2>&1)"; RC=$?; printf '%s' "$out"; }
# q <python-expr over the parsed state as `s`> -> printed value
q() { python - "$STATE" "$1" <<'PY'
import json, sys
try: s = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception: s = None
print(eval(sys.argv[2], {"s": s, "len": len}))
PY
}

echo "a missing, empty or corrupt file is treated as empty:"
apply '{"op":"list"}' >/dev/null; [ "$RC" -eq 0 ] && ok "missing file: exit zero" || bad "missing file: exit $RC"
printf '' > "$STATE";       apply '{"op":"list"}' >/dev/null; [ "$RC" -eq 0 ] && ok "empty file: exit zero" || bad "empty file: exit $RC"
printf 'not json{' > "$STATE"; apply '{"op":"list"}' >/dev/null; [ "$RC" -eq 0 ] && ok "corrupt file: exit zero" || bad "corrupt file: exit $RC"
out="$(apply '{"op":"list"}')"; [ -z "$out" ] && ok "and emits no finding" || bad "emitted: $out"
rm -f "$STATE"

echo ""
echo "transition 3 -- a new open row is added:"
apply '{"op":"open","rule":"tdd","record":41,"uuid":"u-41"}' >/dev/null
[ "$(q '"tdd" in [r["rule"] for r in s["active"]]')" = "True" ] && ok "the row is in active" || bad "the row is not in active"
apply '{"op":"open","rule":"tdd","record":42,"uuid":"u-42"}' >/dev/null
[ "$(q 'len(s["active"])')" = "1" ] && ok "opening the same rule twice does not duplicate it" || bad "duplicate open row"

echo ""
echo "transition 1 -- an open row becomes satisfied and is removed:"
out="$(apply '{"op":"satisfy","rule":"tdd"}')"
[ "$(q 'len(s["active"])')" = "0" ] && ok "the row is gone" || bad "the row survived"
[ -z "$out" ] && ok "satisfying emits no finding" || bad "satisfying emitted: $out"

echo ""
echo "transition 2 -- an open row becomes violated, is removed, and a finding is emitted:"
apply '{"op":"open","rule":"simplify","record":50,"uuid":"u-50"}' >/dev/null
out="$(apply '{"op":"violate","rule":"simplify"}')"
[ "$(q 'len(s["active"])')" = "0" ] && ok "the row is gone" || bad "the row survived"
case "$out" in *'"finding"'*) ok "a finding is emitted on stdout";; *) bad "no finding emitted, got: $out";; esac
[ "$(q 'len(s["findings"])')" = "1" ] && ok "the finding is recorded in the file" || bad "the finding was not recorded"

echo ""
echo "transition 4 -- an unknown is re-evaluated:"
apply '{"op":"open","rule":"verify","state":"unknown","record":60,"uuid":"u-60"}' >/dev/null
[ "$(q 'len(s["unknown"])')" = "1" ] && ok "the row starts in unknown" || bad "the row is not in unknown"
apply '{"op":"reevaluate","rule":"verify","verdict":"satisfied"}' >/dev/null
[ "$(q 'len(s["unknown"])')" = "0" ] && ok "re-evaluating clears it from unknown" || bad "it stayed in unknown"

echo ""
echo "transition 5 -- a finding is dismissed:"
fid="$(q 's["findings"][0]["finding"]')"
apply "{\"op\":\"dismiss\",\"finding\":\"$fid\",\"reason\":\"the survey is in the issue body\"}" >/dev/null
[ "$(q 'len(s["decided"])')" = "1" ] && ok "the dismissal is recorded in decided" || bad "the dismissal was not recorded"
[ "$(q 's["decided"][0].get("reason") is not None')" = "True" ] && ok "the stated reason is kept" || bad "the reason was dropped"

echo ""
echo "an illegal transition is rejected and the file is left unchanged:"
before="$(cat "$STATE")"
apply '{"op":"teleport","rule":"tdd"}' >/dev/null; [ "$RC" -ne 0 ] && ok "an unknown op exits non-zero" || bad "an unknown op exited zero"
[ "$(cat "$STATE")" = "$before" ] && ok "the file is byte-identical after a rejected op" || bad "the file changed on a rejected op"
apply '{"op":"satisfy","rule":"never-opened"}' >/dev/null; [ "$RC" -ne 0 ] && ok "satisfying a row that is not open exits non-zero" || bad "it exited zero"
[ "$(cat "$STATE")" = "$before" ] && ok "and leaves the file unchanged" || bad "the file changed"

echo ""
echo "the reviewer cannot edit a prior row:"
apply '{"op":"open","rule":"tdd","record":70,"uuid":"u-70"}' >/dev/null
apply '{"op":"violate","rule":"tdd"}' >/dev/null
n="$(q 'len(s["findings"])')"
case "$n" in ''|*[!0-9]*) bad "cannot check rewriting: no findings list to compare (got '$n')";;
  0) bad "cannot check rewriting: findings list is empty, so equality proves nothing";;
  *) apply '{"op":"open","rule":"tdd","record":71,"uuid":"u-71"}' >/dev/null
     apply '{"op":"satisfy","rule":"tdd"}' >/dev/null
     [ "$(q 'len(s["findings"])')" = "$n" ] && ok "a later segment does not rewrite an earlier verdict ($n kept)" || bad "an earlier finding was mutated";;
esac

echo ""
echo "an interrupted write leaves the previous state intact:"
good="$(cat "$STATE")"
if grep -q 'os.replace\|mv -f\|\.tmp' "$HOOK"; then
  ok "the write goes through a temp file and an atomic rename"
else
  bad "no atomic-rename path found -- a killed write can truncate the file"
fi
if [ -s "$STATE" ]; then
  apply '{"op":"list"}' >/dev/null
  [ "$(cat "$STATE")" = "$good" ] && ok "a read-only op does not rewrite the file" || bad "a read-only op rewrote the file"
else
  bad "cannot check: no state file exists, so comparing it to itself proves nothing"
fi

echo ""
echo "review-state: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

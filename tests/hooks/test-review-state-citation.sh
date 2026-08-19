#!/usr/bin/env bash
# Every state row cites the record it rests on (#222, write rule 2 of the plan).
#
# Without it a `pending` row is a bare assertion by the previous reviewer, and the
# next one -- which is memoryless -- must either trust it or discard it. Trusting
# it is how a guess written in one segment becomes a premise three segments later.
# The plan calls this "the register rule from t4-dev-workflow applied to the
# reviewer itself: a claim's register does not improve by being carried forward."
#
# SCOPE. This slice enforces that a citation is PRESENT and carries its source.
# Deciding whether a citation still RESOLVES needs the transcript reader (#184),
# which does not exist yet; #184 supplies the resolution and this supplies the field.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-review-state"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude"; printf '{"t4":true}\n' > "$REPO/.claude/t4.json"
STATE="$REPO/.claude/t4-review-state.json"
apply() { out="$(cd "$REPO" && printf '%s' "$1" | bash "$HOOK" 2>&1)"; RC=$?; printf '%s' "$out"; }
q() { python - "$STATE" "$1" <<'PY'
import json, sys
try: s = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception: s = None
print(eval(sys.argv[2], {"s": s, "len": len, "all": all, "any": any}))
PY
}

echo "a row cannot be written without a citation:"
apply '{"op":"open","rule":"tdd"}' >/dev/null
[ "$RC" -ne 0 ] && ok "open with neither record nor uuid is rejected" || bad "it was accepted"
[ ! -f "$STATE" ] && ok "and no file was created" || bad "a file was written for a rejected row"

apply '{"op":"open","rule":"tdd","record":41}' >/dev/null
[ "$RC" -ne 0 ] && ok "open with a record but no uuid is rejected" || bad "it was accepted"
apply '{"op":"open","rule":"tdd","uuid":"u-41"}' >/dev/null
[ "$RC" -ne 0 ] && ok "open with a uuid but no record is rejected" || bad "it was accepted"

echo ""
echo "a complete citation is accepted and kept:"
apply '{"op":"open","rule":"tdd","record":41,"uuid":"u-41"}' >/dev/null
[ "$RC" -eq 0 ] && ok "record + uuid is accepted" || bad "a complete citation was rejected (rc=$RC)"
[ "$(q 'all(r.get("record") is not None and r.get("uuid") for r in s["active"])')" = "True" ] \
  && ok "the row carries both" || bad "the row lost part of its citation"

echo ""
echo "a citation into a subagent transcript carries its source:"
apply '{"op":"open","rule":"simplify","record":12,"uuid":"u-12","source":"agent-a287239d0"}' >/dev/null
[ "$(q 'any(r.get("source")=="agent-a287239d0" for r in s["active"])')" = "True" ] \
  && ok "source is kept on the row" || bad "source was dropped"
out="$(apply '{"op":"violate","rule":"simplify"}')"
case "$out" in *'agent-a287239d0'*) ok "and travels onto the finding";; *) bad "the finding lost its source: $out";; esac

echo ""
echo "the master's own record needs no source, and that is not a silent default:"
apply '{"op":"open","rule":"verify","record":90,"uuid":"u-90"}' >/dev/null
[ "$(q 'any(r["rule"]=="verify" and r.get("source")=="master" for r in s["active"])')" = "True" ] \
  && ok "an unsourced row is recorded as master, explicitly" || bad "source was left null rather than named"

echo ""
echo "the five transitions are unchanged -- this adds a field, not a sixth op:"
apply '{"op":"teleport"}' >/dev/null; [ "$RC" -ne 0 ] && ok "no new op was introduced" || bad "an unknown op now succeeds"
apply '{"op":"satisfy","rule":"verify"}' >/dev/null; [ "$RC" -eq 0 ] && ok "satisfy still works" || bad "satisfy broke (rc=$RC)"

echo ""
echo "review-state-citation: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

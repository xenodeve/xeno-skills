#!/usr/bin/env bash
# Consume the clink compliance record (#221).
# Seam: a record on stdin -> one verdict word. Every degradation goes to `unknown`
# or `delegated`, never to a violation the master cannot check.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-clink-record"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
r() { printf '%s' "$1" | bash "$HOOK" 2>/dev/null; }

FRESH='"reviewer":{"cli":"cursor","continuation_id":"fresh"}'
OBS='"verdicts":[{"skill":"tdd","followed":false,"observed":"edited src/x.ts at event 41; no test before it"}]'

echo "a record resolves the delegation past `delegated`:"
[ "$(r "{$FRESH,$OBS,\"final\":\"not-complied\"}")" = "violated" ] && ok "not-complied -> violated" || bad "not-complied wrong"
[ "$(r "{$FRESH,$OBS,\"final\":\"complied\"}")" = "satisfied" ] && ok "complied -> satisfied" || bad "complied wrong"

echo ""
echo "no record still resolves to delegated -- a missing record is not a failing one:"
[ "$(r '')" = "delegated" ] && ok "empty input -> delegated" || bad "empty input wrong"
[ "$(r '{}')" = "delegated" ] && ok "an empty record -> delegated" || bad "empty record wrong"
[ "$(r 'not json')" = "delegated" ] && ok "unparseable -> delegated" || bad "unparseable wrong"
[ "$(r "{$FRESH,\"final\":\"unknown\"}")" = "delegated" ] \
  && ok "an honest unknown from the far side -> delegated, never a violation" || bad "unknown wrong"

echo ""
echo "a verdict with no observation is not consumable:"
NOOBS='"verdicts":[{"skill":"tdd","followed":false}]'
[ "$(r "{$FRESH,$NOOBS,\"final\":\"not-complied\"}")" = "unknown" ] \
  && ok "no observed -> unknown, not violated" || bad "a judgement with no observation was consumed"
err="$(printf '%s' "{$FRESH,$NOOBS,\"final\":\"not-complied\"}" | bash "$HOOK" 2>&1 >/dev/null)"
case "$err" in *"cannot disagree with a judgement it cannot check"*) ok "and says why";; *) bad "no reason: $err";; esac
[ "$(r "{$FRESH,\"verdicts\":[{\"skill\":\"x\",\"observed\":\"   \"}],\"final\":\"complied\"}")" = "unknown" ] \
  && ok "a blank observation counts as none" || bad "whitespace passed as an observation"

echo ""
echo "a seat that was not fresh reviewed itself:"
STALE='"reviewer":{"cli":"cursor","continuation_id":"abc-123"}'
[ "$(r "{$STALE,$OBS,\"final\":\"not-complied\"}")" = "unknown" ] \
  && ok "a reused continuation_id -> unknown" || bad "a self-review was consumed"
[ "$(r "{$OBS,\"final\":\"not-complied\"}")" = "unknown" ] \
  && ok "a missing reviewer block -> unknown" || bad "an unattributed record was consumed"

echo ""
echo "an unrecognised final is unknown, not silently ignored:"
[ "$(r "{$FRESH,$OBS,\"final\":\"probably-fine\"}")" = "unknown" ] && ok "unrecognised final -> unknown" || bad "wrong"

echo ""
echo "it is a pure function and never writes:"
before="$(ls -a "$REPO_ROOT" | wc -l)"
r "{$FRESH,$OBS,\"final\":\"complied\"}" >/dev/null
[ "$(ls -a "$REPO_ROOT" | wc -l)" = "$before" ] && ok "no files created" || bad "it wrote something"

echo ""
echo "clink-record: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

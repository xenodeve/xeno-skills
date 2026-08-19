#!/usr/bin/env bash
# Resolving a finding by RECEIPT, not by prose (#203).
#
# Without one the reviewer does one of two things, and both are worse than no finding:
# it re-raises what the master already rejected -- which is how a useful critic gets
# switched off, taking its true findings with it -- or it reads silence as consent,
# which turns an unanswered finding into a false pass.
#
# THE SPAN IS NOT SET HERE, AND THAT IS DELIBERATE. "A finding with no receipt inside a
# stated span" needs a number, and that number is #178 -- a decision the plan reserved
# for the developer, to be derived from real sessions. So the mechanism ships with the
# span CONFIGURABLE AND UNSET, nothing expires until someone sets it, and no guessed
# number is written down as though it were derived.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-receipt"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude/hooks"
for f in t4-receipt t4-review-state; do cp "$REPO_ROOT/hooks/$f" "$REPO/.claude/hooks/" 2>/dev/null; done

cfg() { python - "$REPO/.claude/t4.json" "${1:-}" <<'PY'
import json, sys
c = {"t4": True}
if sys.argv[2]:
    c["findingExpirySegments"] = int(sys.argv[2])
with open(sys.argv[1], "w", encoding="utf-8", newline="\n") as f:
    json.dump(c, f)
PY
}
op() { printf '%s' "$1" | (cd "$REPO" && bash .claude/hooks/t4-review-state 2>/dev/null); }
# Raise a finding the honest way -- through the transitions, never by writing the file.
raise() { op "{\"op\":\"open\",\"rule\":\"$1\",\"record\":\"r\",\"uuid\":\"u\"}" >/dev/null
          op "{\"op\":\"violate\",\"rule\":\"$1\"}" >/dev/null; }
receipt() { # a segment carrying a dismissal receipt for $1
  printf '{"type":"assistant","uuid":"a1","message":{"content":[{"type":"text","text":"T4-DISMISS: %s misread the diff"}]}}\n' "$1"
}
quiet() { printf '{"type":"assistant","uuid":"a2","message":{"content":[{"type":"text","text":"carrying on with the work"}]}}\n'; }
run() { (cd "$REPO" && bash .claude/hooks/t4-receipt 2>/dev/null); }
state() { python - "$REPO/.claude/t4-review-state.json" "$1" <<'PY'
import json, os, sys
d = json.load(open(sys.argv[1], encoding="utf-8")) if os.path.exists(sys.argv[1]) else {}
try:
    print(eval(sys.argv[2], {"d": d}))
except Exception as e:
    print("<%s>" % e)
PY
}
counts() { python - "$REPO/.claude/t4-receipt-counts.json" "$1" <<'PY'
import json, os, sys
d = json.load(open(sys.argv[1], encoding="utf-8")) if os.path.exists(sys.argv[1]) else {}
print(d.get(sys.argv[2], 0))
PY
}
nextf() { op '{"op":"next"}'; }
reset() { rm -f "$REPO/.claude/t4-review-state.json" "$REPO/.claude/t4-receipt-counts.json"; }

[ -f "$HOOK" ] && ok "the receipt reader exists" || bad "hooks/t4-receipt is missing"

echo ""
echo "A DISMISSAL IS RECOGNISED, and the finding is not re-emitted in a later segment:"
reset; cfg ''
raise 'Red before green.'
[ -n "$(nextf)" ] && ok "the finding is deliverable before the receipt" || bad "nothing to deliver -- the fixture is broken"
receipt F-001 | run
[ -z "$(nextf)" ] && ok "and silent after it" || bad "the master's dismissal was ignored: $(nextf)"
quiet | run
[ -z "$(nextf)" ] && ok "and stays silent a segment later -- not re-raised once forgotten" \
                  || bad "the finding came back"
[ "$(counts dismissed)" = "1" ] && ok "the dismissal is counted" || bad "dismissed=$(counts dismissed)"

echo ""
echo "SILENCE IS NOT CONSENT -- an unanswered finding stays deliverable:"
reset; cfg ''
raise 'Red before green.'
quiet | run; quiet | run; quiet | run
[ -n "$(nextf)" ] && ok "three quiet segments do not resolve it" || bad "silence was read as agreement"
[ "$(counts dismissed)" = "0" ] && ok "and nothing was counted as dismissed" || bad "silence was counted as a dismissal"

echo ""
echo "#178 IS RESERVED, SO NOTHING EXPIRES UNTIL SOMEONE SETS THE SPAN:"
reset; cfg ''
raise 'Red before green.'
for i in 1 2 3 4 5 6 7 8 9 10; do quiet | run; done
[ -n "$(nextf)" ] && ok "ten segments with no span configured: still open, not silently aged out" \
                  || bad "a finding expired against a number nobody chose"
[ "$(counts unresolved)" = "0" ] && ok "and nothing counted unresolved" || bad "unresolved=$(counts unresolved)"

echo ""
echo "WITH A SPAN SET, a finding with no receipt expires AS UNRESOLVED:"
reset; cfg 3
raise 'Red before green.'
quiet | run; quiet | run
[ -n "$(nextf)" ] && ok "inside the span it is still deliverable" || bad "it expired early"
quiet | run; quiet | run
[ -z "$(nextf)" ] && ok "past the span it stops being delivered" || bad "it never expired"
[ "$(counts unresolved)" = "1" ] && ok "and is counted unresolved" || bad "unresolved=$(counts unresolved)"

echo ""
echo "UNRESOLVED IS NEVER TREATED AS AGREEMENT -- the distinction, asserted:"
[ "$(state 'd["decided"][0]["decision"]')" = "unresolved" ] \
  && ok "the record says unresolved, not dismiss" \
  || bad "an expiry was recorded as a dismissal: $(state 'd["decided"]')"
[ "$(state 'd["decided"][0]["by"]')" = "expiry" ] \
  && ok "and says the clock ended it, not the master" || bad "the expiry claims a decider it did not have"
[ "$(counts dismissed)" = "0" ] \
  && ok "THE COUNTS ARE SEPARATE: an expiry adds nothing to the dismissed count" \
  || bad "dismissed=$(counts dismissed) -- an unanswered finding was folded into agreement"

echo ""
echo "guards:"
out="$(printf '%s' 'not json' | (cd "$REPO" && bash .claude/hooks/t4-receipt 2>&1))"; rc=$?
[ "$rc" -eq 0 ] && ok "unparseable segment: exit zero" || bad "unparseable segment: exit $rc"
PLAIN="$TMP/plain"; mkdir -p "$PLAIN/.claude/hooks"; cp "$REPO_ROOT/hooks/t4-receipt" "$PLAIN/.claude/hooks/" 2>/dev/null
out="$(quiet | (cd "$PLAIN" && bash .claude/hooks/t4-receipt 2>&1))"; rc=$?
{ [ "$rc" -eq 0 ] && [ -z "$out" ]; } && ok "no marker file: silent, exit zero" || bad "rc=$rc out=$out"

echo ""
echo "receipt: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

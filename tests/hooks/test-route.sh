#!/usr/bin/env bash
# hooks/t4-route -- the table's answer, its TRUSTWORTHINESS, and the union (#191).
#
# Seam: a prompt on stdin -> one JSON object on stdout:
#   {"table":[...], "classifier":[...], "routed":[...], "trusted":bool,
#    "reasons":[...], "consulted":bool}
#
# The argument this file exists to hold: running the classifier only on a MISS makes
# the table authoritative whenever it fires -- including when it fires WRONGLY. That
# is a fallback, not redundancy, and calling it redundancy is the more expensive
# mistake because it stops anyone looking for the gap. So five conditions, each with
# its own assertion, and a fixture where the table is wrong on purpose.
#
# WHY THE HOOK DOES NOT PASS --with-classifier, asserted at the bottom. The classifier
# is a model call and a hook is a synchronous barrier on every host (#187). The router
# consults it only when asked to; the gap notice never asks.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude/hooks"
for f in t4-route t4-classifier routing-table.json; do
  [ -f "$REPO_ROOT/hooks/$f" ] && cp "$REPO_ROOT/hooks/$f" "$REPO/.claude/hooks/"
done

cfg() { python - "$REPO/.claude/t4.json" "${1:-}" <<'PY'
import json, sys
path, command = sys.argv[1], sys.argv[2]
cfg = {"t4": True}
if command:
    cfg["classifier"] = command
with open(path, "w", encoding="utf-8", newline="\n") as f:
    json.dump(cfg, f)
PY
}
stub() { printf "cat >/dev/null; printf '%%s' '%s'" "$1"; }

# route <prompt> [--with-classifier]
route() { (cd "$REPO" && printf '%s' "$1" | bash .claude/hooks/t4-route ${2:-} 2>/dev/null); }
# field <json> <expr over the parsed object `d`>
field() { python - "$1" "$2" <<'PY'
import json, sys
try:
    d = json.loads(sys.argv[1])
except Exception:
    print("<unparseable>"); raise SystemExit
try:
    print(eval(sys.argv[2], {"d": d}))
except Exception as e:
    print("<%s>" % e)
PY
}
# reason <prompt> <expected-reason>  -- asserts the reason is present and untrusted
reason() {
  local out; out="$(route "$1")"
  [ "$(field "$out" 'd["trusted"]')" = "False" ] \
    && ok "$3: untrusted" || bad "$3: reported trusted -- $out"
  case "$(field "$out" '",".join(d["reasons"])')" in
    *"$2"*) ok "$3: reason \`$2\`";;
    *) bad "$3: expected \`$2\`, got $(field "$out" '",".join(d["reasons"])')";;
  esac
}

cfg ''
echo "THE FIVE UNTRUSTWORTHY CONDITIONS -- one test apiece:"
reason 'สวัสดี'                  no_match          "1. nothing matched"
reason 'clink'                   multiple_matches  "2. more than one match"
reason 'design กับ clink'        two_families      "3. matches across two families"
reason 'afk'                     weak_trigger      "4. a match on a bare generic word"
# `ship` and not `merge`: `merge` is already a Thai trigger of t4-dev-workflow, so
# the table catches it and there is no mismatch left to detect.
reason 't4-afk ship it'          phase_mismatch    "5. a phase word implying another route"

echo ""
echo "AND THE CONTROL -- a confident single match on a strong term does NOT trigger it:"
out="$(route 't4-afk')"
[ "$(field "$out" 'd["trusted"]')" = "True" ] && ok "\`t4-afk\` alone is trusted" \
  || bad "a strong single match was called untrustworthy: $out"
[ "$(field "$out" 'd["table"]')" = "['t4-afk']" ] && ok "and it routes to exactly that skill" \
  || bad "table was $(field "$out" 'd["table"]')"
# Without this the five conditions above are satisfied by a router that distrusts
# everything, which is a constant and answers nothing.
[ "$(field "$out" 'd["consulted"]')" = "False" ] && ok "a trusted answer costs no classifier call" \
  || bad "the classifier was consulted on a trusted answer"

echo ""
echo "THE UNION -- both answers named, neither suppressed:"
cfg "$(stub '{"skills":["t4-bro"]}')"
out="$(route 'clink' --with-classifier)"
[ "$(field "$out" 'd["consulted"]')" = "True" ] && ok "an untrusted answer consults the classifier" \
  || bad "it was not consulted: $out"
case "$(field "$out" '",".join(d["table"])')"      in *clink*) ok "the table's answer survives";; *) bad "table lost";; esac
case "$(field "$out" '",".join(d["classifier"])')" in *t4-bro*) ok "the classifier's answer survives";; *) bad "classifier lost";; esac
case "$(field "$out" '",".join(d["routed"])')"     in *t4-bro*) ok "and routed is the union of the two";; *) bad "routed dropped one side";; esac

echo ""
echo "AGREEMENT emits one, DISAGREEMENT emits both:"
cfg "$(stub '{"skills":["t4-afk"]}')"
out="$(route 'afk' --with-classifier)"     # weak_trigger, and both say t4-afk
[ "$(field "$out" 'len(d["routed"])')" = "1" ] && ok "agreement collapses to one entry" \
  || bad "agreement produced $(field "$out" 'd["routed"]')"

# THE TABLE IS WRONG HERE ON PURPOSE. `dev` is a trigger of t4-dev-workflow, so a
# prompt about a dev SERVER matches it -- a real wrong answer from a real trigger,
# not an invented one. The classifier says otherwise and both are reported.
cfg "$(stub '{"skills":["t4-bro"]}')"
out="$(route 'the dev server is down' --with-classifier)"
[ "$(field "$out" 'd["table"]')" = "['t4-dev-workflow']" ] \
  && ok "the table matches wrongly on the generic word \`dev\`" \
  || bad "the fixture no longer reproduces the wrong match: $(field "$out" 'd["table"]')"
[ "$(field "$out" 'd["classifier"]')" = "['t4-bro']" ] && ok "the classifier disagrees" || bad "no disagreement"
[ "$(field "$out" 'sorted(d["routed"])')" = "['t4-bro', 't4-dev-workflow']" ] \
  && ok "and BOTH appear -- suppressing one to look decisive is how a routing bug goes invisible" \
  || bad "routed was $(field "$out" 'd["routed"]')"

echo ""
echo "#187's re-cut holds -- the classifier is opt-in, and the HOOK does not opt in:"
cfg "$(stub '{"skills":["t4-bro"]}')"
out="$(route 'clink')"
[ "$(field "$out" 'd["consulted"]')" = "False" ] \
  && ok "no --with-classifier: not consulted even when untrusted" || bad "it ran unasked: $out"
# Anchored to an INVOCATION carrying the flag, not to the string. A bare grep for
# `--with-classifier` matched the comment in that file explaining that it is not
# passed -- the trap the anchor audit records: a corrected document quotes the thing
# it rejects, so an assertion aimed at the mention fires on the correction.
grep -qE 't4-route[^|]*--with-classifier' "$REPO_ROOT/hooks/t4-prompt-reminder" \
  && bad "the gap notice passes --with-classifier, putting a model call inside a hook" \
  || ok "the gap notice does not pass it"
grep -q 't4-route' "$REPO_ROOT/hooks/t4-prompt-reminder" \
  && ok "and it does call the router, so there is one matching implementation" \
  || bad "the gap notice kept its own copy of the matching logic"

echo ""
echo "guards -- it fails to silence, never to a crash:"
PLAIN="$TMP/plain"; mkdir -p "$PLAIN/.claude/hooks"
cp "$REPO_ROOT/hooks/t4-route" "$PLAIN/.claude/hooks/" 2>/dev/null
out="$( (cd "$PLAIN" && printf 'x' | bash .claude/hooks/t4-route 2>&1) )"; rc=$?
{ [ "$rc" -eq 0 ] && [ -z "$out" ]; } && ok "no marker file: silent, exit zero" || bad "rc=$rc out=$out"
cfg ''
out="$(route '')"; rc=$?
[ "$rc" -eq 0 ] && ok "an empty prompt: exit zero" || bad "an empty prompt: exit $rc"

echo ""
echo "route: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

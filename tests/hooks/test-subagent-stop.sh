#!/usr/bin/env bash
# Release on stop_hook_active, and count the correction where the flag flips (#225).
#
# A blocking hook at this boundary without a release condition does not degrade --
# it destroys the turn and bills for it. The related runaway was measured at 168
# extra turns to timeout. No issue in either tracker mentioned the flag before this.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude/hooks"
printf '{"t4":true}\n' > "$REPO/.claude/t4.json"
for f in t4-review-state t4-subagent-stop; do cp "$REPO_ROOT/hooks/$f" "$REPO/.claude/hooks/$f"; done
HOOK="$REPO/.claude/hooks/t4-subagent-stop"
ST="$REPO/.claude/t4-review-state.json"

state() { (cd "$REPO" && printf '%s' "$1" | bash .claude/hooks/t4-review-state >/dev/null 2>&1); }
fire()  { (cd "$REPO" && printf '{"hook_event_name":"SubagentStop"%s}' "$1" | bash "$HOOK" 2>&1); }
corr()  { python - "$ST" <<'PY'
import json,sys,os
p=sys.argv[1]
if not os.path.exists(p): print("nofile"); raise SystemExit
s=json.load(open(p,encoding='utf-8'))
f=s.get("findings",[])
print(f[0].get("corrections",0) if f else "nofinding")
PY
}

# One open finding to count against.
state '{"op":"open","rule":"tdd","record":1,"uuid":"u1"}'
state '{"op":"violate","rule":"tdd"}'
[ "$(corr)" = "0" ] && ok "a fresh finding starts at zero corrections" || bad "unexpected start: $(corr)"

echo ""
echo "the flag releases, and an absent flag means NOT yet blocked:"
fire ',"stop_hook_active":true' >/dev/null
[ "$(corr)" = "0" ] && ok "stop_hook_active true releases without counting" || bad "it counted on a release: $(corr)"
fire '' >/dev/null
[ "$(corr)" = "1" ] && ok "an absent flag counts once -- treated as not yet blocked" || bad "absent flag gave $(corr)"

echo ""
echo "the counter increments per flag TRANSITION, not per invocation:"
fire ',"stop_hook_active":true' >/dev/null
fire ',"stop_hook_active":true' >/dev/null
fire ',"stop_hook_active":true' >/dev/null
[ "$(corr)" = "1" ] && ok "three releases in a row add nothing" || bad "releases incremented the counter: $(corr)"
fire ',"stop_hook_active":false' >/dev/null
[ "$(corr)" = "2" ] && ok "a genuine second objection counts" || bad "second objection gave $(corr)"

echo ""
echo "a run that would previously loop terminates, with a bounded turn count:"
turns=0
for i in 1 2 3 4 5 6 7 8 9 10; do
  out="$(fire ',"stop_hook_active":true')"
  turns=$((turns+1))
  [ -n "$out" ] && break     # any output here is a block, i.e. the loop continuing
done
[ "$turns" -eq 10 ] && ok "ten consecutive releases produced no block (bounded, no runaway)" \
                    || bad "a block appeared on turn $turns: $out"

echo ""
echo "it never blocks the turn and never speaks:"
out="$(fire '')"
[ -z "$out" ] && ok "it emits nothing at all" || bad "it emitted: $out"

echo ""
echo "a dismissed finding is not counted against again:"
fid="$(python - "$ST" <<'PY'
import json,sys
print(json.load(open(sys.argv[1],encoding='utf-8'))["findings"][0]["finding"])
PY
)"
state "{\"op\":\"dismiss\",\"finding\":\"$fid\",\"reason\":\"handled\"}"
before="$(corr)"; fire '' >/dev/null
[ "$(corr)" = "$before" ] && ok "a dismissed finding stops accruing corrections" \
                          || bad "a dismissed finding still counted: $before -> $(corr)"

echo ""
echo "guards:"
PLAIN="$TMP/plain"; mkdir -p "$PLAIN"
out="$( (cd "$PLAIN" && printf '{}' | bash "$HOOK" 2>&1) )"; rc=$?
{ [ "$rc" -eq 0 ] && [ -z "$out" ]; } && ok "no marker file: silent, exit zero" || bad "rc=$rc out=$out"
out="$(fire ',"stop_hook_active":"not-a-bool"')"; rc=$?
[ "$rc" -eq 0 ] && ok "a malformed flag does not crash the boundary" || bad "rc=$rc"

echo ""
echo "subagent-stop: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

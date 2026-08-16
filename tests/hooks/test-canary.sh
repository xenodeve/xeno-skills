#!/usr/bin/env bash
# The liveness canary and its THIRD observation (#212, #227).
#
# The third is the one that matters: a hook firing and an evaluator running still
# prove nothing about the thing the layer exists to do. Everything between the
# evaluator and the master -- the spool, the state file, the delivery hook, the
# one-shot token -- can fail silently, and a detector that stops at "the hook
# fired" reports green through all of it.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-canary"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mk() { # -> a repo dir with the hooks it needs
  local d="$1"; mkdir -p "$d/.claude/hooks"
  printf '{"t4":true}\n' > "$d/.claude/t4.json"
  for f in t4-review-state t4-prompt-reminder t4-transcript-skills routing-table.json; do
    cp "$REPO_ROOT/hooks/$f" "$d/.claude/hooks/$f"
  done
  cp "$REPO_ROOT/hooks/t4-canary" "$d/.claude/hooks/t4-canary"
}

echo "all three observations hold in a healthy repo:"
GOOD="$TMP/good"; mk "$GOOD"
out="$(cd "$GOOD" && bash .claude/hooks/t4-canary 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "exit zero when the layer is live" || bad "exit $rc: $out"
case "$out" in *"state machine accepted"*) ok "observation 1: the layer can record";; *) bad "no observation 1: $out";; esac
case "$out" in *"delivery hook ran"*) ok "observation 2: the layer can speak";; *) bad "no observation 2";; esac
case "$out" in *"observed being consumed"*) ok "observation 3: delivered AND consumed";; *) bad "no observation 3";; esac

echo ""
echo "the synthetic is cleared, and can never be delivered as a real finding:"
python - "$GOOD/.claude/t4-review-state.json" <<'PY'
import json,sys,os
p=sys.argv[1]
if not os.path.exists(p): sys.exit(0)
s=json.load(open(p,encoding='utf-8'))
rows=[r for lst in ("active","pending","unknown") for r in s.get(lst,[])]
assert not any("__t4_canary__" == r.get("rule") for r in rows), "the synthetic row survived"
assert not any("__t4_canary__" == f.get("rule") for f in s.get("findings",[])), \
    "the synthetic became a finding"
PY
[ $? -eq 0 ] && ok "no synthetic row and no synthetic finding remain" || bad "the synthetic leaked"
grep -q "reserved rule name\|__t4_canary__" "$HOOK" && ok "it uses a reserved rule name" || bad "no reserved name"

echo ""
echo "a broken layer is DETECTED -- the check is made dirty on purpose:"
BROKEN="$TMP/broken"; mk "$BROKEN"
rm -f "$BROKEN/.claude/hooks/t4-prompt-reminder"      # kill the delivery half
out="$(cd "$BROKEN" && bash .claude/hooks/t4-canary 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "a dead delivery hook makes the canary red" || bad "the canary stayed green on a dead hook"
case "$out" in *"FAIL"*) ok "and it names which observation failed";; *) bad "no failing observation named";; esac

echo ""
echo "a failing host is disabled, without retry and without blocking:"
[ -f "$BROKEN/.claude/t4-canary-disabled" ] && ok "the disable marker is written" || bad "no disable marker"
case "$out" in *"no retry, no block"*) ok "and it says so, where someone debugging will read it";; *) bad "the no-retry property is not stated";; esac
grep -q "sleep" "$HOOK" && bad "the canary sleeps -- that is the delay it must not add" || ok "it never sleeps"

echo ""
echo "the marker is cleared when the layer comes back:"
cp "$REPO_ROOT/hooks/t4-prompt-reminder" "$BROKEN/.claude/hooks/t4-prompt-reminder"
(cd "$BROKEN" && bash .claude/hooks/t4-canary >/dev/null 2>&1)
[ ! -f "$BROKEN/.claude/t4-canary-disabled" ] && ok "a repaired layer clears the marker" \
                                              || bad "the marker survived a repair"

echo ""
echo "a non-T4 repo is a no-op, not a failure:"
PLAIN="$TMP/plain"; mkdir -p "$PLAIN"
out="$(cd "$PLAIN" && bash "$HOOK" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "exit zero outside a T4 repo" || bad "exit $rc outside a T4 repo"

echo ""
echo "canary: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# The turn-end event, wired in all three settings copies with a script that does
# nothing yet (#185). The parity suite compares plugin against bootstrap only, so
# the repo's own .claude/settings.json needs its own assertion or it drifts
# silently — which is the failure this repo has already recorded twice.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

EVENT="Stop"
SCRIPT="t4-turn-end"

echo "the event is wired in all three copies:"
for rel in "hooks/hooks.json" \
           ".claude/settings.json" \
           "skills/t4/t4-project-bootstrap/references/hooks/settings.json"; do
  if python - "$REPO_ROOT/$rel" "$EVENT" "$SCRIPT" <<'PY'
import json, sys, re
path, event, script = sys.argv[1], sys.argv[2], sys.argv[3]
hooks = json.load(open(path, encoding="utf-8"))["hooks"]
groups = hooks.get(event)
if not groups:
    sys.exit(1)
for g in groups:
    for h in g["hooks"]:
        if re.search(r'run-hook\.cmd"?\s+' + re.escape(script) + r'\b', h["command"]):
            sys.exit(0)
sys.exit(1)
PY
  then ok "$rel wires $EVENT -> $SCRIPT"
  else bad "$rel does NOT wire $EVENT -> $SCRIPT"; fi
done

echo ""
echo "the script exists and does nothing yet:"
HOOK="$REPO_ROOT/hooks/$SCRIPT"
if [ -f "$HOOK" ]; then ok "hooks/$SCRIPT exists"; else bad "hooks/$SCRIPT is missing"; fi

if [ -f "$HOOK" ]; then
  out="$(echo '{}' | bash "$HOOK" 2>&1)"; rc=$?
  [ "$rc" -eq 0 ] && ok "it exits zero" || bad "it exited $rc"
  [ -z "$out" ] && ok "it emits nothing" || bad "it emitted: $out"
else
  bad "cannot run hooks/$SCRIPT — missing"
  bad "cannot check its output — missing"
fi

echo ""
echo "turn-end-wiring: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

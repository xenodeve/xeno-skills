#!/usr/bin/env bash
# Wiring tests for the plugin manifests + hook dispatch.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

echo "Test 1: manifests are valid JSON"
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json; do
  if python -c "import json,sys; json.load(open(sys.argv[1]))" "$REPO_ROOT/$f" 2>/dev/null; then
    ok "$f parses"
  else
    bad "$f invalid JSON"
  fi
done

echo "Test 2: every hook command references an existing script"
if python - "$REPO_ROOT" <<'PY'
import json, sys, os, re
root = sys.argv[1]
h = json.load(open(os.path.join(root, "hooks", "hooks.json")))
names = set()
for _ev, arr in h["hooks"].items():
    for group in arr:
        for hook in group["hooks"]:
            m = re.search(r'run-hook\.cmd"?\s+(\S+)', hook["command"])
            if m:
                names.add(m.group(1))
missing = [n for n in names if not os.path.isfile(os.path.join(root, "hooks", n))]
sys.exit(1 if (missing or not names) else 0)
PY
then ok "all referenced scripts exist"; else bad "some referenced scripts missing"; fi

echo "Test 3: run-hook.cmd dispatches to the named script (Unix path)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/repo/.claude"; printf '{"t4":true}\n' > "$TMP/repo/.claude/t4.json"
out="$( cd "$TMP/repo" \
  && printf '{"session_id":"p1"}' \
  | CLAUDE_PLUGIN_ROOT="$REPO_ROOT" T4_HOOK_LOCK_DIR="$TMP/locks" \
    bash "$REPO_ROOT/hooks/run-hook.cmd" t4-session-start )"
case "$out" in
  *'"additionalContext"'*) ok "wrapper ran t4-session-start and it injected";;
  *) bad "wrapper did not dispatch (got: ${out:0:40})";;
esac

echo ""
echo "plugin: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

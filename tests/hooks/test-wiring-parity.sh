#!/usr/bin/env bash
# The plugin (hooks/hooks.json) and the bootstrap (references/hooks/settings.json)
# register the SAME three hooks; only the base-dir variable differs
# (${CLAUDE_PLUGIN_ROOT} vs ${CLAUDE_PROJECT_DIR}/.claude). The scripts are
# cmp-guarded by test-bootstrap-sync; this guards the wiring that invokes them,
# so a matcher/event/script change can't silently land in only one.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

if python - "$REPO_ROOT" <<'PY'
import json, sys, os, re
root = sys.argv[1]

def norm(path):
    """event -> sorted [(matcher, (script names...))], ignoring the base-dir prefix."""
    hooks = json.load(open(path))["hooks"]
    out = {}
    for ev, groups in hooks.items():
        items = []
        for g in groups:
            scripts = []
            for h in g["hooks"]:
                m = re.search(r'run-hook\.cmd"?\s+(\S+)', h["command"])
                scripts.append(m.group(1) if m else h["command"])
            items.append((g.get("matcher", ""), tuple(scripts)))
        out[ev] = sorted(items)
    return out

plugin    = norm(os.path.join(root, "hooks", "hooks.json"))
bootstrap = norm(os.path.join(root, "skills", "t4", "t4-project-bootstrap",
                               "references", "hooks", "settings.json"))
if plugin == bootstrap:
    sys.exit(0)
print("  PLUGIN   :", plugin)
print("  BOOTSTRAP:", bootstrap)
sys.exit(1)
PY
then ok "plugin hooks.json and bootstrap settings.json register the same hooks"
else bad "plugin/bootstrap hook wiring has DRIFTED"; fi

echo ""
echo "wiring-parity: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# The config generator with per-host allowlists and a byte readback (#226).
#
# Hand-writing a hook config is a documented silent-failure path: a BOM makes
# cursor load the file as nothing, an unknown handler type or event key voids the
# WHOLE file on cursor, and on codex an unknown event key is ignored with no
# diagnostic that --strict-config catches. The generator refuses those here, where
# the refusal is visible, instead of at the client, where it is silent.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN="$REPO_ROOT/scripts/generate-hook-config.py"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
gen() { python "$GEN" "$@" 2>&1; }

echo "each host gets its own shape, and the shapes genuinely differ:"
gen claude "$TMP/claude.json" --hook 'Stop=/x/t4-turn-end' >/dev/null
python - "$TMP/claude.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
assert "hooks" in d and "Stop" in d["hooks"], d
assert d["hooks"]["Stop"][0]["hooks"][0]["type"] == "command"
PY
[ $? -eq 0 ] && ok "claude: nested under hooks, grouped matcher + hooks" || bad "claude shape wrong"

gen codex "$TMP/codex.json" --hook 'Stop=C:\x\t4-turn-end' >/dev/null
python - "$TMP/codex.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
h=d["hooks"][0]
assert "commandWindows" in h, "codex needs commandWindows on Windows"
assert "\\" not in h["commandWindows"], "commandWindows must use forward slashes"
PY
[ $? -eq 0 ] && ok "codex: a hooks array with commandWindows, forward slashes only" || bad "codex shape wrong"

gen cursor "$TMP/cursor.json" --hook 'beforeShellExecution=/x/gate' >/dev/null
python - "$TMP/cursor.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
assert d.get("version") == 1, "cursor needs a version key"
assert isinstance(d["hooks"]["beforeShellExecution"], list)
PY
[ $? -eq 0 ] && ok "cursor: flat entries under a version key" || bad "cursor shape wrong"

echo ""
echo "agy: grouped for tool events, FLAT for the rest -- the trap that cost the most time:"
gen agy "$TMP/agy.json" --hook 'PreToolUse=/x/gate' --hook 'Stop=/x/stop' >/dev/null
python - "$TMP/agy.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
assert "hooks" not in d, "agy's top-level key is a HOOK NAME, not the literal 'hooks'"
assert "t4" in d, d.keys()
pre = d["t4"]["PreToolUse"][0]
assert "matcher" in pre and "hooks" in pre, "a tool event must be GROUPED, or agy drops it silently"
stop = d["t4"]["Stop"][0]
assert "matcher" not in stop and stop.get("type") == "command", "a non-tool event must be FLAT"
PY
[ $? -eq 0 ] && ok "agy: grouped tool event, flat Stop, top-level key is a hook name" || bad "agy shape wrong"

echo ""
echo "the allowlist refuses here, where the refusal is visible:"
out="$(gen claude "$TMP/bad.json" --hook 'NotAnEvent=/x/s')"; rc=$?
[ "$rc" -ne 0 ] && ok "an event outside the allowlist is refused" || bad "an unknown event was written"
case "$out" in *"allowlist"*) ok "and the message says why";; *) bad "unhelpful message: $out";; esac
[ ! -f "$TMP/bad.json" ] && ok "and nothing was written" || bad "a file was written for a refused config"

out="$(gen codex "$TMP/bad2.json" --hook 'PostToolBatch=/x/s')"; rc=$?
[ "$rc" -ne 0 ] && ok "an event valid on ANOTHER host is still refused on codex" \
                || bad "codex accepted a Claude-only event"

echo ""
echo "every write reads its own bytes back:"
grep -q "read(" "$GEN" && ok "the generator reads the file back" || bad "no readback in the generator"
python - "$TMP/cursor.json" <<'PY'
import sys
b=open(sys.argv[1],'rb').read()
assert not b.startswith(b'\xef\xbb\xbf'), "the written file starts with a BOM"
PY
[ $? -eq 0 ] && ok "no BOM on disk -- cursor would load a BOM file as nothing" || bad "a BOM was written"

echo ""
echo "POSITIVE CONTROL -- the BOM refusal detects anything at all:"
python - <<'PY'
import sys, importlib.util, os
spec = importlib.util.spec_from_file_location("g", os.path.join(os.getcwd(), "scripts/generate-hook-config.py"))
g = importlib.util.module_from_spec(spec); spec.loader.exec_module(g)
import json, tempfile
# Force a BOM through the same door a real mistake would come through.
orig = json.dumps
json.dumps = lambda *a, **k: "\ufeff" + orig(*a, **k)
try:
    g.write_and_verify(os.path.join(tempfile.mkdtemp(), "x.json"), {"hooks": {}})
except ValueError as e:
    print("REFUSED:", e); sys.exit(0)
finally:
    json.dumps = orig
sys.exit(1)
PY
[ $? -eq 0 ] && ok "a BOM is refused when one is actually present" \
             || bad "the BOM check passed a file that HAS a BOM -- it detects nothing"

echo ""
echo "hook-config-generator: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

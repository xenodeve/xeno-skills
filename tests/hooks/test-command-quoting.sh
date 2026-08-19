#!/usr/bin/env bash
# An unquoted path containing a space makes a hook never run, and nothing anywhere
# says so -- no session error, no transcript record, nothing from `claude doctor`
# (#207). This repository is safe by accident: its own wiring quotes everything.
# `t4-project-bootstrap` writes wiring into OTHER repositories, where a path with a
# space is the normal case on Windows -- C:\Program Files, or a user directory with
# a space in the name. A repo wired that way has no gate at all and no way to tell.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

# Exit 0 when every space-containing path in every wired command is quoted.
check() {
  python - "$1" <<'PY'
import json, sys, re
path = sys.argv[1]
bad = []
hooks = json.load(open(path, encoding="utf-8")).get("hooks", {})
for event, groups in hooks.items():
    for g in groups:
        for h in g.get("hooks", []):
            cmd = h.get("command", "")
            # Remove every double-quoted span; whatever is left was unquoted.
            rest = re.sub(r'"[^"]*"', "", cmd)
            if ("/" in rest or "\\" in rest) and " " in rest.strip():
                bad.append((event, cmd))
for event, cmd in bad:
    print("    unquoted path with a space in %s: %s" % (event, cmd))
sys.exit(1 if bad else 0)
PY
}

echo "every wired command quotes its paths:"
for rel in "hooks/hooks.json" \
           ".claude/settings.json" \
           "skills/t4/t4-project-bootstrap/references/hooks/settings.json"; do
  if check "$REPO_ROOT/$rel"; then ok "$rel"; else bad "$rel has an unquoted path with a space"; fi
done

echo ""
echo "positive control -- the check detects anything at all:"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/dirty.json" <<'JSON'
{"hooks":{"Stop":[{"matcher":"","hooks":[{"type":"command",
 "command":"C:/Program Files/Git/bin/bash.exe /path/to/hook.sh"}]}]}}
JSON
if check "$tmp/dirty.json" >/dev/null 2>&1; then
  bad "a deliberately unquoted command PASSED -- the check detects nothing"
else
  ok "a deliberately unquoted command fails the check"
fi

cat > "$tmp/clean.json" <<'JSON'
{"hooks":{"Stop":[{"matcher":"","hooks":[{"type":"command",
 "command":"\"C:/Program Files/Git/bin/bash.exe\" \"/path/to/hook.sh\""}]}]}}
JSON
if check "$tmp/clean.json" >/dev/null 2>&1; then
  ok "the same command, quoted, passes -- the check is not just always-red"
else
  bad "a correctly quoted command FAILED -- the check is over-broad"
fi

echo ""
echo "command-quoting: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

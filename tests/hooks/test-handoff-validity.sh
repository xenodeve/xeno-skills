#!/usr/bin/env bash
# Behavioural contract for the handoff validator (#306).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT/hooks/t4-handoff-validity"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
SESSION="session-306"
HANDOFF="$REPO/.claude/t4-handoff/$SESSION.md"
TRANSCRIPT="$TMP/transcript.jsonl"
mkdir -p "$(dirname "$HANDOFF")" "$REPO/docs/thinking"
: > "$REPO/docs/thinking/README.md"

write_valid_handoff() {
cat > "$HANDOFF" <<'EOF'
# Handoff

Session: session-306

## Status
The implementation is in progress.

## Next
Run the focused contract test.
EOF
}

write_valid_handoff

cat > "$TRANSCRIPT" <<'EOF'
{"type":"assistant","timestamp":"2026-08-21T11:59:00Z","sessionId":"session-306"}
{"type":"compact_boundary","timestamp":"2026-08-21T12:00:00Z","sessionId":"session-306"}
EOF

set_mtime() {
  python - "$1" "$2" <<'PY'
import os
import sys
from datetime import datetime, timezone

path, value = sys.argv[1:]
stamp = datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
os.utime(path, (stamp, stamp))
PY
}

pass=0
fail=0
ok() { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

set_mtime "$HANDOFF" "2026-08-21T12:01:00Z"
out="$(bash "$HOOK" "$REPO" "$SESSION" "$TRANSCRIPT" 2>&1)"
rc=$?
if [ "$rc" -eq 0 ] && [[ "$out" == valid* ]]; then
  ok "a handoff newer than the last boundary is valid"
else
  bad "fresh handoff rejected: exit $rc [$out]"
fi

set_mtime "$HANDOFF" "2026-08-21T11:59:00Z"
out="$(bash "$HOOK" "$REPO" "$SESSION" "$TRANSCRIPT" 2>&1)"
rc=$?
if [ "$rc" -ne 0 ] && [[ "$out" == *"stale"* ]]; then
  ok "a handoff older than the last boundary is rejected as stale"
else
  bad "stale handoff accepted or misreported: exit $rc [$out]"
fi

write_valid_handoff
set_mtime "$HANDOFF" "2026-08-21T12:01:00Z"
rm "$HANDOFF"
out="$(bash "$HOOK" "$REPO" "$SESSION" "$TRANSCRIPT" 2>&1)"
rc=$?
if [ "$rc" -ne 0 ] && [[ "$out" == *"session-keyed path"* ]]; then
  ok "a handoff at another path is not consulted"
else
  bad "non-session-keyed handoff accepted: exit $rc [$out]"
fi

write_valid_handoff
set_mtime "$HANDOFF" "2026-08-21T12:01:00Z"
sed -i '/^## Next$/d' "$HANDOFF"
out="$(bash "$HOOK" "$REPO" "$SESSION" "$TRANSCRIPT" 2>&1)"
rc=$?
if [ "$rc" -ne 0 ] && [[ "$out" == *"required section"* ]]; then
  ok "a handoff missing a restore section is rejected"
else
  bad "incomplete handoff accepted: exit $rc [$out]"
fi

: > "$HANDOFF"
set_mtime "$HANDOFF" "2026-08-21T12:01:00Z"
out="$(bash "$HOOK" "$REPO" "$SESSION" "$TRANSCRIPT" 2>&1)"
rc=$?
if [ "$rc" -ne 0 ] && [[ "$out" == *"is empty"* ]]; then
  ok "an empty handoff is rejected"
else
  bad "empty handoff accepted: exit $rc [$out]"
fi

write_valid_handoff
set_mtime "$HANDOFF" "2026-08-21T12:01:00Z"
sed -i 's/^Session: session-306$/Session: another-session/' "$HANDOFF"
out="$(bash "$HOOK" "$REPO" "$SESSION" "$TRANSCRIPT" 2>&1)"
rc=$?
if [ "$rc" -ne 0 ] && [[ "$out" == *"not written by session"* ]]; then
  ok "a handoff owned by another session is rejected"
else
  bad "foreign handoff accepted: exit $rc [$out]"
fi

write_valid_handoff
set_mtime "$HANDOFF" "2026-08-21T12:01:00Z"
printf '# Decision\n' > "$REPO/docs/thinking/001-clean.md"
printf '%s\n' '- [Decision](001-clean.md)' > "$REPO/docs/thinking/README.md"
out="$(bash "$HOOK" "$REPO" "$SESSION" "$TRANSCRIPT" 2>&1)"
rc=$?
if [ "$rc" -eq 0 ] && [[ "$out" == valid* ]]; then
  ok "an indexed record and its file are a clean bijection"
else
  bad "clean thinking-record index rejected: exit $rc [$out]"
fi

printf '# Orphan\n' > "$REPO/docs/thinking/002-orphan.md"
out="$(bash "$HOOK" "$REPO" "$SESSION" "$TRANSCRIPT" 2>&1)"
rc=$?
if [ "$rc" -ne 0 ] && [[ "$out" == *"not indexed"* ]]; then
  ok "an orphan thinking-record file is rejected"
else
  bad "orphan thinking-record file accepted: exit $rc [$out]"
fi

rm "$REPO/docs/thinking/002-orphan.md"
printf '%s\n' '- [Missing](002-missing.md)' >> "$REPO/docs/thinking/README.md"
out="$(bash "$HOOK" "$REPO" "$SESSION" "$TRANSCRIPT" 2>&1)"
rc=$?
if [ "$rc" -ne 0 ] && [[ "$out" == *"no file"* ]]; then
  ok "an orphan thinking-record index entry is rejected"
else
  bad "orphan thinking-record index entry accepted: exit $rc [$out]"
fi

echo ""
echo "handoff-validity: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

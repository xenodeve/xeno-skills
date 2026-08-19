#!/usr/bin/env bash
# The bootstrap (path A) ships its own copies of the hook scripts so a repo
# installed via `npx skills` (no root hooks/) is still self-contained. Those
# copies must stay byte-identical to the plugin's (path B) canonical scripts.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$REPO_ROOT/hooks"
DST="$REPO_ROOT/skills/t4/t4-project-bootstrap/references/hooks"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

# The list is DERIVED, not maintained: every shippable file under hooks/ must have
# a bootstrap copy. A hand-kept list silently stops covering the next script added,
# which is exactly what happened when t4-turn-end, t4-review-state and
# t4-transcript-skills were added and this suite kept passing without them.
for f in $(cd "$SRC" && ls | grep -v '^hooks\.json$'); do
  if [ ! -f "$DST/$f" ]; then
    bad "$f: missing in bootstrap references/hooks/"
  elif cmp -s "$SRC/$f" "$DST/$f"; then
    ok "$f: in sync with plugin hooks/"
  else
    bad "$f: DRIFTED from plugin hooks/ (re-copy from $SRC/$f)"
  fi
done

echo ""
echo "bootstrap-sync: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# The segment the reviewer reads (#197): stop to stop, hook-written records removed,
# and nothing at all when the turn used no tools.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-segment"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

stop()      { printf '{"type":"stop"}\n'; }
notif()     { printf '{"type":"user","message":{"content":"<task-notification>done</task-notification>"}}\n'; }
tooluse()   { printf '{"type":"assistant","tag":"%s","message":{"content":[{"type":"tool_use","name":"Bash","input":{}}]}}\n' "$1"; }
plaintext() { printf '{"type":"assistant","tag":"%s","message":{"content":[{"type":"text","text":"just talking"}]}}\n' "$1"; }
reminder()  { printf '{"type":"user","message":{"content":"T4: this prompt routes to `t4-bro`, and this session has not invoked it."}}\n'; }
sysrem()    { printf '{"type":"user","message":{"content":[{"type":"text","text":"<system-reminder>x</system-reminder>"}]}}\n'; }
attach()    { printf '{"type":"attachment","message":{"content":[{"type":"text","text":"noise"}]}}\n'; }

run() { bash "$HOOK" "$1" 2>/dev/null; }
tags() { run "$1" | python -c "
import sys,json
print(' '.join(json.loads(l).get('tag','?') for l in sys.stdin if l.strip()))"; }

echo "a segment runs stop to stop:"
F="$TMP/a.jsonl"; { tooluse old; stop; tooluse new1; tooluse new2; } > "$F"
got="$(tags "$F")"
case "$got" in *"new1"*) ok "records after the last stop are included";; *) bad "missing new1: [$got]";; esac
case "$got" in *"old"*) bad "a record from the previous segment leaked in";; *) ok "the previous segment is excluded";; esac

echo ""
echo "a turn opened by a task notification still forms a segment:"
F="$TMP/n.jsonl"; { stop; notif; tooluse fromtask; } > "$F"
got="$(tags "$F")"
case "$got" in *"fromtask"*) ok "a notification-opened turn is a segment";; *) bad "the turn was dropped: [$got]";; esac

echo ""
echo "hook-written and injected records are filtered out:"
F="$TMP/h.jsonl"; { stop; reminder; sysrem; attach; tooluse real; } > "$F"
out="$(run "$F")"
case "$out" in *"routes to"*) bad "a previous notice survived into the segment";; *) ok "a previous T4 notice is removed";; esac
case "$out" in *"system-reminder"*) bad "an injected system reminder survived";; *) ok "an injected system reminder is removed";; esac
case "$out" in *"attachment"*) bad "an attachment record survived";; *) ok "attachment records are removed";; esac
case "$out" in *"real"*) ok "and the real work is kept";; *) bad "the real record was filtered too";; esac

echo ""
echo "a fixture containing a previous FINDING produces nothing derived from it:"
F="$TMP/f.jsonl"; { stop; reminder; plaintext idle; } > "$F"
out="$(run "$F")"
[ -z "$out" ] && ok "a segment of only a previous finding yields no segment at all" \
              || bad "a previous finding became reviewable input: ${out:0:60}"

echo ""
echo "a segment with no tool use is skipped before anything spawns:"
F="$TMP/i.jsonl"; { stop; plaintext chatty; } > "$F"
[ -z "$(run "$F")" ] && ok "an idle turn costs nothing" || bad "an idle turn produced a segment"

echo ""
echo "it is a pure function: same input, same output, no side effects:"
F="$TMP/a.jsonl"
[ "$(run "$F")" = "$(run "$F")" ] && ok "two runs agree" || bad "two runs disagree"
before="$(cd "$TMP" && ls | sort | tr '\n' ' ')"
run "$F" >/dev/null
after="$(cd "$TMP" && ls | sort | tr '\n' ' ')"
[ "$before" = "$after" ] && ok "it writes nothing" || bad "it created or removed files"

echo ""
echo "it fails to empty, never to a crash:"
for t in "$TMP/missing.jsonl" "$TMP/empty.jsonl" "$TMP/garbage.jsonl"; do
  case "$t" in *empty*) : > "$t";; *garbage*) printf 'not json{\n[]\n' > "$t";; esac
  bash "$HOOK" "$t" >/dev/null 2>&1
  [ $? -eq 0 ] && ok "$(basename "$t"): exit zero" || bad "$(basename "$t"): non-zero"
done
bash "$HOOK" >/dev/null 2>&1; [ $? -eq 0 ] && ok "no argument: exit zero" || bad "no argument: non-zero"

echo ""
echo "segment: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# Log every Skill invocation -- the denominator half (#145).
# A logger must never be why a turn fails: exit 0 on every path, nothing on stdout.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-skill-log"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude" "$REPO/Obsidian-probe"
printf '{"t4":true}\n' > "$REPO/.claude/t4.json"
LOG="$REPO/Obsidian-probe/skill-usage/.invocations.log"
fire() { (cd "$REPO" && printf '%s' "$1" | bash "$HOOK" 2>&1); rc=$?; return $rc; }

echo "it logs a Skill invocation, and only those:"
out="$(fire '{"tool_name":"Skill","session_id":"s1","tool_input":{"skill":"using-t4"}}')"
[ -z "$out" ] && ok "nothing on stdout" || bad "it spoke: $out"
[ -f "$LOG" ] && ok "the log is created" || bad "no log written"
grep -q "using-t4" "$LOG" 2>/dev/null && ok "the skill name is recorded" || bad "the skill name is missing"
grep -q "s1" "$LOG" 2>/dev/null && ok "the session id is recorded, so a rate has a denominator" || bad "no session id"
grep -qE "^[0-9]{4}-[0-9]{2}-[0-9]{2}T" "$LOG" 2>/dev/null && ok "an ISO timestamp leads the line" || bad "no timestamp"
[ "$(awk -F'\t' '{print NF}' "$LOG" | head -1)" = "3" ] && ok "three tab-separated fields" || bad "wrong field count"

fire '{"tool_name":"Bash","session_id":"s1","tool_input":{"command":"ls"}}' >/dev/null
[ "$(wc -l < "$LOG")" = "1" ] && ok "a non-Skill tool is not logged" || bad "it logged an unrelated tool"
fire '{"tool_name":"Skill","session_id":"s1","tool_input":{}}' >/dev/null
[ "$(wc -l < "$LOG")" = "1" ] && ok "a Skill call with no skill name is not logged" || bad "it logged an empty name"

echo ""
echo "it appends -- the denominator grows, it is not overwritten:"
fire '{"tool_name":"Skill","session_id":"s2","tool_input":{"skill":"t4-bro"}}' >/dev/null
[ "$(wc -l < "$LOG")" = "2" ] && ok "a second invocation appends" || bad "the log was truncated"
grep -q "using-t4" "$LOG" && ok "and the first line survives" || bad "the earlier record was lost"

echo ""
echo "it exits 0 on every path, including ones that cannot write:"
for case_name in "malformed payload" "no vault dir" "no marker"; do
  case "$case_name" in
    "malformed payload") d="$REPO"; p='not json{' ;;
    "no vault dir")      d="$TMP/novault"; mkdir -p "$d/.claude"; printf '{"t4":true}\n' > "$d/.claude/t4.json"; p='{"tool_name":"Skill","tool_input":{"skill":"x"}}' ;;
    "no marker")         d="$TMP/plain"; mkdir -p "$d"; p='{"tool_name":"Skill","tool_input":{"skill":"x"}}' ;;
  esac
  out="$( (cd "$d" && printf '%s' "$p" | bash "$HOOK" 2>&1) )"; rc=$?
  { [ "$rc" -eq 0 ] && [ -z "$out" ]; } && ok "$case_name: exit 0, silent" || bad "$case_name: rc=$rc out=$out"
done
[ ! -f "$TMP/novault/Obsidian-probe" ] && ok "with no vault it writes nothing rather than guessing a path" || bad "it invented a path"

echo ""
echo "the marker guard holds:"
[ ! -d "$TMP/plain/Obsidian-probe" ] && ok "no log outside a T4 repo" || bad "it logged without the marker"

echo ""
echo "both shipped copies are byte-identical and LF:"
for d in "$REPO_ROOT/skills/t4/t4-project-bootstrap/references/hooks" "$REPO_ROOT/.claude/hooks"; do
  cmp -s "$HOOK" "$d/t4-skill-log" && ok "$(basename "$(dirname "$d")")/$(basename "$d") in sync" \
                                   || bad "$d copy has drifted"
done
grep -q $'\r' "$HOOK" && bad "the source has CRLF" || ok "the source is LF"

echo ""
echo "skill-log: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

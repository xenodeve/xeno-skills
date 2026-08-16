#!/usr/bin/env bash
# Contract tests for hooks/t4-prompt-reminder — the GAP NOTICE (#186).
# Seam: stdin (UserPromptSubmit JSON) + cwd -> one notice, or empty.
#
# What changed and why: this hook used to emit the same four sentences every turn,
# persisted into one session's transcript 142 times. Constant text carries no new
# information after the first turn. It now speaks only when a routed skill is
# ABSENT, and what it says comes from what happened rather than what was claimed.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-prompt-reminder"

pass=0 fail=0
ok()   { echo "  PASS: $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL: $1"; fail=$((fail+1)); }
has()  { case "$1" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2, got: ${1:0:90})";; esac; }
hasnt(){ case "$1" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }
empty(){ if [ -z "$1" ]; then ok "$2"; else bad "$2 (got: ${1:0:70})"; fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude"; printf '{"t4":true}\n' > "$REPO/.claude/t4.json"
PLAIN="$TMP/plain"; mkdir -p "$PLAIN"

tooluse() { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"%s"}}]}}\n' "$1"; }
slash()   { printf '{"type":"user","message":{"content":"<command-name>/%s</command-name>"}}\n' "$1"; }

run() { # cwd, prompt, transcript-path
  ( cd "$1" && python -c "import json,sys; print(json.dumps({'session_id':'s1','hook_event_name':'UserPromptSubmit','prompt':sys.argv[1],'transcript_path':sys.argv[2]}))" "$2" "$3" \
      | bash "$HOOK" )
}

PROMPT='ช่วยเปิด issue ให้หน่อย'   # routes to t4-dev-workflow via a Thai trigger

echo "absent -> exactly one notice naming it:"
EMPTY_T="$TMP/none.jsonl"; : > "$EMPTY_T"
out="$(run "$REPO" "$PROMPT" "$EMPTY_T")"
has "$out" '"additionalContext"' "emits additionalContext"
has "$out" 't4-dev-workflow'     "names the routed skill that is absent"
[ "$(printf '%s' "$out" | grep -c additionalContext)" = "1" ] && ok "exactly one notice" || bad "more than one notice"

echo ""
echo "the wording reports an absence and does not assert loading:"
hasnt "$out" "you must"  "does not say 'you must'"
hasnt "$out" "will be loaded" "does not claim the skill will be loaded"
has   "$out" "has not invoked" "states what has not happened"

echo ""
echo "present as a tool-use record -> empty:"
T="$TMP/tool.jsonl"; tooluse t4-dev-workflow > "$T"
empty "$(run "$REPO" "$PROMPT" "$T")" "silent when the routed skill was invoked as a tool"

echo ""
echo "present only as a slash command -> also empty:"
T2="$TMP/slash.jsonl"; slash t4-dev-workflow > "$T2"
empty "$(run "$REPO" "$PROMPT" "$T2")" "silent when it was invoked as a slash command"

echo ""
echo "nothing routed -> the compact route list, and only then (#190):"
miss="$(run "$REPO" 'สวัสดี' "$EMPTY_T")"
has "$miss" 'nothing in the routing table matched' "an unmatched turn emits the route list"
has "$miss" 'ask-xeno'    "it names the family entries"
has "$miss" 'using-t4'    "including using-t4"
[ "$(printf '%s' "$miss" | grep -c additionalContext)" = "1" ] && ok "exactly once" || bad "emitted more than once"
hasnt "$out" 'nothing in the routing table matched' "a MATCHED turn does not emit the route list"

# The byte budget, asserted as a number rather than described. The cost argument is
# the whole reason this is paid on misses only: across a 55-turn session the old
# constant reminder cost about 57 KB; this pays only on the turns that miss.
bytes=$(printf '%s' "$miss" | wc -c)
BUDGET_BYTES=700
[ "$bytes" -le "$BUDGET_BYTES" ] && ok "the route list is ${bytes}B (budget ${BUDGET_BYTES}B)"                                  || bad "the route list is ${bytes}B, over the ${BUDGET_BYTES}B budget"
# Measured, not estimated: 55 turns all missing is the worst case for this design.
worst=$(( bytes * 55 ))
[ "$worst" -lt 58000 ] && ok "worst case 55 misses = ${worst}B, under the 57KB baseline it replaces"                        || bad "worst case ${worst}B exceeds the baseline it was meant to beat"

echo ""
echo "it fails to silence, never to a crash:"
empty "$(run "$PLAIN" "$PROMPT" "$EMPTY_T")" "no marker file: silent"
# A missing transcript must NOT hide a gap: nothing invoked is the honest reading,
# and silence there would turn an unreadable file into a clean bill of health.
out="$(run "$REPO" "$PROMPT" "$TMP/does-not-exist.jsonl")"
case "$out" in *"t4-dev-workflow"*) ok "a missing transcript reports the absence rather than hiding it";;
  *) bad "a missing transcript hid a real gap";; esac
T3="$TMP/garbage.jsonl"; printf 'not json{\n[]\n' > "$T3"
out="$(run "$REPO" "$PROMPT" "$T3")"; rc=$?
[ "$rc" -eq 0 ] && ok "unparseable transcript: exit zero" || bad "unparseable transcript: exit $rc"

echo ""
echo "a large transcript completes inside a stated budget:"
BIG="$TMP/big.jsonl"; : > "$BIG"
for i in $(seq 1 4000); do tooluse "filler-$i"; done >> "$BIG"
start=$(date +%s)
run "$REPO" "$PROMPT" "$BIG" >/dev/null
elapsed=$(( $(date +%s) - start ))
BUDGET=5
[ "$elapsed" -le "$BUDGET" ] && ok "4000 records in ${elapsed}s (budget ${BUDGET}s)" \
                             || bad "4000 records took ${elapsed}s, over the ${BUDGET}s budget"

echo ""
echo "prompt-reminder: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

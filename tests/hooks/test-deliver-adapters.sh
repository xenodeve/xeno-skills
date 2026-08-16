#!/usr/bin/env bash
# The four per-host delivery adapters (#228 Claude Code · #229 codex · #230 cursor
# · #231 agy).
#
# Of the 32 slices #177-#208, exactly one named a host other than Claude Code: they
# were cut from a single-harness architecture and the design moved to four the next
# day. These are the adapters that design assumes.
#
# WHAT THIS SUITE DOES AND DOES NOT PROVE. It drives the adapter and asserts the
# SHAPE each host expects. Only Claude Code can be exercised against a running host
# on this machine; the other three shapes come from the recorded live probes and are
# asserted against fixtures. That is [B], not [L], and the script says so too.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude/hooks"
printf '{"t4":true}\n' > "$REPO/.claude/t4.json"
mkdir -p "$REPO/docs/research"
cp "$REPO_ROOT/docs/research/rule-traces.md" "$REPO/docs/research/"
for f in t4-review-state t4-deliver; do cp "$REPO_ROOT/hooks/$f" "$REPO/.claude/hooks/$f"; done
st()   { (cd "$REPO" && printf '%s' "$1" | bash .claude/hooks/t4-review-state >/dev/null 2>&1); }
give() { (cd "$REPO" && printf '%s' "${2:-{\}}" | bash .claude/hooks/t4-deliver "$1" 2>/dev/null); }

echo "with nothing to say, every host stays silent:"
for h in claude-code codex cursor agy; do
  [ -z "$(give $h)" ] && ok "$h: silent when there is no finding" || bad "$h spoke with no finding"
done

# One open finding for the rest of the suite.
st '{"op":"open","rule":"tdd","record":1,"uuid":"u1"}'
st '{"op":"violate","rule":"tdd"}'

echo ""
echo "#228 Claude Code -- the batch event, with the documented one as fallback:"
out="$(give claude-code '{"hook_event_name":"PostToolBatch"}')"
case "$out" in *'"hookEventName":"PostToolBatch"'*) ok "it answers on the batch event";; *) bad "batch: $out";; esac
out="$(give claude-code '{"hook_event_name":"PostToolUse"}')"
case "$out" in *'"hookEventName":"PostToolUse"'*) ok "and on the documented per-call event alone";;
  *) bad "the fallback path is broken: $out";; esac
case "$out" in *additionalContext*) ok "delivering as additionalContext, not as a block";; *) bad "wrong channel";; esac
[ -z "$(give claude-code '{"hook_event_name":"Stop"}')" ] && ok "and says nothing on an event it does not own" \
                                                          || bad "it answered on Stop"

echo ""
echo "#229 codex -- block REPLACES the tool result, which is the stronger channel:"
out="$(give codex '{"hook_event_name":"PostToolUse"}')"
case "$out" in *'"decision":"block"'*) ok "a corrective finding blocks";; *) bad "no block: $out";; esac
case "$out" in *'"reason"'*) ok "and carries the reason that replaces the result";; *) bad "no reason";; esac
st '{"op":"open","rule":"simplify","record":2,"uuid":"u2"}'
st '{"op":"violate","rule":"simplify"}'
python - "$REPO/.claude/t4-review-state.json" <<'PY'
import json,sys
p=sys.argv[1]; s=json.load(open(p,encoding='utf-8'))
for f in s["findings"]: f["informational"]=True
json.dump(s, open(p,"w",encoding='utf-8'), indent=2)
PY
out="$(give codex '{"hook_event_name":"PostToolUse"}')"
case "$out" in *additionalContext*) ok "an informational finding appends instead, leaving the result alone";;
  *) bad "informational still blocked: $out";; esac

echo ""
echo "#230 cursor -- the gate IS the delivery channel; nothing waits for a turn end:"
out="$(give cursor '{"hook_event_name":"beforeShellExecution"}')"
case "$out" in *'"permission":"deny"'*) ok "it denies, which is how this host delivers mid-turn";; *) bad "no deny: $out";; esac
case "$out" in *agentMessage*) ok "and the reason reaches the agent";; *) bad "no agentMessage";; esac
grep -q "stop\` never fires" "$REPO_ROOT/hooks/t4-deliver" \
  && ok "and the script records that this host has no headless turn end" || bad "the constraint is not recorded"

echo ""
echo "#231 agy -- injectSteps, and the payload that is fatal is checked BEFORE emit:"
out="$(give agy '{"hook_event_name":"PreInvocation"}')"
case "$out" in *injectSteps*) ok "it injects";; *) bad "no injectSteps: $out";; esac
case "$out" in *userMessage*) ok "with the key the implementation actually accepts";; *) bad "wrong key";; esac
grep -q "TERMINATES THE RUN" "$REPO_ROOT/hooks/t4-deliver" \
  && ok "and the fatal-payload hazard is recorded where it is emitted" || bad "the hazard is not recorded";

echo ""
echo "no model call on any path, on any host:"
grep -qiE "anthropic|openai|\"prompt\"|type\": *\"prompt\"" "$REPO_ROOT/hooks/t4-deliver" \
  && bad "a model call leaked into a delivery adapter" || ok "none present"

echo ""
echo "guards:"
[ -z "$(give not-a-host '{}')" ] && ok "an unknown host gets no opinion" || bad "it answered for an unknown host"
PLAIN="$TMP/plain"; mkdir -p "$PLAIN/.claude/hooks"; cp "$REPO_ROOT/hooks/t4-deliver" "$PLAIN/.claude/hooks/"
out="$( (cd "$PLAIN" && printf '{}' | bash .claude/hooks/t4-deliver claude-code 2>&1) )"; rc=$?
{ [ "$rc" -eq 0 ] && [ -z "$out" ]; } && ok "no marker file: silent, exit zero" || bad "rc=$rc out=$out"

echo ""
echo "the evidence grade is stated, not implied:"
grep -q "Treat them as \[B\]" "$REPO_ROOT/hooks/t4-deliver" \
  && ok "three of four shapes are labelled [B], asserted against fixtures rather than a host" \
  || bad "the adapters claim more verification than they have"

echo ""
echo "deliver-adapters: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

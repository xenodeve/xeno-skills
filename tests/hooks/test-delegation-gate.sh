#!/usr/bin/env bash
# The delegation gate on all four spawn tool names, and the clink call (#232).
#
# One seam, four hosts. Every one exposes the spawn as an ordinary tool the
# pre-action hook sees WITH ITS ARGUMENTS before it runs, and #219 measured that the
# same matcher sees an MCP tool name too. This is the thing clink-brainstorm
# currently tries to achieve by asking a skill to persuade the master.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude/hooks"
cp "$REPO_ROOT/hooks/t4-delegation-gate" "$REPO/.claude/hooks/"
on()  { printf '{"t4":true,"delegationGate":true}\n' > "$REPO/.claude/t4.json"; }
off() { printf '{"t4":true}\n' > "$REPO/.claude/t4.json"; }
fire() { (cd "$REPO" && printf '%s' "$1" | bash .claude/hooks/t4-delegation-gate 2>/dev/null); }

GOOD='{"objective":"pick a recovery strategy","scope":{"exclude":["replacing Redis"]},"questions":["which state wins?"]}'
BARE='{"prompt":"have a look at the cache thing"}'

echo "OFF BY DEFAULT:"
off
[ -z "$(fire "{\"tool_name\":\"Agent\",\"tool_input\":$BARE}")" ] \
  && ok "a bare delegation passes while the gate is off" || bad "it denied while off"

on
echo ""
echo "all four native spawn names are gated:"
for t in Agent spawn_agent Task invoke_subagent; do
  out="$(fire "{\"tool_name\":\"$t\",\"tool_input\":$BARE}")"
  case "$out" in *'"permissionDecision":"deny"'*) ok "$t is gated";; *) bad "$t was not gated";; esac
done

echo ""
echo "and a clink call, which #219 measured is visible at the same seam:"
out="$(fire "{\"tool_name\":\"mcp__pal__clink\",\"tool_input\":$BARE}")"
case "$out" in *deny*) ok "mcp__pal__clink is gated";; *) bad "the clink call was not gated";; esac
out="$(fire "{\"tool_name\":\"mcp__openclink__clink\",\"tool_input\":$BARE}")"
case "$out" in *deny*) ok "and so is mcp__openclink__clink -- the prefix is not hardcoded";;
  *) bad "the renamed prefix was not gated";; esac

echo ""
echo "a delegation carrying the shape runs:"
[ -z "$(fire "{\"tool_name\":\"Agent\",\"tool_input\":$GOOD}")" ] \
  && ok "a complete request is allowed through" || bad "a valid delegation was denied"

echo ""
echo "the denial names the missing field, not just 'invalid':"
out="$(fire "{\"tool_name\":\"Agent\",\"tool_input\":$BARE}")"
for f in objective "scope.exclude" questions; do
  case "$out" in *"$f"*) ok "names $f";; *) bad "does not name $f";; esac
done
out2="$(fire "{\"tool_name\":\"Agent\",\"tool_input\":{\"objective\":\"x\",\"questions\":[\"y\"]}}")"
case "$out2" in *"scope.exclude"*) ok "and names only what is actually missing";; *) bad "wrong field named";; esac
case "$out2" in *"objective"*) bad "it named a field that was present";; *) ok "and not what is present";; esac

echo ""
echo "recursive enforcement: the child's own identity is recorded on the denial:"
out="$(fire "{\"tool_name\":\"Task\",\"agent_id\":\"agent-a287239d0\",\"tool_input\":$BARE}")"
case "$out" in *"agent-a287239d0"*) ok "an agent_id is attributed";; *) bad "the child was anonymous";; esac
out="$(fire "{\"tool_name\":\"invoke_subagent\",\"conversationId\":\"7edbb319\",\"tool_input\":$BARE}")"
case "$out" in *"7edbb319"*) ok "a conversationId is attributed";; *) bad "agy's identity was dropped";; esac
out="$(fire "{\"tool_name\":\"Agent\",\"tool_input\":$BARE}")"
case "$out" in *"from master"*) ok "and with no identity it says master, rather than nothing";; *) bad "no attribution at all";; esac

echo ""
echo "it minds its own business:"
[ -z "$(fire '{"tool_name":"Bash","tool_input":{"command":"ls"}}')" ] && ok "an ordinary tool is untouched" || bad "it gated Bash"
[ -z "$(fire '{"tool_name":"mcp__pal__chat","tool_input":{}}')" ] && ok "a non-clink MCP tool is untouched" || bad "it gated an unrelated MCP tool"
PLAIN="$TMP/plain"; mkdir -p "$PLAIN/.claude/hooks"; cp "$REPO_ROOT/hooks/t4-delegation-gate" "$PLAIN/.claude/hooks/"
out="$( (cd "$PLAIN" && printf '{"tool_name":"Agent"}' | bash .claude/hooks/t4-delegation-gate 2>&1) )"; rc=$?
{ [ "$rc" -eq 0 ] && [ -z "$out" ]; } && ok "no marker file: silent, exit zero" || bad "rc=$rc out=$out"

echo ""
echo "it is NOT wired into the live chain -- a trust-boundary decision:"
grep -q "t4-delegation-gate" "$REPO_ROOT/hooks/hooks.json" \
  && bad "it was wired unattended" || ok "it ships tested and dark"

echo ""
echo "delegation-gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

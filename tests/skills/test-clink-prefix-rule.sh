#!/usr/bin/env bash
# The clink tool name is RESOLVED, not spelled (#204).
#
# A documentation-integrity suite, and labelled one: it detects deletion and softening
# of the rule. It cannot stop an agent hardcoding a prefix anyway.
#
# WHAT MAKES THIS MORE THAN A STYLE NOTE. On 2026-08-20 `claude mcp list` on the
# developer's machine reported `pal: openclink` -- the SERVER had been renamed to
# openclink and the REGISTRATION KEY was still pal. The MCP tool prefix comes from the
# key, so the tool is still mcp__pal__clink. An agent that read the rename and
# "corrected" the spelling would have broken all four clink skills at once, and PR #206
# proposes exactly that across 15 files.
#
# BOTH SPELLINGS ARE WRONG ON SOME MACHINE, so the fix is not to flip the string. That
# is why #206 is unmergeable in either direction and why the rule is resolution.
#
# The hooks were already right: t4-delegation-gate matches ^mcp__[A-Za-z0-9_.-]+__clink$
# and t4-clink-boundary says so in its own comment. Only the prose assumed.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLINK="$REPO_ROOT/skills/multi-agent/using-clink/SKILL.md"
GATE="$REPO_ROOT/hooks/t4-delegation-gate"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

[ -f "$CLINK" ] && ok "using-clink is present" || { bad "the family entry is missing"; exit 1; }

echo ""
echo "the rule says the prefix comes from the CLIENT, not the server:"
has "$CLINK" "the key the CLIENT registered it under" "the source of the prefix is named"
has "$CLINK" "claude mcp list" "and the command that reveals it"

echo ""
echo "THE MEASUREMENT IS ON THE PAGE — without it this reads as a style preference:"
has "$CLINK" "pal: openclink" "the observed drift between key and server is quoted"

echo ""
echo "and it says why flipping the string is not the fix:"
has "$CLINK" "both spellings are wrong on some machine" "the reason #206 cannot simply be merged"

echo ""
echo "THE HOOKS ARE CITED AS THE PRECEDENT, so the rule is not inventing a convention:"
has "$CLINK" "t4-delegation-gate" "the hook that already derives is named"

echo ""
echo "and the hook really does derive — the claim is checked, not taken on trust:"
grep -q 'mcp__\[A-Za-z0-9_\.-\]+__clink' "$GATE" \
  && ok "t4-delegation-gate matches any server key, not a fixed one" \
  || bad "the hook does NOT derive — the skill cites it wrongly"

echo ""
echo "clink-prefix-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

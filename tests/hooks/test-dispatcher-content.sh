#!/usr/bin/env bash
# Contract for the dispatcher devices that make using-t4 trigger reliably (the
# superpowers pattern), tested at the real injection seam: what t4-session-start
# emits in a T4 repo. Also a token-budget guard — this content is re-injected on
# every session start AND every compaction, so bloat is a recurring cost.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-session-start"
# The injection is now the COMPACT DIRECTIVE, not the whole using-t4 map (#182).
# The map was 8,974 B and one measured session took four injections of it. The
# budget moved with the injection, and so did the five pinned phrases below -- had
# only the injection moved, this guard would have gone on passing while guarding
# nothing, which is the failure mode it exists to prevent.
BUDGET=2500   # bytes of injected output
PRIOR=8974    # what the map cost per injection, for the saving reported below

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$1" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/repo/.claude"; printf '{"t4":true}\n' > "$TMP/repo/.claude/t4.json"
out="$( cd "$TMP/repo" && printf '{"session_id":"d1"}' \
  | CLAUDE_PLUGIN_ROOT="$REPO_ROOT" T4_HOOK_LOCK_DIR="$TMP/l" bash "$HOOK" )"

echo "Dispatcher devices present in the injected content:"
has "$out" 'Route first'          "pre-response 'route first' directive"
has "$out" 'Red flags'            "rationalization (red-flags) table"
has "$out" 'phase boundary'       "phase-transition re-check rule"
has "$out" 'does not discharge'   "parent-skill != leaf-skill rule"
has "$out" 'load the current one' "skills-evolve rebuttal"

echo "Token budget:"
if [ "${#out}" -le "$BUDGET" ]; then ok "injected output ${#out}B <= ${BUDGET}B"
else bad "injected output ${#out}B exceeds budget ${BUDGET}B (trim the directive)"; fi

# Measured, not estimated: the saving is computed from this run's own output.
saved=$(( PRIOR - ${#out} ))
per_session=$(( saved * 4 ))   # one measured session took four injections
if [ "$saved" -gt 0 ]; then
  ok "saves ${saved}B per injection, ${per_session}B across a four-injection session"
else
  bad "the directive is no smaller than the map it replaced"
fi

echo ""
echo "dispatcher-content: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

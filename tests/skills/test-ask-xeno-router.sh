#!/usr/bin/env bash
# `ask-xeno` is the top of a TWO-LEVEL routing tree, not a flat index of every
# skill. It names the family entries; each family entry names its own members.
#
# The first version of this test required all 17 skills to appear in ask-xeno
# itself. That was the wrong invariant: a top router carrying every leaf grows
# until it is too big to carry anywhere, which is the thing it exists to avoid.
#
# What must hold instead, and what this checks:
#
#   - REACHABILITY. Every skill is reachable in at most two hops — named in
#     ask-xeno, or named by one of the entries ask-xeno names. This is the
#     guarantee that a new skill cannot go missing, and it is what actually
#     failed before: 9 of 17 were reachable from no map at all.
#   - NO SECOND COPY. ask-xeno must not restate a rule a family entry owns.
#     Two routers that both state a rule are two rules that drift apart.
#   - SIZE. It is meant to be cheap enough to carry everywhere, so the cap is
#     asserted rather than described somewhere and forgotten. (#150)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROUTER="$REPO_ROOT/skills/ask-xeno/SKILL.md"
BUDGET=1800

# The family entries ask-xeno delegates to. Renaming one without updating this
# list is itself a defect, so the list is spelled out rather than derived.
ENTRIES="using-t4 clink-masteragent design karpathy-guidelines"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

cd "$REPO_ROOT" || exit 1

echo "the router exists:"
[ -f "$ROUTER" ] && ok "skills/ask-xeno/SKILL.md exists" || bad "skills/ask-xeno/SKILL.md is missing"

echo "it names every family entry:"
for e in $ENTRIES; do
  if [ -f "$ROUTER" ] && grep -qF -- "\`$e\`" "$ROUTER"; then ok "names $e"; else bad "does not name $e"; fi
done

echo "every skill is reachable in at most two hops:"
unreachable=""
while IFS= read -r f; do
  name="$(basename "$(dirname "$f")")"
  [ "$name" = "ask-xeno" ] && continue
  found=""
  [ -f "$ROUTER" ] && grep -qF -- "\`$name\`" "$ROUTER" && found=1
  if [ -z "$found" ]; then
    for e in $ENTRIES; do
      ef="$(find skills -type d -name "$e" -exec test -f '{}/SKILL.md' \; -print | head -1)/SKILL.md"
      [ -f "$ef" ] && grep -qF -- "$name" "$ef" && { found=1; break; }
    done
  fi
  [ -z "$found" ] && unreachable="$unreachable $name"
done <<< "$(find skills -name SKILL.md | sort)"
[ -z "$unreachable" ] && ok "no skill is unreachable from ask-xeno" \
  || bad "reachable from no route:$unreachable"

echo "it does not restate what a family entry owns:"
for phrase in "Skipping a rule requires proof" "Evidence before verdict" "Re-route at every phase boundary"; do
  if [ ! -f "$ROUTER" ]; then
    bad "cannot check duplication, router is missing: $phrase"
  elif grep -qF -- "$phrase" "$ROUTER"; then
    bad "the router restates a family entry's rule verbatim: $phrase"
  else
    ok "does not restate: $phrase"
  fi
done

echo "size — a top router that grows stops being carryable:"
if [ -f "$ROUTER" ]; then
  bytes=$(sed '1{/^---$/!q}; 1,/^---$/d' "$ROUTER" | wc -c | tr -d ' ')
  [ "$bytes" -le "$BUDGET" ] && ok "router body ${bytes}B <= ${BUDGET}B" \
    || bad "router body ${bytes}B exceeds ${BUDGET}B — detail belongs in the family entry"
else
  bad "cannot measure size, router is missing"
fi

echo ""
echo "ask-xeno-router: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

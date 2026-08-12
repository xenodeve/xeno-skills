#!/usr/bin/env bash
# `ask-xeno` is the library-wide index. Two properties keep it honest and both
# are the kind a later edit quietly breaks:
#
#   - COMPLETENESS. Nine of seventeen skills were unreachable from `using-t4`
#     when this was written — every clink-* and the whole design family. An
#     index that drifts out of date recreates exactly that, so the test walks
#     `skills/` and requires each name to appear EXACTLY once. It fails the day
#     someone adds a skill and forgets the index, which is how the nine got lost.
#   - SIZE. The developer wants this injected every prompt, on top of using-t4's
#     9000-byte session budget. A router that grows into prose becomes the
#     largest recurring context cost in the repo, so the cap is asserted here
#     rather than described in the issue and forgotten. (#150)
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROUTER="$REPO_ROOT/skills/ask-xeno/SKILL.md"
BUDGET=3000

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if [ -f "$1" ] && grep -qF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

cd "$REPO_ROOT" || exit 1

echo "the router exists and declares itself:"
[ -f "$ROUTER" ] && ok "skills/ask-xeno/SKILL.md exists" || bad "skills/ask-xeno/SKILL.md is missing"

echo "every skill in the library is reachable from it, exactly once:"
missing="" dupe=""
while IFS= read -r f; do
  name="$(basename "$(dirname "$f")")"
  [ "$name" = "ask-xeno" ] && continue          # the router does not index itself
  # Count ENTRIES, not mentions. The first version counted every backticked
  # occurrence and flagged three skills that a clarifying sentence names a
  # second time — which is not a defect. The defect is two list entries for one
  # skill, so the pattern anchors to the bullet form.
  n=$(grep -cE "^- \*\*\`$name\`\*\*" "$ROUTER" 2>/dev/null || echo 0)
  case "$n" in
    0) missing="$missing $name" ;;
    1) ;;
    *) dupe="$dupe $name($n)" ;;
  esac
done <<< "$(find skills -name SKILL.md | sort)"
[ -z "$missing" ] && ok "no skill is missing from the index" || bad "missing from the index:$missing"
[ -z "$dupe" ]    && ok "no skill is listed twice"          || bad "listed more than once:$dupe"

echo "it indexes rather than restating what using-t4 owns:"
has "$ROUTER" "using-t4" "it hands the T4 rules off instead of copying them"
# The non-negotiable rules live in exactly one file. A second copy is a second
# rule that drifts, so pin the two phrases most likely to be duplicated here.
# A negative assertion passes trivially when the file is absent — the same
# vacuous-green this repo has been bitten by. Require the file to exist first.
for phrase in "Skipping a rule requires proof" "Evidence before verdict"; do
  if [ ! -f "$ROUTER" ]; then
    bad "cannot check duplication, router is missing: $phrase"
  elif grep -qF -- "$phrase" "$ROUTER"; then
    bad "the router restates a using-t4 rule verbatim: $phrase"
  else
    ok "does not restate: $phrase"
  fi
done

echo "size — this is meant to be cheap enough to inject:"
if [ -f "$ROUTER" ]; then
  # Measure the body only; frontmatter is metadata, not injected content.
  bytes=$(sed '1{/^---$/!q}; 1,/^---$/d' "$ROUTER" | wc -c | tr -d ' ')
  if [ "$bytes" -le "$BUDGET" ]; then
    ok "router body ${bytes}B <= ${BUDGET}B"
  else
    bad "router body ${bytes}B exceeds ${BUDGET}B — it is being written as prose, not an index"
  fi
else
  bad "cannot measure size, router is missing"
fi

echo ""
echo "ask-xeno-router: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

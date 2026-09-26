#!/usr/bin/env bash
# The anti-slop family (2026-09-26): seventeen third-party skills that keep an AI-built
# page from looking templated, vendored into skills/vendor/ and reachable through one
# router. A vendored skill no router names is dead weight -- nothing loads it -- so the
# router must name every one, and the tops (ask-xeno, using-design) must reach the router.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
V="$REPO_ROOT/skills/vendor"
R="$REPO_ROOT/skills/anti-slop/using-anti-slop/SKILL.md"
pass=0 fail=0
ok()  { pass=$((pass+1)); }
bad() { echo "FAIL: $1"; fail=$((fail+1)); }

[ -f "$R" ] || { echo "FAIL: router missing: $R"; exit 1; }
grep -qE '^name: using-anti-slop$' "$R" && ok || bad "router frontmatter name is not using-anti-slop"

want="design-taste-frontend design-taste-frontend-v1 redesign-existing-projects stitch-design-taste
minimalist-ui industrial-brutalist-ui brandkit imagegen-frontend-web imagegen-frontend-mobile
hallmark gridgeist web-design-guidelines impeccable ui-ux-pro-max design-system ui-styling brand"
for s in $want; do
  d="$V/$s"
  [ -f "$d/SKILL.md" ] && ok || bad "$s: SKILL.md missing"
  grep -qE "^name: $s\$" "$d/SKILL.md" && ok || bad "$s: frontmatter name differs from its folder"
  u="$d/UPSTREAM.md"
  grep -qE '^- commit: [0-9a-f]{40}$' "$u" 2>/dev/null && ok || bad "$s: UPSTREAM.md pins no 40-hex commit"
  grep -qE '^- license: (MIT|Apache-2\.0)$' "$u" 2>/dev/null && ok || bad "$s: UPSTREAM.md states no license"
  grep -qF "\`$s\`" "$R" && ok || bad "using-anti-slop does not route to $s"
done

# the router stays a router: a table, not a second copy of seventeen skills
sz=$(wc -c < "$R"); [ "$sz" -le 9000 ] && ok || bad "router is $sz bytes (>9000): it is copying, not routing"

grep -qF '`using-anti-slop`' "$REPO_ROOT/skills/ask-xeno/SKILL.md" && ok || bad "ask-xeno does not reach using-anti-slop"
grep -qF '`using-anti-slop`' "$REPO_ROOT/skills/design/using-design/SKILL.md" && ok || bad "using-design does not chain to using-anti-slop"

echo "anti-slop-router: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

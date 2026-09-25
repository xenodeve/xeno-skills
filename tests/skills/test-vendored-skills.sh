#!/usr/bin/env bash
# Third-party skills vendored into skills/vendor/ (#382). A copy with no record of
# where it came from cannot be updated, cannot be attributed, and drifts silently.
# So every vendored skill must carry: its upstream repo, the 40-hex commit it was
# copied at, and the license and where that license is stated. And the chain must
# reach it: using-design routes to each one by name, so a design task can load it.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
V="$REPO_ROOT/skills/vendor"
ROUTER="$REPO_ROOT/skills/design/using-design/SKILL.md"
pass=0 fail=0
ok()  { pass=$((pass+1)); }
bad() { echo "FAIL: $1"; fail=$((fail+1)); }

want="playwright-cli gsap-scrolltrigger threejs-animation r3f-best-practices"
for s in $want; do
  d="$V/$s"
  [ -f "$d/SKILL.md" ] && ok || bad "$s: SKILL.md missing"
  u="$d/UPSTREAM.md"
  [ -f "$u" ] || { bad "$s: UPSTREAM.md missing"; continue; }
  grep -qE '^- repo: https://github\.com/[^ ]+$' "$u" && ok || bad "$s: UPSTREAM.md names no repo"
  grep -qE '^- commit: [0-9a-f]{40}$' "$u" && ok || bad "$s: UPSTREAM.md pins no 40-hex commit"
  grep -qE '^- license: (MIT|Apache-2\.0)$' "$u" && ok || bad "$s: UPSTREAM.md states no license"
  grep -qE '^- license stated in: ' "$u" && ok || bad "$s: UPSTREAM.md does not say where the license is stated"
  grep -qF "\`$s\`" "$ROUTER" && ok || bad "using-design does not route to $s"
done

# every folder under vendor/ is one of the above and carries the same record
for d in "$V"/*/; do
  s="$(basename "$d")"
  [ -f "$d/UPSTREAM.md" ] && ok || bad "vendor/$s has no UPSTREAM.md"
done

# the gate the router names must be the gate that exists (it said 8/8 after check 9 landed)
hasnt_router() { grep -qF -- "$1" "$ROUTER" && bad "using-design still says: $1" || ok; }
hasnt_router "GATE: 8/8"
hasnt_router "eight executable checks"

echo "vendored-skills: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

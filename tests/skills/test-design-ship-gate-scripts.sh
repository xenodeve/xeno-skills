#!/usr/bin/env bash
# The three gate-*.js scripts are RUN here, against fixtures with a known defect and a clean
# control (#359).
#
# Why this file exists: test-design-ship-gate.sh has 43 assertions and every one of them is a
# grep over the scripts' source. Inverting `d < 60` to `d > 60` inside gate-dark.js left the
# whole suite green. A detector nobody has watched find something has not been shown to find
# anything, so each check below runs the real script twice: once on a page carrying the defect
# it exists to catch, once on a page that does not have it.
#
# Playwright is not a dependency of this repo. When it cannot be resolved the file SKIPS and
# says so; it does not silently pass.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
D="$REPO_ROOT/skills/design/design-ship-gate"
FIX="$REPO_ROOT/tests/skills/fixtures/design-ship-gate"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

# --- resolve playwright, or skip loudly -------------------------------------------------
NP=""
if ! node -e "require('playwright')" >/dev/null 2>&1; then
  for c in "${PLAYWRIGHT_NODE_PATH:-}" "$REPO_ROOT/node_modules" \
           "$HOME/AppData/Local/npm-cache/_npx"/*/node_modules; do
    [ -n "$c" ] && [ -d "$c/playwright" ] && NP="$c" && break
  done
  if [ -z "$NP" ]; then
    echo "  SKIP: playwright is not resolvable from this checkout."
    echo "        The gate scripts were NOT executed. Install it (npm i -D playwright &&"
    echo "        npx playwright install chromium) or set PLAYWRIGHT_NODE_PATH, then re-run."
    echo ""
    echo "design-ship-gate-scripts: 0 passed, 0 failed (SKIPPED)"
    exit 0
  fi
fi
run() { NODE_PATH="$NP" node "$D/$1" "$FIX/$2" 2>&1; }

num() { printf '%s' "$1" | sed -n "s/.*$2:[[:space:]]*\([0-9-]\+\).*/\1/p" | head -1; }

# --- check 4: dark-mode stat visibility -------------------------------------------------
echo "gate-dark.js sees an invisible stat and leaves a readable one alone:"
o="$(run gate-dark.js dark-invisible.html)"
[ "$(num "$o" invisible)" = "1" ] && ok "one ghost stat found (invisible: 1)" || bad "dark-invisible.html -> $o"
o="$(run gate-dark.js clean.html)"
[ "$(num "$o" invisible)" = "0" ] && ok "the clean page is clean (invisible: 0)" || bad "clean.html -> $o"

echo "gate-dark.js reports how many candidates it looked at, so a dead detector is visible:"
o="$(run gate-dark.js clean.html)"
c="$(num "$o" candidates)"
[ -n "$c" ] && [ "$c" -ge 2 ] && ok "checked $c candidates on the clean page" || bad "no candidate count in: $o"

echo "gate-dark.js judges a color-scheme dark canvas against the real background, not white:"
o="$(run gate-dark.js dark-colorscheme.html)"
[ "$(num "$o" invisible)" = "0" ] && ok "light text on a color-scheme dark canvas is not called invisible" || bad "dark-colorscheme.html -> $o"

echo "gate-dark.js sees a stat that shares its text node with a word (9.4B users):"
o="$(run gate-dark.js dark-split-stat.html)"
[ "$(num "$o" invisible)" = "1" ] && ok "the split stat is found" || bad "dark-split-stat.html -> $o"

# --- check 5: 390 px overflow -----------------------------------------------------------
echo "gate-390.js sees a block wider than the viewport and passes a page that fits:"
o="$(run gate-390.js overflow-390.html)"
v="$(num "$o" overflow)"; [ -n "$v" ] && [ "$v" -gt 0 ] && ok "overflow found ($v px)" || bad "overflow-390.html -> $o"
o="$(run gate-390.js clean.html)"
[ "$(num "$o" overflow)" = "0" ] && ok "the clean page does not overflow" || bad "clean.html -> $o"

echo "gate-390.js reports content an INNER wrapper clips, which hiding overflow-x concealed:"
o="$(run gate-390.js overflow-inner.html)"
v="$(num "$o" clipped)"; [ -n "$v" ] && [ "$v" -ge 1 ] && ok "the clipped wrapper is reported (clipped: $v)" || bad "overflow-inner.html -> $o"
o="$(run gate-390.js clean.html)"
[ "$(num "$o" clipped)" = "0" ] && ok "the clean page clips nothing" || bad "clean.html clipped -> $o"

# --- check 6: hero collisions -----------------------------------------------------------
echo "gate-hero.js sees text laid across the headline and passes a clear hero:"
o="$(run gate-hero.js hero-collision.html)"
[ "$(num "$o" colliding)" = "1" ] && ok "the ruler over the h1 is found" || bad "hero-collision.html -> $o"
o="$(run gate-hero.js clean.html)"
[ "$(num "$o" colliding)" = "0" ] && ok "the clean hero is clear" || bad "clean.html -> $o"

echo "gate-hero.js says a missing h1 is a missing h1, not a collision:"
o="$(run gate-hero.js hero-no-h1.html)"
[ "$(num "$o" colliding)" = "0" ] && ok "colliding: 0 on a page with no h1" || bad "hero-no-h1.html -> $o"
printf '%s' "$o" | grep -qi "no h1" && ok "and it says the check did not run" || bad "no h1 not reported: $o"

echo ""
echo "design-ship-gate-scripts: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

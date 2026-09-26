#!/usr/bin/env bash
# The web3d family (2026-09-26): 3D engines, 2D canvas, motion and scroll skills, vendored into skills/vendor/ and reachable through one
# router. A vendored skill no router names is dead weight -- nothing loads it -- so the
# router must name every one, and the tops (ask-xeno, using-design) must reach the router.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
V="$REPO_ROOT/skills/vendor"
R="$REPO_ROOT/skills/web3d/using-web3d/SKILL.md"
pass=0 fail=0
ok()  { pass=$((pass+1)); }
bad() { echo "FAIL: $1"; fail=$((fail+1)); }

[ -f "$R" ] || { echo "FAIL: router missing: $R"; exit 1; }
grep -qE '^name: using-web3d$' "$R" && ok || bad "router frontmatter name is not using-web3d"

want="web3d-integration-patterns modern-web-design threejs-webgl react-three-fiber babylonjs-engine
playcanvas-engine aframe-webxr lightweight-3d-effects pixijs-2d motion-framer animejs react-spring-physics
animated-component-libraries lottie-animations rive-interactive locomotive-scroll scroll-reveal-libraries
barba-js spline-interactive threejs-agents-model-optimizer threejs-animation r3f-best-practices gsap-scrolltrigger"

for s in $want; do
  d="$V/$s"
  [ -f "$d/SKILL.md" ] && ok || bad "$s: SKILL.md missing"
  grep -qE "^name: $s\$" "$d/SKILL.md" && ok || bad "$s: frontmatter name differs from its folder"
  u="$d/UPSTREAM.md"
  grep -qE '^- commit: [0-9a-f]{40}$' "$u" 2>/dev/null && ok || bad "$s: UPSTREAM.md pins no 40-hex commit"
  grep -qE '^- license: (MIT|Apache-2\.0)$' "$u" 2>/dev/null && ok || bad "$s: UPSTREAM.md states no license"
  grep -qF "\`$s\`" "$R" && ok || bad "using-web3d does not route to $s"
done

# the router stays a router: a table, not a second copy of seventeen skills
sz=$(wc -c < "$R"); [ "$sz" -le 9000 ] && ok || bad "router is $sz bytes (>9000): it is copying, not routing"

grep -qF '`using-web3d`' "$REPO_ROOT/skills/ask-xeno/SKILL.md" && ok || bad "ask-xeno does not reach using-web3d"
grep -qF '`using-web3d`' "$REPO_ROOT/skills/design/using-design/SKILL.md" && ok || bad "using-design does not chain to using-web3d"

echo "web3d-router: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# `design-ship-gate` is a done-gate for a small model (#353). Nine Qwen3.8-27B
# pages from one brief, audited with real renders, broke rules the loaded
# `design-rules` skill states in plain words — which #134 had already recorded:
# a principle re-injected before every prompt changes nothing. What found every
# defect was a command. So the skill is commands with pass conditions, and this
# test pins the parts a rewrite would smooth away:
#
#   - each anchor is a figure that was measured (5/9, 6/9, 3/9, 390, -0.03em,
#     `.big span`), not a wording the author liked;
#   - the brief-coverage table comes BEFORE the checks, because the two
#     deliverables most often missing (dark mode, OG) are the ones a brief
#     never names;
#   - "a check you did not run is a check that failed" and "8/8 with no
#     outputs is not a pass" — the gate is worthless if the model may skip it;
#   - the 390 px check removes overflow-x:hidden first, since that rule is how
#     the one overflow was hidden;
#   - a non-scope line, so it cannot be read as a second set of design rules.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GATE="$REPO_ROOT/skills/design/design-ship-gate/SKILL.md"
MAP="$REPO_ROOT/skills/design/using-design/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if [ -f "$1" ] && grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }
hasnt() { if [ -f "$1" ] && ! grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "the skill exists and is routable:"
[ -f "$GATE" ] && ok "skills/design/design-ship-gate/SKILL.md exists" || bad "skills/design/design-ship-gate/SKILL.md is missing"
has "$MAP" '| **🚦 `design-ship-gate`** |' "using-design routes to it from the navigation table"
has "$MAP" 'Ship Gate (`design-ship-gate`)' "using-design's workflow ends with the gate, after the audit"

echo "the anchors are measured figures, not wording:"
has "$GATE" "5 / 9" "font-family count: 5 of 9 pages"
has "$GATE" "6 / 9" "Open Graph missing: 6 of 9 pages"
has "$GATE" "3 / 9" "hero collisions and number/unit splits: 3 of 9 each"
has "$GATE" "4 of 5 pages skipped it unasked" "dark mode: 4 of 5 Claude Code pages"
has "$GATE" "2 / 9 answered a Thai brief in English" "language: 2 of 9"
has "$GATE" ".big span{display:block}" "the over-broad selector that split 100B+, verbatim"
has "$GATE" ".big > span" "and the fix"
has "$GATE" "-0.03em" "the tracking value that produced \"Goole\""

# review 2026-09-06: the tracking regex stopped at -0.09em, so -0.1em and -1px went unseen.
# Run the skill's own command against a stylesheet holding one of each.
TR="$(mktemp -d)"
printf 'a{letter-spacing:-0.03em}
b{letter-spacing:-0.1em}
c{letter-spacing:-1px}
d{letter-spacing:-0.02em}
' > "$TR/t.css"
pat="$(grep -F 'letter-spacing: *-' "$GATE" | head -1 | sed -E 's/^grep -nE "//; s/" "\$P"$//')"
hit=$(grep -cE "$pat" "$TR/t.css" 2>/dev/null); hit=${hit:-0}
[ "$hit" -eq 3 ] && ok "the tracking check sees -0.03em, -0.1em and -1px and leaves -0.02em ($hit/3)" || bad "the tracking check saw $hit of 3 tight values"
rm -rf "$TR"
has "$GATE" "390" "the mobile width the overflow was measured at"

echo "the brief table comes first and names the unnamed deliverables:"
first_table=$(grep -n "^## 0. Brief coverage" "$GATE" | head -1 | cut -d: -f1)
first_check=$(grep -n "^## 1" "$GATE" | head -1 | cut -d: -f1)
if [ -n "$first_table" ] && [ -n "$first_check" ] && [ "$first_table" -lt "$first_check" ]; then ok "section 0 (brief) precedes section 1-8 (checks)"; else bad "brief coverage must precede the checks"; fi
has "$GATE" "a deliverable even when the brief does not say it" "dark mode is a deliverable when unnamed"
has "$GATE" "a deliverable when unnamed" "Open Graph is a deliverable when unnamed"
has "$GATE" "the brief's language" "the page answers in the brief's language"

echo "the gate cannot be skipped or rubber-stamped:"
has "$GATE" "A check you did not run is a check that failed" "unrun = failed"
has "$GATE" "with no outputs is not a pass" "8/8 needs the outputs pasted"
has "$GATE" "say so in the report instead of skipping silently" "a missing Playwright is reported, not skipped"

echo "each check is a command with a pass condition:"
for n in 1 2 3 4 5 6 7 8; do
  grep -qE "^\*\*$n\. " "$GATE" && ok "check $n is present" || bad "check $n is missing"
done
[ "$(grep -c '^```' "$GATE")" -ge 16 ] && ok "at least eight fenced commands" || bad "fewer than eight fenced commands"
D="$(dirname "$GATE")"
for f in gate-dark.js gate-390.js gate-hero.js; do
  [ -f "$D/$f" ] && ok "$f ships next to the skill" || bad "$f is missing"
  has "$GATE" "\$G/$f" "the skill runs $f by path, not by pasting it"
done
has "$D/gate-390.js" "overflow-x:visible!important" "the 390 px check removes overflow-x:hidden before measuring"
has "$D/gate-dark.js" "colorScheme: 'dark'" "the stat-visibility check renders in dark mode"
has "$D/gate-dark.js" "SHOW_TEXT" "the stat check reads text nodes (9.4<span>B</span> was skipped by an element test)"
has "$D/gate-hero.js" "nodeType === 3" "the collision check keys on an element's own text, not z-index"
has "$GATE" "Known miss" "the one audited collision the script cannot see is stated, not implied caught"
has "$GATE" "not to hide it" "the collision fix is to move the text, not hide the check"

echo "non-scope, stated:"
has "$GATE" "What this does not touch" "the skill declares its boundary"
has "$GATE" "not a rate" "the counts are what was seen, not a rate"
hasnt "$GATE" "60-30-10" "it does not restate design-rules' colour rule"

echo
echo "design-ship-gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

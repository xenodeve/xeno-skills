#!/usr/bin/env bash
# `t4-bro` fixes the register the agent talks to the developer in. Every device
# below is load-bearing in a specific way, and each one is the kind of thing a
# well-meaning rewrite deletes:
#
#   - the three-way necessity test is what stops the skill collapsing into
#     "avoid English", which would strip identifiers and break copy-paste;
#   - the naturalisation evidence rule is what stops it collapsing the other
#     way, into translating `merge` — a word the developer writes themselves;
#   - the accuracy floor is what stops "say it simply" outranking
#     `No verdict before evidence`;
#   - the before/after pairs are the part that transfers. #134 is the evidence
#     that a principle re-injected before every prompt changes nothing.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BRO="$REPO_ROOT/skills/t4/t4-bro/SKILL.md"
MAP="$REPO_ROOT/skills/t4/using-t4/SKILL.md"
WF="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if [ -f "$1" ] && grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "the skill exists and is routable:"
[ -f "$BRO" ] && ok "skills/t4/t4-bro/SKILL.md exists" || bad "skills/t4/t4-bro/SKILL.md is missing"
# A bare "t4-bro" would also match the HTML maintainer note, which is stripped
# before injection and so reaches no session. Pin the table cell instead.
has "$MAP" "| **\`t4-bro\`** |" "using-t4 routes to it from the map table (not merely mentions it)"

echo "the necessity test — all three ways a term survives:"
has "$BRO" "earns its English only three ways" "the test is stated as a closed list, not a preference"
has "$BRO" "It is an identifier"               "way 1: identifiers are never translated"
has "$BRO" "The developer already uses it"     "way 2: the developer's own vocabulary"
has "$BRO" "Precision would be lost"           "way 3: the word carries meaning nothing else does"
has "$BRO" "the developer's own words are the evidence" \
    "naturalisation is decided by evidence, not by the agent's taste"

echo "the accuracy floor (readability never outranks truth):"
has "$BRO" "Simplifying may never make a claim false" "the floor is stated"
has "$BRO" "Hedges are not jargon"                    "an unverified claim keeps its hedge"

echo "non-scope, stated so it cannot be read as overriding an existing rule:"
has "$BRO" "What this does not touch" "the skill declares its boundary"
has "$BRO" "commit messages"          "commit messages stay English"
has "$BRO" "bilingual"                "tracker bodies keep the EN + TH mirror"

echo "the part that actually transfers:"
has "$BRO" "Before → after" "concrete sentence pairs, not principles alone"
has "$BRO" "Red flags"      "rationalisations are rebutted by name"
has "$BRO" "One new term per explanation" "a bounded budget, not 'be clear'"

# Measured 2026-08-12: an agent following this skill kept every word-level rule
# and still answered in four headings and two tables. The shape rule was the one
# bullet with no example attached, so it got an example.
has "$BRO" "The shape is part of the register" "over-structuring is called out, not left to the bullet"
has "$BRO" "Default to prose" "and the default is stated, not implied"

echo "the parent rule it refines is still the one in t4-dev-workflow:"
has "$WF" "single-language (the developer's — Thai)" "t4-dev-workflow still owns the language choice"

echo "both READMEs list it (an undocumented skill is one nobody installs):"
for r in README.md README.en.md; do
  has "$REPO_ROOT/$r" "skills/t4/t4-bro/SKILL.md" "$r links the skill"
done

echo ""
echo "bro-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# The rule census is generated, and its counts are derived from its own table (#181).
#
# The inherited split -- 33 machine-decidable / 68 needing a trace / 25 undecidable --
# was counted before the delegation question existed and nobody re-counted it since,
# so every downstream slice size rested on a number no one produced. The point of
# this suite is that the same cannot become true of the new numbers.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN="$REPO_ROOT/scripts/rule-census.py"
DOC="$REPO_ROOT/docs/research/rule-census.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

echo "the census is a committed file, generated from the skills:"
[ -f "$GEN" ] && ok "the generator is committed" || bad "the generator is missing"
[ -f "$DOC" ] && ok "the census is a committed file, not a comment" || bad "the census is missing"
python "$GEN" --check && ok "the census agrees with the skills" || bad "the census is stale -- re-run it"

echo ""
echo "the published counts are derived from the table, so they cannot drift apart:"
python - "$DOC" <<'PY'
import re, sys
doc = open(sys.argv[1], encoding="utf-8").read()

rows = re.findall(r"^\| `[^`]+` \| .* \| (machine|trace|undecidable) \| (master|subagent|foreign) \|$",
                  doc, re.M)
assert rows, "no rule rows found -- the table shape changed"

total = re.search(r"\| \*\*total\*\* \| \*\*(\d+)\*\* \| \*\*(\d+)\*\* \| \*\*(\d+)\*\* \| \*\*(\d+)\*\* \|", doc)
assert total, "no totals row found"
m, t, u, all_ = (int(x) for x in total.groups())

from collections import Counter
c = Counter(d for d, _p in rows)
assert c["machine"] == m, "machine: table %d vs published %d" % (c["machine"], m)
assert c["trace"] == t, "trace: table %d vs published %d" % (c["trace"], t)
assert c["undecidable"] == u, "undecidable: table %d vs published %d" % (c["undecidable"], u)
assert len(rows) == all_, "total: table %d vs published %d" % (len(rows), all_)
print("    %d rules: %d machine / %d trace / %d undecidable" % (all_, m, t, u))
PY
[ $? -eq 0 ] && ok "every published count matches the rows it summarises" \
             || bad "a published count disagrees with the table"

echo ""
echo "every rule carries BOTH classifications, which is the second question #181 added:"
python - "$DOC" <<'PY'
import re, sys
doc = open(sys.argv[1], encoding="utf-8").read()
body = doc.split("## The rules", 1)[1]
rows = [l for l in body.splitlines() if l.startswith("| `")]
bad = [l for l in rows
       if not re.search(r"\| (machine|trace|undecidable) \| (master|subagent|foreign) \|$", l)]
assert not bad, "%d rows missing a classification, first: %s" % (len(bad), bad[0][:80])
PY
[ $? -eq 0 ] && ok "no rule is missing a decidability or a producer" || bad "some rule is unclassified"

echo ""
echo "foreign traces are listed separately, not folded into undecidable:"
grep -q "foreign CLI worker" "$DOC" && ok "the foreign row exists" || bad "no foreign row"
grep -q "openclink#116" "$DOC" && ok "and says what makes it reachable" || bad "the foreign row does not say why it is separate"

echo ""
echo "the method is published, so a later re-count is comparable:"
grep -q "## The method" "$DOC" && ok "the method section exists" || bad "no method section"
grep -q "cannot see" "$DOC" && ok "and states what it cannot see -- the count is a floor" \
                            || bad "the method does not state its own boundary"

echo ""
echo "the drift check detects a change rather than only claiming to:"
PROBE="$REPO_ROOT/skills/t4/t4-bro/SKILL.md"
cp "$PROBE" "$PROBE.censusbak"
printf '\n- **A probe rule added by the census test, before every commit.**\n' >> "$PROBE"
if python "$GEN" --check >/dev/null 2>&1; then
  bad "adding a rule did NOT make the check fail -- it detects nothing"
else
  ok "adding a rule to a skill makes the check fail"
fi
mv "$PROBE.censusbak" "$PROBE"
python "$GEN" --check >/dev/null 2>&1 && ok "removing it makes the check pass again" \
                                      || bad "the check stayed red after the probe was removed"

echo ""
echo "rule-census: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

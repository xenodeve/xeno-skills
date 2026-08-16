#!/usr/bin/env bash
# The reviewer-only trace file (#188) and the out-of-scope markers (#195).
#
# Two properties this suite exists for. A trace is a SEQUENCE FACT and never a
# quality criterion -- softening one into "was it done well" hands the reviewer
# something no transcript settles, and it will invent a verdict. And EVERY rule
# carries a state, because an unmarked gap reads as coverage.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN="$REPO_ROOT/scripts/rule-traces.py"
DOC="$REPO_ROOT/docs/research/rule-traces.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

echo "the file exists, is generated, and agrees with the skills:"
[ -f "$GEN" ] && ok "the generator is committed" || bad "the generator is missing"
[ -f "$DOC" ] && ok "the trace file is committed" || bad "the trace file is missing"
python "$GEN" --check && ok "it agrees with the skill graph" || bad "it is stale -- re-run it"

echo ""
echo "every rule carries exactly one state -- an unmarked gap reads as coverage:"
python - "$DOC" <<'PY'
import re, sys
from collections import Counter
doc = open(sys.argv[1], encoding="utf-8").read()
body = doc.split("## Traces", 1)[1]
rows = [l for l in body.splitlines() if l.startswith("| `")]
assert rows, "no rows found"
states = []
for l in rows:
    m = re.match(r"^\| `[^`]+` \| `[^`]+` \| (\S+) \|", l)
    assert m, "row without a state: %s" % l[:70]
    states.append(m.group(1))
c = Counter(states)
assert set(c) <= {"traced", "machine", "untraced", "out-of-scope", "foreign"}, c
for state in ("traced", "machine", "untraced", "out-of-scope", "foreign"):
    published = re.search(r"\| `%s` \| (\d+) \|" % re.escape(state), doc)
    assert published, "no published count for %s" % state
    assert int(published.group(1)) == c[state], \
        "%s: table %d vs published %s" % (state, c[state], published.group(1))
print("    %d rows, all classified, every published count matches" % len(rows))
PY
[ $? -eq 0 ] && ok "no rule is unclassified, and the counts match the rows" || bad "a rule is unclassified or a count disagrees"

echo ""
echo "the trace file and the census agree on how many rules need a trace:"
python - "$REPO_ROOT" <<'PY'
import re, sys, os
root = sys.argv[1]
traces = open(os.path.join(root, "docs/research/rule-traces.md"), encoding="utf-8").read()
census = open(os.path.join(root, "docs/research/rule-census.md"), encoding="utf-8").read()
t  = int(re.search(r"\| `traced` \| (\d+) \|", traces).group(1))
u  = int(re.search(r"\| `untraced` \| (\d+) \|", traces).group(1))
need = int(re.search(r"\| \*\*total\*\* \| \*\*\d+\*\* \| \*\*(\d+)\*\*", census).group(1))
assert t + u == need, "traced %d + untraced %d != census needs-a-trace %d" % (t, u, need)
print("    traced %d + untraced %d = census %d" % (t, u, need))
PY
[ $? -eq 0 ] && ok "traced + untraced equals the census count, so neither file hides the other's gap" \
             || bad "the two files disagree about how many rules need a trace"

echo ""
echo "NEGATIVE: a trace softened into a quality criterion fails:"
python - "$DOC" <<'PY'
import re, sys
doc = open(sys.argv[1], encoding="utf-8").read()
body = doc.split("## Traces", 1)[1]
bad = []
for l in body.splitlines():
    m = re.match(r"^\| `[^`]+` \| `[^`]+` \| traced \| [^|]* \| (.*) \|$", l)
    if not m:
        continue
    trace = m.group(1).lower()
    for word in ("well", "thorough", "quality", "properly", "deeply", "good enough"):
        if re.search(r"\b%s\b" % word, trace):
            bad.append((word, l[:70]))
assert not bad, "quality wording inside a trace: %s" % bad[:2]
PY
[ $? -eq 0 ] && ok "no traced row contains quality wording" || bad "a trace was softened into a quality criterion"

echo ""
echo "no trace appears in any skill body or in the family map:"
leak=0
while IFS= read -r skill; do
  if grep -qF "appears BEFORE the record" "$skill" 2>/dev/null; then leak=1; echo "    leaked into $skill"; fi
done < <(find "$REPO_ROOT/skills" -name SKILL.md)
[ "$leak" -eq 0 ] && ok "no trace text leaked into a skill body" || bad "a trace leaked into a skill body"
grep -qF "appears BEFORE the record" "$REPO_ROOT/.claude/hooks/using-t4.snapshot.md" 2>/dev/null \
  && bad "a trace leaked into the injected family map" || ok "the family map is free of traces"

echo ""
echo "rewording a rule cannot silently orphan its trace:"
PROBE="$REPO_ROOT/skills/t4/t4-bro/SKILL.md"
cp "$PROBE" "$PROBE.tracebak"
# Restore on EXIT -- see the note in test-rule-census.sh. A probe that mutates a
# tracked file must not depend on reaching its own last line.
trap 'if [ -f "$PROBE.tracebak" ]; then mv -f "$PROBE.tracebak" "$PROBE"; fi' EXIT
python - "$PROBE" <<'PY'
import sys, io
p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()
# Reword one existing bolded rule rather than adding a new one -- an ADDED rule
# would prove only that the count changed, not that a REWORD is caught.
i = s.find("- **")
j = s.find("**", i + 4)
s = s[:i+4] + "Reworded by the trace test" + s[j:]
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
PY
if python "$GEN" --check >/dev/null 2>&1; then
  bad "rewording a rule did NOT make the check fail -- the sha proves nothing"
else
  ok "rewording a rule makes the check fail"
fi
mv "$PROBE.tracebak" "$PROBE"
python "$GEN" --check >/dev/null 2>&1 && ok "restoring it makes the check pass again" \
                                      || bad "the check stayed red after restore"

echo ""
echo "foreign is marked distinctly from out-of-scope:"
grep -q '`foreign`' "$DOC" && ok "the foreign state exists" || bad "no foreign state"
grep -q "openclink#116" "$DOC" && ok "and says what makes it reachable" || bad "foreign has no reachability note"

echo ""
echo "rule-traces: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

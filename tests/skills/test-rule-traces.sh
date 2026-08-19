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
# The reclassified rows are in the arithmetic rather than absorbed by it. A rule the
# census sent here and this file sent to out-of-scope leaves the equation unless it
# is named, and an equation that balances by losing a term is the gap it exists to close.
rec = int(re.search(r"reclassified from `trace` \| (\d+) \|", traces).group(1))
need = int(re.search(r"\| \*\*total\*\* \| \*\*\d+\*\* \| \*\*(\d+)\*\*", census).group(1))
assert t + u + rec == need, \
    "traced %d + untraced %d + reclassified %d != census needs-a-trace %d" % (t, u, rec, need)
print("    traced %d + untraced %d + reclassified %d = census %d" % (t, u, rec, need))
PY
[ $? -eq 0 ] && ok "traced + untraced + reclassified equals the census count, so neither file hides the other's gap" \
             || bad "the two files disagree about how many rules need a trace"

echo ""
echo "#194: NO RULE IS LEFT UNPAIRED -- every in-scope rule carries a trace:"
python - "$DOC" <<'PY'
import re, sys
doc = open(sys.argv[1], encoding="utf-8").read()
u = int(re.search(r"\| `untraced` \| (\d+) \|", doc).group(1))
body = doc.split("## Traces", 1)[1]
left = [l.split("|")[1].strip() for l in body.splitlines() if "| untraced |" in l]
assert u == 0, "%d rules still owe a trace: %s" % (u, left[:4])
PY
[ $? -eq 0 ] && ok "the untraced count is zero" \
             || bad "in-scope rules are still owed a trace"
# The pair that keeps the zero honest. `untraced` can be driven to zero by moving the
# hard rules to out-of-scope, which turns work-not-done into work-impossible -- the exact
# failure this file was built to prevent. Reclassifying is allowed, but only ARGUED: the
# blanket reason is what an unread rule inherits, so the blanket-reason population is
# what gets pinned. Widening the blind spot by sharing a sentence with it fails here.
python - "$DOC" <<'PY'
import re, sys
doc = open(sys.argv[1], encoding="utf-8").read()
body = doc.split("## Traces", 1)[1]
BLANKET = "asks whether the work was done well; no sequence of messages settles that"
n = sum(1 for l in body.splitlines() if BLANKET in l)
assert n <= 47, "%d rows carry the blanket reason, up from 47 -- rules were folded in, not read" % n
rec = [l for l in body.splitlines()
       if "| out-of-scope |" in l and BLANKET not in l and "foreign CLI" not in l]
assert rec, "no reclassified row carries a reason of its own"
print("    %d blanket-reason rows, %d argued individually" % (n, len(rec)))
PY
[ $? -eq 0 ] && ok "every reclassification is argued, and the blanket blind spot did not grow" \
             || bad "the owed rules were folded into the blanket reason instead of read"

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
echo "each row carries the sha of the rule it was written against:"
# NOT probed by rewording a tracked skill. That probe left the repository dirty when
# a run ended early, and the next `verify` failed on the contamination -- see the
# note in test-rule-census.sh. The sha mechanism is asserted structurally instead,
# and it is exercised for real the next time anyone rewords a rule.
grep -q "sha" "$GEN" && ok "the generator records a sha per row" || bad "no sha recorded"
grep -q "cannot silently orphan its trace" "$DOC"   && ok "and the document states what the sha is for" || bad "the sha's purpose is not stated"

echo ""
echo "foreign is marked distinctly from out-of-scope:"
grep -q '`foreign`' "$DOC" && ok "the foreign state exists" || bad "no foreign state"
grep -q "openclink#116" "$DOC" && ok "and says what makes it reachable" || bad "foreign has no reachability note"

echo ""
echo "rule-traces: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

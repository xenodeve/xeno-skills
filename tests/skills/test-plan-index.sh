#!/usr/bin/env bash
# docs/plans/README.md resolves the plan level in BOTH directions (#255, slice of #248).
#
# A documentation-integrity suite. #248 gave the plan level a presence on the tracker; a tracking
# issue links plan -> PRD, and this file is the only thing that links PRD-tracker -> plan file.
# Without it the index resolves one way and the other direction is prose nobody can query.
#
# THE RULE THIS PINS, in #255's words: "A plan with no PRD gets no tracking issue. Say so in
# docs/plans/README.md rather than creating an empty one." So an absent tracking issue is a legal
# state and a SILENT absent one is not -- exactly the shape check-gate-ledger enforces for gates.
# A blank cell is indistinguishable from a plan nobody has got to yet, which is the failure.
# WHAT A GREEN HERE DOES NOT MEAN. This checks the index file only. It never calls GitHub, so it
# cannot see whether #256 and #257 still carry their PRDs as sub-issues -- delete those links and
# this stays green. The tree is verified by the command in each tracking issue's Verification
# section, and that is deliberately out of scope here rather than silently uncovered (#195).
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLANS="$REPO_ROOT/docs/plans"
README="$PLANS/README.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

[ -f "$README" ] && ok "docs/plans/README.md is present" || { bad "the index is missing"; exit 1; }

echo ""
echo "every plan has a parsed row, carrying a tracker link or a stated absence:"
PYTHONIOENCODING=utf-8 python - "$README" "$PLANS" <<'PY'
import sys, os, re, glob
readme, plans = sys.argv[1], sys.argv[2]
doc = open(readme, encoding="utf-8").read()

# The column has to exist by name; a number buried in prose is not an index.
hdr = next((l for l in doc.splitlines() if l.startswith("|") and "Tracking issue" in l), None)
assert hdr, "the table has no 'Tracking issue' column"
# Read the column by name. Hardcoding its index means a reordered table is scored against the
# wrong cell, which passes for the wrong reason -- the failure a green is least likely to expose.
cols = [c.strip() for c in hdr.strip("|").split("|")]
TRACK = cols.index("Tracking issue")

rows = [r for r in doc.splitlines() if r.startswith("|") and ".md`" in r]
files = {os.path.basename(p) for p in glob.glob(os.path.join(plans, "*.md"))} - {"README.md"}
seen = set()
for row in rows:
    cells = [c.strip() for c in row.strip("|").split("|")]
    m = re.search(r"`([^`]+\.md)`", cells[0])
    if not m or m.group(1) not in files:
        continue
    name = m.group(1)
    seen.add(name)
    assert len(cells) > TRACK, f"{name}: the row has fewer cells than the header"
    cell = cells[TRACK]
    assert cell, f"{name}: the tracking-issue cell is empty"
    if re.search(r"#\d+", cell):
        continue
    # No issue is legal — but only with a reason, and the reason must say something.
    low = cell.lower()
    assert "none" in low, f"{name}: no issue number and the cell does not say 'none' — a blank reads as unfinished"
    reason = re.sub(r"^\W*none\W*", "", cell, flags=re.I).strip()
    assert len(reason) >= 15, f"{name}: says 'none' with no reason ({cell!r}) — #255 requires the reason be stated"

missed = files - seen
assert not missed, f"plans with no parsed row: {sorted(missed)}"
PY
[ $? -eq 0 ] && ok "every plan is indexed, with an issue number or 'none' plus a reason" \
             || bad "a plan is unindexed, or its cell is blank or an unexplained 'none'"

echo ""
echo "the two tracking issues that exist are attached to the right files:"
# The generic check above cannot catch a swap, so each existing pair is anchored by name.
# Two named assertions rather than a table-driven loop: this suite's house style is repeated
# named assertions, and the loop that briefly replaced them cost more in quoting than the
# duplication saved in lines.
grep -qE "2026-08-13-skill-compliance-plan\.md.*#256" "$README" \
  && ok "#256 tracks the skill-compliance plan" \
  || bad "#256 is not on the 2026-08-13-skill-compliance-plan row"
grep -qE "2026-08-16-clink-delegation-contract\.md.*#257" "$README" \
  && ok "#257 tracks the clink delegation contract" \
  || bad "#257 is not on the 2026-08-16-clink-delegation-contract row"

echo ""
echo "plan-index: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

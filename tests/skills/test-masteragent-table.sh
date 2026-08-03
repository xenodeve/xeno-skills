#!/usr/bin/env bash
# The generated table must put each source field under the heading that names it.
#
# `test-figures-sourced.sh` proves every printed number exists in the source. It
# cannot prove the number is under the right heading: swap two entries in AXES and
# every figure still traces, the contract test stays green, and the skill tells
# every agent that reads it the wrong thing about which model is better at what.
#
# That is the failure this file exists for — a green suite over a wrong table.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN="$REPO_ROOT/docs/research/scripts/generate_masteragent.py"
SRC="$REPO_ROOT/docs/research/data/aa-models-2026-08-02.csv"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

for py in python3 python; do command -v "$py" >/dev/null 2>&1 && PY="$py" && break; done
if [ -z "${PY:-}" ]; then echo "  FAIL: no python interpreter"; exit 1; fi

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

PYTHONIOENCODING=utf-8 "$PY" "$GEN" "$SRC" "$WORK/evidence.md" "$WORK/aug.csv" >/dev/null 2>&1 \
  || { echo "  FAIL: generator did not run"; exit 1; }

# Compare the rendered row against the source record, column by column.
report="$(PYTHONIOENCODING=utf-8 "$PY" - "$SRC" "$WORK/evidence.md" <<'PY'
import csv, io, sys

src, block = sys.argv[1], sys.argv[2]
rows = {r["name"]: r for r in csv.DictReader(io.open(src, encoding="utf-8"))}
lines = [l for l in io.open(block, encoding="utf-8").read().splitlines() if l.startswith("| ")]
header = [c.strip() for c in lines[0].strip("|").split("|")]

# heading -> source column. Stated here independently of the generator, so a swap
# inside the generator disagrees with this file instead of moving in step with it.
EXPECT = {
    "Index": "intelligenceIndex",
    "Agentic": "agenticIndex",
    "Coding": "codingIndex",
    "Non-halluc.": "omniscienceNonHallucination",
    "TermBench": "terminalbenchV21",
    "τ-Banking": "tauBanking",
    "GDPval": "gdpvalNormalized",
}

problems, checked = [], 0
for line in lines[1:]:
    cells = [c.strip() for c in line.strip("|").split("|")]
    name = cells[0]
    row = rows.get(name)
    if not row:
        problems.append(f"row not in source: {name}")
        continue
    for heading, col in EXPECT.items():
        if heading not in header:
            problems.append(f"heading missing from table: {heading}")
            continue
        printed = cells[header.index(heading)].replace(" ★", "").strip()
        if printed == "—":
            continue
        try:
            expected = float(row[col])
        except (KeyError, ValueError):
            problems.append(f"{name}: source has no usable {col}")
            continue
        dec = len(printed.split(".")[1]) if "." in printed else 0
        if round(expected, dec) != round(float(printed), dec):
            problems.append(f"{name}: {heading} shows {printed}, but {col} is {expected}")
        checked += 1

print(f"checked {checked} cells across {len(lines)-1} rows")
for p in problems[:8]:
    print("  " + p)
print("PROBLEMS" if problems else "CLEAN")
PY
)"

echo "$report" | head -3
case "$report" in
  *CLEAN*) ok "every column carries the source field its heading names" ;;
  *)       bad "a column does not match the field its heading names" ;;
esac

# The star must mark the actual maximum, not a row that merely looks plausible.
star_check="$(PYTHONIOENCODING=utf-8 "$PY" - "$SRC" "$WORK/evidence.md" <<'PY'
import csv, io, sys
src, block = sys.argv[1], sys.argv[2]
rows = list(csv.DictReader(io.open(src, encoding="utf-8")))
lines = [l for l in io.open(block, encoding="utf-8").read().splitlines() if l.startswith("| ")]
header = [c.strip() for c in lines[0].strip("|").split("|")]
bad = []
for heading, col in (("Index", "intelligenceIndex"), ("Agentic", "agenticIndex"),
                     ("Coding", "codingIndex"), ("GDPval", "gdpvalNormalized")):
    vals = [(float(r[col]), r["name"]) for r in rows if r.get(col) not in (None, "")]
    true_leader = max(vals)[1]
    starred = [ [c.strip() for c in l.strip("|").split("|")][0]
                for l in lines[1:]
                if "★" in [c.strip() for c in l.strip("|").split("|")][header.index(heading)] ]
    if starred != [true_leader]:
        bad.append(f"{heading}: starred {starred}, true leader {true_leader!r}")
print("STARS-OK" if not bad else "STARS-BAD " + "; ".join(bad))
PY
)"
case "$star_check" in
  STARS-OK*) ok "the leader star sits on the true maximum of each axis" ;;
  *)         bad "$star_check" ;;
esac

echo ""
echo "masteragent-table: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

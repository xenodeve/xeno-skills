"""Generate the evidence block of `clink-masteragent` from the structured source.

The block is regenerated, never edited. A hand-maintained table is how the two
existing skills ended up with figures nobody could trace — and the contract test
(`check-figures-sourced.sh`) will reject any figure this script did not produce.

Two choices here are deliberate and load-bearing:

* **Rows are sorted alphabetically**, not by score. Any score order makes the top
  rows read as a recommendation, and there is no single ranking to recommend:
  across the published axes different models lead, and the composite is only 34%
  tool-using — so ranking delegation candidates by it imports a majority signal
  about something the delegation is not.
* **Leaders are marked per axis, not aggregated.** An agent that cannot find a
  matching case still has to answer "who is best at THIS", and scanning 84 rows
  for it is the step that gets skipped.

UTF-8 explicit: the platform default here is cp1252 and it cannot encode the
markers below.
"""

import csv
import io
import sys

RAW = "docs/research/data/aa-models-2026-08-02.csv"
AUGMENTED = "docs/research/data/aa-models-augmented.csv"
START = f"<!-- figures:start source={AUGMENTED} -->"
END = "<!-- figures:end -->"

# `$/pt` is derived (cost / index), so it is not in the raw export and the
# contract check correctly rejected it — 43 figures with no record behind them.
# The fix is not to exempt derived values: it is to write them into a source of
# their own, produced by this script from the raw one. Provenance stays literal
# (raw export -> this script -> augmented file -> the block), and the rule keeps
# meaning exactly what it says. Relaxing the checker instead would have made
# "traceable" mean "traceable unless inconvenient".
DERIVED = "costPerIndexPoint"

# (column, heading, decimals, higher-is-better)
AXES = [
    ("intelligenceIndex", "Index", 1, True),
    ("agenticIndex", "Agentic", 1, True),
    ("codingIndex", "Coding", 1, True),
    ("omniscienceNonHallucination", "Non-halluc.", 3, True),
    ("terminalbenchV21", "TermBench", 3, True),
    ("tauBanking", "τ-Banking", 3, True),
    ("gdpvalNormalized", "GDPval", 3, True),
]


def num(row, col):
    try:
        return float(row[col])
    except (KeyError, TypeError, ValueError):
        return None


def fmt(v, decimals):
    return "—" if v is None else f"{v:.{decimals}f}"


def write_augmented(rows, path):
    """Raw export plus the derived column, so every printed figure has a record."""
    cols = list(rows[0].keys())
    if DERIVED not in cols:
        cols.append(DERIVED)
    with io.open(path, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            cost, idx = num(r, "intelligenceIndexCostTotal"), num(r, "intelligenceIndex")
            out = dict(r)
            out[DERIVED] = f"{cost / idx:.2f}" if (cost is not None and idx) else ""
            w.writerow(out)


def main(csv_path, out_path, augmented_path):
    rows = list(csv.DictReader(io.open(csv_path, encoding="utf-8")))
    rows = [r for r in rows if r.get("name")]
    rows.sort(key=lambda r: r["name"].lower())
    write_augmented(rows, augmented_path)

    leaders = {}
    for col, _h, _d, higher in AXES:
        best, best_row = None, None
        for r in rows:
            v = num(r, col)
            if v is None:
                continue
            if best is None or (v > best if higher else v < best):
                best, best_row = v, r["name"]
        leaders[col] = best_row

    # Cost per index point: the column that shows when a far cheaper model is
    # equally capable. Lower is better, so it is not marked with a leader star —
    # the whole table is scanned for it deliberately.
    lines = [
        START,
        "",
        f"{len(rows)} reachable model+effort rows. **Sorted by name — position implies no ranking.**",
        "★ marks the leader of that column. Cost is AA's cost to run the whole Index suite;",
        "**$/pt** is that divided by the index, so a low number is capability per unit spend.",
        "",
    ]

    head = ["Model"] + [h for _c, h, _d, _u in AXES] + ["Ctx", "Cost", "$/pt"]
    lines.append("| " + " | ".join(head) + " |")
    lines.append("|" + "---|" * len(head))

    for r in rows:
        cells = [r["name"]]
        for col, _h, dec, _u in AXES:
            v = num(r, col)
            star = " ★" if leaders.get(col) == r["name"] and v is not None else ""
            cells.append(fmt(v, dec) + star)
        ctx = num(r, "contextWindowTokens")
        cells.append("—" if ctx is None else f"{int(ctx):,}")
        cost = num(r, "intelligenceIndexCostTotal")
        cells.append(fmt(cost, 2))
        idx = num(r, "intelligenceIndex")
        cells.append(fmt(cost / idx, 2) if (cost is not None and idx) else "—")
        lines.append("| " + " | ".join(cells) + " |")

    lines += ["", END, ""]
    io.open(out_path, "w", encoding="utf-8").write("\n".join(lines))
    print(f"wrote {out_path}: {len(rows)} rows, {len(head)} columns")
    for col, h, _d, _u in AXES:
        print(f"  leader {h:12} {leaders.get(col)}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])

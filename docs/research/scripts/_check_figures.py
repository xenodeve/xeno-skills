"""Check that every figure in a skill's sourced-figures block exists in its source.

Called by `check-figures-sourced.sh`. Kept separate because the matching is
numeric, not textual, and bash cannot do it honestly:

The structured source carries full precision (`60.0681611916281`) while a skill
quotes a readable figure (`60.07`). A string comparison would reject every
correctly-derived number, the rule would be unusable, and it would be switched
off within a day. So a figure matches when SOME source value rounds to it at the
precision the figure was written with — which also means quoting more digits is
a stricter claim, as it should be.

UTF-8 is set explicitly: the platform default here is cp1252 and these files
contain characters it cannot encode.
"""

import csv
import io
import re
import sys

START = re.compile(r"<!--\s*figures:start\s+source=(\S+)\s*-->")
END = re.compile(r"<!--\s*figures:end\s*-->")
# A figure is a number in a table cell inside the block. Bare prose numbers are
# not figures — a skill legitimately says "3 rounds" and "49 turns", and treating
# those as claims would make the rule fail everywhere and get it deleted.
CELL_NUMBER = re.compile(r"^-?\d[\d,]*(?:\.\d+)?$")


def block_of(text):
    """Return (source_path, [lines]) for the first figures block, or (None, [])."""
    lines = text.splitlines()
    for i, line in enumerate(lines):
        m = START.search(line)
        if not m:
            continue
        body = []
        for line2 in lines[i + 1:]:
            if END.search(line2):
                return m.group(1), body
            body.append(line2)
        return m.group(1), body  # unterminated block: check what we have
    return None, []


def figures_in(body):
    """Numbers appearing in table cells, with the line they came from."""
    found = []
    for line in body:
        if "|" not in line:
            continue
        for cell in line.split("|"):
            cell = cell.strip()
            if CELL_NUMBER.match(cell):
                found.append((cell, line.strip()))
    return found


def source_values(path):
    """Every numeric value in the structured source, as floats."""
    values = set()
    with io.open(path, encoding="utf-8", errors="replace", newline="") as f:
        for row in csv.reader(f):
            for cell in row:
                cell = cell.strip().replace(",", "")
                try:
                    values.add(float(cell))
                except ValueError:
                    continue
    return values


def backed(figure, values):
    """True when some source value rounds to this figure at its own precision."""
    raw = figure.replace(",", "")
    try:
        target = float(raw)
    except ValueError:
        return True  # not numeric after all; nothing to verify
    decimals = len(raw.split(".")[1]) if "." in raw else 0
    return any(round(v, decimals) == round(target, decimals) for v in values)


def main(skill_path, root):
    text = io.open(skill_path, encoding="utf-8", errors="replace").read()
    source_rel, body = block_of(text)

    if source_rel is None:
        print(f"ok: {skill_path} declares no figures block")
        return 0

    source_path = f"{root}/{source_rel}"
    try:
        values = source_values(source_path)
    except OSError:
        print(f"VIOLATION: {skill_path}")
        print(f"  declared source does not exist: {source_rel}")
        return 2

    if not values:
        print(f"VIOLATION: {skill_path}")
        print(f"  declared source has no numeric values: {source_rel}")
        return 2

    unbacked = [(f, line) for f, line in figures_in(body) if not backed(f, values)]
    if unbacked:
        print(f"VIOLATION: {skill_path}")
        print(f"  {len(unbacked)} figure(s) not found in {source_rel}:")
        for f, line in unbacked:
            print(f"    {f}    <- {line}")
        return 2

    print(f"ok: {skill_path} — every figure traced to {source_rel}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2]))

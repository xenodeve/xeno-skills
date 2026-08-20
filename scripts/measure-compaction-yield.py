"""What compaction actually returns, measured from real sessions (docs/research/2026-08-21-compaction-yield.md).

Reads `~/.claude/projects/*/*.jsonl` and, for every `system`/`compact_boundary` record,
compares the TOTAL INPUT of the assistant turn before it with the one after it:

    input_tokens + cache_creation_input_tokens + cache_read_input_tokens

READING cache_read ALONE IS THE TRAP. A compaction moves tokens from cache_read into
cache_creation, so that one field falls far further than the context does -- which is how
the #305 write-up came to claim a 9 % reduction for a compaction that was pathological
anyway (9 K of conversation on a 41 K prefix).

Writes nothing. Only transcripts already on this machine are read.
"""
import glob
import json
import os
import statistics
import sys

MIN_BYTES = 200_000   # a transcript smaller than this has no long-session behaviour in it
BANDS = [
    ("context >= 500K", lambda b: b >= 500_000),
    ("250K - 500K", lambda b: 250_000 <= b < 500_000),
    ("150K - 250K", lambda b: 150_000 <= b < 250_000),
    ("context < 150K", lambda b: b < 150_000),
]


def total_input(usage):
    return ((usage.get("input_tokens") or 0)
            + (usage.get("cache_creation_input_tokens") or 0)
            + (usage.get("cache_read_input_tokens") or 0))


def pairs(root):
    """(before, after) for every compaction boundary found under root."""
    out = []
    for path in glob.glob(os.path.join(root, "*", "*.jsonl")):
        try:
            if os.path.getsize(path) < MIN_BYTES:
                continue
        except OSError:
            continue
        last, pending = None, None
        try:
            handle = open(path, encoding="utf-8", errors="replace")
        except OSError:
            continue
        with handle:
            for line in handle:
                if '"usage"' not in line and "compact_boundary" not in line:
                    continue
                try:
                    rec = json.loads(line)
                except ValueError:
                    continue
                if rec.get("type") == "system" and rec.get("subtype") == "compact_boundary":
                    pending = last
                    continue
                if rec.get("type") != "assistant":
                    continue
                usage = (rec.get("message") or {}).get("usage")
                if not usage:
                    continue
                size = total_input(usage)
                if size <= 0:
                    continue
                if pending:
                    out.append((pending, size))
                    pending = None
                last = size
    return out


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.claude/projects")
    rows = pairs(root)
    if not rows:
        print("no compaction boundaries found under", root)
        return 1

    print("compactions measured: %d" % len(rows))
    print("%-18s %5s %12s %14s %14s" % ("band", "n", "median drop", "median saved", "median after"))
    for label, pick in BANDS:
        band = [(b, a) for b, a in rows if pick(b)]
        if not band:
            print("%-18s %5d" % (label, 0))
            continue
        print("%-18s %5d %11.0f%% %14d %14d" % (
            label, len(band),
            statistics.median(100.0 * (b - a) / b for b, a in band),
            statistics.median(b - a for b, a in band),
            statistics.median(a for _, a in band)))

    grew = [(b, a) for b, a in rows if a >= b]
    print("\nmedian drop overall: %.0f%%   median context before: %d" % (
        statistics.median(100.0 * (b - a) / b for b, a in rows),
        statistics.median(b for b, _ in rows)))
    print("compactions that did NOT shrink the context: %d of %d (%.0f%%), all near the floor: %s"
          % (len(grew), len(rows), 100.0 * len(grew) / len(rows),
             sorted(b for b, _ in grew)[:6]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

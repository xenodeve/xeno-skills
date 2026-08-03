"""Extract per-endpoint (provider x model) records from the AA providers page.

The providers leaderboard is the only page carrying host-level fields — pricing,
cache-hit/write price, function-calling and JSON-mode support, and reasoning time
per endpoint. Model-level pages do not have them, so a routing decision that
depends on what an endpoint costs or supports cannot be made from those.

Method is the same one the rest of this set uses: decode the Next.js flight
payload and raw_decode objects out of it, rather than reading rendered charts —
charts show only the top rows, and transcribing them has produced fabricated
numbers before.
"""

import csv
import io
import json
import re
import sys

PUSH = re.compile(r'self\.__next_f\.push\(\[1,"((?:[^"\\]|\\.)*)"\]\)', re.S)
DECODER = json.JSONDecoder()
# Present on every endpoint row and essentially nowhere else on this page.
ANCHOR = re.compile(r'"hostApiId"\s*:')
BACK_WINDOW = 40000


def blob_from(path):
    html = io.open(path, encoding="utf-8", errors="replace").read()
    out = []
    for p in PUSH.findall(html):
        try:
            out.append(json.loads('"' + p + '"'))
        except ValueError:
            continue
    return "".join(out)


def records(blob):
    seen = set()
    for m in ANCHOR.finditer(blob):
        lo = max(0, m.start() - BACK_WINDOW)
        j = m.start()
        while j >= lo:
            if blob[j] == "{":
                try:
                    obj, end = DECODER.raw_decode(blob, j)
                except ValueError:
                    j -= 1
                    continue
                if isinstance(obj, dict) and end > m.start():
                    if (j, end) not in seen:
                        seen.add((j, end))
                        yield obj
                    break
            j -= 1


def flatten(obj, prefix=""):
    """One level of nesting is enough here; deeper values are lists of footnotes."""
    flat = {}
    for k, v in obj.items():
        key = f"{prefix}{k}"
        if isinstance(v, dict):
            flat.update(flatten(v, key + "."))
        elif isinstance(v, (list, tuple)):
            flat[key] = json.dumps(v, ensure_ascii=False) if v else ""
        else:
            flat[key] = v
    return flat


def main(page, out_csv, out_json):
    blob = blob_from(page)
    rows = []
    seen_ids = set()
    for obj in records(blob):
        flat = flatten(obj)
        ident = (flat.get("hostApiId"), flat.get("model.slug") or flat.get("slug"), flat.get("name"))
        if ident in seen_ids:
            continue
        seen_ids.add(ident)
        rows.append(flat)

    cols = []
    for r in rows:
        for k in r:
            if k not in cols:
                cols.append(k)

    with io.open(out_csv, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)
    json.dump(rows, io.open(out_json, "w", encoding="utf-8"), ensure_ascii=False)

    print(f"endpoint records: {len(rows)}")
    print(f"columns:          {len(cols)}")
    hosts = sorted({str(r.get("host")) for r in rows})
    print(f"distinct hosts:   {len(hosts)}")
    print("  " + ", ".join(hosts[:12]) + (" ..." if len(hosts) > 12 else ""))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])

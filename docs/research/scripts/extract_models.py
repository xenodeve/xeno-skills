"""Extract AA model records from the Next.js flight payload using raw_decode.

Charts render only the top ~25 rows; the page ships the whole dataset inline.
Reading it directly avoids the failure mode where an LLM asked to transcribe a
chart invents per-effort numbers for a model that only has one bar.
"""

import json
import re
import sys

DECODER = json.JSONDecoder()
# A field that reliably appears in a model row and rarely anywhere else.
ANCHOR = re.compile(r'"(intelligence_index|lcr|scicode|terminal_bench|gpqa)"\s*:')
BACK_WINDOW = 60000


def records(blob):
    seen_spans = set()
    for m in ANCHOR.finditer(blob):
        lo = max(0, m.start() - BACK_WINDOW)
        # nearest '{' at or before the anchor, walking outward
        j = m.start()
        while j >= lo:
            if blob[j] == '{':
                try:
                    obj, end = DECODER.raw_decode(blob, j)
                except ValueError:
                    j -= 1
                    continue
                if isinstance(obj, dict) and end > m.start():
                    span = (j, end)
                    if span not in seen_spans:
                        seen_spans.add(span)
                        yield obj
                    break
            j -= 1


def main(blob_path, out_path):
    blob = open(blob_path, encoding='utf-8', errors='replace').read()
    rows = []
    seen = set()
    for obj in records(blob):
        name = obj.get('name') or obj.get('model_name') or obj.get('slug')
        if not name:
            continue
        numeric = [k for k, v in obj.items() if isinstance(v, (int, float))]
        if len(numeric) < 3:
            continue
        key = (name, obj.get('slug'))
        if key in seen:
            continue
        seen.add(key)
        rows.append(obj)

    print('records:', len(rows))
    allkeys = set()
    for r in rows:
        allkeys |= {k for k, v in r.items() if isinstance(v, (int, float))}
    print('numeric fields:', len(allkeys))
    print(sorted(allkeys))
    print('--- sample names ---')
    for r in rows[:15]:
        print('  ', r.get('name'))
    json.dump(rows, open(out_path, 'w', encoding='utf-8'), ensure_ascii=False)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])

"""Decode a Next.js flight payload out of a saved AA page and survey its keys.

Written as a file rather than a heredoc: the payload regex needs literal
backslashes, and passing it through a shell heredoc corrupts the character class.
UTF-8 is set explicitly — the platform default on this machine is cp1252 and it
raises on the check marks these pages contain.
"""

import collections
import io
import json
import re
import sys

PUSH = re.compile(r'self\.__next_f\.push\(\[1,"((?:[^"\\]|\\.)*)"\]\)', re.S)
KEY = re.compile(r'"([a-zA-Z_][a-zA-Z0-9_]{2,40})"\s*:')


def blob_from(path):
    html = io.open(path, encoding="utf-8", errors="replace").read()
    parts = PUSH.findall(html)
    out = []
    for p in parts:
        try:
            out.append(json.loads('"' + p + '"'))
        except ValueError:
            continue
    return "".join(out), len(parts)


def main(page, out_blob):
    blob, n = blob_from(page)
    io.open(out_blob, "w", encoding="utf-8").write(blob)
    print(f"pushes={n}  blob_chars={len(blob)}")
    keys = collections.Counter(KEY.findall(blob))
    print("\n--- most common keys ---")
    for k, c in keys.most_common(40):
        print(f"  {c:6}  {k}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])

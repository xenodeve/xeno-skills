"""Derive each Cursor model's tunable parameters from `cursor-agent --list-models`.

There is no structured catalog to query: the CLI prints `id - Label` lines and the
knobs are encoded in the id suffixes. This peels the known suffix vocabulary off
each id and regroups, so you get the real per-model ladder instead of guessing.
"""

import os
import re
import subprocess
import sys
from collections import defaultdict

EFFORT = ["low", "medium", "high", "xhigh", "max"]
CLI = os.path.join(os.environ["LOCALAPPDATA"], "cursor-agent", "cursor-agent.cmd")

raw = subprocess.run([CLI, "--list-models"], capture_output=True, text=True).stdout

entries = []
for line in raw.splitlines():
    m = re.match(r"^\s*([a-z0-9][\w.\-]*)\s+-\s+(.+?)\s*$", line)
    if m:
        entries.append((m.group(1), m.group(2)))

if not entries:
    print("could not parse any models", file=sys.stderr)
    sys.exit(1)

models = defaultdict(lambda: {"effort": set(), "thinking": False, "fast": False,
                              "ctx": set(), "ids": 0})

for mid, label in entries:
    parts = mid.split("-")
    fast = thinking = False
    effort = None

    if parts and parts[-1] == "fast":
        parts.pop()
        fast = True
    if parts and parts[-1] in EFFORT:
        effort = parts.pop()
    if parts and parts[-1] == "thinking":
        parts.pop()
        thinking = True

    base = "-".join(parts)
    e = models[base]
    e["ids"] += 1
    if effort:
        e["effort"].add(effort)
    e["thinking"] |= thinking
    e["fast"] |= fast
    for ctx in re.findall(r"\b(\d+K|1M)\b", label):
        e["ctx"].add(ctx)

order = {v: i for i, v in enumerate(EFFORT)}
print(f"{'base model':<26} {'effort ladder':<34} {'ctx':<10} think fast  ids")
print("-" * 92)
for base in sorted(models):
    e = models[base]
    ladder = " < ".join(sorted(e["effort"], key=lambda x: order[x])) or "-"
    ctx = "/".join(sorted(e["ctx"])) or "-"
    print(f"{base:<26} {ladder:<34} {ctx:<10} "
          f"{'yes' if e['thinking'] else '-':<5} {'yes' if e['fast'] else '-':<5} {e['ids']}")

print(f"\n{len(entries)} model ids -> {len(models)} base models")

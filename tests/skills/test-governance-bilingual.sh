#!/usr/bin/env bash
# Every bilingual root-doc skeleton in governance-docs must carry both language
# markers. Guards the B9 regression: a skeleton shipped without <!-- lang:th -->
# (which happened to PRODUCT.md) so bootstrapped repos silently lose the mirror.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
F="$REPO_ROOT/skills/t4/t4-project-bootstrap/references/governance-docs.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

if python - "$F" <<'PY'
import sys, re
text = open(sys.argv[1], encoding="utf-8").read()
# Region = between one root-doc heading and the next (robust to the skeletons'
# own inner ### sub-headings and nested code fences).
order = ["CONTEXT.md", "UBIQUITOUS_LANGUAGE.md", "PRODUCT.md", "docs/agents/domain.md"]
pos = {}
for name in order:
    m = re.search(r'(?m)^### ' + re.escape(name) + r'\b', text)
    pos[name] = m.start() if m else -1
bad = []
for i, name in enumerate(order[:-1]):
    start, end = pos[name], pos[order[i+1]]
    if start < 0:
        bad.append(name + "(no heading)"); continue
    region = text[start:(end if end > start else len(text))]
    if "<!-- lang:en -->" not in region or "<!-- lang:th -->" not in region:
        bad.append(name)
print("MISSING:", ", ".join(bad) if bad else "none")
sys.exit(1 if bad else 0)
PY
then ok "CONTEXT / UBIQUITOUS_LANGUAGE / PRODUCT skeletons all carry lang:en + lang:th"
else bad "a root-doc skeleton is missing its language markers (B9 regression)"; fi

echo ""
echo "governance-bilingual: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

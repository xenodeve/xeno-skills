#!/usr/bin/env bash
# What the bootstrap says to do when CI cannot run at all.
#
# THIS IS NOT A HYPOTHETICAL CONFIGURATION. PRD #129 records it in this very repo:
# every workflow run fails at provisioning with "the job was not started because your
# account is locked due to a billing issue", so the branch ruleset has no required
# checks attached and Tier 3 cannot catch what Tier 0 misses.
#
# AND THE DOCUMENT'S EXISTING ADVICE MADE IT WORSE. The section above the new one is
# for a repo whose ruleset cannot be enforced but whose workflows still RUN, and its
# fallback is `requireGreenCI: true`. Applied to a repo where nothing runs, that denies
# every merge forever — `gh pr checks` reports non-zero for "no checks" exactly as it
# does for "failing" — which is a deadlock wearing a guard's clothing.
#
# The assertions read only the NEW section, extracted by heading. The file is long and
# says "requireGreenCI" in four other places; a whole-file grep would pass on any of
# them and prove nothing about the advice that was added.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOC="$REPO_ROOT/skills/t4/t4-project-bootstrap/references/ci-cd-layer.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

SECTION="$(mktemp)"; trap 'rm -f "$SECTION"' EXIT
python - "$DOC" "$SECTION" <<'PY'
import re, sys
doc = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"^## When CI cannot run at all.*?(?=^## )", doc, re.M | re.S)
open(sys.argv[2], "w", encoding="utf-8").write(m.group(0) if m else "")
PY
has()   { case "$(cat "$SECTION")" in *"$1"*) ok "$2";; *) bad "$2 (missing: $1)";; esac; }
hasnt() { case "$(cat "$SECTION")" in *"$1"*) bad "$2 (found: $1)";; *) ok "$2";; esac; }

[ -s "$SECTION" ] && ok "the section exists and is its own heading" \
                  || bad "no 'When CI cannot run at all' section — every assertion below is vacuous"

echo ""
echo "it is distinguished from the section it sits next to, which advises the opposite:"
has "billing" "it names the condition — a locked billing account"
has "requireGreenCI" "it addresses requireGreenCI"
has "off" "and says to turn it OFF"
has "deadlock" "because leaving it on denies every merge — stated as the deadlock it is"

echo ""
echo "the compensations are specific, not 'be careful':"
has "e2e"             "1. the local verify has to widen — e2e otherwise has no home at all"
has "core.hooksPath"  "2. the pre-push guards are made to actually bind, not merely installed"
has "direct pushes"   "3. the half of the ruleset that needs no check is still installed"
has "ledger"          "4. the state is written where the next agent reads it"
has "issue"           "5. the restoration is a tracked item rather than a memory"
has "T4-Gates"        "6. the gate trailer becomes the only record that judgment gates ran"

echo ""
echo "and the ceiling is stated rather than implied:"
has "merging on the web" "it says what none of this can bind"
# THE NEGATIVE THIS SECTION IS MOST AT RISK OF. A list of six compensations reads as
# cover; the one thing that must not be claimed is that it restores what was lost.
# `equivalent` is the word the neighbouring section already uses to refuse the same
# claim, so it is the asserted form here, not an invented one.
hasnt "is equivalent" "it never claims the compensations equal a required check"

echo ""
echo "ci-unavailable-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

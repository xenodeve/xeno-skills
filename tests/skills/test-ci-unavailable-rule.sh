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
echo "it names the PROPERTIES CI provided, so a compensation can be checked against one:"
has "a clean machine"          "clean machine"
has "unconditional execution"  "unconditional execution"
has "cannot forge"             "a result the author cannot forge"

echo ""
echo "the compensations are MECHANISMS, and the mechanisms come first:"
# The version this replaced had three of six compensations be "write it down". A
# paragraph in CLAUDE.md has never caught a defect, and the developer said so.
has "runs nowhere at all"  "1. a CI-only suite is named as running NOWHERE, not as running slower"
has "skill-discovery"      "   and this repo's own CI-only suite is named"
has "fast prefix"          "2. verify widens, because the slow half it deferred to is gone"
has "no tests"             "3. pre-push is called out for running the guards and no tests"
has "false"                "   and its own message about CI is called false, since it is"
has "git worktree add"     "4. a clean-checkout run, which is the property nothing else recovers"
has "talked round"         "5. review becomes the only independent check left"
has "fail on purpose"      "6. the local gate is probed, since nothing else disagrees with it now"
python - "$SECTION" <<'PYX'
import sys
sec = open(sys.argv[1], encoding="utf-8").read()
# Order is the claim: mechanisms before paperwork. If the write-it-down paragraph
# migrates back above the numbered list, the section has quietly become the old one.
mech = sec.find("runs nowhere at all")
paper = sec.find("Then, and only then, write it down")
assert mech != -1 and paper != -1, "an anchor is missing"
assert mech < paper, "the recording advice moved ahead of the mechanisms again"
PYX
[ $? -eq 0 ] && ok "   and the write-it-down advice sits AFTER them, not among them"              || bad "recording advice is back among the mechanisms"

echo ""
echo "the recording half is kept, but demoted rather than deleted:"
has "direct pushes"   "the half of the ruleset that needs no check is still installed"
has "ledger"          "the state is written where the next agent reads it"
has "not a memory"    "the restoration is a tracked item rather than a memory"
has "T4-Gates"        "the gate trailer is where the review is recorded"

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

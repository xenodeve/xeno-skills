#!/usr/bin/env bash
# Section 3 covers COMPLETING something incomplete, and disclosure is not authorisation (#136).
#
# A documentation-integrity suite, and labelled one. #136 asks for a NARROWNESS FIX --
# one or two lines per point, not a rewrite -- so this pins the three additions and
# nothing about the section's shape.
#
# WHAT HAPPENED, measured. Editing a preset list in pal-mcp-server to add opencode.json,
# an agent noticed cursor.json had NEVER been added to that list, added it too, and
# disclosed the addition in the PR body. Section 3's own test - "every changed line
# should trace directly to the user's request" - forbids it, and the section did not
# reach the case because its bullets name improving, refactoring and deleting.
#
# THE GAP LOOKS LIKE AN ERROR, WHICH IS WHY IT IS DIFFERENT IN KIND. Improving adjacent
# code feels like a choice; finishing an obviously unfinished list feels like a fix. The
# rule has to say so or the reader does not recognise the case as covered.
#
# AND DISCLOSURE WAS READ AS AUTHORISATION. Saying it in the PR body made it visible,
# not requested - the reviewer now has to reject it rather than never see it.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
KG="$REPO_ROOT/skills/karpathy-guidelines/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

[ -f "$KG" ] && ok "karpathy-guidelines is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "COMPLETING IS COVERED, alongside improving and deleting:"
has "$KG" "mention it - don't complete it" "the incomplete case has its own bullet"
has "$KG" "the gap looks like an error" "and why it is not recognised as the same move"

echo ""
echo "DISCLOSURE IS NOT AUTHORISATION — the sentence that closes the loophole used:"
has "$KG" "does not authorise it" "disclosure is refused as a licence"
has "$KG" "visible, not requested" "with what it actually buys"

echo ""
echo "the trace test is not limited to code by its wording:"
has "$KG" "code, config, docs and lists alike" "the scope is spelled out"

echo ""
echo "AND IT STAYED A NARROWNESS FIX — #136 asks for one or two lines per point:"
python - "$KG" <<'PY'
import sys
doc = open(sys.argv[1], encoding="utf-8").read()
i = doc.find("## 3. Surgical Changes")
j = doc.find("## 4. Goal-Driven Execution")
assert i != -1 and j > i, "section 3 boundaries not found"
body = doc[i:j]
# Three additions were asked for. A section that has grown past ~30 lines has been
# rewritten rather than narrowed, which is what #136 explicitly did not want.
n = len([l for l in body.splitlines() if l.strip()])
assert n <= 30, "section 3 is now %d non-empty lines -- this was a narrowness fix" % n
PY
[ $? -eq 0 ] && ok "section 3 is still a short section, not a rewritten one" \
             || bad "section 3 grew past a narrowness fix"

echo ""
echo "surgical-completion-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

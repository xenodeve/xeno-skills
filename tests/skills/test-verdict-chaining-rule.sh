#!/usr/bin/env bash
# A verdict you RUN is checked by nothing, and shell chaining is where it escapes (#297).
#
# A documentation-integrity suite, and labelled one. It asserts a SHAPE, not a phrase:
# the corrected form must read the precondition as its own step, and must not join it to
# the action with `&&`. That is the difference the rule is about.
#
# MEASURED, 2026-08-19. `gh issue close 132 --reason completed` fired TWICE while its pull
# request was unmerged. Both times it sat in the same command block as a `gh pr merge`
# that had just printed `Pull Request has merge conflicts`, then `not mergeable` -- and
# both times it was joined by `&&` to a DIFFERENT command's success, so it ran.
#
# THE ARTIFACT EXISTED AND WAS NEVER READ. This is not a missing check; it is a check
# whose output scrolled past because the next command was already queued. #233 landed the
# same day and says an ACTION verdict carries the action's own preconditions -- the rule
# was merged hours before this happened, twice.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WF="${1:-$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md}"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$WF" ] && ok "the skill under test is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE DISTINCTION IS STATED — a verdict you run is not checked by a reader:"
has "$WF" "a verdict you *run*" "running a verdict is named as a verdict"
has "$WF" "queues the next line" "and the mechanism is the block, not the command"

echo ""
echo "the measurement is on the page, because twice is not bad luck:"
has "$WF" "fired twice while its PR was unmerged" "the occurrence count"
has "$WF" "not mergeable" "and what the ignored output actually said"

echo ""
echo "IT IS TIED TO THE RULE IT ESCAPES, not left as a separate tip:"
has "$WF" "action's own preconditions" "the #233 rule is the one being escaped"

echo ""
echo "AND THE CORRECTED SHAPE IS A SHAPE — this is the assertion that bites:"
python - "$WF" <<'PYX'
import re, sys
doc = open(sys.argv[1], encoding="utf-8").read()
i = doc.find("read that output as its own step")
assert i != -1, "the operative sentence is missing"
# The corrected form is shown somewhere in the rule's own section.
sect = doc[max(0, i - 2500): i + 1500]
view = sect.find("gh pr view")
close = sect.find("gh issue close", view if view != -1 else 0)
assert view != -1, "the verification command is not shown"
assert close != -1 and close > view,     "the close is not shown AFTER the read that licenses it"
between = sect[view:close]
assert "&&" not in between,     "the corrected form joins the read to the action with && -- that IS the defect"
PYX
[ $? -eq 0 ] && ok "the read comes first and is not chained to the action"              || bad "the corrected shape does not demonstrate the rule"

echo ""
echo "THE NEGATIVE THAT CARRIES IT — chaining must not be presented as acceptable:"
hasnt "$WF" "chaining the close is fine" "it does not license the chained form"

echo ""
echo "verdict-chaining-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

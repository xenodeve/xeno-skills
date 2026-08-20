#!/usr/bin/env bash
# Intake: which gaps in a DEVELOPER DIRECTIVE may be asked about, and when (#301).
#
# A documentation-integrity suite, and labelled one. NO MECHANISM IS ADDED -- nothing
# can check whether an agent asked a good question; what a test can hold is the BAR,
# and this one asserts the bar as a shape rather than as a slogan.
#
# WHY A BAR AND NOT A PROMPT. t4-afk records that the over-asking failure has NO
# NATURAL CORRECTIVE SIGNAL: a guess produces a visible wrong artifact and somebody
# says so, while an unnecessary question produces a polite list that reads as
# diligence. A rule that says "ask more" without a ceiling makes the agent worse, so
# the ceiling is the part under test -- two askable slots, three refused, and a
# sentence that has to be finishable before a question is allowed out.
#
# MEASURED, 2026-08-20, in the session that wrote it. The directive was "is it possible
# to use CRISPE with xeno-skills" and the answer went to the DELEGATION layer. The next
# message said the prompt meant was the one between the dev and the master agent. One
# unasked slot cost a whole turn.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WF="${1:-$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md}"
UT="${2:-$REPO_ROOT/skills/t4/using-t4/SKILL.md}"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$WF" ] && ok "t4-dev-workflow is present" || { bad "the workflow skill is missing"; exit 1; }
[ -f "$UT" ] && ok "using-t4 is present" || { bad "the map is missing"; exit 1; }

echo ""
echo "THE INPUT THAT HAD NO CONTRACT — the reason the rule exists at all:"
has "$WF" "capacity/role" "the five slots are named in CRISPE terms"
has "$WF" "only input to this repo with no contract" "the directive is named as the ungoverned input"

echo ""
echo "the measurement is on the page, because one unasked slot cost a turn:"
has "$WF" "which layer" "the slot that was missed"

echo ""
echo "THE CEILING IS THE POINT — two askable, three refused, each with its reason:"
python - "$WF" <<'PYX'
import sys
doc = open(sys.argv[1], encoding="utf-8").read()
i = doc.find("| **C — capacity/role**")
assert i != -1, "the CRISPE table is missing"
table = doc[i:doc.find("\n\n", i)]
rows = [r for r in table.splitlines() if r.startswith("|")]
assert len(rows) == 5, "the table does not carry exactly five slots: %d" % len(rows)
askable = [r for r in rows if "**yes**" in r]
assert len(askable) == 2, "exactly two slots must be askable, found %d" % len(askable)
for name in ("personality", "experiment"):
    row = [r for r in rows if name in r.lower()]
    assert row, "the %s row is gone" % name
    assert "never" in row[0].lower(), \
        "%s is no longer refused -- the ceiling is what this rule IS" % name
PYX
[ $? -eq 0 ] && ok "five slots, exactly two askable, personality and experiment refused" \
             || bad "the askable set has drifted — that is the rule, not a detail"
has "$WF" "it is a cost call you make" "and the refusal of *experiment* carries its reason"

echo ""
echo "THE SENTENCE THAT MUST BE FINISHABLE BEFORE A QUESTION IS ALLOWED OUT:"
has "$WF" "the two readings produce materially different work" "the two-readings test is stated"
has "$WF" "take the simpler one and" "and its failure branch is act, not ask"
has "$WF" "a read is not a question" "a gap the repo already answers is not a gap"

echo ""
echo "THE MOMENT IS THE AGENT'S — that is what the developer asked for:"
has "$WF" "before the first action that commits" "the deadline is an action, not a phase"
has "$WF" "one per directive" "one ask per directive"
has "$WF" "not a drip" "and it is one batch"

echo ""
echo "AND UNATTENDED THERE IS NO ASK, or the batch stops being unattended:"
has "$WF" "Under AFK there is no ask" "AFK behaviour is stated"

echo ""
echo "THE BRAKE IS CITED, NOT PARAPHRASED AWAY — the asymmetry is why this is dangerous:"
has "$WF" "no natural corrective signal" "the t4-afk asymmetry is quoted"
has "$WF" "makes the agent worse" "and what an unbounded version of this rule would do"

echo ""
echo "THE NEGATIVE THAT CARRIES IT — a five-question interview is the failure, not the rule:"
hasnt "$WF" "ask for whatever the directive does not say" "it does not license a blanket interview"

echo ""
echo "the cross-cutting half reaches the agent, since using-t4 is what gets injected:"
has "$UT" "only *insight* and *statement* are askable" "using-t4 carries the one-line rule"

echo ""
echo "crispe-intake-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

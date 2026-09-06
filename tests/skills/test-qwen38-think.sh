#!/usr/bin/env bash
# `qwen38-think` (#357, slice 2 of #355): the thinking a small model skips,
# turned into two tables it must write before the first edit and one line
# when stuck. The pair runs in the tuning repo against fixtures/think-task-1..3
# (a contradiction, a missing fact, an impossible ask). This test pins:
#
#   - the tables come BEFORE building, and doing them after is named as a fail;
#   - each flaw row is checked by a command, not judged from the brief's text;
#   - pushback is a written line and the work continues — never a question
#     that stops the run (the developer is not at the keyboard);
#   - the stuck procedure is three fixed lines and the missing-tool escape;
#   - the family rule against installing/searching/spawning is restated here,
#     because this is the skill most likely to send the model looking.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
THINK="$REPO_ROOT/skills/qwen38/qwen38-think/SKILL.md"
ROUTER="$REPO_ROOT/skills/qwen38/using-qwen38/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if [ -f "$1" ] && grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }
hasnt() { if [ -f "$1" ] && ! grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "the skill exists, names its model, and is routed:"
[ -f "$THINK" ] && ok "skills/qwen38/qwen38-think/SKILL.md exists" || bad "the skill is missing"
has "$THINK" "target-model: Qwen3.8-27B" "declares target-model"
has "$ROUTER" "qwen38-think" "using-qwen38 loads qwen38-think"

echo "the tables come first, and after is a fail:"
has "$THINK" "Before the first edit, write the two tables" "the order is stated"
has "$THINK" "Doing the work first and the tables after is a fail" "the wrong order is named as a fail"
has "$THINK" "| open in the brief | the assumption you take | why this one |" "the assumptions table"
has "$THINK" "Take the assumption; do not ask." "assumptions are taken, not asked"

echo "three flaw types, each checked by a command:"
has "$THINK" "**contradiction**" "flaw 1"
has "$THINK" "**missing fact**" "flaw 2"
has "$THINK" "**impossible ask**" "flaw 3"
has "$THINK" "| flaw type | what you looked for | the command you ran | found? |" "each row carries the command run"

echo "pushback is a line, and the work goes on:"
has "$THINK" "do not stop, do not ask, do not invent the missing thing" "the three prohibitions"
has "$THINK" "Pushback:" "the line's exact prefix"
has "$THINK" "build the part that stands" "the work continues"
has "$THINK" "instead of" "a question asked INSTEAD of the work is what is forbidden"
has "$THINK" "unattended run" "the never-ask rule is scoped to an unattended run (review 2026-09-06: unscoped, it told the developer's own interactive sessions to stay silent)"
has "$THINK" "interactive session" "and an interactive session may ask once the report is delivered"
hasnt "$THINK" "ask the user" "never tells the model to ask the user"

echo "the stuck procedure and the escape:"
has "$THINK" "Observed:" "line 1"
has "$THINK" "Hypothesis:" "line 2"
has "$THINK" "Falsify:" "line 3"
has "$THINK" "never install, never search for an alternative, never spawn an agent" "the escape, restated here"

echo "the report line and the boundary:"
has "$THINK" "THINK: assumptions" "the report line"
has "$THINK" "**first** line of the final report" "the THINK line comes first, before any gate line"
has "$THINK" "What this does not touch" "the boundary"

echo
echo "qwen38-think: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# An agentic agent told not to read files is `chat` with worse latency (#137).
#
# A documentation-integrity suite, and labelled one. NO ENFORCEMENT IS ADDED and #137
# asks for none.
#
# WHY IT IS A THIRD STATE AND NOT A MISTAKE. The skill's chat-vs-agentic rule frames the
# choice as WHICH CLIENT, so a reader satisfies it by picking the agentic one -- and then
# "Do NOT read files; everything you need is below" reproduces chat's blindness while
# paying the CLI bootstrap. The rule was followed and the outcome was the worst cell.
#
# MEASURED, one round, same question, same models, 2026-08-11. Blind, all three designed
# a transport-neutral authorization platform and a pre-publication claim checker, NEITHER
# OF WHICH CAN EXIST HERE. One agent then ignored the instruction, read eleven files
# (351s, 426k input tokens), withdrew its own enforcement phase citing that architectural
# fact, and produced the cost ranking that replaced the plan.
#
# AND THE INSTRUCTION CAME FROM THE SKILL'S OWN FEASIBILITY ADVICE -- suppressing reads
# is the obvious way to stay under a 60-120s transport ceiling. Two pieces of advice
# conflicting on a codebase question, with nothing saying which wins, is the defect.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BS="$REPO_ROOT/skills/multi-agent/clink-brainstorm/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

[ -f "$BS" ] && ok "clink-brainstorm is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE STATE IS NAMED — a failure with no name is one a reader cannot recognise:"
has "$BS" "worse latency" "the blinded-agentic state is named"
has "$BS" "The third state" "and marked as distinct from both the others"

echo ""
echo "the evidence is on the page, or it reads as a preference between two setups:"
has "$BS" "neither can exist in this repository" "what the blind round produced"
has "$BS" "351" "and the read round that replaced it"

echo ""
echo "THE CONFLICT IS RESOLVED, WITH ONE NAMED AS WINNING — #137's central ask:"
has "$BS" "the codebase rule wins" "the winner is stated outright"
has "$BS" "expecting" "and the alternative handling of a long round"

echo ""
echo "and suppressing reads is a stated decision, not a default:"
has "$BS" "say so in the prompt as a decision" "the deliberate case must be written down"
has "$BS" "deliberate choice from an unexamined default" "with the reason it has to be"

echo ""
echo "THE RULE IT SITS BESIDE IS INTACT — this adds a state, it does not replace the choice:"
has "$BS" "use the agentic \`clink\` agent, not \`chat\`" "the original chat-vs-agentic rule is still there"

echo ""
echo "blinded-agentic-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

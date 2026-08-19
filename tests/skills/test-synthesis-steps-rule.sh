#!/usr/bin/env bash
# The synthesis says which loop steps ran, and a waiver is disclosed (#138).
#
# A documentation-integrity suite, and labelled one. NO MECHANISM IS ADDED and #138
# refuses one explicitly -- nothing can inspect an orchestrator's process from outside.
#
# WHAT HAPPENED, measured 2026-08-11. The adversarial round found real dissent by any
# reading: ALL THREE PANELLISTS REVERSED, each on a different axis. The stop condition
# requires a resolving round in that case. It was never run; the orchestrator synthesised
# and recommended directly, and two panellists ended in DIRECT CONTRADICTION without
# being made to meet -- "pre-execution interception is the wrong layer" against "the
# matcher change is the cheap, correct fix and should be done first".
#
# THE RESOLVING ROUND IS THE ONLY STEP WHOSE ABSENCE LOOKS LIKE ITS COMPLETION, because
# its output would have been folded into the same synthesis. Every other step leaves
# something behind. That is why the fix is an artifact and not an exhortation.
#
# AND THE RESOLUTION WAS PROBABLY RIGHT. The orchestrator held a fact neither panellist
# had -- a merge through mcp__github__merge_pull_request produces no local git push, so
# a pre-push hook can never observe it. A documented step replaced by private judgment,
# undisclosed, is the shape clink-debug already refuses.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BS="$REPO_ROOT/skills/multi-agent/clink-brainstorm/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

[ -f "$BS" ] && ok "clink-brainstorm is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE SYNTHESIS CARRIES AN ARTIFACT — an exhortation would have the same failure mode:"
has "$BS" "states which loop steps ran" "the requirement is stated"
has "$BS" "ran or skipped-with-reason" "and what each entry must say"
has "$BS" "absence looks identical to its completion" "with why this step and not the others"

echo ""
echo "REVERSAL ON DIFFERENT AXES IS ITS OWN CASE — it reads as agreement and is not:"
has "$BS" "not dissent against a consensus" "it is distinguished from ordinary dissent"
has "$BS" "the wrong layer" "and the contradiction that stood is quoted"

echo ""
echo "the waiver is permitted AND conditioned — #138 asks for both halves:"
has "$BS" "may be waived" "waiving is allowed"
has "$BS" "named in the synthesis" "only if the waiver and its evidence are disclosed"

echo ""
echo "AND THE PRECEDENT IS CITED, so the discipline is not new here:"
has "$BS" "hypothesis wearing a verdict" "clink-debug's same-shaped refusal is quoted"

echo ""
echo "the stop condition itself is intact — this adds disclosure, it does not replace the step:"
has "$BS" "run one normal challenge loop round" "the resolving round is still required"

echo ""
echo "synthesis-steps-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

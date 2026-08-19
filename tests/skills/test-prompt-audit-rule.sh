#!/usr/bin/env bash
# Audit the prompt before the round, not the answers after it (#131).
#
# A documentation-integrity suite, and labelled one. NO ENFORCEMENT IS ADDED and #131
# asks for none -- nothing can read a prompt and decide whether it is leading.
#
# WHAT HAPPENED, measured. On 2026-08-11 a round asked whether a change was "the right
# next move, or displacement activity while the mechanism has four known bypasses", and
# attached Major/security to the competing option. Three agents on three model families
# converged on displacement. The forced adversarial round fired correctly and ALL THREE
# REVERSED; one wrote back  "self_critique": "I walked into the offered displacement
# slot"  and named the cause: "three panellists under that frame 'independently'
# choosing B is not triangulation."
#
# WHY THE AUDIT GOES IN STEP 1 AND NOT IN THE CONVERGENCE SECTION. That section says
# "given the same prompt framing" in passing and then never asks anyone to look at the
# prompt -- every downstream step applies pressure AFTER the answers exist. Recovery
# worked and cost a full extra round. Before the call, a rewrite is free.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BS="$REPO_ROOT/skills/multi-agent/clink-brainstorm/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

[ -f "$BS" ] && ok "clink-brainstorm is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE AUDIT IS IN STEP 1 — before the call, where a rewrite is still free:"
python - "$BS" <<'PY'
import sys
doc = open(sys.argv[1], encoding="utf-8").read()
i = doc.find("1. **Write one precise question/proposal**")
assert i != -1, "step 1 is missing"
j = doc.find("2. **Fire agents in parallel**")
assert j != -1 and j > i, "step 2 is missing"
step1 = doc[i:j]
assert "Audit the prompt before it is sent" in step1, "the audit is not inside step 1"
PY
[ $? -eq 0 ] && ok "the audit sits inside step 1, ahead of firing" \
             || bad "the audit is absent from step 1 — after the call it is a different check"

echo ""
echo "the two specific defects are named, not 'be neutral':"
has "$BS" "supply one of the candidate answers as a phrase" "supplying a candidate answer"
has "$BS" "Does it label one option" "and labelling one option"

echo ""
echo "IT IS ANSWERABLE — a question you can only answer by judgement is not an audit:"
has "$BS" "Would a reader who saw only this prompt know which answer you wanted" "the decisive question is stated"

echo ""
echo "and it says what to do when the audit FAILS, including the honest fallback:"
has "$BS" "rewrite and re-fire" "the first answer is to fix the prompt"
has "$BS" "convergence unverified" "and the caveat when a rewrite is impossible"

echo ""
echo "THE TWO SECTIONS REFERENCE EACH OTHER, so neither reads as the whole answer:"
has "$BS" "The prompt audit in step 1 is this section's other half" "convergence points at the audit"
has "$BS" "the half the forced adversarial round cannot supply" "and the audit points back"

echo ""
echo "prompt-audit-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

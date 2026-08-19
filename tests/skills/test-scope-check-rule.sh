#!/usr/bin/env bash
# Scope the terms the answer turns on — a neutral prompt can still be under-specified (#160).
#
# A documentation-integrity suite, and labelled one. NO MECHANISM IS ADDED.
#
# WHAT HAPPENED, measured 2026-08-13. A round judged a plan for a review agent whose job
# was described as "asks whether the invoked skills' RULES WERE FOLLOWED". Three agents
# on different model families ALL resolved that toward OUTCOME -- is the resulting code
# good -- correctly concluded that session history cannot establish outcome, and two of
# them refused to build parts of the design. The developer rejected it in one sentence:
# the reviewer checks whether the prescribed WORKFLOW was followed; code quality is CI's
# job.
#
# THE PANEL WAS NOT WRONG ABOUT THE QUESTION IT ANSWERED. It answered a different one.
#
# WHY THIS IS NOT #131. That one records a LEADING prompt -- an answer supplied as a
# phrase, an option pre-labelled -- so convergence measured the frame. This is the
# opposite: nothing was supplied, a scope word was left undefined, and the panel filled
# it in. A prompt can be scrupulously neutral and still under-specified.
#
# AND THE TELL IS THAT THERE IS NO TELL. That prompt carried measured constraints, file
# paths, three named options and a word count. Unanimous agreement on the wrong reading
# looks exactly like unanimous agreement.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BS="$REPO_ROOT/skills/multi-agent/clink-brainstorm/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

[ -f "$BS" ] && ok "clink-brainstorm is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE CHECK IS ON THE TERMS, not on the prompt's overall quality:"
has "$BS" "scope the terms the answer turns on" "the check is stated"
has "$BS" "would two competent readers scope it the same way" "and it is answerable"

echo ""
echo "it is distinguished from the leading-prompt audit, which is a different defect:"
has "$BS" "catches one that supplies none" "the two checks are told apart"

echo ""
echo "THE MEASUREMENT, and the sentence that makes it more than an anecdote:"
has "$BS" "rules were followed" "the ambiguous phrase is quoted"
has "$BS" "It answered a different one" "with what the panel actually did"

echo ""
echo "AND THE TELL IS THAT THERE IS NO TELL — the reason a reader cannot catch it later:"
has "$BS" "no tell" "the absence of a signal is stated"
has "$BS" "looks exactly like unanimous agreement" "with what it is mistaken for"

echo ""
echo "the existing instruction is kept — precision was never the thing missing:"
has "$BS" "Write one precise question/proposal" "step 1's original wording stands"
has "$BS" "precision was never the thing missing" "and is explicitly not blamed"

echo ""
echo "it sits inside step 1, where a rewrite is still free:"
python - "$BS" <<'PY'
import sys
doc = open(sys.argv[1], encoding="utf-8").read()
i = doc.find("1. **Write one precise question/proposal**")
j = doc.find("2. **Fire agents in parallel**")
assert i != -1 and j > i, "step boundaries not found"
assert "scope the terms the answer turns on" in doc[i:j], "the scope check is not inside step 1"
PY
[ $? -eq 0 ] && ok "the scope check is inside step 1, before the round is fired" \
             || bad "it landed outside step 1 — after the call it is a different check"

echo ""
echo "scope-check-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

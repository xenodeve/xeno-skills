#!/usr/bin/env bash
# A red must fail for the reason the test names (#132).
#
# A documentation-integrity suite, and labelled one. NO ENFORCEMENT IS ADDED and #132
# asks for none: nothing can read an assertion and decide what it is ABOUT.
#
# WHAT HAPPENED, measured. Building check-issue-ref test-first on 2026-08-11 the RED
# PASSED against a MISSING FILE -- sh exits non-zero when it cannot open a script, so
# every assertion downstream of "it exited non-zero" was satisfied by the absence of the
# thing under test. The second assertion, "the message names what is missing", matched
# on the word `issue` because the interpreter's error contains the path, and the script
# is called check-issue-ref. The test was reading its own filename.
#
# AND THE SAME TRAP RUNS THE OTHER WAY, seen 2026-08-19 in this repo: a fixture built
# with json.dump to prove a control byte is stripped could not emit a raw ESC, so the
# assertion passed against a file that never contained the attack. A green that was
# never capable of red is the same defect from the other side.
#
# PLACEMENT, which #132 asked to settle first: the general case lives here, and the
# DELEGATED case stays in clink-masteragent. This suite asserts the pointer exists
# rather than the restatement, because two scattered copies is what the repo's
# reconcile-don't-duplicate rule forbids.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WF="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"
MA="$REPO_ROOT/skills/multi-agent/clink-masteragent/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$WF" ] && ok "t4-dev-workflow is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE RULE, and it is about reading rather than about exit codes:"
has "$WF" "A non-zero exit is not a red" "an exit code alone is refused"
has "$WF" "Read the failure output" "and reading it is the instruction"

echo ""
echo "both generators are named — one is not enough to recognise the second:"
has "$WF" "missing file" "the harness reporting the failure"
has "$WF" "path leaks into the assertion" "and the path leaking into the assertion"

echo ""
echo "THE CORRECTION IS A RULE, not a warning:"
has "$WF" "assert on something only the implementation can emit" "the positive instruction is stated"

echo ""
echo "the mirror case is here too, because a green that cannot fail is the same defect:"
has "$WF" "never capable of red" "an assertion that cannot fail is named"
has "$WF" "positive controls" "and the probe that catches it"

echo ""
echo "PLACEMENT — the delegated case is POINTED AT, not restated (#132's own condition):"
has "$WF" "clink-masteragent" "the delegated case is referred to"
has "$WF" "not restated here" "and explicitly not duplicated"
hasnt "$WF" "A delegated green is not a green" "the masteragent paragraph is not copied in"
has "$MA" "A delegated green is not a green" "and it still lives where it was"

echo ""
echo "AND NO ENFORCEMENT IS CLAIMED:"
has "$WF" "No enforcement is added" "the absence of a mechanism is stated"

echo ""
echo "red-reason-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

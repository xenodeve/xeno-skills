#!/usr/bin/env bash
# Retarget a stacked PR before merging its parent (#133).
#
# A documentation-integrity suite, and labelled one: it detects deletion and softening
# of the rule. NO HOOK ENFORCES THIS and the issue asks for none -- the gate sees one
# prospective tool call and cannot know another PR is stacked on the branch this one
# deletes, which would cost a network call it has no budget for.
#
# WHAT HAPPENED, measured. 2026-08-11: three PRs open, #41 based on #35's branch.
# Merging #35 with --delete-branch removed feat/root-cause-first, GitHub closed #41,
# and BOTH recovery paths failed -- reopen returned "Could not open the pull request"
# and retargeting returned "Cannot change the base branch of a closed pull request".
#
# THE TWO FAILURES ARE ONE WALL, which is why the rule is about ORDER and not about
# recovery: a closed PR's base is immutable so it cannot be retargeted, and it cannot be
# reopened because its base branch is gone. The review history is stranded.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WF="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$WF" ] && ok "t4-dev-workflow is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "THE ORDER IS THE RULE — retarget first, merge second:"
has "$WF" "Retarget every child to \`main\` first" "the child is retargeted before the parent merges"
has "$WF" "gh pr edit <child> --base main" "and the command is given, not described"

echo ""
echo "the irreversibility is named, or the order reads as a preference:"
has "$WF" "not reversible" "the close is stated as irreversible"
has "$WF" "Cannot change the base branch of a closed pull request" "with the error that proves it"
has "$WF" "Could not open the pull request" "and the reopen that also fails"

echo ""
echo "THE RECOVERY PATH IS STATED, because the first reader of this will already be past it:"
has "$WF" "replacement" "a replacement PR is named"
has "$WF" "reference the closed one" "and the reference that keeps the history findable"

echo ""
echo "AND NO ENFORCEMENT IS CLAIMED — #133 asks for none, and a false claim is worse:"
has "$WF" "No hook enforces this" "the absence of a mechanism is stated outright"
hasnt "$WF" "the gate blocks a stacked merge" "no hook is claimed to catch it"

echo ""
echo "stacked-pr-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# The anti-sticking rule failed silently once already (#78): the guidance existed,
# the agent consulted it, and four already-decided items were escalated anyway.
# What was missing was a test you must PASS to park, rather than a list to consult
# — and the reason it drifts is that over-asking produces no corrective signal, so
# nothing pushes the bar back up on its own. These assertions are that pressure.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AFK="$REPO_ROOT/skills/t4/t4-afk/SKILL.md"
REF="$REPO_ROOT/skills/t4/t4-afk/references/afk-artifacts.md"
MAP="$REPO_ROOT/skills/t4/using-t4/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "a park must pass a written test, not a consulted list:"
has "$AFK" "This is unresolved because the plan does not say" "the two-blank park sentence is stated verbatim"
has "$AFK" "and it is the developer's because"                "its second blank is stated too"
has "$AFK" "cannot be filled with a quotation from the plan"  "blank one fails closed toward acting"

echo
echo "the three cases the old checklist had no entry for:"
has "$AFK" "for the implementer"        "a plan that ASSIGNS a question has decided it"
has "$AFK" "are assignments, not deferrals" "the trigger phrases are named as assignments"
has "$AFK" "invalidates the premise"    "a review finding against a settled spec: escalate only on an invalidated premise"
has "$AFK" "disagreeing is not itself new information" "a reviewer disagreeing is not new information about intent"
has "$AFK" "re-read"                    "the plan's structured sections are re-read, not recalled"
has "$AFK" "change inventory"           "the change inventory is named as a section to re-read"

echo
echo "the asymmetry is stated, because it is why the bar drifts:"
has "$AFK" "no natural corrective signal" "over-asking has no feedback signal and its bar must be defended deliberately"

echo
echo "scope: the rule is not AFK-only, which is why it did not fire:"
has "$AFK" "not only when the developer has stepped away" "t4-afk states the section applies whenever a plan exists"
has "$MAP" "assigns the decision to you" "the injected map carries the delegated-decision trigger"

echo
echo "the four failures are usable as worked examples:"
has "$REF" "Worked examples" "the reference carries them"

echo
if [ "$fail" -gt 0 ]; then echo "FAILED: $fail, passed: $pass"; exit 1; fi
echo "OK: $pass passed"

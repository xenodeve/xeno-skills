#!/usr/bin/env bash
# What a bootstrapped CLAUDE.md is REQUIRED to say — pinned, because the failure
# is silent in both directions.
#
# `using-t4` was carried into step 3 as "a pointer to using-t4 as the entry map".
# A pointer is read once at session start, which is precisely the behaviour the
# map forbids of itself ("a check at task start does not discharge a later
# trigger"). pal-mcp-server was bootstrapped and carried no standing-default
# sentence at all until it was added by hand months later — the wording produced
# the behaviour it described, and nothing failed.
#
# The clink-masteragent half is the mirror image: the skill costs ~19 KB per
# session against using-t4's 9 KB ceiling, so wiring it in by default is wrong;
# but omitting it silently is how #74's failure happened (a model chosen from
# memory while the data sat unread). The rule is therefore that bootstrap ASKS
# and RECORDS, so a later reader can tell a decision from an omission.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BS="$REPO_ROOT/skills/t4/t4-project-bootstrap/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

if [ ! -f "$BS" ]; then
  echo "cannot run: bootstrap skill not found at $BS" >&2
  exit 1
fi

echo "the bootstrap requires using-t4 to be written in as a standing default:"
has "$BS" "standing default"                     "step 3 uses the words 'standing default'"
has "$BS" "phase boundary"                       "re-routing at phase boundaries is required, not just an entry pointer"
has "$BS" "does not discharge a later trigger"   "the sentence that forecloses the read-once reading is mandated"

echo "the bootstrap asks about clink-masteragent rather than deciding for the developer:"
has "$BS" "clink-masteragent"                    "the skill is named in the procedure at all"
has "$BS" "ask the user"                         "the procedure instructs an ask, not a default"
has "$BS" "record the answer"                    "the answer is written down in both directions"
has "$BS" "not wired"                            "the unanswered default is stated explicitly"

echo "the bootstrap hands the tracker/label/domain layer off instead of rebuilding it:"
# using-t4 declares that T4 *reuses* pocock's tracker/label/domain conventions, and
# the family's composition rule is to invoke the ecosystem skill rather than copy it.
# The bootstrap was the one place that rebuilt those three files from a second set of
# skeletons, so two skills carried seed templates for one decision.
# Assert the HANDOFF, not a mention. The skill name also appears in step 2 (which
# borrows its ask-flow), so grepping the bare name passes while step 5 still writes
# the three files itself — a mutant proved exactly that before this line was tightened.
has "$BS" "Invoke \`/setup-matt-pocock-skills\`" "step 5 hands the layer off, not merely names the skill"
has "$BS" "T4 delta"                             "what T4 keeps on top of it is named as a delta"

echo "the label vocabulary produces labels that exist:"
# Neither skill created them. pocock's triage-labels.md is a mapping table that assumes
# the labels are already there; T4's said "create lazily / proceed silently", which
# combine into never. Measured: 8 of 19 documented labels existed in a bootstrapped repo.
has "$BS" "gh label create"                      "the procedure creates labels, not only documents them"
has "$BS" "report which were created"            "the outcome is reported, so a gap cannot be absorbed"

echo
echo "bootstrap-wiring-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

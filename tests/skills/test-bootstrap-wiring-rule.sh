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

echo
echo "bootstrap-wiring-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

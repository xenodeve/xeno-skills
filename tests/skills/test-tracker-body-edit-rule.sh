#!/usr/bin/env bash
# The bilingual mirror is checked on EDIT, and a commit message is not a PR body (#238).
#
# A documentation-integrity suite, and labelled one. NO MECHANISM IS ADDED -- #238's
# second option is a gh pr edit guard in t4-gate, which is a trust-boundary file and a
# separate decision that issue explicitly declines to recommend.
#
# TWO MEASUREMENTS, and the second is the one that changes the diagnosis.
#
#   PR #235's body stayed English-only across 42 commits and 34 issues -- 9,465
#   characters, zero Thai -- in a repo whose CLAUDE.md was in context throughout. The
#   body was created early as a working index and extended in place, and "update the PR
#   body" reads as an edit, so the rule governing AUTHORING never re-fired.
#
#   Then on 2026-08-19, in ONE session, 25 PR bodies: 9 bilingual, then 16 CONSECUTIVE
#   English-only ones. The switch point is exactly where the commit-message file started
#   being passed to `gh pr create --body-file`. Commit messages are English by this
#   repo's rule and tracker bodies are bilingual by the same rule, so reusing the file
#   imports the wrong language rule across a boundary where it changes.
#
# A CLEAN BREAK LIKE THAT IS A MECHANISM, NOT A LAPSE, which is why the rule names the
# substitution and not just the drift.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IT="$REPO_ROOT/docs/agents/issue-tracker.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }

[ -f "$IT" ] && ok "issue-tracker.md is present" || { bad "the doc is missing"; exit 1; }

echo ""
echo "THE MIRROR IS CHECKED ON EDIT — the moment the old wording could not reach:"
has "$IT" "checked when the body is EDITED" "the edit moment is named"
has "$IT" "outlives the turn that wrote it" "with why a PR body is the artifact that needs it"

echo ""
echo "AND A COMMIT MESSAGE IS NOT A PR BODY — the second mechanism, and the sharper one:"
has "$IT" "never reuse a commit message as a PR body" "the substitution is forbidden"
has "$IT" "imports the wrong language rule" "with what goes wrong when it happens"

echo ""
echo "both measurements are on the page, because one reads as an anecdote:"
has "$IT" "42 commits and 34 issues" "the long-lived-body case"
has "$IT" "16" "and the consecutive-English-only count"
has "$IT" "a mechanism, not a lapse" "with the inference the break licenses"

echo ""
echo "IT IS A GOVERNED DOC, so both mirrors carry it — a one-sided rule about mirrors is a joke:"
python - "$IT" <<'PY'
import sys
doc = open(sys.argv[1], encoding="utf-8").read()
en = doc.split("<!-- lang:en -->", 1)[1].split("<!-- lang:end -->", 1)[0]
th = doc.split("<!-- lang:th -->", 1)[1].split("<!-- lang:end -->", 1)[0]
assert "checked when the body is EDITED" in en, "the EN mirror lacks the rule"
assert "EDIT" in th, "the TH mirror lacks the rule"
assert "commit message" in en and "commit message" in th, "the substitution rule is one-sided"
PY
[ $? -eq 0 ] && ok "both lang:en and lang:th carry the new rule" \
             || bad "the rule landed in one mirror only"

echo ""
echo "tracker-body-edit-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# Contract tests for references/guards/check-issue-ref.
# Seam: a real git repo as cwd (+ PR_BODY / BASE_REF env) -> exit code + message.
# Nothing inside the script is reached into; only the CLI boundary is observed.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GUARD="$REPO_ROOT/skills/t4/t4-project-bootstrap/references/guards/check-issue-ref"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Builds a repo with a base commit on `main`, then a feature branch named $1
# carrying one commit whose message is $2.
mkrepo() {
  local dir="$TMP/$1" branch="$2" msg="$3"
  rm -rf "$dir"; mkdir -p "$dir"
  ( cd "$dir"
    git init -q -b main
    git config user.email t@t; git config user.name t
    echo base > base.txt; git add .; git commit -qm "base"
    git checkout -qb "$branch"
    echo work > work.txt; git add .; git commit -qm "$msg"
  ) >/dev/null 2>&1
  echo "$dir"
}

# $1 = repo dir, $2 = PR_BODY. Prints the guard's output; exit code in $rc.
run() { rc=0; out="$( cd "$1" && PR_BODY="${2-}" BASE_REF=main sh "$GUARD" 2>&1 )" || rc=$?; }

# A missing script also "fails", and `sh` even echoes the word "issue" back from
# the path — so the first red was vacuously green. Assert the guard's own exit
# code (1, not sh's 127) and a marker only the guard itself can emit.
echo "the guard exists and is runnable:"
if [ -f "$GUARD" ]; then ok "check-issue-ref is present"; else bad "check-issue-ref is missing"; fi

echo "no issue reference anywhere:"
r="$(mkrepo norefs feature/cleanup 'tidy up the helper')"
run "$r" ""
if [ "$rc" -eq 1 ]; then ok "exits 1 when branch, commits and PR body all lack an issue ref"; else bad "expected exit 1, got $rc"; fi
case "$out" in *"no issue reference"*) ok "the failure states the guard's own verdict";; *) bad "no guard-owned verdict (got: ${out:0:70})";; esac
case "$out" in *"branch name"*) ok "the message says where a ref can live";; *) bad "message doesn't say where a ref can go";; esac

echo "the branch name carries the reference:"
r="$(mkrepo brref feat/42-add-thing 'tidy up the helper')"
run "$r" ""
if [ "$rc" -eq 0 ]; then ok "exits 0 for a branch named feat/42-…"; else bad "expected 0 for feat/42-…, got $rc ($out)"; fi
# A version number in a branch name is not an issue reference — the number has
# to sit in the issue-slug position, or every `chore/bump-v2` push passes.
r="$(mkrepo brnum chore/bump-node-22 'bump node')"
run "$r" ""
if [ "$rc" -eq 1 ]; then ok "a stray number elsewhere in the name is not a reference"; else bad "chore/bump-node-22 wrongly accepted"; fi

echo "a commit on the branch carries the reference:"
r="$(mkrepo cmref feature/cleanup 'tidy the helper (refs #77)')"
run "$r" ""
if [ "$rc" -eq 0 ]; then ok "exits 0 when a branch commit references #77"; else bad "expected 0 for a commit with #77, got $rc"; fi
# Only commits ON the branch count. A #ref that exists solely on the base is
# someone else's work and must not vouch for this push.
r="$(mkrepo baseref feature/cleanup 'tidy the helper')"
( cd "$r" && git checkout -q main && git commit -q --allow-empty -m 'base work for #99' && git checkout -q feature/cleanup ) >/dev/null 2>&1
run "$r" ""
if [ "$rc" -eq 1 ]; then ok "a reference only on the base branch does not count"; else bad "base-only #99 wrongly vouched for the branch"; fi

echo "the PR body carries the reference:"
r="$(mkrepo prref feature/cleanup 'tidy the helper')"
run "$r" "This PR does the thing. Closes #12"
if [ "$rc" -eq 0 ]; then ok "exits 0 when PR_BODY references #12"; else bad "expected 0 for PR_BODY with #12, got $rc"; fi

echo "wip/ branches are exempt (deliberate one-off freeze):"
r="$(mkrepo wip wip/freeze 'checkpoint')"
run "$r" ""
if [ "$rc" -eq 0 ]; then ok "exits 0 on a wip/ branch with no reference"; else bad "wip/ branch was blocked, got $rc"; fi

echo ""
echo "check-issue-ref: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# Contract tests for references/guards/check-tree-budget.
# Seam: a real git repo as cwd (+ budget env) -> exit code + message.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GUARD="$REPO_ROOT/skills/t4/t4-project-bootstrap/references/guards/check-tree-budget"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# A repo on branch $2 with $3 tracked-and-modified files and $4 untracked ones.
mkrepo() {
  local dir="$TMP/$1" branch="$2" tracked="$3" untracked="$4" i
  rm -rf "$dir"; mkdir -p "$dir"
  ( cd "$dir"
    git init -q -b main; git config user.email t@t; git config user.name t
    i=0; while [ "$i" -lt "$tracked" ]; do echo v1 > "t$i.txt"; i=$((i+1)); done
    echo base > base.txt
    git add .; git commit -qm base
    [ "$branch" = main ] || git checkout -qb "$branch"
    i=0; while [ "$i" -lt "$tracked" ]; do echo v2 > "t$i.txt"; i=$((i+1)); done
    i=0; while [ "$i" -lt "$untracked" ]; do echo new > "u$i.txt"; i=$((i+1)); done
  ) >/dev/null 2>&1
  echo "$dir"
}

run() { rc=0; out="$( cd "$1" && sh "$GUARD" 2>&1 )" || rc=$?; }

echo "the guard exists and is runnable:"
if [ -f "$GUARD" ]; then ok "check-tree-budget is present"; else bad "check-tree-budget is missing"; fi

echo "a clean-enough tree passes:"
r="$(mkrepo small feature/x 3 2)"
run "$r"
if [ "$rc" -eq 0 ]; then ok "exits 0 for 3 modified + 2 untracked"; else bad "expected 0, got $rc ($out)"; fi

echo "an over-budget tree is blocked:"
r="$(mkrepo big feature/x 30 0)"
run "$r"
if [ "$rc" -eq 1 ]; then ok "exits 1 above the tracked-file budget"; else bad "expected 1 for 30 modified files, got $rc"; fi
case "$out" in *"check-tree-budget"*) ok "the failure is attributed to this guard";; *) bad "no guard-owned marker (got: ${out:0:70})";; esac
case "$out" in *30*) ok "the message reports the actual count";; *) bad "message doesn't report the count (got: ${out:0:70})";; esac

echo "wip/ bypasses the COUNT gate (deliberate one-time freeze):"
r="$(mkrepo wipbig wip/freeze 30 0)"
run "$r"
if [ "$rc" -eq 0 ]; then ok "exits 0 for 30 modified files on wip/"; else bad "wip/ was blocked by the count gate, got $rc"; fi

echo "wip/ never bypasses the ARTIFACT gate:"
r="$(mkrepo artifact wip/freeze 1 0)"
mkdir -p "$r/test-results" && echo junk > "$r/test-results/out.png"
run "$r"
if [ "$rc" -eq 1 ]; then ok "exits 1 for a build artifact even on wip/"; else bad "artifact slipped through on wip/, got $rc"; fi
case "$out" in *"test-results"*) ok "the message names the offending path";; *) bad "message doesn't name the artifact (got: ${out:0:70})";; esac

echo "an ordinary source file is not an artifact:"
r="$(mkrepo notartifact feature/x 1 0)"
mkdir -p "$r/src" && echo 'export const a = 1' > "$r/src/thing.ts"
run "$r"
if [ "$rc" -eq 0 ]; then ok "exits 0 for a normal untracked source file"; else bad "false artifact match on src/thing.ts, got $rc ($out)"; fi

echo "this repo does not trip its own artifact gate (#258):"
# The guard is right to block every untracked *.log unconditionally, so the burden is on the
# repo to hide the ones its own tooling writes. The skill-usage invocation log lands inside a
# COMMITTED vault directory, so without a rule it is untracked, matches \.log$, and blocks every
# push from the clone -- which is exactly how it was found.
# Every path the hooks write into the repo at runtime, not just the one that was found
# the hard way. The invocation log was caught because it BLOCKED a push; these three are
# the same class and have not been written yet only because their hooks ship dark.
for RUNTIME in "Obsidian-xeno-skills/skill-usage/.invocations.log"                ".claude/t4-review-state.json"                ".claude/t4-receipt-counts.json"                ".claude/t4-canary-disabled"; do
  if git -C "$REPO_ROOT" check-ignore -q "$RUNTIME"; then
    ok "$RUNTIME is gitignored, so the guard can never see it"
  else
    bad "$RUNTIME is hook-written runtime state and is not gitignored"
  fi
done

echo ""
echo "check-tree-budget: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

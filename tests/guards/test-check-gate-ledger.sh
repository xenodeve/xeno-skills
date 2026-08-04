#!/usr/bin/env bash
# Contract tests for references/guards/check-gate-ledger (#104).
# Seam: a real git repo as cwd (+ BASE_REF env) -> exit code + message.
# Nothing inside the script is reached into; only the CLI boundary is observed.
#
# What the guard is for: nine PRs shipped on 2026-08-04 (pal-mcp-server #44-#48,
# #50; xeno-skills #100-#103) with /simplify, /code-review and /scrutinize run
# zero times, and NOTHING detected it — an unrun judgment gate is indistinguishable
# from a passed one in the only report anybody reads. The guard does not force a
# gate to run. It forbids expressing an omission as SILENCE, which is why
# `not-run` is a legal value and a missing gate name is not.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GUARD="$REPO_ROOT/skills/t4/t4-project-bootstrap/references/guards/check-gate-ledger"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Builds a repo with a base commit on `main`, then a feature branch named $2
# carrying one commit whose message is $3. $4 optionally replaces the BASE
# commit's message, which is how the "someone else's claim" case is built.
mkrepo() {
  local dir="$TMP/$1" branch="$2" msg="$3" base_msg="${4-base}"
  rm -rf "$dir"; mkdir -p "$dir"
  ( cd "$dir"
    git init -q -b main
    git config user.email t@t; git config user.name t
    echo base > base.txt; git add .; git commit -qm "$base_msg"
    git checkout -qb "$branch"
    echo work > work.txt; git add .; git commit -qm "$msg"
  ) >/dev/null 2>&1
  echo "$dir"
}

LEDGER='T4-Gates: simplify=ran code-review=ran scrutinize=ran security-review=ran verify=ran'

# $1 = repo dir. Prints the guard's output; exit code in $rc.
run() { rc=0; out="$( cd "$1" && BASE_REF=main sh "$GUARD" 2>&1 )" || rc=$?; }

# A missing script also "fails", and `sh` echoes part of the path back — so the
# first red can be vacuously green (the sibling check-issue-ref test records
# exactly this trap). Assert the guard's OWN exit code (1, not sh's missing-file
# status) and a marker only the guard itself could emit.
echo "the guard exists and is runnable:"
if [ -f "$GUARD" ]; then ok "check-gate-ledger is present"; else bad "check-gate-ledger is missing"; fi

echo "no T4-Gates trailer anywhere on the branch:"
r="$(mkrepo norecord feature/cleanup 'tidy up the helper')"
run "$r"
if [ "$rc" -eq 1 ]; then ok "exits 1 when the branch has no gate ledger"; else bad "expected exit 1, got $rc"; fi
case "$out" in *"no gate ledger"*) ok "the failure states the guard's own verdict";; *) bad "no guard-owned verdict (got: ${out:0:70})";; esac
for gate in simplify code-review scrutinize security-review verify; do
  case "$out" in *"$gate"*) ok "the message names missing $gate";; *) bad "the message omits missing $gate";; esac
done

echo "a complete all-ran trailer passes:"
r="$(mkrepo complete feature/gates "implement the ledger

$LEDGER")"
run "$r"
if [ "$rc" -eq 0 ]; then ok "exits 0 for five ran gates"; else bad "expected 0 for a complete ledger, got $rc ($out)"; fi

echo "not-run and n-a remain legal — this is the design, not a loophole:"
r="$(mkrepo legal feature/gates 'record what actually happened

T4-Gates: simplify=ran code-review=ran scrutinize=not-run security-review=n-a verify=ran')"
run "$r"
if [ "$rc" -eq 0 ]; then ok "exits 0 for legal not-run and n-a values"; else bad "legal not-run/n-a values were rejected, got $rc ($out)"; fi

echo "a trailer missing exactly one gate fails:"
r="$(mkrepo missingone feature/gates 'record an incomplete ledger

T4-Gates: simplify=ran code-review=ran scrutinize=ran security-review=ran')"
run "$r"
if [ "$rc" -eq 1 ]; then ok "exits 1 when verify is omitted"; else bad "expected exit 1 for missing verify, got $rc"; fi
case "$out" in *"gate ledger is incomplete"*) ok "the missing-gate failure is guard-owned";; *) bad "no guard-owned missing-gate verdict (got: ${out:0:70})";; esac
case "$out" in *"verify"*) ok "the message names missing verify";; *) bad "the message omits missing verify";; esac

echo "an illegal value fails:"
r="$(mkrepo illegal feature/gates 'record an invalid ledger

T4-Gates: simplify=ran code-review=ran scrutinize=maybe security-review=ran verify=ran')"
run "$r"
if [ "$rc" -eq 1 ]; then ok "exits 1 for scrutinize=maybe"; else bad "expected exit 1 for an illegal value, got $rc"; fi
case "$out" in *"not a legal value"*) ok "the illegal-value failure is guard-owned";; *) bad "no guard-owned illegal-value verdict (got: ${out:0:70})";; esac

# The claim is about the BRANCH, not about its tip commit — a follow-up commit
# must not invalidate a ledger already recorded on the branch. NOTE: the
# delegated first draft of this file built this case with no trailer anywhere and
# still asserted exit 0, which would have forced the guard to accept exactly the
# branch case 2 rejects. Verified and rewritten rather than accepted.
echo "a trailer on an earlier branch commit still counts:"
r="$(mkrepo earlier feature/gates "record the ledger

$LEDGER")"
( cd "$r" && git commit --allow-empty -qm "follow-up work, no trailer of its own" ) >/dev/null 2>&1
run "$r"
if [ "$rc" -eq 0 ]; then ok "exits 0 when the ledger is on an earlier branch commit"; else bad "an earlier branch ledger was ignored, got $rc ($out)"; fi

echo "wip/ branches are exempt, same escape hatch as check-issue-ref:"
r="$(mkrepo wip wip/freeze 'checkpoint')"
run "$r"
if [ "$rc" -eq 0 ]; then ok "exits 0 on a wip/ branch with no ledger"; else bad "wip/ branch was blocked, got $rc ($out)"; fi

echo "a trailer only on BASE does not vouch for this branch:"
r="$(mkrepo baseonly feature/cleanup 'tidy up the helper' "base work

$LEDGER")"
run "$r"
if [ "$rc" -eq 1 ]; then ok "exits 1 when the ledger exists only on BASE"; else bad "a BASE-only ledger wrongly vouched for the branch, got $rc"; fi
case "$out" in *"no gate ledger"*) ok "the BASE-only failure is guard-owned";; *) bad "no guard-owned BASE-only verdict (got: ${out:0:70})";; esac

echo ""
echo "check-gate-ledger: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

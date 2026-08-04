#!/usr/bin/env bash
# Contract tests for references/guards/pre-push.
# Seam: running the hook in a repo -> exit code. The hook's whole job is to run
# both guards and propagate a failure, so that propagation is what's tested —
# a hook that swallows a guard's exit code is worse than no hook, because the
# repo then believes it is guarded.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GUARDS="$REPO_ROOT/skills/t4/t4-project-bootstrap/references/guards"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

LEDGER='T4-Gates: simplify=ran code-review=ran scrutinize=ran security-review=n-a verify=ran'

# A repo with the guards installed at .githooks/, on branch $2. $3 optionally
# replaces the branch commit's message; it defaults to one carrying a complete
# gate ledger, so a case that is not about check-gate-ledger stays about its own
# guard rather than tripping over this one.
mkrepo() {
  local dir="$TMP/$1" branch="$2" msg="${3-"work

$LEDGER"}"
  rm -rf "$dir"; mkdir -p "$dir/.githooks"
  cp "$GUARDS/pre-push" "$GUARDS/check-issue-ref" "$GUARDS/check-tree-budget" \
     "$GUARDS/check-gate-ledger" "$dir/.githooks/" 2>/dev/null
  chmod +x "$dir/.githooks/"* 2>/dev/null
  ( cd "$dir"
    git init -q -b main; git config user.email t@t; git config user.name t
    echo base > base.txt; git add .; git commit -qm base
    git checkout -qb "$branch"
    echo work > work.txt; git add .; git commit -qm "$msg"
  ) >/dev/null 2>&1
  echo "$dir"
}

run() { rc=0; out="$( cd "$1" && BASE_REF=main sh .githooks/pre-push 2>&1 )" || rc=$?; }

echo "the hook exists:"
if [ -f "$GUARDS/pre-push" ]; then ok "pre-push is present"; else bad "pre-push is missing"; fi

echo "a compliant push is allowed through:"
r="$(mkrepo good feat/42-thing)"
run "$r"
if [ "$rc" -eq 0 ]; then ok "exits 0 when all three guards pass"; else bad "expected 0, got $rc ($out)"; fi

echo "a failing guard is propagated, not swallowed:"
r="$(mkrepo noissue feature/cleanup)"
run "$r"
if [ "$rc" -ne 0 ]; then ok "exits non-zero when check-issue-ref fails"; else bad "issue-ref failure was swallowed by the hook"; fi
case "$out" in *"check-issue-ref"*) ok "the failing guard's own message reaches the user";; *) bad "guard output was suppressed (got: ${out:0:70})";; esac

r="$(mkrepo artifact feat/42-thing)"
mkdir -p "$r/dist" && echo x > "$r/dist/bundle.js"
run "$r"
if [ "$rc" -ne 0 ]; then ok "exits non-zero when check-tree-budget fails"; else bad "tree-budget failure was swallowed by the hook"; fi

# A guard the hook never calls is a guard the repo believes it has — the exact
# failure mode line 5 names, one guard later (#104).
r="$(mkrepo noledger feat/42-thing "work with no gate ledger at all")"
run "$r"
if [ "$rc" -ne 0 ]; then ok "exits non-zero when check-gate-ledger fails"; else bad "gate-ledger failure was swallowed by the hook"; fi
case "$out" in *"no gate ledger"*) ok "check-gate-ledger's own message reaches the user";; *) bad "gate-ledger output suppressed (got: ${out:0:70})";; esac

echo "the hook says how to proceed when it blocks:"
case "$out" in *"--no-verify"*) ok "names the escape hatch rather than leaving the user stuck";; *) bad "no guidance on how to proceed";; esac

echo ""
echo "pre-push: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

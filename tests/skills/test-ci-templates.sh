#!/usr/bin/env bash
# Contract tests for the CI/CD layer templates (t4-project-bootstrap).
# The invariant that actually rots: the job names in t4-verify.yml and the
# required-check contexts in ci-cd-layer.md are the SAME list. Rename a job and
# the documented ruleset silently requires a check that will never report.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CI="$REPO_ROOT/skills/t4/t4-project-bootstrap/references/ci"
DOC="$REPO_ROOT/skills/t4/t4-project-bootstrap/references/ci-cd-layer.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "templates present:"
for f in t4-verify.yml t4-e2e.yml t4-deploy.yml; do
  [ -f "$CI/$f" ] && ok "$f exists" || bad "$f is missing"
done
[ -f "$DOC" ] && ok "ci-cd-layer.md exists" || bad "ci-cd-layer.md is missing"

echo "required checks: workflow jobs == documented ruleset contexts:"
if python - "$CI/t4-verify.yml" "$DOC" <<'PY'
import sys, re
wf, doc = (open(p, encoding="utf-8").read() for p in sys.argv[1:3])
# Top-level job keys: two-space indented `name:` under `jobs:`.
body = wf.split("\njobs:\n", 1)[1]
jobs = re.findall(r'(?m)^  ([a-z][\w-]*):\s*$', body)
# Only the ruleset snippet itself — prose after it (e.g. "promoting e2e") may
# legitimately name a check that isn't required yet.
ruleset = doc.split("\nJSON\n", 1)[0]
contexts = re.findall(r'"context"\s*:\s*"([^"]+)"', ruleset)
print("jobs:", jobs, "contexts:", contexts)
sys.exit(0 if jobs and jobs == contexts else 1)
PY
then ok "t4-verify.yml jobs match the required_status_checks contexts in the doc"
else bad "DRIFT: t4-verify.yml job names and the doc's required contexts differ"; fi

echo "gate hardening:"
has "$CI/t4-verify.yml" "contents: read"        "verify runs with least-privilege permissions"
has "$CI/t4-verify.yml" "cancel-in-progress: true"  "verify cancels superseded runs"
has "$CI/t4-e2e.yml"    "timeout-minutes"       "e2e has a timeout (a hung browser can't pin a runner)"

echo "CD is downstream of the gate (not triggered by a bare push):"
has "$CI/t4-deploy.yml" "workflow_run:"                        "deploy triggers on workflow_run"
has "$CI/t4-deploy.yml" "conclusion == 'success'"              "deploy requires a successful gate run"
has "$CI/t4-deploy.yml" "workflow_run.head_sha"                "deploy checks out the sha that passed"
has "$CI/t4-deploy.yml" "cancel-in-progress: false"            "deploy is never cancelled mid-apply"
if grep -Eq '^on:$' -A3 "$CI/t4-deploy.yml" 2>/dev/null && grep -Eq '^\s+push:' "$CI/t4-deploy.yml"; then
  bad "deploy is triggered by push (must be workflow_run only)"
else
  ok "deploy has no push trigger"
fi

echo "the local fallback is documented as weaker, not equivalent:"
has "$DOC" "requireGreenCI"   "doc covers the requireGreenCI fallback"
has "$DOC" "weaker than a ruleset" "doc states the fallback's honest scope"

echo ""
echo "ci-templates: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

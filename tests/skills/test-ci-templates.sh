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
for f in t4-verify.yml t4-verify-monorepo.yml t4-e2e.yml t4-deploy.yml t4-codeql.yml dependabot.yml; do
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

echo "required-check context = the job's name: (falls back to the key):"
# t4-verify.yml's documented contexts are job KEYS, which is only true while no
# job sets a `name:`. Adding one silently renames the check and the ruleset then
# waits forever on a context that never reports.
if grep -Eq '^    name:' "$CI/t4-verify.yml"; then
  bad "t4-verify.yml sets a job-level name: — the doc's contexts (job keys) are now wrong"
else
  ok "t4-verify.yml sets no job-level name:, so key == documented context"
fi
has "$DOC" "is the job's \`name:\`, not its key" "doc states the context is the job name, not the key"

echo "monorepo template: the check always reports (no trigger-level paths filter):"
if grep -Eq '^\s+paths:' "$CI/t4-verify-monorepo.yml"; then
  bad "monorepo template path-filters its trigger — required checks would hang on 'Expected'"
else
  ok "monorepo template has no workflow-level paths: filter"
fi
has "$CI/t4-verify-monorepo.yml" "steps.scope.outputs.run == 'true'" "expensive steps are conditional, the job is not"
has "$CI/t4-verify-monorepo.yml" "fetch-depth: 0"                    "checkout can diff against the base branch"
has "$CI/t4-verify-monorepo.yml" "--health-cmd"                      "service containers carry a healthcheck"
has "$DOC" "creates no check run"                                    "doc explains the path-filter deadlock"

echo "provisional checks name their exit condition:"
has "$CI/t4-e2e.yml" "FLIP CONDITION"      "e2e template states how it stops being advisory"
has "$DOC" "exit condition"                "doc requires an exit condition for provisional/quarantined checks"
has "$DOC" "cites a tracking issue"        "doc carries the quarantine discipline"

echo "supply-chain layer: gate vs alert is decided, not left implied:"
has "$DOC" "Alerts are not gates"            "doc separates a blocking gate from an alert"
has "$DOC" "never bypassed"                  "push protection: no bypass"
has "$DOC" "rotate the credential"           "the response to a blocked push is rotation, not bypass"
has "$DOC" "never exemptable by argument"    "push protection is tied to the non-exemptable class"
has "$DOC" "by nature, not by argument"      "Dependabot PRs vs the issue gate is decided explicitly"
has "$DOC" "GitHub Advanced Security"        "CodeQL's private-repo cost is stated, not implied"
# CodeQL's matrix expands the check name; a ruleset written from the job key hangs.
has "$CI/t4-codeql.yml" "not \`analyze\`"    "codeql template warns the matrix renames the check"
has "$CI/t4-codeql.yml" "security-events: write" "codeql has the permission it needs to upload results"
if grep -Eq '^\s+groups:' "$CI/dependabot.yml"; then
  ok "dependabot template groups updates (ungrouped spam trains rubber-stamping)"
else
  bad "dependabot template does not group updates"
fi

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

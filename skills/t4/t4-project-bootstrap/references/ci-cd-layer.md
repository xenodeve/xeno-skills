# CI/CD layer — the gate that isn't the agent's to skip

The hooks layer (`hooks-layer.md`) raises the floor for **agent-run** commands. It cannot cover a human merging on the web, a `--no-hooks` run, or a checkout without the hooks installed. This layer is the one that holds: **checks the machine runs, and a branch rule the agent has no way to satisfy except by making them green.**

Install it in the same pass as the hooks layer — a repo with the local gate and no CI has the *appearance* of enforcement with none of the guarantee.

## The three-way split — who runs what, and why

| Layer | Runs | Contains | Why there |
|---|---|---|---|
| **Local `verify`** (`.claude/t4.json`) | `t4-gate` before `gh pr merge` | lint + typecheck + unit + build — the **fast** subset | Fails in seconds, before a PR is opened or merged. Slow suites here make shipping expensive (issue #13). |
| **CI required checks** (`t4-verify.yml`) | GitHub, every push/PR | the same four, as **separate** jobs | Un-forgeable, covers human merges, and separate jobs tell you *what* broke from the check name alone. |
| **CI advisory → required** (`t4-e2e.yml`) | GitHub, every PR | e2e / browser | Too slow for the local gate; too valuable to drop. Start advisory, promote when stable. |

**The rule:** the local `verify` is a *fast prefix* of CI, never a different suite. If they can diverge, the local gate stops predicting the server one and the agent learns to distrust it.

## Files this installs

```
<repo>/.github/workflows/
├── t4-verify.yml    # required: lint · typecheck · test · build
├── t4-e2e.yml       # advisory at first, then required: e2e
└── t4-deploy.yml    # only if the repo deploys — CD, gated on a green t4-verify
```

**Several independently-built components?** Use `t4-verify-monorepo.yml` *instead of* `t4-verify.yml` — one job per component, each skipping its own suite when the PR doesn't touch it. Read the trap it's built around before adapting it (below).

Copy them verbatim from `references/ci/`, then replace `<ORG>/<REPO>`, `<DIST_DIR>`, `<DEPLOY_COMMAND>`, `<PRODUCTION_URL>`, `<HEALTHCHECK_URL>`, and drop any job the repo genuinely has no command for (a `typecheck` job that runs a script that doesn't exist is a red check that teaches everyone to ignore red checks).

## Install steps

1. **Copy the workflows** into `.github/workflows/` and fill the placeholders. Drop `t4-deploy.yml` unless the repo deploys.
2. **Arm the local gate** — set `.claude/t4.json` `"verify"` to the fast subset, e.g. `"bun run lint && bun run typecheck && bun test && bun run build"`.
3. **Push and let them run once.** You cannot require a check GitHub has never seen — the name only becomes selectable after a first run.
4. **Make them required + block direct pushes** (below).
5. **Tell the user what now blocks a merge**, and that a red check can no longer be merged past locally.

## Making the checks required

A **ruleset** is the current mechanism (rulesets supersede the older branch-protection API and work on private repos on paid plans). Run from the repo:

```bash
gh api --method POST repos/{owner}/{repo}/rulesets \
  --input - <<'JSON'
{
  "name": "T4 main gate",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": true,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true,
        "allowed_merge_methods": ["squash"]
      } },
    { "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [
          { "context": "lint" },
          { "context": "typecheck" },
          { "context": "test" },
          { "context": "build" }
        ]
      } }
  ]
}
JSON
```

What each line buys you:

- **`pull_request` rule** — direct pushes to `main` stop being possible; everything arrives through a PR. This is what makes the PRD → issues → PR gate meaningful rather than a convention.
- **`strict_required_status_checks_policy: true`** — the branch must be up to date with `main` before merging. Without it, two PRs that pass independently can break `main` together.
- **`non_fast_forward` + `deletion`** — `main` can't be force-pushed or deleted, matching what `t4-gate` denies locally. The local rule is a courtesy; this one is the guarantee.
- **`required_review_thread_resolution`** — an unresolved review comment blocks merge. The one review-discipline item that *is* mechanically checkable.
- **`required_approving_review_count: 0`** — deliberate for a solo/agent-primary repo: requiring an approval you then give yourself is theater, and it deadlocks an AFK run. Raise it the moment a second human is on the repo.

**A check's name is the job's `name:`, not its key.** The templates in `references/ci/t4-verify.yml` set no job-level `name:`, so the key *is* the context (`lint`, `test`, …) and the ruleset above is correct as written. The moment a job gains `name: jest (unit)`, the context becomes `jest (unit)` and a ruleset requiring `test` waits forever on a check that will never report. Matrix jobs get `name (matrix-values)`. Read the names off an actual run (`gh pr checks`) rather than off the YAML keys.

Verify it took, and check whether a run is green:

```bash
gh api repos/{owner}/{repo}/rulesets            # the rule exists and is "active"
gh pr checks <pr>                               # 0 = green · 1 = failing · 8 = pending
```

**Promoting e2e:** once `t4-e2e.yml` has been stable for a week, add `{ "context": "e2e" }` to the same `required_status_checks` list.

## Monorepos: never path-filter a required check's trigger

The obvious way to stop a Frontend-only PR from paying for the Backend suite is a workflow-level `paths:` filter. It is also the way to deadlock the repo: **a workflow that doesn't run creates no check run**, so a required check stays on *"Expected — waiting for status"* until someone disables the rule — and once a team has disabled a rule to land a PR, it stays disabled.

The rule: **the check always runs; only the expensive work inside it is conditional.** `t4-verify-monorepo.yml` does this with a `git diff` against the base branch feeding a step-level `if:` — dependency-free, and the check reports green with an explicit "no changes in this component" line in the log.

(A job skipped by a job-level `if:` *is* reported as success to branch protection, so that also works. Step-level is preferred anyway: the log says why it was a no-op instead of showing an empty skipped job.)

## When tests need real infrastructure

Unit specs that talk to Redis/Postgres deserve a real one — a mock that drifts from the real client is how a green gate ships a broken cache.

- **Service containers with a healthcheck.** Without `--health-cmd`, the suite starts before the container accepts connections and the failure reads as flakiness, which is the fastest way to teach a team to re-run CI instead of reading it.
- **Dummy env vars for import-time config reads.** A module that reads `process.env.X` at import crashes every test that merely imports it, including ones that never touch that service. Set placeholder values in the job's `env:`. Real secrets belong to the deploy workflow, never to the gate.
- **Serialize when specs share state.** One Redis, one database, parallel workers → cross-worker bleed. `--runInBand` (or the runner's equivalent) trades wall-clock for a suite whose failures mean something.
- **Install with the tool that maintains the lockfile; run with what the repo actually runs.** These are allowed to differ — MangaDock's Backend installs with `bun` (its `package-lock.json` is stale, so `npm ci` fails) and runs Jest under Node. Honor the repo's reality over the "Bun is the default" rule; that rule is for new repos.

## Keeping the fast gate fast, by construction

The local `verify` is only a fast prefix of CI for as long as someone keeps it that way — unless the split is **mechanical**:

> Name integration specs `*.integration.test.ts` (or an equivalent convention) and have the unit run *exclude the pattern* rather than *enumerate the files*.

Then a new unit test is picked up automatically and a new integration test is auto-excluded from the fast gate. Nobody has to remember the rule, so nobody can forget it. Same idea for e2e: it lives in `t4-e2e.yml`, never in `"verify"`.

## Provisional and quarantined checks

Both of these keep a gate meaningful when part of the suite isn't ready. Both are also how a gate quietly rots, so each needs a stated **exit condition** — in the file, not in someone's memory.

**A report-only check** (`continue-on-error: true`) is for a suite that can't block yet. Its header must state *why*, *the proper fix*, and *the exact condition to flip it*. MangaDock's `mit-ci.yml` is the model: eager `import torch` drags the whole ML stack into a font-fit unit test → lazy-import it → then drop `continue-on-error`. A provisional check with no flip condition is permanent.

**A quarantine list** is for known, pre-existing failures. The discipline that makes it safe:

- **Inherit the real config; don't copy it.** MangaDock's `jest.ci.config.js` spreads `require('./package.json').jest` and only *adds* a skip list — so a future change to transforms or module mapping is picked up automatically and CI can't silently drift from local.
- **Every skip cites a tracking issue**, and no new skip lands without one.
- **Delete each line as its suite is fixed.** The list converges toward zero; a growing one is a gate being dismantled.

The reason to bother, stated the way MangaDock states it: *a perpetually-red gate gets ignored, which is worse than none.* That is the failure this whole layer is trying to avoid — not an unfixed test, but a team that has learned to merge past red.

## Supply chain and secrets — a different class of gate

Everything above catches *code that doesn't do what it should*. None of it catches a vulnerable transitive dependency, a credential committed by accident, or an injection path in code that passes every test. Those controls are **configuration, not code**, which is exactly why they get skipped: nothing fails when they're absent.

**Gate vs alert — decide which each one is, deliberately:**

| Control | Type | Blocks a merge? |
|---|---|---|
| **Push protection** | **gate**, and the earliest one | Blocks the **push** — before the secret is in history at all |
| **CodeQL / code scanning** | alert by default | Only if you add its job to `required_status_checks`, or turn on code-scanning merge protection |
| **Dependabot alerts** | alert, never a gate | No. It notifies; a human or a cadence has to act |
| **Dependabot version PRs** | ordinary PRs | They pass the same required checks as anything else |

**Alerts are not gates.** An alert is invisible unless someone looks. If nobody owns the Security tab on a stated cadence, alerts accumulate into a dashboard that proves the repo is being watched while nobody is watching it. Either give it an owner and a cadence, or make it blocking — don't leave it in between and count it as coverage.

### Enabling them

Public repos get secret scanning and push protection on by default. A private repo gets nothing by default:

```bash
gh api --method PATCH repos/{owner}/{repo} --input - <<'JSON'
{ "security_and_analysis": {
    "secret_scanning":                    { "status": "enabled" },
    "secret_scanning_push_protection":    { "status": "enabled" },
    "secret_scanning_validity_checks":    { "status": "enabled" },
    "secret_scanning_non_provider_patterns": { "status": "enabled" }
} }
JSON
gh api --method PUT repos/{owner}/{repo}/vulnerability-alerts          # Dependabot alerts
gh api --method PUT repos/{owner}/{repo}/automated-security-fixes      # Dependabot security PRs
gh api repos/{owner}/{repo} --jq .security_and_analysis                # verify, don't assume
```

Then copy `references/ci/dependabot.yml` → `.github/dependabot.yml`, and `references/ci/t4-codeql.yml` → `.github/workflows/t4-codeql.yml`.

**CodeQL cost, stated plainly:** free on public repos; on a private repo it needs GitHub Advanced Security (paid, per active committer). If you don't have it, delete the workflow rather than leaving a permanently-failing one, and fall back to what *is* free — `actions/dependency-review-action` on PRs (blocks a PR that introduces a known-vulnerable dependency), the security rules in the repo's linter, and `/security-review` on every boundary-crossing change (which the T4 pipeline already mandates).

### Where these collide with the T4 rules

Three interactions an agent will otherwise improvise. They are decided here:

- **A Dependabot PR has no issue, and that's fine.** The PRD → issues → PR rule exists so human/agent work has tracked state; a bot PR is created server-side and never passes through the agent's Bash tool, so the `PreToolUse` gate never fires on it either. Treat it as an exception **by nature, not by argument** — and don't let it become precedent for skipping an issue on your own work. It still passes every required check; that is what makes merging it safe.
- **A push blocked by push protection is never bypassed.** *"It's only a test key"* is the reason that will occur to you, and it is wrong: a credential that reached a commit is already exposed to anyone who gets the object, and the bypass is permanent and logged. The action is **rotate the credential, then remove it from the commit** — not the bypass link. This is a safety boundary, so it is one of the rules that is **never exemptable by argument** (`t4-dev-workflow` → skipping a rule requires proof).
- **A vulnerability alert is work, so it gets tracked like work.** An alert you act on becomes an issue (or a ledger row) like anything else — otherwise the fix lands with no record of why, and `t4-engineering-records` loses the trail. An alert you deliberately *don't* act on gets a stated reason, same as closing an issue.

## When you can't have required checks

Private repos on the free plan can't enforce rulesets. Then the fallback is the local gate:

```jsonc
// .claude/t4.json
{ "requireGreenCI": true }
```

`t4-gate` then runs `gh pr checks` before `gh pr merge` and **denies while any check is failing or still pending** — including under `"autoMerge"`/`"afk"` (standing authorization skips the review *ask*, never a checkable guard).

Honest scope: this is weaker than a ruleset — it only binds commands the agent runs through the hook, and a human merging on the web bypasses it entirely. Use it as a stopgap, and say so; don't present it as equivalent.

## CD gating

If the repo deploys, the discipline is that **deploy is downstream of the same gate as merge** — `t4-deploy.yml` triggers on `workflow_run` of `T4 verify` completing successfully on `main`, and checks out `workflow_run.head_sha` so it ships the exact commit that passed.

- **GitHub Environments are the human gate.** Add required reviewers on the `production` environment when a deploy needs sign-off; that pauses the run instead of relying on an agent to stop.
- **Never `cancel-in-progress` a deploy** — cancelling mid-apply leaves a half-deployed system. The gate cancels; the deploy queues.
- **Prefer OIDC (`id-token: write`) over long-lived secrets.** A leaked deploy token in an agent-primary repo is a boundary crossing an agent can trigger accidentally.
- **Write the rollback down** in the repo runbook before the first deploy. Under `t4-afk`, an incident mid-run is a 🛑 park — an unattended agent must not be improvising a rollback.

## Troubleshooting

| Symptom | Likely cause → fix |
|---|---|
| **The check name isn't selectable when creating the ruleset** | The workflow has never run → push once, then add it. Required checks are matched by the **job's `name:`** (falling back to its key), not the workflow name (`T4 verify`). |
| **A PR is stuck "Expected — waiting for status"** | A required check never reported on this PR — almost always a workflow-level `paths:` filter (see the monorepo section) or a renamed job. Fix the workflow so the check always runs; don't "fix" it by removing the rule. |
| **`gh pr merge` denied with "checks are not green" but GitHub looks green** | A check is *pending*, not failing (`gh pr checks` exits 8) → wait for it. Or the PR has no checks at all, which `gh pr checks` also reports non-zero — remove `requireGreenCI` in a repo with no CI. |
| **CI red, local `verify` green** | The two have diverged → make `"verify"` a literal prefix of the CI jobs. This is the failure that erodes trust in the local gate fastest. |
| **AFK run stalls on every merge** | `requireGreenCI` waits for pending checks and never polls → have the AFK loop wait for CI (`gh pr checks --watch`) before attempting the merge, or park the item. |
| **Deploy ran on a commit that failed the gate** | `t4-deploy.yml` is triggered by `push` instead of `workflow_run`, or is missing the `conclusion == 'success'` guard → use the template as-is. |
| **A required check can't pass because the repo has no such script** | Don't merge past it — either add the script or remove that job from both the workflow and the ruleset. A permanently red check trains everyone to ignore red. |
| **A suite is red for reasons this PR didn't cause** | Quarantine it (see above) — a skip list that inherits the real config, cites a tracking issue per line, and shrinks. Not a disabled gate, and not `continue-on-error` on the whole job unless the header names the flip condition. |
| **A monorepo job runs on every PR even when its component wasn't touched** | Intended: the *check* must always report. Only the install/test steps are conditional — the no-op run costs a runner spin-up and keeps the ruleset satisfiable. |

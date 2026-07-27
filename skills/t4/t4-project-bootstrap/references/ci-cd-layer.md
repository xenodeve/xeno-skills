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

Verify it took, and check whether a run is green:

```bash
gh api repos/{owner}/{repo}/rulesets            # the rule exists and is "active"
gh pr checks <pr>                               # 0 = green · 1 = failing · 8 = pending
```

**Promoting e2e:** once `t4-e2e.yml` has been stable for a week, add `{ "context": "e2e" }` to the same `required_status_checks` list.

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
| **The check name isn't selectable when creating the ruleset** | The workflow has never run → push once, then add it. Required checks are matched by **job name** (`lint`), not workflow name (`T4 verify`). |
| **A PR is stuck "Expected — waiting for status"** | A required check is named for a job that didn't run on this PR (e.g. path filters, or the job was renamed) → align the name, or drop it from the ruleset. |
| **`gh pr merge` denied with "checks are not green" but GitHub looks green** | A check is *pending*, not failing (`gh pr checks` exits 8) → wait for it. Or the PR has no checks at all, which `gh pr checks` also reports non-zero — remove `requireGreenCI` in a repo with no CI. |
| **CI red, local `verify` green** | The two have diverged → make `"verify"` a literal prefix of the CI jobs. This is the failure that erodes trust in the local gate fastest. |
| **AFK run stalls on every merge** | `requireGreenCI` waits for pending checks and never polls → have the AFK loop wait for CI (`gh pr checks --watch`) before attempting the merge, or park the item. |
| **Deploy ran on a commit that failed the gate** | `t4-deploy.yml` is triggered by `push` instead of `workflow_run`, or is missing the `conclusion == 'success'` guard → use the template as-is. |
| **A required check can't pass because the repo has no such script** | Don't merge past it — either add the script or remove that job from both the workflow and the ruleset. A permanently red check trains everyone to ignore red. |

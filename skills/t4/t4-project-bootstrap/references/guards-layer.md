# Guards layer — the enforcement tier that isn't Claude-only

The hooks layer (`hooks-layer.md`) is a Claude Code feature. It fires on the `PreToolUse` event, which means it sees **commands Claude runs, and nothing else**. In a repo where the team also runs Codex or Gemini — as MangaDock does — those agents push past a gate they never trigger. So does a human, and so does Claude itself the moment work leaves the tool loop.

This layer closes that hole by moving the same rules into **git**, where every agent and every human meets them.

```
Tier 0    PreToolUse gate   →  binds Claude          (hooks-layer.md)
Tier 0.5  git pre-push      →  binds every agent + human on this clone   ← this file
Tier 3    CI required check →  binds everyone, unbypassable  (ci-cd-layer.md)
```

Each tier catches what the one above it can't reach, and each is cheaper to hit than the one below: the gate answers in milliseconds, the hook in seconds, CI in minutes. None of them replaces the others.

## What it installs

```
<repo>/.githooks/
├── pre-push            # runs all three guards, propagates failure
├── check-issue-ref     # every push carries a GitHub issue reference
├── check-tree-budget   # no large dirty tree, no build artifacts
└── check-gate-ledger   # every push states what happened to each judgment gate
```

Copy them from `references/guards/`, mark them executable, then **enable per clone**:

```bash
git config core.hooksPath .githooks
```

**Opt-in per clone is deliberate.** `core.hooksPath` is local config, not something a checkout can set for you — and that's the right shape: a hook nobody enabled is honest, a hook that silently rewrites someone's workflow is not. The same scripts run in CI (below), which is where the rule is actually guaranteed.

## The rules, and where they came from

Both are distilled from MangaDock's `scripts/`, which exists because of three recurring failures the team named: **features colliding**, **features/plans getting lost**, and **silent quality regressions**. Their invariant is worth carrying verbatim:

> Every session starts with a clean tree · every piece of work has a GitHub issue · code reaches prod only through a merge from a named branch, never from a dirty working tree.

**`check-issue-ref`** — a reference may live in the branch name (`feat/42-thing`), any commit message on the branch (`#42`), or the PR body (passed as `PR_BODY` in CI). It is stricter than it looks in two places that matter:

- The number must sit in the **issue-slug position**, so `chore/bump-node-22` is not mistaken for a reference to issue 22.
- Only commits **on this branch** count. A `#ref` that exists solely on the base branch is someone else's work and must not vouch for this push.

**`check-tree-budget`** — fails above 25 tracked changes or 50 untracked files (`T4_MAX_TRACKED` / `T4_MAX_UNTRACKED`), and fails on any build artifact regardless of count. The budget exists because of a real incident: a **312-file WIP** accumulated on a shared MangaDock branch and blocked the next stage of work. "Start from a clean tree" was already the rule; the budget is what made it checkable instead of aspirational.

**`check-gate-ledger`** — every push must carry a `T4-Gates:` trailer on some commit on the branch, naming all five judgment gates with `ran` | `not-run` | `n-a`:

```
T4-Gates: simplify=ran code-review=ran scrutinize=not-run security-review=n-a verify=ran
```

**It does not force a gate to run.** `not-run` passes. What it forbids is saying *nothing* about a gate, because the other guards catch a missing artifact while a skipped judgment gate leaves no trace at all — and `t4-dev-workflow` admits hooks "can raise the cost of skipping a judgment skill but can't verify the reasoning". Raising that cost from zero is the entire job. It exists because of a real incident: an AFK batch on 2026-08-04 opened **nine PRs** (`pal-mcp-server` #44–#48, #50; `xeno-skills` #100–#103) with `/simplify`, `/code-review` and `/scrutinize` run **zero** times, and nothing failed, warned, or went missing — the omission surfaced only when the developer asked. Paying the gates afterwards found a real defect in **seven of the ten** PRs.

A trailer on any commit of the branch counts, since the claim is about the branch and a follow-up commit must not invalidate it. As with `check-issue-ref`, a trailer that exists only on the base branch is someone else's claim and does not vouch for this push.

**The `wip/` escape hatch, and its limit.** A `wip/*` branch bypasses the **count** gate, the issue-ref requirement and the gate ledger — that is the sanctioned way to push a deliberate one-time freeze, and the branch name is the declaration. It **never** bypasses the **artifact** gate: a freeze is a statement about how much unfinished work is in flight, never a licence to commit generated output.

## Same guards in CI

The local hook is opt-in and `--no-verify`-able, so it raises the floor rather than setting it. Wire the same scripts into the gate workflow (`ci-cd-layer.md`) to make them real:

```yaml
      - run: sh .githooks/check-tree-budget
      - run: sh .githooks/check-gate-ledger
        env:
          BASE_REF: origin/${{ github.base_ref }}
      - run: PR_BODY="$(gh pr view "${{ github.event.number }}" --json body -q .body)" sh .githooks/check-issue-ref
        env:
          BASE_REF: origin/${{ github.base_ref }}
          GH_TOKEN: ${{ github.token }}
```

One script, two callers — the local run and the CI run cannot drift, which is the failure that erodes trust in a local gate fastest.

## Where this overlaps the Claude gate — on purpose

`check-issue-ref` and the `PreToolUse` rule "a PR needs a referenced issue" enforce the same rule at different moments: the gate blocks `gh pr create` before the PR exists, the guard blocks the push regardless of who or what made it. **The overlap is the point** — the gate gives a fast, well-worded refusal inside the agent's loop; the guard is the one that still holds when the work didn't come through that loop.

They are not identical, and the difference is worth knowing: the gate reads only the `gh pr create` command string, so work pushed and PR'd another way never meets it. The guard reads the branch, the commits, and the PR body.

## Troubleshooting

| Symptom | Likely cause → fix |
|---|---|
| **The hook never runs** | `core.hooksPath` isn't set in this clone (it is per-clone by design) → `git config core.hooksPath .githooks`. Check with `git config --get core.hooksPath`. |
| **"no issue reference found" on a branch that has one** | The number isn't in the slug position (`feat/thing-42` ≠ `feat/42-thing`), or the `#ref` is only on the base branch → rename the branch, or put `#NNN` in a commit on this branch. |
| **The guard passes locally, fails in CI** | CI compares against a different base (`BASE_REF`) or has no `PR_BODY` → pass both, as in the snippet above. |
| **Over budget from files you didn't create** | Generated output isn't ignored → add it to `.gitignore`. The artifact gate is telling you the repo is missing an ignore rule, not that you did something wrong. |
| **A legitimate large change is blocked** | Split it across issue-scoped commits, or raise `T4_MAX_TRACKED` for the repo *deliberately* and say why. Raising it silently to land one push is how the budget stops meaning anything. |
| **`sh: not found` on Windows** | The hook needs a POSIX shell; Git for Windows provides one. Same dependency the `run-hook.cmd` launcher documents in `hooks-layer.md`. |

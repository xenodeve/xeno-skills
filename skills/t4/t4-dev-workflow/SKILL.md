---
name: t4-dev-workflow
description: Use when planning or implementing a feature/change in a T4-team repo (T4 Labs / Slow-Inc) — deciding how to go from idea to shipped code, filing or updating a GitHub issue or PRD, writing a bilingual (Thai + English) issue/PR body, opening a PR, or closing an issue. Covers the grill→PRD→issues→TDD pipeline, the PRD→issues→PR gate, the auto-triggered skill map, triage labels, and the issue lifecycle. Triggers include "let's build X", "file an issue for this", "write the PRD", "open a PR", "what labels", "how do we work here".
---

# T4 Dev Workflow

## Overview

The T4 team's development pipeline, built for an **agent-primary** repo where GitHub issues are the source of truth for *what to do* and *its state* — not a formality. Session-local todos must reconcile back to issues before the session ends. This skill covers how work flows from idea to merge, which skills fire automatically, and the tracker conventions (labels, lifecycle, bilingual bodies).

## The pipeline

When planning or implementing a feature, follow this order:

1. **`/grill-me`** — stress-test the concept interview-style before committing to it.
2. **`/grill-with-docs`** — challenge the plan against existing ADRs in `docs/adr/`; this also lazily produces domain docs (`CONTEXT.md` / ADRs) when a term or decision actually resolves.
3. **Survey the change sites** — enumerate *every* place the change touches **before** writing the plan (below). A PRD written without this plans the change you imagined, not the one the repo needs.
4. **`/to-prd`** — turn the grilled plan into a PRD (one PRD per epic), carrying the survey as its change inventory.
5. **`/to-issues`** — break the PRD into GitHub issues with triage labels (one issue per deliverable).
6. **`/tdd`** — implement test-first (red → green → refactor).

**Hard gate: PRD → issues → PR.** Never open a PR without a referenced issue. A PRD becomes issues before code; code maps to an issue before a PR.

## Survey the change sites before writing the plan

Most "surprise cases" aren't surprises — they're **sites the plan never knew about**. They surface mid-implementation, when the cheapest moment to have found them has already passed, and they arrive as scope growth (which under AFK is a 🛑 park). The survey is the step that converts them from surprises into line items.

**Do it after the concept is settled (`/grill-me`) and before `/to-prd`** — surveying a concept that's still moving is wasted, and planning without it is guessing.

**What to enumerate — don't stop at the obvious file:**

- **Every occurrence of the thing you're changing**, not the first one. `rg` for the symbol, the string, the config key, the route, the error message. **Duplicates are the classic miss:** the same list, rule, or constant written in two files drifts the moment you update one — this repo's own pipeline is described in both `SKILL.md` and `references/workflow-artifacts.md`, and a change to one alone is a defect.
- **Both sides of every mirror.** Bilingual doc pairs (`*.md` / `*.en.md`), a doc and its diagram, a script and its copy in another delivery path, a template and the test that guards it.
- **Callers, not just the definition.** Who consumes this? What breaks if its shape changes?
- **Tests and fixtures** that assert on what you're changing — including a test whose *string literals* encode the old wording.
- **Docs that state the current behavior.** A README sentence describing what you're about to change is a change site; leaving it is how docs drift.
- **Config, CI, and generated artifacts** that reference the thing by name.

**Output: a change inventory** — a flat list of `path` → *what changes there* → *how you'll verify it*. Put it in the PRD (`references/workflow-artifacts.md` has the block) and in the issue. It becomes the implementation checklist and, later, the reviewer's map.

**Say what the survey couldn't reach.** "I searched `rg '<symbol>'` across `skills/` and `docs/`; anything reached by dynamic name construction wouldn't appear" is an honest boundary and belongs in the plan. An unstated search boundary reads as completeness you didn't verify (`No verdict before evidence`, below).

**Cost check:** the survey is minutes of `rg`; the alternative is finding site #4 after the PR is open, when the fix is a re-plan. It scales down — a one-file change gets a one-line survey — but it doesn't get skipped, and skipping it needs the same proof any other rule does.

*The high-risk refactor protocol's "Inventory first" is this same step applied to behavior rather than files — do both when a refactor is in scope.*

## No verdict before evidence (don't state it as settled until it is)

A confident wrong answer is worse than an uncertain right one, because it ends the investigation. State claims in the register the evidence supports — and never upgrade a claim just because you've repeated it.

**Three registers. Pick the one you've earned:**

| Register | Use when | Say it like |
|---|---|---|
| **Verified** | you produced the evidence *in this session* | "`bun test` → 42 passed" · "read `auth.ts:88`, it returns early on null" |
| **Hypothesis** | it's reasoning, inference, or memory | "**Likely** the cache key collides — unverified, would confirm by ___" |
| **Unknown** | you don't know and haven't checked | "I don't know whether X; checking costs ___" |

**A verdict word requires a named artifact.** *Fixed · works · passes · safe · done · the root cause is · no impact* — each is a claim about the world, so each needs the command you ran, the output you saw, or the `file:line` you read, stated with it. Without that, downgrade the sentence to a hypothesis; don't delete the hedge to sound decisive.

**These are not evidence:**

- *"It should work"* / *"by design"* / *"the types line up"* — reasoning about code is not observing it.
- *"The docs say so"* — for a pinned or non-standard version, read the vendored source.
- *"It worked before"* / *"this pattern always works"* — not about this change.
- *"The test exists"* — existing ≠ run ≠ passing.
- **Another agent said so.** A subagent's or bot's report is a hypothesis until you check it (`clink-subagents` says the same: verify everything a subagent returns).

**The laundering failure mode — the one to actually watch for:** a guess stated in turn 1 gets referenced as established in turn 3, and by turn 6 it's the premise of a design decision no one can trace back to a check. **A claim's register never improves by being repeated or summarized.** When you carry a claim forward, carry its register with it.

**Reporting is part of the rule.** If you didn't run it, say you didn't — "tests not run" is a complete, acceptable sentence. Reporting a suite as green without running it is not optimism; it's a false statement about the repo. Same for partial work: name what's unfinished rather than letting "done" cover it.

**Why it's load-bearing here:** the records layer is an index future agents trust without re-checking (`t4-engineering-records` — validated-only, `file:line`, commit SHAs). One unverified verdict written as fact poisons it, and the cost lands on whoever inherits the repo, not on the session that saved a minute.

## Skipping a rule requires proof (the burden is on the skip)

Every rule here has a cost, so there is always a locally-reasonable argument for skipping one. That argument is exactly the failure mode: skipped once with a good story, the rule stops being a rule. So the burden of proof sits on the skip, never on compliance.

**The default is comply.** An exemption is valid only when you can state a **checkable fact about this specific change** that makes the rule inapplicable — one a reviewer can verify *without redoing your reasoning*.

| Not a proof (judgment dressed up) | A proof (checkable fact) |
|---|---|
| "Small change, tests can't be affected" | "`git diff --name-only` is `README.md` only — no code path is reachable from it" |
| "This is unrelated to the failing suite" | "The suite imports `src/a.ts`; the diff touches `src/b.ts`, which nothing in `a` imports — checked with the import graph" |
| "Obviously safe" / "I'm confident" | "The function is unreferenced: `rg 'fooBar\(' -g '!*.test.*'` returns only its definition" |
| "Running it is slow" | *Never* a proof. Cost is not evidence. |
| "The user is in a hurry" | *Never* a proof. Urgency changes priority, not truth. |

**If you cannot state the proof, follow the skill.** Uncertainty resolves toward compliance — always, and without asking. "I'm not sure whether this needs a test" means it needs a test.

**Say it where the work is reported.** An exemption that lives only in your head is a violation, not an exemption: write it in the PR body / the message reporting the work, in the form *rule → the checkable fact → how to verify it*. This is what makes it reviewable, and what makes a wrong exemption catchable later.

**Never exemptable by argument:**

- **Hook-enforced rules** — a PR needs a referenced issue, `verify` must pass, dangerous git. The gate does not read prose; arguing with it means disabling it, which is the anti-pattern itself.
- **Safety and trust boundaries** — `/security-review` on anything touching auth/secrets/input trust, and the destructive-command rules. The blast radius is asymmetric: being right saves minutes, being wrong is unrecoverable.
- **Anything the user has just told you to do.** A direct instruction is not a rule you get to prove your way out of.

**Consequence for a stated exemption that turns out wrong:** it becomes a record, not a shrug — the rule that was skipped goes back on, and the wrong proof is worth a line in the post-mortem (`t4-engineering-records`), because a bad exemption pattern will otherwise repeat.

*This meta-rule governs every "narrow exception" clause in these skills, including the one below.*

## Root cause before fix (applies to bugs *and* review findings)

**Do not propose a fix, and do not edit, until you can name the root cause with evidence.** The output of diagnosis is a sentence of the shape: *"X fails because `path/file.ts:42` does Y when Z, which I reproduced by ___."* Until you can write that sentence, any fix is a guess dressed as a solution.

The order — no step skipped because the answer "looks obvious":

1. **Reproduce.** A failing test, a command, or an exact sequence. If you can't reproduce it, say so explicitly and treat everything after as a hypothesis, not a diagnosis.
2. **Trace the actual path.** Read the real code from entry point to failure — not the diff, not the file you assume is at fault. Cite `file:line`.
3. **Falsify.** State the hypothesis so it can be wrong, then try to break it. If two causes both explain the symptom, you haven't finished.
4. **Then** propose the fix — and say which part of the trace it addresses.

`/debug-mantra` (9arm) is the discipline for this; invoke it on any bug, error, stack trace, or failing test rather than working from the symptom.

**Why it's a rule here:** a symptom-level fix in an agent-primary repo is expensive twice — it lands, looks green, and the real cause resurfaces later with the misleading fix now in the way. It also poisons the records layer: a post-mortem written from an untraced fix is a *wrong* index entry, worse than none (`t4-engineering-records`).

**Applies equally to:** review findings (`/scrutinize`, `/code-review` — verify the finding against the code before acting on it, including one an agent or a bot reported), CI failures (read the log; don't re-run hoping), and performance work (measure first; a guessed bottleneck is the same error wearing a stopwatch).

**The exceptions are narrow, and you say them out loud:** a trivially-reversible one-liner where reproduction costs more than the change, or an emergency mitigation to stop the bleeding — in which case the mitigation is *not* the fix, and the root cause stays open work (ledger row + issue).

## Auto-triggered skills (fire without waiting for the user)

| Trigger | Skill | Condition |
|---|---|---|
| Bug / error / stack trace | `/debug-mantra` | Start a debug session every time |
| Complex debug / perf regression | `/diagnose` | reproduce → minimise → hypothesise → fix |
| After fixing a bug | `/post-mortem` (see t4-engineering-records) | Record root cause + fix + validation |
| After writing or changing code | `/simplify` | Before committing — check over-engineering |
| Editing UI / frontend | `/impeccable` | Every time a component or CSS is touched |
| Before merge / ship | `/code-review` + `/scrutinize` | Correctness + outsider perspective |
| Touching auth / token / secret / any security boundary | `/security-review` | Every boundary crossing |
| After implementation | `/verify` | Confirm the feature works in the app |
| New UI needs a design brief | `/impeccable` (shape) | Plan the UX before implementing a component |
| UI ready to ship | `/impeccable` (audit + harden) | a11y / perf / responsive + edge cases before merge |
| Codebase complexity growing | `/improve-codebase-architecture` (or equivalent) | On a cadence (e.g. every few days) or after a major feature |
| Exploring unfamiliar code | `/zoom-out` | High-level context before editing |
| User asks "is there a skill for X?" | `/find-skills` | Search before hand-writing code |

## Capability router (optional)

Route by the *capability* a task needs, not a hardcoded tool name — the capability is stable; the tool/command is repo/runtime config that `t4-project-bootstrap` populates from the installed MCP/PAL tools.

| Capability | Tool (repo-configured — examples) |
|---|---|
| Code review | `mcp__pal__codereview` |
| Debug / diagnose | `mcp__pal__debug` |
| Architecture review | `mcp__pal__analyze` |
| Security audit | `mcp__pal__secaudit` |
| Test / QA planning | `mcp__pal__testgen` |
| Deep reasoning / second opinion | `mcp__pal__thinkdeep` / `consensus` |

If nothing is configured for a capability, use the general skills directly.

## What's mechanically enforced (vs. agent discipline)

In a repo with the T4 hooks installed (`t4-project-bootstrap` → `references/hooks-layer.md`), part of this pipeline is a **hard gate**, not just discipline the agent is trusted to keep:

- **PRD → issues → PR** — the `PreToolUse` gate **denies** `gh pr create` with no referenced issue.
- **Ship gate (`/verify`)** — before `gh pr merge` (merge is the ship point; not the iterative `create`), the gate **runs the repo's `verify` command itself** (`.claude/t4.json` `"verify"` — keep it fast; e2e belongs in CI) and denies on failure. The server-side CI required-check + branch protection is the real guarantee (it also covers a human merging on the web).
- **Before merge** — `gh pr merge` **asks** you to confirm `/code-review` + `/scrutinize` ran — unless `.claude/t4.json` sets `"autoMerge"`/`"afk"` (an unattended run under standing authorization), which skips the ask; the `verify` deny still holds.
- **Dangerous git** (`reset --hard`, force-push, `clean -f`, `branch -D`) is **denied**.
- **CI required checks** — the layer above the hooks (`t4-project-bootstrap` → `references/ci-cd-layer.md`): `lint`/`typecheck`/`test`/`build` are separate **required status checks** on `main` and direct pushes are blocked, so a red PR can't be merged by anyone — agent or human on the web. Where a ruleset isn't available, `.claude/t4.json` `"requireGreenCI": true` makes the gate check `gh pr checks` before merge instead (weaker: it only binds agent-run commands). E2E lives in CI, not in the local `verify`.

Everything else — TDD discipline, `/simplify`, the *depth* of a review — stays agent discipline, reinforced by the session-start dispatcher (the injected `using-t4` map). Hooks can raise the cost of skipping a judgment skill but can't verify the reasoning; only checkable actions are hard-enforced.

## High-risk / core refactor protocol

Ordinary TDD covers most changes. A refactor of a **large or load-bearing module** — a "god object", a critical seam, a monolith you're decomposing — needs more, because the risk is *silent behavior change during relocation*. When you're moving/extracting code in such a module, follow this (distilled from the MangaDock characterization ADRs):

1. **Inventory first.** List the behavioral variants and landmines the module actually has (known divergences, edge cases) before moving anything — you only preserve what you've named. (This is the *behavioral* half of the change-site survey above; a refactor needs both.)
2. **Characterize before you move.** Add characterization tests that pin the *current* output (quirks included) at the seam **first**. Refactor only behind green characterization — it's the net that catches a relocation that changed behavior.
3. **One seam per commit.** Extract one boundary at a time, each commit output-equivalent (ideally byte-identical). A reviewer or a diff can verify one seam; a ten-seam commit hides a regression.
4. **Never mix relocation with a behavior fix.** Move in one commit, fix in another — otherwise "did the move change anything?" is unanswerable.
5. **Preserve known divergences.** A deliberate quirk stays (with its characterization test); don't "clean it up" mid-move.
6. **Attach new features at the new seam, not the monolith** you're retiring.

Under AFK this is doubly load-bearing: seam/architecture decisions are a 🛑 **park** (see `t4-afk`), so an unattended run does the *mechanical* extraction behind characterization tests and parks the judgment calls.

## Bilingual tracker rule (GitHub only)

Issue bodies, PRD bodies, and PR descriptions must be **bilingual — English + a full Thai mirror**:

- **Title:** English, conventional-commit style (e.g. `fix(<scope>): ...`).
- **Body:** each section in English, then a mirrored Thai version — either a `## สรุปภาษาไทย` section covering the whole body, or `EN / TH` paired paragraphs per section for long docs.
- **The Thai must mirror the English exactly** — same detail, sentence count, bullets, tables. "สรุป" is not a summary; never shorten or omit.
- Code identifiers, filenames, log excerpts, and acceptance-criteria checkboxes stay English; the Thai explains them, never translates identifiers.
- **Review-reply comments may be English-only.** Anything a teammate reads to *decide* gets both languages.
- **Scope: the GitHub tracker.** This rule governs issue / PRD / PR bodies. Governed **agent docs** (`CONTEXT.md`, `DESIGN.md`, `PRODUCT.md`, `docs/agents/*`) have their *own* bilingual convention — `<!-- lang:en/th -->` markers, full mirror (see `t4-project-bootstrap` → governance-docs). Chat, reports, and status updates are single-language (the developer's — Thai); code, commit messages, and inline comments stay English.

## Issue lifecycle (Definition-of-Done gate)

- Every code change maps to **one issue you're allowed to work** — authored by us, or labeled `ready-for-agent`.
- Keep the issue **body** current (not just comments) as scope/state changes, bilingual.
- **Close with a stated reason** — completed-with-evidence / cancelled / duplicate / wontfix / stale. Never close silently; never leave finished work open.
- New work discovered mid-session gets a ledger row and (if non-trivial) an issue, so it doesn't vanish into MD (see t4-agent-memory).

## Triage labels

Five canonical triage roles: `needs-triage` · `needs-info` · `ready-for-agent` · `ready-for-human` · `wontfix`. Optional groups as the tracker grows: **Component** (one per issue), **Type** (`Bug`/`tech-debt`/`security`/`Feature`/…), **Severity** (`critical`/`Major`/`Minor` — a `security` issue must be `critical` or `Major`). Full definitions + the `docs/agents/triage-labels.md` skeleton are in the reference.

## Delegation guardrail

Delegate only mechanical, low-blast-radius work to a cheap subagent (bulk renames, boilerplate, log summarizing, grep-and-report). Never delegate security-boundary code, architecture/seam decisions, bilingual issue/PR authoring, or judgment-gated skills (`/scrutinize`, `/code-review`, `/security-review`, `/debug-mantra`). A delegated change is not exempt from the verify/E2E mandate. See **`references/delegation.md`** for the discipline: sizing (chunk by independently-governed unit), the Option A/B skill-handoff economics (a handed-off skill costs context budget, not free), landmine injection into the child prompt, and component-aware verification.

## Skeletons

See `references/workflow-artifacts.md` for: `docs/agents/{workflow,issue-tracker,triage-labels}.md`, and the PRD / design-spec / implementation-plan templates.

## Cross-skill

- Recording the *outcome* of the work (post-mortem / ADR / impact entry) → **t4-engineering-records**.
- Reconciling issues ↔ the open-work ledger, and session-start reads → **t4-agent-memory**.
- Scaffolding these files into a new repo → **t4-project-bootstrap**.

## Common mistakes

- **Opening a PR with no issue.** Breaks the gate; the work has no tracked state.
- **A Thai body that summarizes instead of mirrors.** The rule is same-depth mirror, not a digest.
- **Closing an issue silently.** Always state the reason + evidence.
- **Fixing the symptom you saw first.** Name the root cause with evidence before proposing or applying a fix — see above.
- **Planning from the first file you opened.** Survey every change site before the PRD; the sites you didn't look for become mid-implementation "surprises".
- **Translating code identifiers into Thai.** Identifiers stay English; the Thai explains around them.

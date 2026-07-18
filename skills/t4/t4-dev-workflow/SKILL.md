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
3. **`/to-prd`** — turn the grilled plan into a PRD (one PRD per epic).
4. **`/to-issues`** — break the PRD into GitHub issues with triage labels (one issue per deliverable).
5. **`/tdd`** — implement test-first (red → green → refactor).

**Hard gate: PRD → issues → PR.** Never open a PR without a referenced issue. A PRD becomes issues before code; code maps to an issue before a PR.

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

Everything else — TDD discipline, `/simplify`, the *depth* of a review — stays agent discipline, reinforced by the session-start dispatcher (the injected `using-t4` map). Hooks can raise the cost of skipping a judgment skill but can't verify the reasoning; only checkable actions are hard-enforced.

## High-risk / core refactor protocol

Ordinary TDD covers most changes. A refactor of a **large or load-bearing module** — a "god object", a critical seam, a monolith you're decomposing — needs more, because the risk is *silent behavior change during relocation*. When you're moving/extracting code in such a module, follow this (distilled from the MangaDock characterization ADRs):

1. **Inventory first.** List the behavioral variants and landmines the module actually has (known divergences, edge cases) before moving anything — you only preserve what you've named.
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
- **Translating code identifiers into Thai.** Identifiers stay English; the Thai explains around them.

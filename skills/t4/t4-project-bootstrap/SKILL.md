---
name: t4-project-bootstrap
description: Use when starting, scaffolding, or setting up a new repository for the T4 team (T4 Labs / Slow-Inc) — or retrofitting an existing one — so an agent-primary repo gets the team's standard operating layer (domain glossary, product brief, decision records, durable memory, dev workflow) in one pass instead of hand-copying docs from a sibling repo. Triggers include "set up a new T4 project", "scaffold the docs/conventions", "add CLAUDE.md + docs/agents", "bootstrap the governance layer", "port the MangaDock conventions".
---

# T4 Project Bootstrap

## Overview

The T4 team (T4 Labs / `Slow-Inc`) runs several repos — MangaDock, T4-Fastwork, and more — where **the coding agent is the primary developer**. They share one operating standard, built so an agent keeps context across sessions and compaction. This skill scaffolds that standard into a new (or under-documented) repo in one pass.

**Core principle:** the standard is agent infrastructure, not team paperwork. You are installing the files a future agent will read at session start to know *what the words mean, why the code is the way it is, what's still open, and how to ship*. Copy the structure and rules; fill `<PLACEHOLDER>` tokens with this project's specifics; never carry another project's domain content across.

This skill owns the **domain + product layer** and orchestrates the install. The ongoing-use disciplines are sibling skills — install their files here, but read them for the how:

- **`using-t4`** — the entry-point map routing a task to the right skill below. The repo's `CLAUDE.md` should point a fresh agent here first.
- **`t4-agent-memory`** — durable working memory (open-work ledger, ship log, survey-manifest, memory vault, Serena). The retrieval-first backbone of an agent-primary repo.
- **`t4-engineering-records`** — ADRs, post-mortems, the impact register, the bug-case catalog.
- **`t4-dev-workflow`** — the grill→PRD→issues→TDD pipeline, bilingual tracker rules, triage labels, auto-triggered skills.

## When to use

- Standing up a brand-new T4 repo (before or just after the code scaffold).
- An existing T4 repo missing the operating layer (no memory ledger, no `CONTEXT.md`, no `docs/agents/`).
- You caught yourself about to hand-copy a doc from MangaDock/T4-Fastwork — do this instead.

**When NOT to use:** a throwaway prototype; a non-T4 project (the bilingual tracker rule and label vocabulary are team-specific).

## Tier by agent-context-load, not team size

An agent-primary repo needs its **memory layer from day one** — that's what makes work survive a context reset. So the memory backbone is default-on; scale the rest by how much the agent has to hold.

| Repo stage | Install |
|---|---|
| **Seed** (new repo, first sessions) | `CLAUDE.md` wiring · **the workflow-hooks layer** (`references/hooks-layer.md`) — keeps the session on the rails from day one · `docs/agents/{domain,issue-tracker,triage-labels,workflow}.md` (`t4-dev-workflow`) · `docs/adr/README.md` (`t4-engineering-records`) · **`docs/OPEN-WORK-LEDGER.md` + `DONE.md` + the memory vault** (`t4-agent-memory`) — memory is not deferred. Create `CONTEXT.md`/`UBIQUITOUS_LANGUAGE.md`/`PRODUCT.md` **lazily** (proceed-silently rule). |
| **Active** (real feature work, growing surface) | + `CONTEXT.md` + `UBIQUITOUS_LANGUAGE.md` + `PRODUCT.md` + `DESIGN.md` + `docs/reports/README.md` + `post-mortem` / `impact-register` / `bug-catalog` (`t4-engineering-records`) + `docs/superpowers/{plans,specs}/` (`t4-dev-workflow`) + the `survey-manifest` (`t4-agent-memory`). |
| **Consolidating** (work scattered; agent misses MD-only items) | + a full `docs/OPEN-WORK-LEDGER.md` reconciliation pass + Serena `mem:` graph. This is the tier where the ledger earns its keep. |
| **Formal delivery** (academic / client dossier) | + the optional 7-phase SE set — see `references/se-deliverables.md`. On demand only. |

## Bootstrap procedure

1. **Read the target repo first.** `git remote -v` (get `<ORG>/<REPO>`), the existing `CLAUDE.md`/`AGENTS.md`, `package.json` (package manager, pinned framework versions), any `docs/` present. Never overwrite a governed doc — reconcile.
2. **Pick a tier** with the user; memory layer is in from the Seed tier.
3. **Write the `CLAUDE.md` wiring** — engineering north-star, repo layout, commands, a pointer to **`using-t4`** as the entry map, the **session-start read protocol** (point it at `docs/OPEN-WORK-LEDGER.md` + the memory vault `Home.md` — see `t4-agent-memory`), the dev-notification protocol, the bilingual writing-conventions block, and pointers to `docs/agents/*`.
4. **Install the memory layer** from `t4-agent-memory` (ledger, ship log, vault `Home.md` + note format). This is what makes the repo agent-durable.
5. **Install the workflow layer** from `t4-dev-workflow` (`docs/agents/{workflow,issue-tracker,triage-labels}.md`) — replace `<ORG>/<REPO>`, the E2E/verify command, the label vocabulary.
6. **Install the hooks layer** from `references/hooks-layer.md` — copy the marker (`.claude/t4.json`), the `.claude/hooks/` scripts + `run-hook.cmd`, merge the hook entries into `.claude/settings.json`, and write `using-t4.snapshot.md`. This is what keeps a session on the rails: session-start injects `using-t4`, a per-turn reminder re-anchors it, and a `PreToolUse` gate blocks a PR with no issue and dangerous git. Tell the user what the gate will block.
7. **Install the records layer** from `t4-engineering-records` (`docs/adr/README.md`; the templates the tier calls for).
8. **Write the domain/product docs** from `references/governance-docs.md` at the chosen tier.
9. **Verify placeholders are gone** — grep the new files for `<PLACEHOLDER>` / a stale `<ORG>/<REPO>` and any residual sibling-project domain words (e.g. manga/cache/MIT). A leftover is a defect.
10. **Reconcile, don't duplicate** — upgrade any narrower existing rule to the team standard; don't leave two conflicting statements.

## Reference files

- **`references/governance-docs.md`** — the domain/product/index layer this skill owns: taxonomy + status system, and skeletons for `CONTEXT.md`, `UBIQUITOUS_LANGUAGE.md`, `PRODUCT.md`, `docs/agents/domain.md`, and the reports/research/plans README indexes. (ADR, memory, and workflow skeletons live in the sibling skills.)
- **`references/se-deliverables.md`** — the optional 7-phase Software-Engineering deliverable set + UML outline (formal delivery only).
- **`references/hooks-layer.md`** + **`references/hooks/`** — the workflow-hooks layer (path A): the `.claude/t4.json` marker, the `.claude/hooks/` scripts + `run-hook.cmd`, and the `settings.json` hook entries that make session-start / prompt-reminder / PreToolUse-gate keep a session on the T4 rails. The scripts are byte-identical to the `xeno-skills` plugin's `hooks/` (a repo test enforces the sync).

## The non-negotiable team rules

These are the rules the skeletons carry; know them so you don't dilute them.

- **Agent memory is first-class.** The ledger + ship log + vault exist so a fresh agent recovers state. Install them early; keep them retrieval-first (see `t4-agent-memory`).
- **Bilingual (TH + EN) is GitHub-tracker-only, Thai mirrors English exactly** — issue bodies, PRD bodies, PR descriptions. Not chat/reports. Identifiers stay English. (See `t4-dev-workflow`.)
- **PRD → issues → PR.** Never a PR without a referenced issue. Issues are the source of truth.
- **TDD is mandatory** for features and bugfixes.
- **Non-standard framework version → read the vendored docs first** (e.g. `node_modules/<pkg>/dist/docs/`), not prior knowledge.
- **Verify every frontend change end-to-end** — unit tests can't see real layout/hydration; run the repo's E2E/verify pass and add a case per new page/interactive UI.
- **Bun** is the package manager/runtime — commit `bun.lock`, never `package-lock.json`/`yarn.lock`, use `bunx`.
- **Close issues with a stated reason**; **domain glossary is load-bearing**; **proceed silently if a governance file is absent** (details in the sibling skills + `references/governance-docs.md`).

## Common mistakes

- **Deferring the memory layer.** In an agent-primary repo that's the one thing you can't defer — without it, the next session starts blind.
- **Carrying sibling-project domain content across.** Strip every manga/cache/MIT/wallet word. Grep before you commit.
- **Duplicating a sibling skill's skeleton here.** Bootstrap installs those files but the skeletons + discipline live in `t4-agent-memory` / `t4-engineering-records` / `t4-dev-workflow`. Reference, don't copy.
- **Weakening the bilingual rule** to match an older repo's narrower version — upgrade to the team standard.
- **Leaving `<PLACEHOLDER>` tokens or a stale `<ORG>/<REPO>`.** Step 8 exists for this.

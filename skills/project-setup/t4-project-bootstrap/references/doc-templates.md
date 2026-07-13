# Doc Templates — ready-to-copy skeletons

Reusable writing templates for a T4 repo. Fill `<PLACEHOLDER>` tokens; strip sibling-project domain words. Outer fences are four backticks where a template contains its own ``` blocks.

## When to use which

| Situation | Template |
|---|---|
| A bug is fixed **and validated** — closing the ticket / opening the fix PR | **post-mortem** |
| Any system-affecting change (feature, refactor, security, hotfix) needs a report-level log entry | **system-impact-report** entry |
| A notable bug worth remembering for its transferable lesson (retro / onboarding / deck) | **bug-case-catalog** entry |
| Defining *what* to build and *why*, before design — problem, users, requirements, acceptance, scope | **PRD** |
| Turning an approved PRD into a concrete technical design — architecture, data flow, per-file changes | **design-spec** |
| Turning a design into an ordered, TDD, checkbox execution list | **implementation-plan** |
| Recording what was read (files/issues/PRs) so the next scan can skip/diff unchanged sources | **survey-manifest** |

---

## post-mortem-template.md

The canonical record of a **fixed, validated bug**, written after the fix lands. Code identifiers (`file:line`, function names, commit SHAs) are the index the next person greps back through.

```markdown
# Post-mortem template (<PROJECT>)

> The canonical engineering record of a **fixed, validated bug**. Written *after* a fix lands,
> *for* other engineers + future-you. Code identifiers are first-class (function names,
> `file:line`, commit SHAs) — the index that lets the next person grep back to the change.
>
> **When to use:** closing a bug issue, or opening a PR that fixes a bug.
> **When NOT to use:** a feature / refactor (use the impact-report change record instead),
> a trivial one-liner (the PR description is enough), or a not-yet-validated fix (refuse — a
> post-mortem of a hypothesis is worse than none). A customer-visible outage needs a separate
> incident report, not this.
>
> <If your repo requires bilingual tracker posts, note it here.> Copy the block below, fill it,
> delete the guidance italics. Also drop a one-line pointer into the system-impact report.

## Required inputs — do not draft without all four
- [ ] **Reliable repro** exists (deterministic or high-rate, runnable by the next person).
- [ ] **Root cause known** (the mechanism, not a hypothesis).
- [ ] **Fix identified** (PR / commit / branch).
- [ ] **Fix validated** (the original repro now passes / the failing workload now succeeds).

If any is missing: list what's missing and stop.

---

## Template (fill, keep this order)

**Summary** *(mandatory)* — one paragraph: what broke (in user/workload terms), what fixed it
(one sentence), issue #, PR #, owner. A reader who stops here has the right answer.

**Symptom** — what was actually observed: test output, error message, log line, perf number,
screenshot. Concrete identifiers, not paraphrase.

**Root cause** *(mandatory)* — the actual mechanism. Code identifiers expected: function,
`file:line`, branch condition, the commit SHA of the offending change. Walk the cause chain
end-to-end. Most important section.

**Why it produced the symptom** — link cause → symptom when non-obvious (the bug is in X but
the visible failure is Y, three frames later).

**Fix** *(mandatory)* — what changed and **why it addresses the root cause** (not hides the
symptom). Link PR/commit. If a prior attempt papered over it, name it + what was wrong.

**How it was found** — the debugging path: the repro that made it deterministic; the tool that
cracked it; hypotheses tried + rejected (one line each); the single experiment that confirmed it.

**Why it slipped through** — the real reason it reached the branch/release: CI gap, latent code
(correct when written, broken by a later change elsewhere), workload gap, incomplete prior fix,
or review miss. **Blameless** — describe the gap, never the person.

**Validation** *(mandatory)* — how we know it works: original failing test now passes (name/link),
benchmark/E2E now succeeds, perf number before → after. **State coverage honestly** — if only one
config was tested, say so.

**Action items / follow-ups** — concrete next-steps not in the fix PR (regression test at `<seam>`,
refactor to prevent the class, CI gap closed, doc updated, related ticket filed). If none: write
"None — the fix is sufficient." Don't manufacture items.

## Rules
- Refuse without all four required inputs. Never invent root cause / owner / validation / action items.
- Keep code identifiers — they are the index.
- Blameless; active voice; no hedging ("we believe" / "appears to" → drop or prove).
```

---

## system-impact-report.md (change + tech-debt register)

Curated, report-level record of changes that **affect the running system**, plus the tech-debt register. Append a dated section per significant batch.

````markdown
# <PROJECT> — System-Impact Change & Tech-Debt Report

> Curated, report-level record of changes that **affect the running system** plus the
> **tech-debt register**. Audience: team / stakeholders / status reports. Append a dated
> section per significant batch; keep entries terse + linkable.
>
> **Required fields per system-affecting change** (write "not measured" / "N/A" honestly —
> never fabricate numbers): **What & where** (component / file:line) · **Why** (problem/goal) ·
> **Before → After** (concrete observable difference) · **Performance Δ** · **Quality** ·
> **Validation** (tests / E2E / benchmark) · **Risk / rollback** · **Links** (issue #, commit).

---

## <YYYY-MM-DD> — <Short change title> (<feature | bugfix/hotfix | refactor | security>) [— #<issue>]

**Scope:** <area(s) + key files touched> · **Type:** <one line> · **Tests:** <N/N green (+M new); typecheck; E2E status>
[**Severity:** <low/medium/high — only for bug/security entries>]

**What & where:** <concrete symbols / new files / modified files with responsibilities.>

**Why:** <the problem or goal this change addresses.>

**Before → After:** <old observable behavior> → <new observable behavior>.

**Performance Δ:** <measured latency/memory/token delta, or "N/A" honestly.>

**Quality:** <correctness / UX improvement vs the target.>

**Validation:** <tests green, N new unit tests covering <cases>; typecheck; E2E result. State "Not run: <X>" honestly.>

**Risk / rollback:** <additive? single knob? revert steps.>

**Links:** <#issue, #related, commit SHAs, ADR, spec/handoff docs.>

---
````

---

## bug-case-catalog.md (war-stories)

A durable, curated catalog keyed by the **CS concept** each bug demonstrates. Each entry is a compact **symptom → root cause → fix → lesson**. Good for retros, onboarding, decks.

```markdown
# <PROJECT> — Bug & Engineering Case Catalog (War Stories)

> Curated catalog of notable bugs and engineering cases. Each entry:
> **symptom → root cause → fix → the lesson**. Sourced from the dev log, the system-impact
> report, memory notes, and git history.

## ⭐ Top <N>

| # | Case | The concept it demonstrates |
|---|---|---|
| 1 | **<Case name>** | <concurrency / atomicity / cache coherency / input validation / …> |

## <Category, e.g. A. Concurrency & Distributed Systems>

### <A1>. <Case title> → <one-line resolution>
- **Symptom:** <what was actually observed, in concrete terms.>
- **Root cause:** <the actual mechanism — name the class of bug (TOCTOU, shared mutable state, fail-open config, …).>
- **Fix:** <what changed and why it addresses the root cause; note if TDD/RED→GREEN.>
- **Lesson:** <the transferable, durable takeaway.> *(<source ref: issue #, ADR, doc>)*
```

---

## PRD template

Distilled from a numbered feature PRD and an infra PRD — keeps the strongest sections of both. If the repo requires bilingual PRDs, duplicate the whole block under a `<!-- lang:th -->` … `<!-- lang:end -->` marker.

````markdown
<!-- lang:en -->
# PRD: <Feature / Component name> [(Phase <N>)]

**Component:** `<area>` · **Owner:** <owner>
**Labels:** `<status-label>` · `<area>` · `<type>`
**Status:** <Draft | Ready for implementation | Approved>

---

## Problem Statement
<The concrete pain today: what's broken, slow, missing, or costly, and why it matters as the product scales.>

## Goals
- <Measurable outcome 1>

## Non-goals / Out of Scope
- <Explicitly excluded item> (<deferred to Phase X | rejected: reason>)

## Target Users
- **<Persona>:** <what they need / do with this.>

## User Stories
1. As a <persona>, I want <capability> so that <benefit>.

## Functional Requirements
### <Sub-system 1>
- <Requirement, concrete and testable.>

## UI/UX Specifications  *(if user-facing)*
- **<Design principle / pattern>:** <constraint.>

## Technical Architecture / Implementation Decisions
### Modules to build or modify
**New: `<Module>`** — <responsibility, interface it implements, how wired.>
**Modified: `<Module>`** — <what changes and why.>

### Data model / conventions
| <Object type> | <Key pattern / table> |
|---|---|
| <…> | <…> |

### Key flow(s)
```
<request → decision → side-effect → response, as a small ASCII diagram>
```

## Acceptance Criteria / Testing Decisions
| Module | What to test |
|---|---|
| `<Module>` | <same input → same output; failure/expiry paths; tamper rejection.> |

## Risks & Rollback
- <Risk> → <mitigation / rollback plan.>

## Further Notes
- <Defaults that keep local dev / CI zero-config; idempotency requirements; ownership split.>
<!-- lang:end -->
````

---

## design-spec template (`docs/superpowers/specs/`)

A dated, approvable design doc: problem, goals, target architecture with a data-flow diagram, and concrete per-file changes (with illustrative code) — the "what and why" a plan then turns into ordered tasks.

````markdown
# <Feature> — Design Spec

**Date**: <YYYY-MM-DD>
**Status**: <Draft | Approved>
**Scope**: <module(s) / components touched>

---

## Problem
1. **<Problem 1>**: <concrete description — latency, correctness, missing capability.>

> **Note (<context, e.g. local dev>)**: <environment caveat a reader must know.>

## Goals
- <Target end-state behavior 1.>
- <Security / correctness invariants to uphold.>

## Architecture

### Data Flow
```
<step-by-step flow across services: trigger → backend → event/side-effect → client update>
```

## <Backend | Frontend> Changes

### 1. `<NewService>` (new file: `<path>`)
```<lang>
// illustrative interface / core logic — not the final code, the shape
```

### 2. <New endpoint> (in `<controller>`)
```
<METHOD> <route>
Guards: <auth / ownership>
```
Security layers:
1. <auth guard>
2. <ownership check before subscribe/act>
3. <auto-close / timeout / idempotency>
4. <response headers / wire format>

### 3. `<ExistingUnit>` — **unchanged / modified**
<what stays, what changes, and the ordering constraint (e.g. emit only after DB commit succeeds).>
````

---

## implementation-plan template (`docs/superpowers/plans/`)

A dated, checkbox-driven, TDD-ordered plan derived from a design spec. Each task names exact files and is executable task-by-task.

````markdown
# <Feature> Implementation Plan

> **For agentic workers:** use a subagent-driven / plan-execution skill to implement this plan
> task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** <one sentence: the observable end-state this plan delivers.>

**Architecture:** <2-3 sentences summarizing the mechanism from the design spec.>

**Tech Stack:** <frameworks · libs · language, one line>

## Global Constraints
- <Invariant every task must uphold.>
- <Ordering constraint, e.g. emit only after DB commit succeeds.>
- <What must NOT change.>

## File Map
| File | Action | Responsibility |
|---|---|---|
| `<path>` | **Create** | <what it owns> |
| `<path>` | **Modify** | <what changes> |

---

### Task <N>: <Task name>

**Files:**
- Create: `<path>`
- Modify: `<path>`

**Interfaces — Produces:**
- `<Type.method(args): ReturnType>`

- [ ] **Step 1: Write failing tests**
  <create `<spec path>` with the cases that pin the behavior.>
- [ ] **Step 2: Run tests — verify FAIL**
  ```bash
  <test command scoped to the new spec>
  ```
  Expected: `<the failure message proving RED>`
- [ ] **Step 3: Implement <unit>**
- [ ] **Step 4: Run tests — verify PASS**
- [ ] **Step 5: <wire into module / integration step, if any>**
````

---

## survey-manifest convention (`docs/reports/survey-manifest/`)

A central, provenance-rich knowledge base so a later scan (a new report, an ADR, an audit) does **not** re-read files/issues/PRs that haven't changed.

**Scan procedure (for the next agent):**
1. Open the fragment covering the area to update (see the index table).
2. Before re-reading, check whether the recorded source changed:
   - Code/docs: `git log -1 --format=%H -- <path>` vs stored `last_commit` — equal ⇒ **skip**.
   - Issue/PR: `gh issue view <n> --json updatedAt` / `gh pr view <n> --json updatedAt` vs stored `updated_at` — equal ⇒ skip.
3. If changed, read only the diff (`git diff <last_commit>..HEAD -- <path>`), not the whole file, unless the diff is huge.
4. Update only the changed part and bump `last_commit` / `updated_at`.

**Per-entry provenance schema:**

```markdown
### <file path>                         <!-- code/doc -->
- **last_commit:** <full SHA from `git log -1 --format=%H -- <path>`>
- **lines_covered:** <"1-450 (full)" | "230-310 (partial — boilerplate skipped)">
- **read_date:** <YYYY-MM-DD>
- **findings:** <short bullets with line-number references>

### Issue/PR #<n>                        <!-- github -->
- **state:** open/closed/merged (at read time)
- **updated_at:** <ISO timestamp from gh>
- **read_date:** <YYYY-MM-DD>
- **findings:** <short bullets>
```

Add a **Fragment index** table (Fragment | Scope | Status) at the top, plus an "already surveyed — don't repeat unless diffing" list that links back to the canonical output rather than duplicating findings.

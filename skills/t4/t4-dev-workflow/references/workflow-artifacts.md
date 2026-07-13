# Workflow Artifacts — skeletons

Drop-in skeletons for the T4 dev workflow. Fill `<PLACEHOLDER>` tokens; strip sibling-project domain words. Outer fences are four backticks where a template contains its own ``` blocks.

## `docs/agents/workflow.md`

```markdown
# Agent Workflow

How agents plan and implement in this repo, and which skills to invoke automatically.

## Development workflow

When planning or implementing a feature, follow this order:

1. **`/grill-me`** — stress-test the concept first (interview-style)
2. **`/grill-with-docs`** — challenge the plan against existing ADRs in `docs/adr/`
3. **`/to-prd`** — create a PRD from the grilled plan (one PRD per epic)
4. **`/to-issues`** — break the PRD into GitHub issues on `<ORG>/<REPO>` with triage labels (one issue per deliverable)
5. **`/tdd`** — implement test-first, then make the tests pass

Hard ordering: **PRD → issues → PR**. Never open a PR without a referenced issue.

## Auto-triggered skills

| Trigger | Skill | Condition |
|---|---|---|
| Bug / error / stack trace | `/debug-mantra` | Start a debug session every time |
| After fixing a bug | `/post-mortem` | Record root cause + fix + validation |
| After writing or changing code | `/simplify` | Before committing — check over-engineering |
| Editing UI / frontend | `/impeccable` | Every time a component or CSS is touched |
| Before merge / ship | `/code-review` + `/scrutinize` | Correctness + outsider perspective |
| Touching a security boundary | `/security-review` | Every time code crosses auth/secret/token |
| After implementation | `/verify` | Confirm the feature works in the app |

## Verification mandate

Run `<E2E_OR_VERIFY_COMMAND>` to verify every `<FRONTEND_OR_RELEVANT>` change — unit tests
can't see real layout/hydration. Add a test case when adding a page or interactive UI.
```

## `docs/agents/issue-tracker.md`

```markdown
# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues on `<ORG>/<REPO>`. Use the `gh` CLI for all operations.

> **`gh` path/auth:** <if not on PATH, give the full path>. Authenticated as `<USER>`, with access to the `<ORG>` org.

## Language: bilingual bodies (English + Thai)

Every issue body, PRD body, and PR description must be **bilingual**:

- **Title**: English, conventional-commit style (e.g. `fix(<scope>): ...`).
- **Body**: each section in English, then a mirrored Thai version — a `## สรุปภาษาไทย` section
  covering the whole body, or `EN / TH` paired paragraphs per section for long docs.
- **Thai must mirror English exactly** — same detail, sentence count, bullets, tables. Never
  summarise or omit. "สรุป" does not mean "shorter".
- Code identifiers, filenames, log excerpts, and acceptance-criteria checkboxes stay English;
  the Thai explains them, never translates identifiers.
- Review-reply comments may be English-only; anything a teammate reads to decide gets both languages.

## Conventions

- **Create**: `gh issue create --title "..." --body "..."` (heredoc for multi-line bodies).
- **Read**: `gh issue view <n> --comments`.
- **List**: `gh issue list --state open --json number,title,body,labels,comments --jq '...'`.
- **Comment**: `gh issue comment <n> --body "..."`.
- **Label**: `gh issue edit <n> --add-label "..."` / `--remove-label "..."`.
- **Close (with REASON)**: `gh issue close <n> --comment "<reason + evidence>"`.

Infer the repo from `git remote -v` — `gh` does this automatically inside a clone.

## Skill phrase mapping

- "publish to the issue tracker" → create a GitHub issue.
- "fetch the relevant ticket" → `gh issue view <n> --comments`.
```

## `docs/agents/triage-labels.md`

```markdown
# Triage Labels

The skills speak in five canonical triage roles. This file maps them to the repo's label strings.

| Role | Label in our tracker | Meaning |
| ---- | -------------------- | ------- |
| `needs-triage`    | `needs-triage`    | Maintainer needs to evaluate this issue |
| `needs-info`      | `needs-info`      | Waiting on the reporter for more information |
| `ready-for-agent` | `ready-for-agent` | Fully specified, ready for an AFK agent |
| `ready-for-human` | `ready-for-human` | Requires human implementation |
| `wontfix`         | `wontfix`         | Will not be actioned |

## Optional label groups (add as the tracker grows)

- **Component** — one per issue: `<AREA_1>`, `<AREA_2>`, … (which part of the codebase owns it).
- **Type** — one or more: `Bug`, `tech-debt`, `security`, `Optimization`, `Cleanup`, `Feature`, `Test`.
- **Severity** — one per Bug/Security: `critical`, `Major`, `Minor`.
- **Lifecycle** — `Latent` (exists in code, not yet manifested), `Dormant` (real but deprioritised).

## Conventions

- Every issue has ≥1 triage-state label and (if component labels exist) exactly one component label.
- `security` issues must be `critical` or `Major` — a `Minor` security label is not valid.
- A `Latent` bug that activates is upgraded to a full Bug issue with severity.
```

## PRD template (output of `/to-prd`)

If the repo requires bilingual PRDs, duplicate the whole block under a `<!-- lang:th -->` … `<!-- lang:end -->` marker.

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
<!-- lang:end -->
````

## design-spec template — `docs/superpowers/specs/YYYY-MM-DD-<slug>-design.md`

````markdown
# <Feature> — Design Spec

**Date**: <YYYY-MM-DD>
**Status**: <Draft | Approved>
**Scope**: <module(s) / components touched>

---

## Problem
1. **<Problem 1>**: <concrete description — latency, correctness, missing capability.>

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

## implementation-plan template — `docs/superpowers/plans/YYYY-MM-DD-<slug>.md`

````markdown
# <Feature> Implementation Plan

> **For agentic workers:** use a subagent-driven / plan-execution skill to implement this plan
> task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** <one sentence: the observable end-state this plan delivers.>

**Architecture:** <2-3 sentences summarizing the mechanism from the design spec.>

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

**Files:** Create `<path>` · Modify `<path>`
**Interfaces — Produces:** `<Type.method(args): ReturnType>`

- [ ] **Step 1: Write failing tests** — create `<spec path>` with the cases that pin the behavior.
- [ ] **Step 2: Run tests — verify FAIL**
  ```bash
  <test command scoped to the new spec>
  ```
  Expected: `<the failure message proving RED>`
- [ ] **Step 3: Implement <unit>**
- [ ] **Step 4: Run tests — verify PASS**
- [ ] **Step 5: <wire into module / integration step, if any>**
````

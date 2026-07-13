# Record Templates — skeletons

Drop-in skeletons for T4 engineering records. Fill `<PLACEHOLDER>` tokens; strip sibling-project domain words. Outer fences are four backticks where a template contains its own ``` blocks.

## post-mortem — `docs/reports/YYYY-MM-DD-<slug>.md`

The canonical record of a **fixed, validated bug**, written after the fix lands. Code identifiers are the index the next agent greps back through.

```markdown
# Post-mortem — <short title> (<YYYY-MM-DD>)

## Required inputs — do not draft without all four
- [ ] **Reliable repro** exists (deterministic or high-rate, runnable by the next person).
- [ ] **Root cause known** (the mechanism, not a hypothesis).
- [ ] **Fix identified** (PR / commit / branch).
- [ ] **Fix validated** (the original repro now passes / the failing workload now succeeds).

If any is missing: list what's missing and stop.

---

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

**Action items / follow-ups** — concrete next-steps not in the fix PR. If none: write
"None — the fix is sufficient." Don't manufacture items.
```

## system-impact register entry — append to `docs/reports/system-impact-report.md`

````markdown
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

The file header (write once, at the top of the register):

```markdown
# <PROJECT> — System-Impact Change & Tech-Debt Report

> Curated, report-level record of changes that **affect the running system** plus the
> **tech-debt register**. Audience: team / stakeholders / status reports. Append a dated
> section per significant batch; keep entries terse + linkable. Write "not measured" / "N/A"
> honestly — never fabricate numbers.
```

## bug-case-catalog entry — append to `docs/reports/bug-case-catalog.md`

```markdown
### <A1>. <Case title> → <one-line resolution>
- **Symptom:** <what was actually observed, in concrete terms.>
- **Root cause:** <the actual mechanism — name the class of bug (TOCTOU, shared mutable state, fail-open config, …).>
- **Fix:** <what changed and why it addresses the root cause; note if TDD/RED→GREEN.>
- **Lesson:** <the transferable, durable takeaway.> *(<source ref: issue #, ADR, doc>)*
```

The file header + top-N table (write once):

```markdown
# <PROJECT> — Bug & Engineering Case Catalog (War Stories)

> Curated catalog of notable bugs and engineering cases. Each entry:
> **symptom → root cause → fix → the lesson**. Sourced from the dev log, the system-impact
> report, memory notes, and git history.

## ⭐ Top <N>
| # | Case | The concept it demonstrates |
|---|---|---|
| 1 | **<Case name>** | <concurrency / atomicity / cache coherency / input validation / …> |
```

## a single ADR — `docs/adr/NNNN-<kebab-title>.md`

```markdown
# ADR NNNN — <Full decision title>

- **Status:** Accepted (<YYYY-MM-DD>) — <implemented | impl pending #NNN | planned | Superseded by NNNN>
- **Area:** <Frontend | Backend | Infra | …>
- **Related:** <links to related ADRs / issues / the code seam this completes>

## Context

<The forces at play. What problem, what constraints, what pressures made a decision necessary.>

## Decision

<What was chosen, concretely, grounded in the code as it is now. Cite `file:line`. Number the
distinct mechanisms if there are several.>

## Alternatives considered

- **<Alternative>.** Rejected — <why.>
- **<Alternative>.** Rejected — <why.>

## Consequences

- **Positive:** <what this buys.>
- **Negative / limits:** <the cost, the fragile invariant, what must be maintained by hand.>
- **Follow-ups:** <tests missing, future work, conditions that would reopen this.>
```

## ADR index — `docs/adr/README.md`

```markdown
# Architecture Decision Records

Each ADR captures one significant, hard-to-reverse decision: its context, what was chosen,
the alternatives rejected, and the consequences. They document decisions **already in the
codebase** (unless marked *pending*), so a new maintainer — human or agent — can recover the
*why* without re-deriving it. A decision that overturns an earlier one marks the old ADR **Superseded**.

| # | Title | Area | Status |
|---|-------|------|--------|
| [0001](0001-<kebab-title>.md) | <Short decision title> | <Area> | Accepted |
| [0002](0002-<kebab-title>.md) | <Title> | <Area> | **Superseded by 000N** |
| [0003](0003-<kebab-title>.md) | <Title> | <Area> | Accepted — **impl pending** (#NNN) |

## Conventions

- Filename: `NNNN-kebab-title.md`, zero-padded. **Numbers must be unique** across *all* branches.
- Body: title line, a status/context bullet block, then `## Context`, `## Decision`,
  `## Alternatives considered`, `## Consequences`.
- Ground every claim in the code as it is **now**; cite `file:line`.
```

# Governance & Knowledge Docs — taxonomy, conventions, skeletons

The canonical governance doc set for a T4 repo, the status/index conventions that bind them, and drop-in skeletons. Fill `<PLACEHOLDER>` tokens; strip every sibling-project domain word.

## 1. Doc taxonomy & file map

| Doc | Location | Purpose |
|-----|----------|---------|
| `CLAUDE.md` | root | Agent operating manual: engineering north-star, repo structure, commands, writing conventions, `docs/agents/*` wiring, architecture map. |
| `CONTEXT.md` | root | System-context doc — subsystem architecture notes, truth hierarchies, dated design captures. Points at `UBIQUITOUS_LANGUAGE.md` as the canonical glossary. (Multi-context repos use `CONTEXT-MAP.md` → one `CONTEXT.md` per bounded context.) |
| `UBIQUITOUS_LANGUAGE.md` | root | Canonical term glossary: bold terms + definition + "aliases to avoid", relationships, example dialogue, flagged ambiguities. |
| `PRODUCT.md` | root | Product brief — users, purpose, brand personality, anti-references, principles, accessibility. The "why". |
| `DESIGN.md` | root | Visual design system — YAML frontmatter (color/type/spacing/component tokens) + prose (colors, typography, elevation, components, do/don'ts). The "how". |
| `Roadmap.md` | root | Phase-by-phase implementation roadmap (Phase 0→N) preceded by a small "engineering pillars" preamble. |
| `docs/adr/` | dir + `README.md` | Architecture Decision Records — one file per significant hard-to-reverse decision. |
| `docs/reports/` | dir + `README.md` | Change registers, post-mortems, benchmarks, dated snapshots. |
| `docs/research/` | dir + `README.md` | Deep-dive analyses / reference material. |
| `docs/superpowers/plans/` | dir + `README.md` | Dated implementation plans (checkbox lists) written before executing a feature. |
| `docs/superpowers/specs/` | dir | Design specs paired with plans (a plan links its spec). |
| `docs/OPEN-WORK-LEDGER.md` | `docs/` | Single consolidated source of all open work — GitHub-tracked and MD-only — deduped, phased. Read at session start. |
| `DONE.md` | root | Append-only session log: what each session shipped (Goal/Shipped/Validation/Report). |
| `docs/agents/*.md` | `docs/` | Agent skill configs — see `agent-conventions.md`. |
| Team memory | in-repo Obsidian vault (e.g. `Obsidian-<Repo>/`, gitignored or committed per team choice) | `Home.md` is a Map-of-Content index of one-note-per-memory records with `type`/`description` frontmatter + `[[wikilinks]]`. |

## 2. Status vocabulary & index convention

Every `docs/<subdir>/` opens its `README.md` with a one-line purpose, a **status legend**, an optional `> Start here:` pointer, then a **table** indexing every file.

Status vocabulary (reports/research/plans):

- `LIVING` — kept current; edit in place.
- `SNAPSHOT` — point-in-time; **never edit**, add a new dated one.
- `ARCHIVED` — superseded/historical; retained for the record.
- `TEMPLATE` — a skeleton to copy.
- `REALIZED` — (plans only) the work landed; kept as history.

Index table shape: `| File | Status | What it is |` (plans use `What it planned`). ADRs use `| # | Title | Area | Status |`, where ADR Status is `Accepted` / `Superseded by NNN` / `Accepted — impl pending (#NNN)` / `Accepted — planned`.

- Dated files: `YYYY-MM-DD-slug.md`, SNAPSHOT by nature.
- A superseded doc keeps a **redirect marker** at its top pointing to its replacement.
- READMEs note site-render visibility when a docs site exists (e.g. "Not rendered on the public docs site").

## 3. Cross-cutting conventions to encode

- **Bilingual doc bodies via language markers.** Root docs wrap each language in `<!-- lang:en -->…<!-- lang:end -->` and `<!-- lang:th -->…<!-- lang:end -->`. The Thai side is a **full mirror, same depth — not a summary**. Code identifiers, env vars, and glossary terms stay English inside Thai text. (This is the *doc-body* convention; the *GitHub-tracker* bilingual rule lives in `agent-conventions.md`.)
- **PRODUCT vs DESIGN split.** `PRODUCT.md` = why (users, brand, principles); `DESIGN.md` = how (tokens, components, do/don'ts). Cross-link, don't duplicate. `DESIGN.md` carries machine-readable tokens in YAML frontmatter.
- **Proceed silently if absent.** If `CONTEXT.md` / `CONTEXT-MAP.md` / `docs/adr/` don't exist, proceed silently — don't flag or pre-scaffold; they're created lazily when a term or decision actually resolves.
- **Single-context now, multi-context later.** Start with one root `CONTEXT.md` + `docs/adr/`. Introduce `CONTEXT-MAP.md` (→ per-context `CONTEXT.md` + context-scoped `docs/adr/`) only when a second bounded context appears.
- **Glossary is load-bearing.** Any domain concept in an issue title, hypothesis, test name, or PR uses the exact bold term; drifting to an "alias to avoid" is a defect. A concept missing from the glossary is a signal (inventing language, or a real gap to model).
- **ADR discipline.** Quality/perf-affecting or non-trivial decisions get an ADR; overturning one marks the old ADR **Superseded by NNN**. ADR numbers are globally unique across branches. Claims cite `file:line` against current code.
- **Status markers + redirects.** SNAPSHOT/benchmark files are never edited — add a new dated one. Superseded docs get a redirect marker.
- **Ledger ↔ issue reconciliation.** GitHub issues are the task source of truth; the ledger consolidates issue-tracked + MD-only work. 🔴 = MD-only/untracked = highest miss-risk. Finishing an item updates both the ledger row and the issue.

---

## 4. Skeletons

### CONTEXT.md

(Outer fence is four backticks because the template itself contains ``` blocks.)

````markdown
<!-- lang:en -->
# <Project> System Context

## Language

> **Canonical glossary = `UBIQUITOUS_LANGUAGE.md`** (root). The terms below are a
> local quick-reference for this document; if they ever disagree, `UBIQUITOUS_LANGUAGE.md` wins.

**<Term>**:
<One-paragraph definition — what it is, why it exists, what it is NOT authoritative for.>
_Avoid_: <alias>, <alias>, <alias>

**<Term>**:
<Definition.>
_Avoid_: <alias>, <alias>

### Example dialogue

> **Dev A:** "<question that would use the term wrongly>"
> **Dev B:** "<correction that pins the precise meaning>"

---

## <Subsystem> Architecture — <YYYY-MM-DD>

### <Aspect>
<Prose or fenced diagram describing how the subsystem works as it is NOW.>

### Truth Hierarchy   <!-- if the subsystem has layered state -->
```
<Layer>  <impl>   — <role / durability note>
<Layer>  <impl>   — <role>
DB       <impl>   — <long-term authority>
```

### Module Graph   <!-- optional, fenced ASCII tree -->
```
<RootModule>
  ├── <Module> (<note>)
  └── <Module>
```
<!-- lang:end -->

<!-- lang:th -->
# <Project> System Context — ภาษาไทย
<Thai mirror of the above — same depth, not a summary.>
<!-- lang:end -->
````

### UBIQUITOUS_LANGUAGE.md

```markdown
<!-- lang:en -->
# Ubiquitous Language

Canonical term glossary for <Project>. When a term appears in **bold**, use it exactly
as written — in code identifiers, PR descriptions, issue titles, and team conversations.

---

## <Category>

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **<Term>** | <Definition, may reference other **bold** terms> | <alias>, <alias> |
| **<Term>** | <Definition> | <alias> |

---

## Relationships

- A **<Term>** contains one or more **<Term>**.
- <Ordered pipeline / cardinality statements using bold terms.>

---

## Example dialogue

> **Dev:** "<realistic question using the terms>"
> **Domain expert:** "<answer that disambiguates overlapping terms>"

---

## Flagged ambiguities

- **"<loose term>" vs "<canonical term>"**: <where each appears in code/UI; which is
  canonical and why.>
<!-- lang:end -->

<!-- lang:th -->
# Ubiquitous Language — คำศัพท์มาตรฐาน
<Thai mirror — same tables, keep code identifiers in English.>
<!-- lang:end -->
```

### PRODUCT.md

```markdown
# Product

> This is the product brief (users, purpose, brand). The **visual design system** —
> color tokens, typography, components, do/don'ts — is canonical in **`DESIGN.md`**;
> the brand/principles below are the "why", DESIGN.md is the "how".

## Register

product

## Users

<Primary user + what they need from this product. Secondary surface/users if any.>

## Product Purpose

<What the product is and the job it does. A concrete "succeeds when…" statement.>

## Brand Personality

<3–5 adjective-led paragraphs describing the intended feel.>

## Anti-references

**<Thing to avoid>** — <why it's wrong for us.>

## Design Principles

1. **<Principle>** — <one line.>
2. **<Principle>** — <one line.>

## Accessibility & Inclusion

<WCAG target, i18n stance, reduced-motion, focus indicators.>
```

### docs/adr/README.md

```markdown
# Architecture Decision Records

Each ADR captures one significant, hard-to-reverse decision: its context, what was chosen,
the alternatives rejected, and the consequences. They document decisions **already in the
codebase** (unless marked *pending*), so a new maintainer — human or agent — can recover the
*why* without re-deriving it. New quality/perf-affecting or non-trivial decisions get an ADR;
a decision that overturns an earlier one marks the old ADR **Superseded**.

| # | Title | Area | Status |
|---|-------|------|--------|
| [0001](0001-<kebab-title>.md) | <Short decision title> | <Area> | Accepted |
| [0002](0002-<kebab-title>.md) | <Title> | <Area> | **Superseded by 000N** |
| [0003](0003-<kebab-title>.md) | <Title> | <Area> | Accepted — **impl pending** (#NNN) |

## Conventions

- Filename: `NNNN-kebab-title.md`, zero-padded number. **Numbers must be unique** across *all*
  branches — pick the next free number before reusing one.
- Body: title line, a status/context bullet block, then `## Context`, `## Decision`,
  `## Alternatives considered`, `## Consequences`.
- Ground every claim in the code as it is **now**; cite `file:line`.
```

### A single ADR file (`NNNN-title.md`)

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

### docs/reports/README.md

```markdown
# docs/reports — index & status

Change registers, post-mortems, benchmarks, and dated snapshots. Status:
`LIVING` = keep current · `SNAPSHOT` = point-in-time (don't edit, add new) ·
`ARCHIVED` = superseded/historical · `TEMPLATE`.

> **Start here:** current open work → `../OPEN-WORK-LEDGER.md`. Change/tech-debt register →
> `system-impact-report.md`. Durable war-stories → `bug-case-catalog.md`.

| File | Status | What it is |
|------|--------|-----------|
| `system-impact-report.md` | LIVING | Full-field change log + tech-debt register (append per batch) |
| `bug-case-catalog.md` | LIVING | symptom→root→fix→lesson war-stories (durable learnings) |
| `post-mortem-template.md` | TEMPLATE | Post-mortem skeleton for bug write-ups |
| `YYYY-MM-DD-<slug>.md` | SNAPSHOT | <one-off dated write-up> |
| `benchmarks/*` | SNAPSHOT | Dated before/after measurements + proof assets — never edit, add new |
```

### docs/research/README.md

```markdown
# docs/research — index & status

Deep-dive analyses (reference material, mostly archival). Status:
`LIVING` = keep current · `SNAPSHOT` = point-in-time, don't edit · `ARCHIVED` = superseded.

> **Start here:** <the canonical reference doc for the main investigation>.

| File | Status | What it is |
|------|--------|-----------|
| `<canonical-analysis>.md` | LIVING | <the reference comparison / map> |
| `<study>.md` | SNAPSHOT (MM-DD) | <executive summary> |

> Note: <call out any deliberate read-order chain among the docs.>
```

### docs/superpowers/plans/README.md

```markdown
# docs/superpowers/plans — index & status

Dated implementation plans (checkbox task lists) written before executing a feature.
Most are `REALIZED` (the work landed — kept as historical record). Check the matching
commit/issue before assuming a plan is still open.

| File | Status | What it planned |
|------|--------|-----------------|
| `YYYY-MM-DD-<slug>.md` | REALIZED | <feature> (spec in `../specs/YYYY-MM-DD-<slug>-design.md`) |

> These are archival by nature — a plan is a snapshot of intent at its date. For current
> work use `../../OPEN-WORK-LEDGER.md`, not these files.
```

### docs/OPEN-WORK-LEDGER.md

```markdown
# Open Work Ledger — consolidated single source (<YYYY-MM-DD>)

> **Why this file exists:** open work was scattered across GitHub issues, ADRs, plans, and
> DONE.md. Agents read issues but often miss the MD. This ledger consolidates **everything
> still open** — GitHub-tracked **and** MD-only — into one place, deduped, with a phased plan.
> **Read this file at session start (it is linked from CLAUDE.md).** When you finish an item,
> update its row here AND its GitHub issue; when you discover new work, add a row here and
> (for anything non-trivial) file an issue so it doesn't vanish into MD again.

**Legend:** ✅ done, pending merge · 🟢 buildable now · 🟡 gated (needs merge / resource /
decision) · 🔴 **UNTRACKED** (MD-only, no GitHub issue — highest miss-risk)

---

## Track <N> — <theme>

| Item | Status | Gate | Next action |
|---|---|---|---|
| #<NNN> <item> | 🟡 | <blocker> | <next step> |
| <MD-only item> | 🔴 | — | <source doc:line> |

---

## Management Plan — phased execution order

**Phase 0 — <unblock, highest leverage>.** <the actions nothing else can proceed without.>
**Phase 1 — Tracking hygiene.** File issues for the 🔴 UNTRACKED items.
**Phase 2 … — <themed batches>.**

**Gating summary:** <which phase is the multiplier and why.>
```

### DONE.md (append-only session log; newest on top)

```markdown
# DONE — Claude Code Session Log

---

## <Title of the change> (<YYYY-MM-DD>, <skill e.g. /tdd + /debug-mantra>, branch `<branch>`)

**Goal:** <what the session set out to fix/build and why it mattered.>

**Shipped (<N files>):**
- `<path>` — <what changed and why>
- `<path>` — <what changed>

**Validation:** <tests: N pass / 0 fail; typecheck/lint state; live E2E result with the
concrete observed behavior that proves it works.>

**Report:** <link to the post-mortem / ADR / impact-report entry created; pointers added.>

**Next:** <optional — follow-up work surfaced, filed as #NNN or noted 🔴.>

---
```

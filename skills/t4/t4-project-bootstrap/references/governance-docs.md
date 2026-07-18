# Governance & Knowledge Docs — taxonomy, conventions, skeletons

The domain/product/index layer a T4 repo gets at setup. Fill `<PLACEHOLDER>` tokens; strip every sibling-project domain word.

> **Ownership.** This file holds the *setup-time* skeletons the bootstrap writes. Ongoing-use
> artifacts live with their discipline skill: the **open-work ledger, ship log, survey-manifest,
> and memory vault** → `t4-agent-memory`; **ADRs, post-mortems, the impact register, the bug-case
> catalog** → `t4-engineering-records`; **`docs/agents/{workflow,issue-tracker,triage-labels}.md`,
> PRD / spec / plan templates** → `t4-dev-workflow`.

## 1. Doc taxonomy & file map

The full governance doc set for a T4 repo, and which skill owns each.

| Doc | Location | Owner skill | Purpose |
|-----|----------|-------------|---------|
| `CLAUDE.md` | root | bootstrap | Agent operating manual: north-star, repo structure, commands, memory + notify wiring, `docs/agents/*` pointers, architecture map. |
| `CONTEXT.md` | root | bootstrap | System-context doc; points at `UBIQUITOUS_LANGUAGE.md` as the canonical glossary. (Multi-context repos use `CONTEXT-MAP.md`.) |
| `UBIQUITOUS_LANGUAGE.md` | root | bootstrap | Canonical term glossary: bold terms + definition + "aliases to avoid". |
| `PRODUCT.md` | root | bootstrap | Product brief (the "why"). |
| `DESIGN.md` | root | bootstrap | Visual design system (the "how") — YAML token frontmatter + prose. |
| `docs/agents/domain.md` | `docs/` | bootstrap | How agents consume `CONTEXT.md` + `docs/adr/`. |
| `docs/reports/README.md`, `docs/research/README.md`, `docs/superpowers/plans/README.md` | `docs/` | bootstrap | Status-indexed README for each knowledge dir. |
| `docs/adr/` + `README.md` | `docs/` | **t4-engineering-records** | Architecture Decision Records + index. |
| `docs/OPEN-WORK-LEDGER.md`, `DONE.md`, `docs/reports/survey-manifest/`, `Obsidian-<Repo>/` | root/`docs/` | **t4-agent-memory** | Durable working memory. |
| `docs/agents/{workflow,issue-tracker,triage-labels}.md` | `docs/` | **t4-dev-workflow** | Pipeline + tracker conventions. |

## 2. Status vocabulary & index convention

Every `docs/<subdir>/` opens its `README.md` with a one-line purpose, a **status legend**, an optional `> Start here:` pointer, then a **table** indexing every file.

Status vocabulary: `LIVING` (edit in place) · `SNAPSHOT` (point-in-time, never edit — add a new dated one) · `ARCHIVED` (superseded/historical) · `TEMPLATE` · `REALIZED` (plans only — the work landed).

Index table shape: `| File | Status | What it is |` (plans use `What it planned`). Dated files: `YYYY-MM-DD-slug.md`. A superseded doc keeps a **redirect marker** at its top pointing to its replacement.

## 3. Cross-cutting conventions to encode

- **Bilingual doc bodies via language markers.** Root docs wrap each language in `<!-- lang:en -->…<!-- lang:end -->` and `<!-- lang:th -->…<!-- lang:end -->`. The Thai side is a **full mirror, same depth — not a summary**. Code identifiers, env vars, and glossary terms stay English inside Thai text. (The *GitHub-tracker* bilingual rule is in `t4-dev-workflow`.)
- **PRODUCT vs DESIGN split.** `PRODUCT.md` = why (users, brand, principles); `DESIGN.md` = how (tokens, components, do/don'ts). Cross-link, don't duplicate.
- **Proceed silently if absent.** If `CONTEXT.md` / `CONTEXT-MAP.md` / `docs/adr/` don't exist, proceed silently — don't flag or pre-scaffold; they're created lazily when a term or decision actually resolves.
- **Single-context now, multi-context later.** Start with one root `CONTEXT.md` + `docs/adr/`. Introduce `CONTEXT-MAP.md` (→ per-context `CONTEXT.md` + context-scoped `docs/adr/`) only when a second bounded context appears.
- **Glossary is load-bearing.** Any domain concept in an issue title, hypothesis, test name, or PR uses the exact bold term; drifting to an "alias to avoid" is a defect. A concept missing from the glossary is a signal (inventing language, or a real gap to model).

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
DB       <impl>   — <long-term authority>
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

## <Category>

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **<Term>** | <Definition, may reference other **bold** terms> | <alias>, <alias> |

## Relationships

- A **<Term>** contains one or more **<Term>**.

## Flagged ambiguities

- **"<loose term>" vs "<canonical term>"**: <which is canonical and why.>
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

## Users
<Primary user + what they need. Secondary surface/users if any.>

## Product Purpose
<What the product is and the job it does. A concrete "succeeds when…" statement.>

## Brand Personality
<3–5 adjective-led paragraphs describing the intended feel.>

## Anti-references
**<Thing to avoid>** — <why it's wrong for us.>

## Design Principles
1. **<Principle>** — <one line.>

## Accessibility & Inclusion
<WCAG target, i18n stance, reduced-motion, focus indicators.>
```

### docs/agents/domain.md

````markdown
# Domain Docs

How engineering skills should consume this repo's domain documentation when exploring.

## Layout: Single-context

One `CONTEXT.md` at the root covers the whole codebase.

```
/
├── CONTEXT.md          ← domain glossary for the whole codebase
├── docs/adr/           ← architectural decision records
└── <SRC>/
```

(Revisit as multi-context — a root `CONTEXT-MAP.md` pointing at one `CONTEXT.md` per
context, plus context-scoped `docs/adr/` — once a second package/context is added.)

## Before exploring, read these

- **`CONTEXT.md`** at the repo root — the system-context doc; the **canonical term glossary is `UBIQUITOUS_LANGUAGE.md`** (`CONTEXT.md` points at it and defers to it on any conflict).
- **`docs/adr/`** — read ADRs touching the area you're about to work in before proposing alternatives.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't
suggest creating them upfront. The producer skill (`/grill-with-docs` → `/domain-modeling`)
creates them lazily when terms or decisions actually get resolved.

## Use the glossary's vocabulary

When your output names a domain concept (issue title, refactor proposal, hypothesis, test
name), use the term exactly as defined in `CONTEXT.md`. Don't drift to synonyms the glossary
avoids. If a concept isn't in the glossary yet, that's a signal — either you're inventing
language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly instead of silently overriding:

> _Contradicts ADR-<NNNN> (<one-line decision>) — but worth reopening because…_
````

### docs/reports/README.md · docs/research/README.md · docs/superpowers/plans/README.md

```markdown
# docs/<reports|research|plans> — index & status

<one-line purpose>. Status: `LIVING` = keep current · `SNAPSHOT` = point-in-time (don't edit,
add new) · `ARCHIVED` = superseded · `TEMPLATE` <· `REALIZED` for plans>.

> **Start here:** <the canonical pointer for this dir, e.g. `../OPEN-WORK-LEDGER.md` for reports>.

| File | Status | What it is |
|------|--------|-----------|
| `<file>.md` | LIVING | <one line> |
| `YYYY-MM-DD-<slug>.md` | SNAPSHOT | <dated write-up> |
```

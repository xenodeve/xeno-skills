# Domain Docs

How engineering skills should consume this repo's domain documentation when exploring.

## Layout: Single-context

One `CONTEXT.md` at the root covers the whole repo.

```
/
├── CONTEXT.md              ← domain glossary for the whole repo
├── UBIQUITOUS_LANGUAGE.md  ← canonical term glossary (CONTEXT.md points at it)
├── docs/adr/               ← architectural decision records
├── docs/research/          ← empirical research that calibrated the skills
└── skills/                 ← the skills themselves
```

(Revisit as multi-context — a root `CONTEXT-MAP.md` pointing at one `CONTEXT.md` per
context — once the repo gains a second bounded context.)

## Before exploring, read these

- **`CONTEXT.md`** at the repo root — the system-context doc; the **canonical term glossary is `UBIQUITOUS_LANGUAGE.md`** (`CONTEXT.md` points at it and defers to it on any conflict).
- **`docs/adr/`** — read ADRs touching the area you're about to work in before proposing alternatives.
- **`docs/research/`** — the empirical data (delegation routing, effort ladders) the `multi-agent` skills' figures are drawn from.

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

> _Contradicts ADR-0001 (hook-based workflow enforcement) — but worth reopening because…_

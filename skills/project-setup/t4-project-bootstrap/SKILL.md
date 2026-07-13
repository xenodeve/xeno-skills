---
name: t4-project-bootstrap
description: Use when starting, scaffolding, or setting up a new repository for the T4 team (T4 Labs / Slow-Inc) — or retrofitting an existing one — and you need the team's standard governance docs, agent operating conventions, ADR/report/PRD structure, and doc templates without hand-copying them from a sibling repo. Triggers include "set up a new T4 project", "scaffold the docs/conventions", "add CLAUDE.md + docs/agents", "bootstrap the governance layer", "port the MangaDock conventions".
---

# T4 Project Bootstrap

## Overview

The T4 team (T4 Labs / `Slow-Inc`) runs several repos — MangaDock, T4-Fastwork, and more — that share **one** documentation, governance, and agent-operating standard. This skill is that standard, distilled and made project-agnostic, so a new (or under-documented) repo gets the whole layer in one pass instead of re-porting docs by hand every time.

**Core principle:** the conventions are the product. Copy the *structure and rules*, fill the `<PLACEHOLDER>` tokens with this project's specifics, never carry another project's domain content across.

What this installs, at full scope:

- **Domain layer** — `CONTEXT.md` + `UBIQUITOUS_LANGUAGE.md` (glossary that's load-bearing in every issue/PR/test name).
- **Product layer** — `PRODUCT.md` (the "why") split from `DESIGN.md` (the "how").
- **Decision layer** — `docs/adr/` + its `README.md` index.
- **Knowledge layer** — `docs/reports/`, `docs/research/`, `docs/superpowers/{plans,specs}/`, each with a `README.md` status index; `docs/OPEN-WORK-LEDGER.md`; `DONE.md`.
- **Agent layer** — `CLAUDE.md` wiring + `docs/agents/{workflow,domain,issue-tracker,triage-labels}.md` + Serena memory conventions.
- **Templates** — post-mortem, system-impact register, bug-case catalog, PRD, design-spec, implementation-plan, survey-manifest.
- **Optional formal deliverable** — the 7-phase Software-Engineering document set (academic / client dossier only).

## When to use

- Standing up a brand-new T4 repo (before or just after the code scaffold).
- An existing T4 repo is missing the governance layer (no ADR index, no `CONTEXT.md`, no `docs/agents/workflow.md`).
- You caught yourself about to hand-copy a doc from MangaDock/T4-Fastwork into another repo — do this instead.

**When NOT to use:** a throwaway prototype or a repo that will never carry issues/ADRs; a non-T4 project (the bilingual TH+EN tracker rule and specific label vocabulary are team-specific).

## Don't install everything blindly — tier by repo maturity

Match scope to the project, or you bury a small repo in empty scaffolding.

| Repo stage | Install |
|---|---|
| **Minimal** (new, single package) | `CLAUDE.md` wiring · `docs/agents/{domain,issue-tracker,triage-labels,workflow}.md` · `docs/adr/README.md` · `docs/reports/README.md` + `post-mortem-template.md`. Create `CONTEXT.md`/`UBIQUITOUS_LANGUAGE.md`/`PRODUCT.md` **lazily** (see the "proceed silently if absent" rule). |
| **Standard** (active feature work) | Everything in Minimal + `CONTEXT.md` + `UBIQUITOUS_LANGUAGE.md` + `PRODUCT.md` + `DESIGN.md` + `docs/superpowers/{plans,specs}/README.md` + `DONE.md` + Serena memory conventions. |
| **Consolidating** (work scattered across issues + MD) | Everything in Standard + `docs/OPEN-WORK-LEDGER.md` + `docs/reports/{system-impact-report,bug-case-catalog}.md`. |
| **Formal delivery** (academic / client dossier) | Add the 7-phase SE set — see `references/se-deliverables.md`. Optional, on demand only. |

## Bootstrap procedure

1. **Read the target repo first.** `git remote -v` (get `<ORG>/<REPO>`), the existing `CLAUDE.md`/`AGENTS.md`, `package.json` (package manager, pinned framework versions), and any `docs/` already present. Never overwrite an existing governed doc — reconcile.
2. **Pick a tier** from the table above with the user; don't over-scaffold.
3. **Fill the `CLAUDE.md` wiring** — engineering north-star, repo layout, commands, the writing-conventions (bilingual scope) block, and the "Agent skills" pointers to `docs/agents/*`. See `references/agent-conventions.md`.
4. **Write the agent layer** (`docs/agents/*`) from `references/agent-conventions.md` skeletons — replace `<ORG>/<REPO>`, the E2E/verify command, and the label vocabulary.
5. **Write the governance/knowledge docs** from `references/governance-docs.md` skeletons at the chosen tier.
6. **Drop in the templates** the tier calls for from `references/doc-templates.md` (post-mortem template always; the rest as needed).
7. **Verify placeholders are gone** — grep the new files for `<` `PLACEHOLDER` `>` and any residual sibling-project domain words (e.g. manga/cache/MIT). A leftover placeholder or foreign domain term is a defect.
8. **Reconcile, don't duplicate** — if the repo already has a narrower version of a rule (e.g. a looser bilingual scope), upgrade it to the team standard and note the change; don't leave two conflicting statements.

## Reference files

Read the one you need when you reach that step — don't load all four up front.

- **`references/governance-docs.md`** — doc taxonomy, the LIVING/SNAPSHOT/ARCHIVED/TEMPLATE status system, and full skeletons for `CONTEXT.md`, `UBIQUITOUS_LANGUAGE.md`, `PRODUCT.md`, ADR README + a single ADR, the `docs/reports|research|plans/README.md` indexes, `OPEN-WORK-LEDGER.md`, and `DONE.md`.
- **`references/agent-conventions.md`** — the T4 dev workflow (grill → PRD → issues → TDD), the auto-triggered-skills table, the cross-repo hard rules (bilingual scope, TDD, framework-doc-reading, E2E-verify mandate, Bun/lockfile), and skeletons for `docs/agents/{workflow,domain,issue-tracker,triage-labels}.md` + Serena memory conventions.
- **`references/doc-templates.md`** — ready-to-copy skeletons: post-mortem, system-impact register, bug-case catalog, PRD, design-spec, implementation-plan, survey-manifest, plus a "when to use which" table.
- **`references/se-deliverables.md`** — the optional 7-phase Software-Engineering deliverable set (project plan + Gantt, SRS + analysis, dialogues + prototype, internal docs + versioning, test spec + UAT, deployment + manuals, quality + process evidence) and a UML report outline.

## The non-negotiable team rules (encode these in every repo)

These are the rules the skeletons carry; know them so you don't dilute them when filling placeholders.

- **Bilingual (TH + EN) is GitHub-tracker-only, and the Thai must *mirror* the English** — same depth, bullets, tables. Applies to issue bodies, PRD bodies, PR descriptions. Not chat, not reports. Code/commits/identifiers stay English. ("สรุป" ≠ shorter.)
- **PRD → issues → PR.** Never open a PR without a referenced issue. GitHub issues are the source of truth for *what* and its *state*.
- **TDD is mandatory** for features and bugfixes (the `/tdd` step isn't optional).
- **Non-standard framework version → read the vendored docs first** (e.g. `node_modules/<pkg>/dist/docs/`), not prior knowledge.
- **Verify every frontend change end-to-end** — unit tests can't see real layout/hydration; run the repo's E2E/verify pass and add a case per new page/interactive UI.
- **Bun** is the package manager/runtime — commit `bun.lock`, never `package-lock.json`/`yarn.lock`, use `bunx`.
- **Close issues with a stated reason** (completed-with-evidence / cancelled / duplicate / wontfix / stale) — never silently.
- **Domain glossary is load-bearing** — name concepts with the exact bold term from `CONTEXT.md`/`UBIQUITOUS_LANGUAGE.md`; drifting to an "alias to avoid" is a defect. A missing term is a signal to model it, not to invent language.
- **Proceed silently if a governance file is absent** — the domain/producer skills create `CONTEXT.md`/ADRs lazily when a term or decision actually resolves; don't flag their absence or scaffold them prematurely on a minimal repo.

## Common mistakes

- **Carrying sibling-project domain content across.** The whole point is project-agnostic structure — strip every manga/cache/MIT/wallet word. Grep before you commit.
- **Over-scaffolding a tiny repo.** Empty `docs/research/` and an `OPEN-WORK-LEDGER` with nothing in it are noise. Tier it.
- **Weakening the bilingual rule.** Some older repos state a narrower scope; the team standard is issue *bodies* + PRD bodies + PR descriptions with an exact Thai mirror. Upgrade, don't match-the-weakest.
- **Leaving `<PLACEHOLDER>` tokens** or a stale `<ORG>/<REPO>`. Step 7 exists for this.
- **Duplicating instead of reconciling** an existing doc — you end up with two conflicting rule statements.

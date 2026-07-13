# Agent Conventions — workflow, rules, `docs/agents/*` skeletons

The T4 team's agent operating standard: how agents plan/implement, which skills auto-fire, the hard cross-repo rules, and drop-in `docs/agents/*` skeletons. Fill `<PLACEHOLDER>` tokens.

## 1. The T4 development workflow

Canonical order when planning or implementing any feature:

1. **`/grill-me`** — stress-test the concept interview-style before committing.
2. **`/grill-with-docs`** — challenge the plan against existing ADRs in `docs/adr/`; also lazily produces domain docs (`CONTEXT.md` / ADRs) when a term or decision resolves.
3. **`/to-prd`** — turn the grilled plan into a PRD (one PRD per epic).
4. **`/to-issues`** — break the PRD into GitHub issues with triage labels (one issue per deliverable).
5. **`/tdd`** — implement test-first (red → green → refactor).

Hard ordering that wraps this: **PRD → issues → PR.** Never open a PR without a referenced issue. GitHub issues are the source of truth for *what to do* and *its state* — session-local todos reconcile back to issues before the session ends.

## 2. Auto-triggered skills (invoke without waiting for the user)

| Trigger | Skill | Condition |
|---|---|---|
| Bug / error / stack trace | `/debug-mantra` | Start a debug session every time |
| Complex debug / perf regression | `/diagnose` | reproduce → minimise → hypothesise → fix |
| After fixing a bug | `/post-mortem` | Record root cause + fix + validation |
| After writing or changing code | `/simplify` | Before committing — check over-engineering |
| Editing UI / frontend | `/impeccable` | Every time a component or CSS is touched |
| New UI needs a design brief | `/impeccable shape` | Plan UX before implementing |
| UI ready to ship | `/impeccable audit` + `/impeccable harden` | a11y/perf/responsive + edge cases |
| Before merge / ship | `/code-review` + `/scrutinize` | Correctness + outsider perspective |
| Touching auth / token / secret / any security boundary | `/security-review` | Every boundary crossing |
| After implementation | `/verify` | Confirm the feature works in the app |
| Exploring unfamiliar code | `/zoom-out` | High-level context before editing |
| Codebase growing complex | `/improve-codebase-architecture` | Every 2–3 days or after a major feature |
| User asks "is there a skill for X?" | `/find-skills` | Search before hand-writing code |

Optional PAL-tool mapping (if PAL MCP is connected): code review→`codereview`, debug→`debug`, architecture→`analyze`, test planning→`testgen`, refactor→`refactor`, security→`secaudit`, deep reasoning→`thinkdeep`.

## 3. Cross-repo hard rules

- **Bilingual scope (TH + EN) — GitHub tracker only.** Issue bodies, PRD bodies, PR descriptions must be bilingual, and the **Thai must mirror the English exactly** — same depth, bullet count, tables. "สรุป" is not a summary. Code identifiers, filenames, log excerpts, and acceptance-criteria checkboxes stay English (the Thai explains them, never translates them). Review-reply comments may be English-only. Everything outside the tracker (chat, reports, status) follows the user's preferred language (Thai) and is **not** required bilingual. Code, commit messages, inline comments stay English.
- **TDD is mandatory** for features and bugfixes.
- **Non-standard framework version → read the vendored docs first.** Repos pin framework versions newer than model training data. Before writing/modifying such code, read the guide under the installed package's own docs (e.g. `node_modules/<pkg>/dist/docs/`); heed deprecation notices.
- **Verify every change end-to-end.** Unit tests can't see real layout/hydration; a real E2E/verify pass is mandatory for every frontend change (e.g. `<E2E_COMMAND>` smoke-checks every public page — visible `<h1>`, no nav overlap, no console/hydration errors, working TH/EN switch). Add an E2E case whenever a page or interactive UI is added. A delegated (subagent) change is not exempt.
- **Package manager / lockfile.** Bun is the package manager and runtime. Commit `bun.lock`; never commit `package-lock.json` / `yarn.lock`. Use `bunx`, not `npx`.
- **Issue lifecycle is a Definition-of-Done gate.** Every code change maps to one issue you're allowed to work (authored by us, or labeled `ready-for-agent`). Keep the issue *body* current (bilingual) as scope/state changes. Close with a stated REASON (completed-with-evidence / cancelled / duplicate / wontfix / stale) — never silently, never leave finished work open.
- **Engineering North Star.** Simplest logic that works · easy to maintain · sustainable · good performance. Prefer deleting complexity over propping it up; pick the lightest sufficient construct; make surgical changes.
- **Delegate only mechanical, low-blast-radius work** to a cheap subagent (bulk renames, boilerplate, log summarizing, grep-and-report). Never delegate security-boundary code, architecture/seam decisions, bilingual issue/PR authoring, or judgment-gated skills (`/scrutinize`, `/code-review`, `/security-review`, `/debug-mantra`).

## 4. Skeletons

### docs/agents/workflow.md

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
| Complex debug / perf regression | `/diagnose` | reproduce → minimise → hypothesise → fix |
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

- **`CONTEXT.md`** at the repo root — the authoritative domain glossary.
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

### docs/agents/issue-tracker.md

```markdown
# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues on `<ORG>/<REPO>`. Use the `gh` CLI for all operations.

> **`gh` path/auth:** <if not on PATH, give the full path>. Authenticated as `<USER>`, with access to the `<ORG>` org.

## Language: bilingual bodies (English + Thai)

Every issue body, PRD body, and PR description must be **bilingual**:

- **Title**: English, conventional-commit style (e.g. `fix(<scope>): ...`).
- **Body**: each section in English, then a mirrored Thai version — either a `## สรุปภาษาไทย`
  section covering the whole body, or `EN / TH` paired paragraphs per section for long docs.
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

### docs/agents/triage-labels.md

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

## 5. Serena memory conventions (quick reference — for `.serena/memories/memory_maintenance.md`)

- **Discovery graph.** Memories form a graph reached by progressive discovery. `mem:core` is the root — read it first; it references memories for major domains, which reference more specific ones. Depth scales with project complexity.
- **`mem:` prefix.** Reference other memories as `` `mem:<folder>/<name>` `` in backticks. Group by folders mirroring project structure (frontend/backend) or topic (debugging/architecture).
- **Referring text carries the "when to read".** The referring memory states which aspects a target covers and when to open it — more precise than the name alone. A memory never documents when to read *itself*.
- **Dense-notes style.** Terse invariants and bullets, not prose. Skip obvious context/rationale/examples unless they prevent a likely mistake. Durable and generalizable, not task-local.
- **Add/update threshold.** Only for stable, non-obvious project conventions that save future rediscovery. Do NOT add: quick-read facts, generic framework knowledge, one-off task notes, volatile line-level details, behavior likely to change soon.
- **Maintenance.** Rename via Serena's rename tool so references auto-update; run the stale-memory check after deletions.

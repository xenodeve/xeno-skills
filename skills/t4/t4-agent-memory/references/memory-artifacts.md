# Memory Artifacts — skeletons

Drop-in skeletons for the T4 agent-memory layers. Fill `<PLACEHOLDER>` tokens; strip sibling-project domain words.

## Team memory vault — `Obsidian-<Repo>/Home.md` (Map-of-Content index)

```markdown
# <Repo> — Team Memory (Map of Content)

> Read this index first each session; open only the linked notes the current task touches.
> One note = one memory. Unresolved `[[links]]` = memories worth writing.

## feedback — how agents should work here
- [[<feedback-slug>]] — <one-line description>

## project — ongoing goals / constraints not derivable from the code
- [[<project-slug>]] — <one-line description>

## reference — pointers to external resources (URLs, dashboards, tickets)
- [[<reference-slug>]] — <one-line description>

## user — who the developer is (role, preferences)
- [[<user-slug>]] — <one-line description>
```

## A memory note — `Obsidian-<Repo>/<slug>.md`

```markdown
---
name: <short-kebab-slug>            # must match the filename so [[wikilinks]] resolve
description: <one-line summary — what a future agent skims to decide relevance>
type: feedback | project | reference | user
---

<The fact. For feedback/project, follow with:>
**Why:** <the reason it matters>
**How to apply:** <the concrete action it changes>

<Link related memories with [[other-slug]]. Convert relative dates to absolute.>
```

## `docs/OPEN-WORK-LEDGER.md`

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

## `DONE.md` (append-only ship log; newest on top; archive by period)

```markdown
# DONE — Agent Session Log

> Newest entry on top. One dated `##` heading per shipped unit so an agent can jump to one.
> When this crosses ~a few hundred lines or a phase closes, move older entries to
> `DONE-archive-<period>.md` and leave a redirect line here.

---

## <Title of the change> (<YYYY-MM-DD>, <skill e.g. /tdd + /debug-mantra>, branch `<branch>`)

**Goal:** <what the session set out to fix/build and why it mattered.>

**Shipped (<N files>):**
- `<path>` — <what changed and why>

**Validation:** <tests: N pass / 0 fail; typecheck/lint state; live E2E result with the
concrete observed behavior that proves it works.>

**Report:** <link to the post-mortem / ADR / impact-report entry created.>

**Next:** <optional — follow-up filed as #NNN or noted 🔴 in the ledger.>

---
```

## `docs/reports/survey-manifest/` — provenance cache

**What it's for:** so a later scan (a new report, an ADR, an audit) does **not** re-read files/issues/PRs that haven't changed.

**Scan procedure (for the next agent):**
1. Open the fragment covering the area to update (see the fragment index at the top).
2. Before re-reading, check whether the recorded source changed:
   - Code/docs: `git log -1 --format=%H -- <path>` vs stored `last_commit` — equal ⇒ **skip**.
   - Issue/PR: `gh issue view <n> --json updatedAt` / `gh pr view <n> --json updatedAt` vs stored `updated_at` — equal ⇒ skip.
3. If changed, read only the diff (`git diff <last_commit>..HEAD -- <path>`), not the whole file, unless the diff is huge.
4. Update only the changed part and bump `last_commit` / `updated_at`.

**Per-entry schema:**

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

Add a **Fragment index** table (Fragment | Scope | Status) at the top, plus an "already surveyed — don't repeat unless diffing" list linking back to the canonical output rather than duplicating findings.

## Serena `mem:` code memories (quick reference for `.serena/memories/memory_maintenance.md`)

- **Discovery graph.** Memories form a graph reached by progressive discovery. `mem:core` is the root — read it first; it references memories for major domains, which reference more specific ones. Depth scales with project complexity.
- **`mem:` prefix.** Reference other memories as `` `mem:<folder>/<name>` `` in backticks. Group by folders mirroring project structure (frontend/backend) or topic (debugging/architecture).
- **Referring text carries the "when to read".** The referring memory states which aspects a target covers and when to open it — more precise than the name alone. A memory never documents when to read *itself*.
- **Dense-notes style.** Terse invariants and bullets, not prose. Skip obvious context/rationale/examples unless they prevent a likely mistake. Durable and generalizable, not task-local.
- **Add/update threshold.** Only for stable, non-obvious project conventions that save future rediscovery. Do NOT add: quick-read facts, generic framework knowledge, one-off task notes, volatile line-level details, behavior likely to change soon.
- **Maintenance.** Rename via Serena's rename tool so references auto-update; run the stale-memory check after deletions.

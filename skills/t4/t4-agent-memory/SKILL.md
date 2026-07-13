---
name: t4-agent-memory
description: Use when working as the primary coding agent in a T4-team repo (T4 Labs / Slow-Inc) and you need durable memory across sessions and context-compaction — at session start (what's the open work, what did past sessions decide), after shipping or learning something worth persisting, or when open work is scattered across issues, ADRs, and MD files. Covers the team memory vault, the open-work ledger, the ship log, the survey-provenance cache, and Serena code memories. Triggers include "where did we leave off", "record what I shipped", "read the project memory", "what's still open".
---

# T4 Agent Memory

## Overview

In a T4 repo the **agent is the primary coder**, and an agent's binding constraint is its context window — it loses everything on compaction and between sessions. So the repo's memory files are not team paperwork; they are the agent's **durable working memory**. This skill is how to read and write that memory efficiently.

**Core principle: retrieval-first.** Store memory so a future agent can pull the *one relevant slice* into a fresh context — never so it must load a giant file to find one fact. An index you skim + linked detail you open on demand beats one append-only wall of text every time. The whole-file scan is the failure mode; the index-then-open is the pattern.

## The memory layers

Each layer exists because it answers a different question, and each is structured so you retrieve a slice, not the whole.

| Layer | Answers | Retrieval unit | Read it when |
|---|---|---|---|
| **Team memory vault** — `Obsidian-<Repo>/` (committed), `Home.md` is the Map-of-Content index | "What durable facts/decisions/feedback does the team hold?" | one note per memory, opened via `Home.md` links | **Every session start** — read `Home.md`, then only the linked notes the task touches |
| **Personal memory** — `~/.claude/projects/<slug>/memory/` + `MEMORY.md` index | "What did *I* learn across my own sessions?" (same note format) | one file per memory, via `MEMORY.md` | Loaded by the runtime each session; keep in sync with the vault |
| **Open-work ledger** — `docs/OPEN-WORK-LEDGER.md` | "What is still open, tracked *and* untracked?" | one row per work item | **Every session start** — this is the single source of open work |
| **Ship log** — `DONE.md` | "What did past sessions actually ship, and how was it validated?" | one dated entry (newest on top) | When you need the history of a change; append after each shipped unit |
| **Survey-provenance cache** — `docs/reports/survey-manifest/` | "What did a prior scan already read, at which commit?" | one entry per file/issue/PR | Before a broad codebase/issue survey — skip or diff unchanged sources |
| **Serena code memories** — `mem:` graph | "How is the *code* structured?" | one memory per topic, reached via `mem:core` | When exploring unfamiliar code |

## Session-start read protocol

Do this at the start of every session in a T4 repo, in order, and **stop pulling detail once you have enough for the task** — don't preload the whole graph.

1. **`Home.md`** (team vault MoC) — skim the one-line descriptions; open only the notes the current task touches. Unresolved `[[wikilinks]]` = memories worth writing.
2. **`docs/OPEN-WORK-LEDGER.md`** — the current open work. The 🔴 UNTRACKED rows (MD-only, no issue) are the highest miss-risk; they don't show up in `gh issue list`.
3. **The relevant GitHub issue(s)** — `gh issue view <n> --comments` for the item you're picking up.
4. **`DONE.md` / survey-manifest / Serena `mem:core`** — only if the task needs history, prior scan provenance, or code-structure context. Not by default.

## Retrieval-first rules (this is the discipline)

- **Index-then-open, never whole-file scan.** `Home.md`, the ledger table, and the survey-manifest index exist so you load a pointer and open one slice. If you catch yourself reading a 1000-line log end-to-end to find one fact, the file is mis-structured — fix the structure (add an index / split it), don't normalize the scan.
- **One source of truth per fact.** Open work lives in the ledger (mirrored to a GitHub issue); a decision lives in one ADR; a shipped change is logged once in `DONE.md`. Duplicating the same fact across `Todo.md` + `Roadmap.md` + ledger + log is how an agent ends up trusting a stale copy. When you find a duplicate, collapse it: keep the canonical one, replace the others with a one-line redirect marker.
- **Bound the append-only logs.** `DONE.md` and the impact register grow forever. Keep them retrievable: newest entry on top, one dated `##` heading per unit so an agent can jump; when a log crosses ~a few hundred lines or a phase closes, archive the old part to `DONE-archive-<period>.md` and leave a redirect. A log you can't load isn't memory.
- **Freshness over authority.** A memory or doc that cites `file:line` looks authoritative but silently rots when code moves. Before you rely on a cited location, verify it still exists. A wrong fact that looks confident is worse than a missing one — for a human, far worse for an agent that can't easily sanity-check.
- **Write memory a future agent can act on, not a diary.** Dense, durable, generalizable. Not "today I fixed X" — instead the invariant/decision that stops the next agent repeating the mistake.

## Writing memory

- **One note = one memory.** Filename = hyphen-kebab slug matching the note's `name:` frontmatter so `[[wikilinks]]` resolve. Frontmatter carries `type` (`feedback` / `project` / `reference` / `user`) + a one-line `description` (this is what a future agent skims in `Home.md` to decide relevance). Add a line to `Home.md` when you create one.
- **Add/update threshold — be strict.** Persist only stable, non-obvious conventions/decisions/feedback that save a future agent from costly rediscovery. Do NOT persist: quick-read facts, generic framework knowledge, one-off task notes, volatile line-level details, or anything likely to change soon. If asked to "remember" something the repo already records (code structure, git history, a past fix), persist instead *what was non-obvious about it*.
- **Link liberally.** A `[[name]]` that doesn't exist yet marks a memory worth writing later — it's a to-do, not an error. Reference related memories so the graph, not any single note, holds the structure.
- **Update, don't duplicate.** Before writing, check `Home.md` for a note that already covers it; edit that one. Delete memories that turn out to be wrong.

## Dev notifications (agent → developer)

The agent runs long/AFK; surface reaching-a-decision or done to the developer's phone. Prefer the repo's real-toast script (e.g. `scripts/notify.ps1`) over the built-in push tool when the latter doesn't surface a toast on the dev's setup. Notify on: a TDD cycle / long task complete, needing a confirm (before closing issues / merging), or an AFK batch done — not routine sub-progress.

## Skeletons

See `references/memory-artifacts.md` for drop-in skeletons: `Home.md` (MoC index), a memory note, `OPEN-WORK-LEDGER.md`, `DONE.md`, the survey-manifest schema, and the Serena `mem:` conventions.

## Common mistakes

- **Loading the whole vault / whole log every session.** Defeats the point. Skim the index, open the few notes that matter.
- **A ledger that only lists GitHub-tracked work.** The MD-only 🔴 items are exactly the ones that vanish — the ledger's job is to catch them.
- **Letting `DONE.md` grow to thousands of lines unindexed.** It stops being loadable. Archive by period; keep it skimmable.
- **Trusting a `file:line` citation without checking it.** Verify before relying.
- **Writing a diary entry as "memory."** If it isn't a durable, act-on-able invariant, it's noise in the graph.

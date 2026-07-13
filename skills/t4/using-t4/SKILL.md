---
name: using-t4
description: Use at the start of any task in a T4-team repo (T4 Labs / Slow-Inc) to decide which T4 skill applies — setting up the repo, session-start memory and open-work, planning or shipping a feature, or recording a bug/decision/change — and to hand off to the companion skill ecosystems the team runs alongside (superpowers, matt pocock, 9arm). The entry-point map for the t4-* skill family; consult it before acting when you're unsure which T4 discipline or which external skill a task needs. Triggers include working in a repo whose CLAUDE.md points here, "how do we work in this repo", "which T4 skill", and starting a session in a Slow-Inc repo (MangaDock, T4-Fastwork).
---

# Using T4

## Overview

The T4 team runs its repos **agent-primary** — the coding agent is the main developer, so the repo's docs are the agent's operating manual, not team paperwork. The `t4-*` skills encode that operating standard. This skill is the **map**: it tells you which one to invoke for the situation in front of you.

**Core rule:** in a T4 repo, when a task matches one of the skills below, **invoke that skill before acting** — don't work from memory of what it says. Skills evolve; load the current one. (User instructions — this repo's `CLAUDE.md` / direct requests — always win over any skill.)

## The map — route by what you're doing

| You are… | Invoke |
|---|---|
| **Starting a session** — need to know where work left off, what's still open, what past sessions decided | **`t4-agent-memory`** (read `Home.md` → open-work ledger → the relevant issue) |
| **Setting up a new repo**, or retrofitting one missing the operating layer | **`t4-project-bootstrap`** |
| **Planning or building a feature** — an idea to ship, filing an issue/PRD, writing a bilingual issue/PR body, opening a PR | **`t4-dev-workflow`** |
| **Something notable just happened** — fixed & validated a bug, made a hard-to-reverse decision, shipped a system-affecting change | **`t4-engineering-records`** |
| **Recording or recalling durable memory** — persisting a convention/decision/feedback, or finding where open work lives | **`t4-agent-memory`** |
| **Going AFK** — the developer hands you a bounded batch to run unattended and steps away ("handle it", "clear the queue", "keep going without me") | **`t4-afk`** |

## Companion ecosystems — use them alongside T4

The `t4-*` skills are a thin, team-specific layer **on top of** three general skill ecosystems the team runs. They are not alternatives — the T4 workflow is literally built from them, and you should invoke them by their own triggers whenever a task fits. When a T4 skill names a slash-command (`/grill-me`, `/to-prd`, `/to-issues`, `/tdd`, `/debug-mantra`, `/post-mortem`, `/scrutinize`), that command lives in one of these — this is where it comes from.

| Ecosystem | Reach it via | Use it for | Representative skills |
|---|---|---|---|
| **superpowers** | its own map — invoke **`superpowers:using-superpowers`** first | general process discipline (defer to it for *how to work*) | `brainstorming`, `test-driven-development`, `systematic-debugging`, `writing-plans`, `writing-skills`, `verification-before-completion`, `dispatching-parallel-agents` |
| **matt pocock** (`mattpocock/skills`) | `/setup-matt-pocock-skills` to install + configure the tracker/labels/domain layout | **the flow the T4 pipeline is built on** — the grill→spec→tickets loop and the issue-tracker / triage-label / domain-doc conventions T4 reuses | `grilling` (`/grill-me`), `to-prd`/`to-spec`, `to-issues`/`to-tickets`, `domain-modeling`, `code-review` |
| **9arm** (`thananon/9arm-skills`) | `npx skills add thananon/9arm-skills` | debugging + adversarial review discipline + cheap delegation | `debug-mantra`, `post-mortem`, `scrutinize`, `qwen-agent`, `qwenchance`, `management-talk` |

**Routing rule:** T4 skills own the *team-specific* decision (which record, which memory layer, the bilingual/tracker rules); they **hand off the general technique** to the ecosystem skill. E.g. `t4-engineering-records` decides a bug needs a post-mortem, then invokes `/post-mortem` (9arm) to write it; `t4-dev-workflow` sequences the pipeline, then invokes `grilling` / `to-prd` / `/tdd` for each step. For anything about *how to work* that isn't T4-specific, prefer `superpowers:using-superpowers` and the skill it points to.

## Session-start protocol

At the start of any session in a T4 repo, before picking up work:

1. **`t4-agent-memory`** — read the memory vault index and the open-work ledger (this is what survives a context reset). Then read the specific GitHub issue you're picking up.
2. Route the task through the map above.

## The non-negotiable rules (all skills carry these)

- **Memory is first-class** — record what you ship; the next agent inherits only what you wrote (`t4-agent-memory`).
- **PRD → issues → PR** — never a PR without a referenced issue; issues are the source of truth (`t4-dev-workflow`).
- **Bilingual is tracker-only, Thai mirrors English exactly** — issue/PRD/PR bodies; not chat/reports; identifiers stay English (`t4-dev-workflow`).
- **TDD is mandatory**; **verify every frontend change end-to-end** (unit tests can't see real layout/hydration).
- **Non-standard framework version → read the vendored docs first**, not prior knowledge.
- **Bun** is the package manager — commit `bun.lock`, use `bunx`.
- **Records stay a reliable index** — `file:line`, commit SHAs, validated-only, blameless (`t4-engineering-records`).
- **Glossary is load-bearing**; **proceed silently if a governance file is absent**.

## When NOT to use

A non-T4 project (the bilingual rule, label vocabulary, and memory layout are team-specific). A throwaway prototype with no issues/memory. For those, use the general skills directly.

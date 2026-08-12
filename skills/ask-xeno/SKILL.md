---
name: ask-xeno
description: Ask which skill in this library fits what you are doing. A router over every skill here — the T4 operating standard, multi-agent delegation, the web/UI design family, and the coding guardrails. Reach for it when you are unsure which skill applies, when you are about to hand work to another agent, when a task spans families, or when you suspect a skill exists for this and cannot name it. Triggers include "is there a skill for X", "which skill should I use", "how do we do X here", and any moment you are about to improvise a process this library already encodes.
---

# Ask Xeno

Which skill fits what you are doing. **One line each — the skill itself carries the rules, and this file never restates them.**

If you are working in a T4 repo, load **`using-t4`** first; it owns the operating rules and the session protocol, and this router does not repeat them.

## Working in a T4 repo — agent-primary, issues are the source of truth

- **`using-t4`** — the entry map and the non-negotiable rules. **Start here**; everything else in this section hangs off it.
- **`t4-dev-workflow`** — idea → PRD → issues → PR. Survey change sites, TDD, triage labels, bilingual tracker bodies.
- **`t4-project-bootstrap`** — scaffold or retrofit a repo with the operating layer: docs, hooks, guards, CI.
- **`t4-agent-memory`** — what survives a context reset: the vault, the open-work ledger, the ship log, and the skill-usage feedback loop.
- **`t4-engineering-records`** — something notable happened: post-mortem vs ADR vs impact entry, and how to keep the index trustworthy.
- **`t4-afk`** — the developer hands you a batch and leaves. Scope lock, decide-alone vs park, landing digest.
- **`t4-bro`** — how to say the answer: plain Thai at a working developer's level, English only where it earns its place.

## Handing work to another agent

- **`clink-masteragent`** — **read this before any delegation.** What you may never hand out, and how to pick the model from measured scores instead of memory.
- **`clink-subagents`** — hand out a scoped chunk of *work* and get it back done.
- **`clink-brainstorm`** — convene a panel for *judgment*: which design wins, what is wrong with this plan.
- **`clink-debug`** — hunt a bug across agents. Owns who may sit in a falsification seat and what evidence reaches them.

*Work versus judgment is the whole routing decision here: a subtask executed → `clink-subagents`; an opinion weighed → `clink-brainstorm`. Getting it backwards is the common error.*

## Web and UI design

- **`design`** — the family router; send design work through it rather than guessing between the four below.
- **`design-setup`** — 0→1 prototyping: preflight, decision gate, build phases.
- **`design-rules`** — micro-UI rules: type scale, colour balance, grid, spacing, button states.
- **`design-audit`** — review a UI or portfolio: first-impression test, hierarchy, trust, conversion readiness.
- **`design-psychology`** — why it works: personas, mental models, chunking, white space.

## Writing code at all

- **`karpathy-guidelines`** — simplest thing that works, surgical diffs that trace to the request, verifiable success criteria. Applies to every edit, in any repo.

## When nothing here fits

Say so and use the general skills directly. A skill invoked because it was nearest is worse than none — it makes the wrong process look chosen.

# Delegation reference

Offloading a mechanical sub-task to a cheap model (e.g. `qwen-agent` / a headless `claude-9arm`) during a build. The general mechanism — command syntax, prompt rules, context-window limits, failure modes — lives in the `qwen-agent` skill; read that first. This adds the **T4 sizing and handoff discipline** on top, distilled from MangaDock's real delegation practice.

## What to delegate — and what never to

**Delegate** mechanical, self-contained, low-blast-radius work with an obvious "done":
- bulk rename of a symbol across a codebase once the new name is decided
- boilerplate scaffolding that copies an established pattern (a new spec shell modeled on a sibling)
- summarizing / condensing a long log or stack trace before you read it
- lint / format / import-sort passes
- grep-and-report sweeps ("every call site of X, as `file:line`")

**Never delegate** (judgment this conversation holds and a small model doesn't):
- security-boundary code (auth / payments / token / secret / entitlement paths)
- architecture / seam / data-model decisions
- **bilingual issue/PR authoring** — the Thai must mirror the English *exactly* (same depth, bullet count); a small model's default failure is to shorten or drift, silently breaking the rule
- judgment-gated skills: `/scrutinize`, `/code-review`, `/security-review`, `/debug-mantra`, `qa` — a literal model applies judgment-gating confidently and wrongly

## Sizing a delegated task

- **Chunk by independently-governed unit** (sub-project / stack / package). Never fold a cross-stack rename or sweep into one prompt — one run per unit, each with its own conventions.
- **Chunk logs by window, not whole-file.** Path-heavy or mixed-language logs tokenize denser than a ÷4 estimate — treat a segment as bigger than it looks and split earlier than you'd think.
- **A "detailed requirement" =** absolute file paths + an explicit acceptance criterion + any repo **landmine** that applies (pasted verbatim — see below). Don't assume the model infers a repo-specific gotcha.

## Handing the worker a skill — Option A vs B

The worker runs on the same harness, so it can invoke skills from `~/.claude/skills/` too — proven to raise quality (skill-guided stays on structure and honest about gaps; unguided drifts and fabricates).

- **Option A — name the skill, let the worker invoke it.** Default for procedural skills that apply cleanly even to a small model: `karpathy-guidelines`, `tdd`, `simplify`, `post-mortem`. The tool allowlist must include `Skill` **plus every tool the invoked skill calls**, or the worker stalls mid-skill waiting for approval.
- **Option B — inline just the relevant rule** into the prompt. Use when the task's own file footprint already fills much of the context window.
- **Budget the skill as part of the task, not free.** A skill's `SKILL.md` (plus any reference files it opens) is real context cost on top of the task's own footprint, inside the same window. Measure it for the model you're using; don't stack Option A on an already-large chunk. Reserve Option A for chunks that are already small (one file, one bounded edit, a short log) where the skill's judgment/gating is worth the tokens.

## Landmine injection

Repo-specific gotchas (a worker-restart step, a `cache:reset` rule, a disk-headroom check) must be **retrieved and pasted into the child prompt** — the worker won't infer them. Make it part of the delegation preflight: paste every landmine that applies to the touched files, verbatim.

## Verify what comes back — component-aware

A delegated change is **not exempt** from the verify/E2E mandate. Rerun **the touched unit's own real checks** (its tests / build / E2E) after the worker returns — not a generic "looks fine". Keep, per unit: its ownership boundary, its commands, whether it needs a restart, whether it needs E2E, and its prompt-chunk boundary.

[🇹🇭 ภาษาไทย](./README.md) · **🇬🇧 English**

# xeno-skills

Agent skills loaded by Claude Code.

## Background

This repo grew out of a project to replace the human-in-the-middle bottleneck of AI brainstorming — instead of a developer sitting at a terminal answering each model's questions one by one, a master agent fans the problem out to a panel of independent CLI agents that debate automatically, then surfaces only the final synthesised result for human approval.

The architecture is documented in [`docs/agentic-workflow-presentation.en.md`](./docs/agentic-workflow-presentation.en.md) — a write-up of the Hybrid Multi-Agent Architecture (Multi-Turn Negotiation Loop + Dynamic Skill Injection) originally prepared as a project presentation.

## Layout

Skills live under `skills/`:

- `multi-agent/` — orchestrating multiple AI CLIs together
- `t4/` — the T4 team's agent-primary operating standard (entry map, bootstrap, memory, records, workflow)
- `design/` — the web/UI design skill family (setup, rules, audit, psychology) plus its reference library
- `karpathy-guidelines/` — behavioral guardrails for writing code (T4 auto-loads it at session start)

Each skill is its own directory containing a `SKILL.md` (with YAML frontmatter — `name` and `description`) and any bundled reference files.

This repo is also a **Claude Code plugin** (`.claude-plugin/` + `hooks/`) that ships **workflow-enforcement hooks** to keep a session on the T4 rails.

## Install

### With `npx skills` (Recommended — works for every agent)

```bash
npx skills add xenodeve/xeno-skills
```

Install a specific skill by name:

```bash
npx skills add xenodeve/xeno-skills --skill clink-brainstorm
```

### As a plugin (adds the workflow-enforcement hooks)

Install as a Claude Code plugin to get the hooks that keep a session on the T4 rails:

```
/plugin marketplace add xenodeve/xeno-skills
/plugin install xeno-skills
```

Three hooks — they fire only in a repo carrying the `.claude/t4.json` marker (no other repo is touched):

- **`SessionStart`** → injects the `using-t4` content once per session (fixes "didn't invoke the skill at start")
- **`UserPromptSubmit`** → a short rails reminder every turn (reduces mid-session drift)
- **`PreToolUse`** → **blocks / asks** before risky commands: `gh pr create` with no referenced issue, dangerous git (`reset --hard`, force-push, `clean -f`, `branch -D` — `reset --hard`/`clean` are allowed under `"afk"` for revert-to-green), and a **ship gate** — it runs the repo's verify command (`.claude/t4.json` `"verify"`) **itself** before `gh pr merge` and denies on failure (keep `verify` a **fast** suite — unit+build+lint; leave e2e to CI); `gh pr merge` also `ask`s you to confirm `/scrutinize` + `/code-review` ran — **skipped when `"autoMerge"`/`"afk"` is set** (AFK / standing authorization). With `"requireGreenCI": true` it also runs `gh pr checks` and denies while any check is failing or pending

These are Claude Code hooks, so they only see commands **Claude** runs — a repo that also runs Codex/Gemini (or a human) pushes straight past them. A **git `pre-push` guard** layer covers that: it re-checks the issue reference from the branch/commits/PR body and blocks an over-budget dirty tree or committed build artifacts, binding every agent on the clone — see [`guards-layer.md`](./skills/t4/t4-project-bootstrap/references/guards-layer.md).

Injected hooks are *reminders* (the model can still ignore them); the hard enforcement is the `PreToolUse` deny + the **verify the hook runs itself** (un-forgeable — it runs the tests rather than trusting a claim). The top guarantee — "no merge without a green gate" — lives in **CI required-checks + a branch ruleset**: `t4-project-bootstrap` ships the workflows (`lint` · `typecheck` · `test` · `build` as separate required checks, a separate e2e suite, and an optional CD workflow gated on a green verify) plus the ruleset commands that make them required and block direct pushes to `main` — see [`ci-cd-layer.md`](./skills/t4/t4-project-bootstrap/references/ci-cd-layer.md) — and this repo runs the same gate on itself ([`.github/workflows/t4-verify.yml`](./.github/workflows/t4-verify.yml): `tests` for the contract suite, `skill-discovery` running the real installer to prove every `SKILL.md` is actually found) — **though only the workflow is installed here, not the ruleset, so those two checks are advisory on this repo until one is added.** Verified 2026-08-04: `gh api repos/xenodeve/xeno-skills/rulesets` returns `[]` and `main` has no branch protection. Saying otherwise would be the exact appearance-of-enforcement this section warns about. That layer also covers a human merging on the web; local hooks only catch agent-run commands. Repos scaffolded by `t4-project-bootstrap` carry the same hooks via git without needing the plugin.

> **The full design rationale** (the two failure modes it solves, the enforcement ladder, and the honest ceiling of what's enforceable vs. theater) is in [`docs/adr/0001`](./docs/adr/0001-hook-based-workflow-enforcement.md). A report-level workflow overview (pipeline + enforcement ladder) is in [`docs/development-workflow.md`](./docs/development-workflow.md).

## Reference

### Start here

- **[ask-xeno](./skills/ask-xeno/SKILL.md)** — a router over **every** skill in this library: which one fits what you are doing, one line each. It indexes and hands off; the skills themselves carry the rules, and it never restates them. Written because nine of the seventeen skills here — every `clink-*` and the whole design family — were unreachable from `using-t4`, so an agent that did not already know they existed had nothing to tell it. A contract test fails the day a new skill is added and the index is not.

### Multi-agent

- **[clink-brainstorm](./skills/multi-agent/clink-brainstorm/SKILL.md)** — Fan a question out to multiple independent AI CLI agents (Gemini/Antigravity, Codex, Claude, etc.) through [PAL](https://github.com/BeehiveInnovations/pal-mcp-server)'s `clink` tool, then synthesize one recommendation. Each agent has a distinct cognitive lens (Code-centric, System-centric, Logic-centric, Conceptual-centric) that determines how to tailor challenge prompts. Includes a judge-led challenge loop for when agents disagree and a lens-targeted adversarial round for when they converge (convergence without pressure ≠ validation). **Requires PAL MCP server** connected to your agent with at least two `clink` CLI agents configured.

- **[clink-subagents](./skills/multi-agent/clink-subagents/SKILL.md)** — Delegate a **well-scoped chunk of work** (implementation, refactor, bulk transform, focused research, first-draft) to Codex (GPT-5.6) or Antigravity (Gemini) as a subagent through [PAL](https://github.com/BeehiveInnovations/pal-mcp-server)'s `clink` tool — to offload effort, parallelize, or save context. Unlike `clink-brainstorm` (which gathers *opinions*), this one *has work done and returned*. Ships a routing rubric grounded in [Artificial Analysis](https://artificialanalysis.ai/models) indices (Codex = elite coding model but weaker agentic harness → hard self-contained tasks + verify; Antigravity = weak agentic → trivial single-shot tasks only; you = orchestrate + verify) and the non-negotiable rule: **verify everything a subagent returns**. **Requires PAL MCP server** with the `codex`/`antigravity` `clink` agents configured.

### T4 team (agent-primary operating standard)

A family of skills distilled project-agnostic from the T4 team's mature repos (MangaDock, T4-Fastwork), for repos where **the coding agent is the primary developer**. Built retrieval-first so an agent keeps context across sessions and compaction. Each is independently discoverable by its own trigger; `using-t4` is the entry map, `t4-project-bootstrap` installs the files, and the rest own the ongoing disciplines.

- **[using-t4](./skills/t4/using-t4/SKILL.md)** — The entry-point map for the family (like `using-superpowers`). At the start of any task in a T4 repo it routes you to the right skill — session-start memory, repo setup, feature pipeline, or engineering record — and carries the non-negotiable team rules. A repo's `CLAUDE.md` points a fresh agent here first.
- **[t4-project-bootstrap](./skills/t4/t4-project-bootstrap/SKILL.md)** — Scaffold a new (or under-documented) T4 repo with the operating layer in one pass: the domain/product docs (`CONTEXT.md`, `UBIQUITOUS_LANGUAGE.md`, `PRODUCT.md`, `DESIGN.md`, `docs/agents/domain.md`), the status-indexed knowledge dirs, and the `CLAUDE.md` wiring — orchestrating the three sibling skills below. Tiered by agent-context-load (memory layer is default-on), plus an optional 7-phase Software-Engineering deliverable set.
- **[t4-agent-memory](./skills/t4/t4-agent-memory/SKILL.md)** — The durable working memory an agent-primary repo runs on: the team memory vault (`Home.md` Map-of-Content → linked notes), the open-work ledger, the ship log, the survey-provenance cache, and Serena code memories — with the session-start read protocol and the retrieval-first rules (index-then-open, single-source, bounded logs, freshness over authority).
- **[t4-engineering-records](./skills/t4/t4-engineering-records/SKILL.md)** — Which record to write when something notable happens (post-mortem vs ADR vs system-impact entry vs bug-case-catalog) and how to write it so it stays a reliable index (`file:line`, commit SHAs, validated-only, blameless). Templates included.
- **[t4-dev-workflow](./skills/t4/t4-dev-workflow/SKILL.md)** — The feature pipeline (grill→survey→PRD→issues→TDD), the PRD→issues→PR gate, the auto-triggered skill map, triage labels, the issue lifecycle, and the bilingual (Thai-mirrors-English) tracker rule. `docs/agents/*` + PRD/spec/plan templates included.
- **[t4-afk](./skills/t4/t4-afk/SKILL.md)** — The discipline layer for running an unattended autonomous batch: the preflight scope-lock (AFK runs only on a pre-approved worklist), the may-decide-alone vs must-park boundary, the safe per-item loop (conventions→TDD→gates→checkpoint), the stop-and-park conditions that keep the tree from breaking, and how to land the batch with one digest and every issue reconciled. Preflight / park-note / landing-digest templates included. It doesn't relax any T4 rule — it removes the human checkpoint, so the gates hold themselves.
- **[t4-bro](./skills/t4/t4-bro/SKILL.md)** — The register for everything the developer reads: plain Thai at a working developer's level, with a three-way necessity test an English term must pass to survive (it's an identifier · the developer already uses it · precision would be lost) and an evidence rule for the middle case — a term counts as naturalised when the developer themselves writes it. Carries the accuracy floor (simplifying may never make a claim false; hedges are not jargon), before/after pairs from real sessions, and an explicit non-scope so identifiers, commit messages and the bilingual tracker rule stay exactly as `t4-dev-workflow` defines them.

### Coding behavior

- **[karpathy-guidelines](./skills/karpathy-guidelines/SKILL.md)** — Behavioral guardrails that reduce the mistakes LLMs commonly make when writing code (think before coding, keep it simplest, make surgical changes, define verifiable success criteria), distilled from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876). `using-t4` auto-loads this once at session start in a T4 repo — so it runs alongside the T4 family out of the box (MIT, credits Karpathy).

### Design (web / UI)

A web-design skill family distilled from the video libraries of Chase AI, Flux Academy (Ran Segall), Chris McCoy, Kole Jain and Satori Graphics, with `design` as the coordinator routing to the other four (source transcripts live in `skills/design/references/` — credit belongs to each video's creator).

- **[design](./skills/design/design/SKILL.md)** — The family coordinator; routes a design task to the right skill below.
- **[design-setup](./skills/design/design-setup/SKILL.md)** — End-to-end 0→1 web setup and prototyping: preflight checks, decision gates, exploratory-code isolation, 4-part prompts, a 3-phase build sequence, and token-commit finalization.
- **[design-rules](./skills/design/design-rules/SKILL.md)** — Micro-UI rules at the CSS/Tailwind level: typography (-2% tracking, Major Third 1.25x scale, 150% body line-height), 60-30-10 color balance, 12/8/4 column grids, 8pt spacing rhythm, 4-state buttons, and the LIFT system with its 6 levels of visual flow.
- **[design-audit](./skills/design/design-audit/SKILL.md)** — UI and portfolio review via the 30-Second First Impression Test and the LIFT system: instant clarity, visual hierarchy, trust signals, conversion readiness.
- **[design-psychology](./skills/design/design-psychology/SKILL.md)** — UX and conversion psychology: 3-Brain Persona alignment (Survival/Emotional/Rational), mental-model layout familiarity, MAYA pattern breaks, cognitive chunking (the 3-4 item working-memory rule), and Luxury White Space.

## Related

**Companion skill ecosystems** — the `t4-*` family is a thin team-specific layer on top of these; `using-t4` routes to them and they're meant to be installed alongside:

- **[superpowers](https://github.com/obra/superpowers)** — general process discipline (brainstorming, TDD, systematic-debugging, writing-plans/skills, verification-before-completion). Its own entry map is `superpowers:using-superpowers`; T4 defers to it for *how to work*.
- **[mattpocock/skills](https://github.com/mattpocock/skills)** — "Skills for Real Engineers." The flow the T4 pipeline is built on: the grill→spec→tickets loop plus the issue-tracker / triage-label / domain-doc conventions T4 reuses. Install/configure via `/setup-matt-pocock-skills`.
- **[thananon/9arm-skills](https://github.com/thananon/9arm-skills)** — `debug-mantra`, `post-mortem`, `scrutinize`, `qwen-agent` (delegate to a cheap Qwen-backed subagent via `claude-9arm`), `qwenchance`, `management-talk`.

**Tooling:**

- **[xenodeve/pal-mcp-server](https://github.com/xenodeve/pal-mcp-server)** — Fork of PAL that adds the `antigravity` clink agent (Google's Gemini successor, `agy`, via ConPTY on Windows) and a `claude-9arm.json.example` template for pointing `claude` at an alternate model gateway. Prerequisite for using `clink-brainstorm` / `clink-subagents` with Antigravity or a custom gateway.

## License

MIT — see [LICENSE](LICENSE).

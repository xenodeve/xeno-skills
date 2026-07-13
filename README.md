# xeno-skills

Agent skills loaded by Claude Code.

## Background

This repo grew out of a project to replace the human-in-the-middle bottleneck of AI brainstorming — instead of a developer sitting at a terminal answering each model's questions one by one, a master agent fans the problem out to a panel of independent CLI agents that debate automatically, then surfaces only the final synthesised result for human approval.

The architecture is documented in [`docs/agentic-workflow-presentation.md`](./docs/agentic-workflow-presentation.md) — a write-up of the Hybrid Multi-Agent Architecture (Multi-Turn Negotiation Loop + Dynamic Skill Injection) originally prepared as a project presentation.

## Layout

Skills live under `skills/`:

- `multi-agent/` — orchestrating multiple AI CLIs together
- `t4/` — the T4 team's agent-primary operating standard (entry map, bootstrap, memory, records, workflow)

Each skill is its own directory containing a `SKILL.md` (with YAML frontmatter — `name` and `description`) and any bundled reference files.

## Install

### With `npx skills` (Recommended — works for every agent)

```bash
npx skills add xenodeve/xeno-skills
```

Install a specific skill by name:

```bash
npx skills add xenodeve/xeno-skills --skill clink-brainstorm
```

## Reference

### Multi-agent

- **[clink-brainstorm](./skills/multi-agent/clink-brainstorm/SKILL.md)** — Fan a question out to multiple independent AI CLI agents (Gemini/Antigravity, Codex, Claude, etc.) through [PAL](https://github.com/BeehiveInnovations/pal-mcp-server)'s `clink` tool, then synthesize one recommendation. Each agent has a distinct cognitive lens (Code-centric, System-centric, Logic-centric, Conceptual-centric) that determines how to tailor challenge prompts. Includes a judge-led challenge loop for when agents disagree and a lens-targeted adversarial round for when they converge (convergence without pressure ≠ validation). **Requires PAL MCP server** connected to your agent with at least two `clink` CLI agents configured.

### T4 team (agent-primary operating standard)

A family of skills distilled project-agnostic from the T4 team's mature repos (MangaDock, T4-Fastwork), for repos where **the coding agent is the primary developer**. Built retrieval-first so an agent keeps context across sessions and compaction. Each is independently discoverable by its own trigger; `using-t4` is the entry map, `t4-project-bootstrap` installs the files, and the other three own the ongoing disciplines.

- **[using-t4](./skills/t4/using-t4/SKILL.md)** — The entry-point map for the family (like `using-superpowers`). At the start of any task in a T4 repo it routes you to the right skill — session-start memory, repo setup, feature pipeline, or engineering record — and carries the non-negotiable team rules. A repo's `CLAUDE.md` points a fresh agent here first.
- **[t4-project-bootstrap](./skills/t4/t4-project-bootstrap/SKILL.md)** — Scaffold a new (or under-documented) T4 repo with the operating layer in one pass: the domain/product docs (`CONTEXT.md`, `UBIQUITOUS_LANGUAGE.md`, `PRODUCT.md`, `DESIGN.md`, `docs/agents/domain.md`), the status-indexed knowledge dirs, and the `CLAUDE.md` wiring — orchestrating the three sibling skills below. Tiered by agent-context-load (memory layer is default-on), plus an optional 7-phase Software-Engineering deliverable set.
- **[t4-agent-memory](./skills/t4/t4-agent-memory/SKILL.md)** — The durable working memory an agent-primary repo runs on: the team memory vault (`Home.md` Map-of-Content → linked notes), the open-work ledger, the ship log, the survey-provenance cache, and Serena code memories — with the session-start read protocol and the retrieval-first rules (index-then-open, single-source, bounded logs, freshness over authority).
- **[t4-engineering-records](./skills/t4/t4-engineering-records/SKILL.md)** — Which record to write when something notable happens (post-mortem vs ADR vs system-impact entry vs bug-case-catalog) and how to write it so it stays a reliable index (`file:line`, commit SHAs, validated-only, blameless). Templates included.
- **[t4-dev-workflow](./skills/t4/t4-dev-workflow/SKILL.md)** — The feature pipeline (grill→PRD→issues→TDD), the PRD→issues→PR gate, the auto-triggered skill map, triage labels, the issue lifecycle, and the bilingual (Thai-mirrors-English) tracker rule. `docs/agents/*` + PRD/spec/plan templates included.

## Related

- **[xenodeve/pal-mcp-server](https://github.com/xenodeve/pal-mcp-server)** — Fork of PAL that adds the `antigravity` clink agent (Google's Gemini successor, `agy`, via ConPTY on Windows) and a `claude-9arm.json.example` template for pointing `claude` at an alternate model gateway. Prerequisite for using `clink-brainstorm` with Antigravity or a custom gateway.
- **[thananon/9arm-skills](https://github.com/thananon/9arm-skills)** — Skills that complement this repo: `qwen-agent` (delegate tasks to a cheap Qwen-backed subagent via `claude-9arm`), `debug-mantra`, `scrutinize`, `post-mortem`, and others.

## License

MIT — see [LICENSE](LICENSE).

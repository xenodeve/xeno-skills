# xeno-skills

Agent skills loaded by Claude Code.

## Background

This repo grew out of a project to replace the human-in-the-middle bottleneck of AI brainstorming — instead of a developer sitting at a terminal answering each model's questions one by one, a master agent fans the problem out to a panel of independent CLI agents that debate automatically, then surfaces only the final synthesised result for human approval.

The architecture is documented in [`docs/agentic-workflow-presentation.md`](./docs/agentic-workflow-presentation.md) — a write-up of the Hybrid Multi-Agent Architecture (Multi-Turn Negotiation Loop + Dynamic Skill Injection) originally prepared as a project presentation.

## Layout

Skills live under `skills/`:

- `multi-agent/` — orchestrating multiple AI CLIs together
- `project-setup/` — bootstrapping a repo with team conventions

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

### Project setup

- **[t4-project-bootstrap](./skills/project-setup/t4-project-bootstrap/SKILL.md)** — Scaffold a new (or under-documented) T4-team repo with the team's shared standard: the domain layer (`CONTEXT.md` + `UBIQUITOUS_LANGUAGE.md`), product/design split (`PRODUCT.md` / `DESIGN.md`), ADR + reports + research + plans indexes, the agent operating layer (`docs/agents/{workflow,domain,issue-tracker,triage-labels}.md`, Serena memory conventions), and drop-in templates (post-mortem, system-impact register, bug-case catalog, PRD, design-spec, implementation-plan, survey-manifest) — plus an optional 7-phase Software-Engineering deliverable set. Distilled project-agnostic from the team's mature repos so a new project gets the whole governance layer in one pass instead of hand-porting docs. Tiered by repo maturity so small repos aren't over-scaffolded.

## Related

- **[xenodeve/pal-mcp-server](https://github.com/xenodeve/pal-mcp-server)** — Fork of PAL that adds the `antigravity` clink agent (Google's Gemini successor, `agy`, via ConPTY on Windows) and a `claude-9arm.json.example` template for pointing `claude` at an alternate model gateway. Prerequisite for using `clink-brainstorm` with Antigravity or a custom gateway.
- **[thananon/9arm-skills](https://github.com/thananon/9arm-skills)** — Skills that complement this repo: `qwen-agent` (delegate tasks to a cheap Qwen-backed subagent via `claude-9arm`), `debug-mantra`, `scrutinize`, `post-mortem`, and others.

## License

MIT — see [LICENSE](LICENSE).

# xeno-skills

Agent skills loaded by Claude Code.

## Layout

Skills live under `skills/`:

- `multi-agent/` — orchestrating multiple AI CLIs together

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

## Related

- **[xenodeve/pal-mcp-server](https://github.com/xenodeve/pal-mcp-server)** — Fork of PAL that adds the `antigravity` clink agent (Google's Gemini successor, `agy`, via ConPTY on Windows) and a `claude-9arm.json.example` template for pointing `claude` at an alternate model gateway. Prerequisite for using `clink-brainstorm` with Antigravity or a custom gateway.
- **[thananon/9arm-skills](https://github.com/thananon/9arm-skills)** — Skills that complement this repo: `qwen-agent` (delegate tasks to a cheap Qwen-backed subagent via `claude-9arm`), `debug-mantra`, `scrutinize`, `post-mortem`, and others.

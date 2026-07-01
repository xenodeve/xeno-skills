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

- **[clink-brainstorm](./skills/clink-brainstorm/SKILL.md)** — Fan a question out to multiple independent AI CLI agents (Gemini/Antigravity, Codex, Claude, etc.) through [PAL](https://github.com/BeehiveInnovations/pal-mcp-server)'s `clink` tool, then synthesize one recommendation. Supports a bounded, judge-led challenge loop for round 2+ when agents genuinely disagree. **Requires PAL MCP server** connected to your agent with at least two `clink` CLI agents configured.

## Related

- **[xenodeve/pal-mcp-server](https://github.com/xenodeve/pal-mcp-server)** — Fork of PAL that adds the `antigravity` clink agent (Google's Gemini successor, `agy`, via ConPTY on Windows) and a `claude-9arm.json.example` template for pointing `claude` at an alternate model gateway. Prerequisite for using `clink-brainstorm` with Antigravity or a custom gateway.
- **[thananon/9arm-skills](https://github.com/thananon/9arm-skills)** — Skills that complement this repo: `qwen-agent` (delegate tasks to a cheap Qwen-backed subagent via `claude-9arm`), `debug-mantra`, `scrutinize`, `post-mortem`, and others.

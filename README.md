# xeno-skills

A personal collection of agent skills, installable via [`npx skills`](https://github.com/vercel-labs/skills) (the [Agent Skills](https://agentskills.io) ecosystem CLI) into Claude Code, Codex, Cursor, and 60+ other supported agent runtimes.

## Install

```bash
# Install everything in this repo
npx skills add xenodeve/xeno-skills --all

# Or install one skill by name
npx skills add xenodeve/xeno-skills --skill clink-brainstorm
```

## Skills in this repo

### [`clink-brainstorm`](skills/clink-brainstorm/SKILL.md)

Runs a multi-agent "manual consensus" brainstorm through [PAL MCP server](https://github.com/BeehiveInnovations/pal-mcp-server)'s `clink` tool — fans one precise question out to several independent CLI agents in parallel (Gemini, Codex, Claude, or whatever else you have configured), reads what each actually says, and synthesizes a single recommendation, with an optional bounded challenge loop for consequential decisions where the first round produced real disagreement.

**Requires PAL MCP server, connected as an MCP server to your agent, with `clink` configured for at least two CLI agents.** Upstream PAL ships `gemini`/`claude`/`codex` presets out of the box. If you're on Windows and want Google's Antigravity CLI (`agy`) as an agent too, or want an example of pointing Claude Code at an alternate model gateway, see [xenodeve/pal-mcp-server](https://github.com/xenodeve/pal-mcp-server) — a fork adding both (see its `CHANGES-FORK.md`). This skill is a prompting/orchestration layer on top of `clink` — it does not work standalone without PAL installed and at least 2 clink agents configured.

## License

MIT — see [LICENSE](LICENSE).

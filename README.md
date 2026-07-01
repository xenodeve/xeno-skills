# clink-brainstorm

A Claude Code skill (also usable from any agent runtime that supports Markdown-based skills) for running a multi-agent "manual consensus" brainstorm through [PAL MCP server](https://github.com/BeehiveInnovations/pal-mcp-server)'s `clink` tool.

Instead of asking one model, this fans the same precise question out to several independent CLI agents in parallel (Gemini, Codex, Claude, or whatever else you have configured), reads what each one actually says, and synthesizes a single recommendation — with an optional bounded challenge loop for consequential decisions where the first round produced real disagreement.

## Prerequisites

1. [PAL MCP server](https://github.com/BeehiveInnovations/pal-mcp-server) installed and connected to your coding agent as an MCP server.
2. At least two `clink` CLI agents configured (upstream PAL ships `gemini`, `claude`, `codex` presets out of the box in `conf/cli_clients/`).
3. *(Optional)* If you're on Windows and want Google's Antigravity CLI (`agy`, the 2026 successor to Gemini CLI) as one of your agents, or want an example of pointing the Claude Code CLI at an alternate model gateway, see [xenodeve/pal-mcp-server](https://github.com/xenodeve/pal-mcp-server) — a fork that adds both as ready-made `clink` configs (`CHANGES-FORK.md` has the details and setup steps).

None of the optional parts are required — this skill works with any 2+ independent `clink` agents.

## Installing the skill

Claude Code (and compatible runtimes) load skills from a directory containing a `SKILL.md`. Clone this repo somewhere and symlink (or copy) it into your skills directory:

```bash
git clone https://github.com/xenodeve/clink-brainstorm.git
# Claude Code (personal skills):
ln -s "$(pwd)/clink-brainstorm" ~/.claude/skills/clink-brainstorm
```

Restart your agent session (or reload skills, if your runtime supports that) and invoke it — e.g. in Claude Code: `/clink-brainstorm <your question>`, or just ask to "brainstorm this with multiple models."

## What's in `SKILL.md`

- How to write one question that fans out cleanly to multiple agents
- When to use an agentic `clink` call vs. a plain `chat` call (codebase questions need real file access — not all agents/routes have it)
- A bounded, judge-led challenge loop for round 2+ when agents genuinely disagree on something consequential
- How to hand a clink agent your own skill's rules for a task (with a reliable method, since self-discovery across different CLI tools is inconsistent)
- Known gotchas around clink config caching and PATH resolution

## License

MIT — see [LICENSE](LICENSE).

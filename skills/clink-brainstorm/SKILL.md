---
name: clink-brainstorm
description: Fan out a question to multiple independent AI agents (Gemini/Antigravity, OpenAI/Codex, and optionally a third model of your choice) through PAL's clink tool, then synthesize their answers into one recommendation. Use for multi-agent brainstorming, getting a second/third opinion on a design or plan, sanity-checking a decision across model families, or when the user says "ask the other AIs", "brainstorm with multiple models", or "get other perspectives".
---

# clink-brainstorm

> **Requires [PAL MCP server](https://github.com/BeehiveInnovations/pal-mcp-server)** connected as an MCP server, with its `clink` tool configured for at least two independent CLI agents. This skill is a prompting/orchestration layer on top of `clink` — it does nothing standalone without PAL installed and reachable. See Prerequisites below.

Drive 3+ independent AI agents on the **same well-specified question**, then synthesize the answers yourself into one recommendation. This is "manual consensus" — PAL's native `consensus` tool cannot mix clink CLI agents with its own model provider roster, so the orchestration is done by hand, here.

## Prerequisites

This skill assumes [PAL MCP server](https://github.com/BeehiveInnovations/pal-mcp-server) is installed and connected as an MCP server, with its `clink` tool configured for at least two independent CLI agents. Out of the box, upstream PAL ships `gemini`, `claude`, and `codex` presets in `conf/cli_clients/`.

If you want the two extra agents referenced below:
- **`antigravity`** (Google's Gemini-CLI successor, `agy`) needs a small platform-specific fix — plain piped subprocesses get empty output from `agy` unless it's driven through a real pseudo-console. A ready-made fix (Windows, via `pywinpty`) lives in [this PAL fork](https://github.com/xenodeve/pal-mcp-server) — see its `CHANGES-FORK.md`.
- **A third model behind an alternate gateway** (this doc uses `claude-9arm` as a running example — Claude Code CLI pointed at a non-Anthropic OpenAI-compatible backend via `--settings`/`--model`) is just a config file, no code — see the same fork's `conf/cli_clients/claude-9arm.json.example`. Swap in whatever gateway you actually use; the pattern is generic.

None of this is required to use the skill — two or three agents from any mix of `clink` CLIs (or PAL's own `chat`/`consensus` for a non-agentic angle) is enough for a brainstorm round. Adjust the example `cli_name`s below to whatever you actually have configured.

## Available agents (example roster — adjust to your setup)

| Call | Backend model | Mechanism | Typical latency |
|---|---|---|---|
| `mcp__pal__clink(cli_name="antigravity")` | Gemini (via Google's `agy` CLI) | ConPTY-driven subprocess (see fork) | ~20-25s |
| `mcp__pal__clink(cli_name="codex")` | OpenAI Codex | subprocess, `--json` | ~10-15s |
| `mcp__pal__clink(cli_name="claude-9arm")` (example name — use your own gateway config) | any model your gateway exposes | subprocess, real `claude` CLI routed through `--settings`/`--model` | ~8-10s |
| `mcp__pal__chat(model=<your-provider-model>, ...)` | same model as above, direct PAL route — no clink | PAL's own provider call | usually faster, no CLI bootstrap overhead |
| `mcp__pal__clink(cli_name="claude")` | Anthropic Claude | subprocess | upstream default preset |
| `mcp__pal__clink(cli_name="gemini")` | — | **dead as of mid-2026** — Gemini CLI binary was retired in favor of `agy`/Antigravity | n/a |

If a clink agent and `chat` hit the **same underlying model**, they are NOT interchangeable — `chat` has no file/tool access at all (a single-shot text completion via PAL's provider routing), while a `clink` CLI agent is a full agent loop that can genuinely read real files (verified: a real repo file was correctly read and quoted back, with `num_turns: 2` in the response confirming an actual Read-tool round-trip, not a guess). **This changes which one belongs in a brainstorm round:**
- **Question is about the actual codebase** (review an implementation, verify a claim against real code, anything where "read this file" would help) → use the agentic `clink` agent, not `chat`. `chat` literally cannot check anything against the real repo — asking it a codebase question makes it guess from whatever text you pasted, with no verification.
- **Question is purely conceptual/architectural** (answerable without touching a file) → `chat` is fine and faster (no CLI bootstrap tax).
- If unsure, default to the agentic `clink` call — it can still answer conceptual questions fine, just costs a bit more latency; the reverse (using `chat` when the question needed real files) silently produces a worse-grounded answer with no error to signal it.

## Why you can't just call `consensus` with all of them

`mcp__pal__consensus`'s `models[]` roster only accepts PAL-configured provider models — it has no concept of a clink CLI agent (they live in a completely separate registry: `clink/registry.py` + `conf/cli_clients/*.json`). There is no single tool call that spans both. Orchestrate manually instead (see below).

## How to run a brainstorm round

1. **Write one precise question/proposal** — the same exact prompt goes to every agent. Vague or drifting prompts make answers incomparable. State the question, relevant constraints, and what kind of answer you want (recommendation, critique, risk list, etc.) — these agents have **zero context from your conversation**, so include everything they need to answer standalone (paths, prior decisions, what's already been tried).
2. **Fire agents in parallel** — put multiple tool calls in a single message (independent calls, no shared state) rather than sequentially. Sequential stacks latencies; parallel is bounded by the slowest single agent.
   - **Codebase question** (needs real file access — see the `chat` vs agentic split above) — use your agentic clink agents, not `chat`:
     ```
     mcp__pal__clink(prompt=Q, cli_name="antigravity")
     mcp__pal__clink(prompt=Q, cli_name="codex")
     mcp__pal__clink(prompt=Q, cli_name="claude-9arm")
     ```
   - **Purely conceptual question** (no file grounding needed) — `chat` is fine and adds a free extra angle since it usually returns fastest:
     ```
     mcp__pal__clink(prompt=Q, cli_name="antigravity")
     mcp__pal__clink(prompt=Q, cli_name="codex")
     mcp__pal__clink(prompt=Q, cli_name="claude-9arm")
     mcp__pal__chat(prompt=Q, model=<your-provider-model>, working_directory_absolute_path=<project root>)
     ```
   Either way, if a clink agent and a `chat` call are the same underlying model, treat that pair as one vote when weighing convergence, not two independent ones.
3. **Read each response for what it actually says**, not just whether it returned 200. Note where they agree (signal — independent agents converging is real validation), where they diverge (the interesting part — dig into *why* before picking a side), and any agent that clearly misread the question (these may be smaller/different models than your main one; treat their output as input to your judgment, not a vote to average blindly).
4. **Synthesize and present your own recommendation** — don't just paste the raw responses at the user. State what the agents converged on, what they disagreed about, and your own read on which is right and why (you have the full session context they don't).
5. **Use `continuation_id`** (returned in each clink/chat response) to follow up with the *same* agent in the *same* thread if you want to push back or ask a clarifying question — it preserves that agent's prior context, so you don't have to re-explain the whole question from scratch.

## Round 2+: bounded judge-led challenge loop

A single round (independent parallel answers) is the default. For a genuinely consequential decision where round 1 produced real disagreement, run a **bounded challenge loop** instead of accepting round 1 as final — but **you (the orchestrating agent) are the judge and the stop condition**, not the sub-agents:

1. **Round 1** as above — same question to all agents, in parallel.
2. **You synthesize**: convergence (agents agreeing independently = signal), divergence (the interesting part), anything one agent caught that the others missed.
3. **Round 2 — write one challenge prompt per agent**, reusing that agent's own `continuation_id` (separate thread per agent, do NOT mix). The challenge must:
   - **Quote the other agents' actual claims and reasoning, not a vague "others disagreed."** Specific quotes ("Reviewer B recommended X because Y") is what makes the next round sharpen instead of restate. Generic "what do you think now?" gets a generic non-answer.
   - **Ask explicitly whether they revise or stand firm, and why** — give them room to concede with new reasoning, not just cave to majority.
   - **Surface what the OTHER agents caught that this agent didn't mention**, and ask them to react to it specifically.
4. **You synthesize again** — check whether round 2 produced genuinely new information (positions moved, reasoning sharpened) or was dry (just repeated round 1). Real convergence looks like: agents narrowing from "3-way disagreement" to "agree on the bookends, one narrow wrinkle left" — that's a sign the loop is working, not stalling.
5. **Default cap: 2 rounds of challenge (3 rounds total including round 1).** This is not a cost-driven limit if your backends are flat-rate subscriptions — it's there because **dry rounds are the actual stop signal, and a cap is just the safety valve for when a loop fails to self-terminate.** Stop *before* the cap whenever either hits: (a) positions have converged enough that you're confident making the final call, or (b) a round comes back dry (no new reasoning, just restated positions). If a round is still producing real movement, it's fine to go a round further; raise the cap explicitly with the user rather than silently looping past it. Looping past *dry* is the actual waste, not looping past some fixed round count.

## Latency is usually the real constraint, not cost

If your backends ride flat-rate subscriptions you're already paying for (rather than metered per-token billing), the `total_cost_usd` figure some tools report in responses is just internal accounting against a configured rate — it doesn't reflect money actually charged. Check your own setup before assuming either way.

**What's usually real is latency**:
- A CLI-driven agent's own session bootstrap (reading project context, system prompt injection) adds real tokens/time before it even starts on your question — larger real questions take proportionally longer.
- Agents that explore their working directory before answering (common for agentic CLIs) add tens of seconds per call.
- A 3-round, 3-agent challenge loop is a multi-minute wall-clock operation. That's the thing to budget for.

**Reach for this when the decision is worth the wait** — architecture calls, "am I missing something obvious", cross-checking a plan before a big/risky change. Don't use it for things a single careful pass already answers confidently — not necessarily because it costs money, but because burning minutes of wall-clock on a low-stakes question is its own waste.

## Giving a clink agent one of your skills

You can make a clink agent follow one of your own skill's rules for a task — useful when you want it held to the same discipline (a style guide, a refuse-gate, a checklist) rather than answering freely.

**Self-discovery is unreliable — don't rely on it.** Telling an agent "use the Skill tool to invoke X" produces inconsistent results because most clink agents have no skill system of their own that maps to yours:
- Some agentic CLIs with full filesystem access may go find and read your skill file on their own initiative if asked to.
- CLIs with their own separate skill/plugin system typically check that system, don't find your skill there, and give up without trying to read the raw file.
- Routing the *same* underlying model through a full agent loop (`clink`) vs. directly can behave inconsistently for this specific ask — don't assume they behave identically.

**The reliable method: paste the skill's content directly into the prompt.** Read the skill file yourself (full or a distilled excerpt, either works) and include it verbatim in the `prompt` you send, with a short framing line like *"Follow this skill for the rest of this conversation (full content sent directly, no file to find): ---\n<skill content>\n---"*. This works regardless of the target agent's own tooling and doesn't depend on filesystem access. It reliably works for both simple rule-following (an agent correctly cites specific rule names and applies them to a scenario, not just parrots the text back) and conditional gates (an agent correctly refuses a request that's missing required inputs per the pasted rules, quoting exactly which items are unmet — a harder test, since the natural instinct is to be helpful and act anyway despite the constraint).

**Data handling — decide your own policy before sending project content to a third-party model.** Whether sending your project's source/architecture/skills to a clink agent needs case-by-case gating is a call only you can make based on what's actually in your repo and who's authorizing it. If nothing in your codebase is confidential beyond literal secret values (API keys, tokens in `.env` or config files), it's reasonable to send ordinary project/skill content without asking each time — just never paste literal credential values into a clink prompt.

**One hard constraint that some coding-agent platforms won't let you waive by consent:** Claude Code's own auto-mode permission classifier hard-blocks the `absolute_file_paths` parameter on `clink` when it points into a repo's source, even with explicit user consent, and blocks attempts to write a skill policy that tries to pre-waive it. If you hit this, don't try to route around the classifier — treat it as a genuine constraint, not a negotiation.

**The working alternative for giving a clink agent real file access:** put the file path in the prompt *text* and ask the agent to read it with its own tools, instead of using a dedicated file-path parameter — e.g. *"Read this file directly using your own file-reading tools: /path/to/file.py, then answer: ..."*. This works because it's the agent's own initiative/tooling reading the file, not the orchestrator handing over a flagged parameter. Prefer this over paraphrasing when accuracy matters — a paraphrase risks losing detail you didn't think to include; direct file reads don't have that gap. Note that some agentic CLIs (ones with standing filesystem access via a bypass-approvals flag) will go read the real file on their own initiative regardless of what you send them — don't assume a careful paraphrase keeps them from seeing the real file.

## Known gotchas

- **A retired/replaced CLI binary stays dead** — if a vendor swaps CLI tools (e.g. Gemini CLI → Antigravity's `agy`), the old `cli_name` won't come back; route to the successor instead and update your config.
- **Clink CLI-client config is typically cached at MCP-server process start, not read per-call.** If you edit `conf/cli_clients/*.json` or the agent registry, the running server won't see the edit until it's restarted. Don't conclude a fix didn't work until you've restarted and retested.
- **A clink CLI agent only resolves if its `command` field is reachable from the *server's* process environment, not just your interactive shell.** A CLI that works fine in your terminal isn't automatically visible to a long-running or freshly-spawned server process — if a clink call fails with "not found in PATH", swap the config's bare command name for a full absolute path to the executable.

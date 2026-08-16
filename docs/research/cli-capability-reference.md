# CLI capability reference — what each harness gives you, and what you build

A living reference distilled from `2026-08-14-compliance-hook-surface-across-harnesses.md`. That file is
the evidence and the method; this one is the answer, kept short enough to read before implementing.

**Versions probed, 2026-08-14.** Claude Code (binary at `~/.local/bin/claude.exe`) · `codex-cli`
**0.147.0-alpha.6.5** under `%LOCALAPPDATA%\OpenAI\Codex\bin\` — note a second install at `0.144.4` is on
`PATH` and differs · `cursor-agent` **2026.08.11-e8db854** · `agy` **1.1.12**. All measurements are
headless (`-p` / `exec` / `--print`) on Windows 11. **Interactive behaviour is not covered and must not
be inferred from this.**

**Evidence grades.** **[L]** live with a positive control in the same run · **[B]** read from the shipped
binary or bundle · **[D]** vendor documentation, untested · **[U]** unknown. A **[D]** cell is a
hypothesis with a citation: three of them were wrong on the day this was written.

---

## The loop all four support

```text
gate the delegation → enforce inside every child session → capture evidence synchronously
                    → judge asynchronously → return a finding to the master
```

Only the tool name the gate matches differs: `Agent` (Claude Code), `spawn_agent` (codex),
`invoke_subagent` (agy), `Task` (cursor). **All four verified live.**

---

## Native (N) versus build-it-yourself (C)

| Feature | Claude Code | codex | cursor | agy |
|---|---|---|---|---|
| Delegation gate | **N** [L] `PreToolUse` on `Agent` | **N** [L] `SubagentStart` | **N** [L] `preToolUse` on `Task` | **N** [L] `PreToolUse` on `invoke_subagent` |
| Spawn arguments visible first | **N** [L] | **N** [L] `spawn_agent` | **N** [L] | **N** [L] |
| Hooks inherited by children | **N** [L] | **N** [L] | **N** [L] | **N** [L] |
| Per-child identity | **N** [L] `agent_id` | **N** [L] `agent_id` | **N** [L] `session_id` | **N** [L] `conversationId` |
| Child's own transcript | **N** [L] | **N** [L] | **N** [L] path often `null` | **N** [L] |
| Turn-boundary signal | **N** [L] `Stop` | **N** [L] `Stop` | **C** — tail `turn_ended` in the transcript | **N** [L] `Stop` |
| Mid-turn delivery | **N** [L] `PostToolUse`, `PostToolBatch` | **N** [L] `additionalContext` | **N** [L] the gate's reason | **N** [L] `PreInvocation` + `injectSteps` |
| Block at turn end | **N** [L] | **N** [L] | **C** — no `stop`; move to the pre-action gate | **N** [L] |
| Model evaluator | **N** [L] Haiku 4.5 | **C** | **N** [L] `type:"prompt"` | **C** — or a native subagent |
| Tool-using hook | **N** [L] `type:"agent"` | **C** | **C** | **C** |
| Detached child from a hook | **N** [L] | [U] | [U] | [U] |
| Global off switch | **N** [L] `disableAllHooks` | **N** [L] `[features] hooks=false` | **C** — none found | **C** — per-hook `enabled:false` only |
| Loop guard | **N** [L] `stop_hook_active` | **N** [L] `stop_hook_active` | **C** | **C** — mandatory, see below |
| Resume the same worker | **N** [L] block at `SubagentStop` reaches the child | [U] | **impossible** [L] — the event never fires | [U] |

---

## Per-CLI tool surface — a separate, deeper reference

`docs/research/cli/` holds a tool-surface document per harness, built from vendor documentation and, for
codex, the official source registry. **It answers a different question from this file** — *what tools
exist on this CLI* rather than *what the compliance design can use* — and it grades every row
`[DOC]` / `[SRC]` / `[GATED]` / `[EXT]` / `[RUNTIME]`.

**One finding from it changes this document.** codex carries a full multi-agent surface, and **all of it
is present in the `0.147` binary probed here**, verified by string scan: `spawn_agent` ×58,
`wait_agent` ×22, `send_input` ×13, `close_agent` ×13, `resume_agent` ×10, plus the V2 set —
`send_message` ×9, `followup_task` ×4, `interrupt_agent` ×3, `list_agents` ×3 — and `MultiAgentVersion` ×2.
The full scan also confirms the execution family it documents: `exec_command` ×42, `shell_command` ×22,
`write_stdin` ×12.

**And the probed build runs V1, not V2 — which the tool document warned would matter.** A live run
showed the model calling `spawn_agent`, `multi_agent_v1wait_agent` and `multi_agent_v1close_agent`, so
the V1 family is **[L]** and namespaced. **`followup_task` is therefore not reachable in this build**; V1's
equivalents are `send_input` on a live agent and `resume_agent` on a closed one. The persistent-peer-
reviewer shape exists on codex, but through V1's vocabulary — exactly the distinction between *present in
source* and *visible this turn*.

## Claude Code

**Build almost nothing.** It is the only host carrying every capability in the table, including the model
evaluator and a block that reaches a child agent rather than its parent.

**Worth knowing:** 31 hook events exist in the binary against **9** documented, and the undocumented ones
are configurable and fire. `PostToolBatch` fires **once per batch** where `PostToolUse` fires once per
call — three tool calls produced 3 and 1. `type:"agent"` hooks read files and can block with what they
found.

**Traps.** A `prompt` hook with a wrong `model` **does nothing, silently** — its `command` sibling still
fires, so a heartbeat will not catch it. A `prompt` hook on `PostToolUse` **runs, bills Haiku, and kills
the turn whatever it returns.** `--settings` **adds to** the project `.claude/settings.json` rather than
replacing it, which will contaminate a probe.

**The liveness detector to use here:** `modelUsage` in `--output-format json` names every model called.
A second model appearing there is proof the evaluator ran.

---

## codex

**Build the evaluator; everything else is native.** Richest payloads of the four — `tool_response`,
`transcript_path`, `turn_id`, `tool_use_id`, and `agent_transcript_path` on `SubagentStop`. Its
`PostToolUse` `{decision:"block"}` **replaces the tool result** with your text, which is a stronger
mid-turn channel than appending context.

**Worth knowing:** ten hook events and **that is all** — an exhaustive enum, verified, so unlike the
other three its documentation is not a subset. Handler types are enforced individually: an unsupported
`prompt` or `agent` handler is skipped with a diagnostic naming the file, and its siblings still fire.

**Traps.** An unknown **event key** is ignored with no diagnostic, and `--strict-config` does not catch
it. `--ignore-user-config` also drops the **project** layer. On `0.147` a hook did not fire without a
sandbox flag even with hook trust bypassed — unexplained, and absent from `0.144.4`'s source. Windows
needs `commandWindows`, forward slashes only.

---

## cursor

**Build four things**: the turn boundary, the turn-end block, a global off switch, and a loop guard.

**Worth knowing:** 21 events in the bundle, 8 seen firing. It has a native evaluator, and the gate, the
evaluator and mid-turn delivery are **one mechanism** — a `prompt` hook at `beforeShellExecution` denies
with a reason the agent reads mid-turn. It also loads **Claude Code's own** `~/.claude/settings.json` and
`<project>/.claude/settings.json`, deduplicated against its own.

**The turn boundary exists as data, not as a callback:** `stop` never fires headless, but the transcript
carries a `turn_ended` record. Tail it.

**Its transcript omits tool results** — `tool_use` is recorded, `tool_result` is not. The command's
`output` is in the `afterShellExecution` payload instead, so capture at the hook rather than reading
history.

**Traps, and it has the most.** Four separate ways a config loads as nothing, all silent: an unknown
handler **type**, an unknown **event key**, a wrong evaluator `model`, and a **UTF-8 BOM** — which is the
default output of Windows PowerShell's `Set-Content -Encoding utf8`. The first two void the **entire
file**, not the offending entry. An untrusted workspace refuses the run before hooks load at all.

---

## agy

**Build three things**: the evaluator, a global off switch, and a release condition for `Stop` — the last
is mandatory rather than optional.

**Worth knowing:** it ships its own hook contract at
`~/.gemini/antigravity-cli/builtin/skills/agy-customizations/docs/hooks.md`, 10.4 KB, which answers most
questions faster than probing. Its `injectSteps` channel is the richest mid-turn mechanism of the four —
it injects a user message, an ephemeral message, a system message, **or a tool call the model then
runs**. And its collaboration verbs — `invoke_subagent`, `send_message`, `manage_subagents`,
`define_subagent` — are ordinary tools, so the tool hooks cover the whole agent tree.

**Structure differs per event, and this is the trap that costs the most time.** `PreToolUse` and
`PostToolUse` take a **grouped** `matcher` + `hooks` wrapper; `PreInvocation`, `PostInvocation` and
`Stop` take handler objects **flat**. A flat list on a tool event is dropped with no diagnostic and the
file still counts as loaded.

**Other traps.** The top-level key of `hooks.json` is a **hook name**, not the literal string `hooks`.
`decision:"continue"` on `Stop` means *keep going* — returning it every call ran 168 extra turns to
timeout; **silence releases.** A malformed `injectSteps` **terminates the run** rather than failing open
— the only host here where a bad payload is fatal. Discovery needs a **`.git` root or a path in
`trustedWorkspaces`**; a plain directory is not a workspace. Hooks are **synchronous and capped** at a
30 s default per handler.

---

## What you build once, for every host

The per-host column above is the plug. This is the socket, and it is most of the work:

- a **spool**, the only interface a hook knows — two filesystem operations, nothing else
- a **verdict state machine**: one-shot delivery tokens, expiry, restart recovery, sticky debt
- a **detached judge**, which may take as long as it likes
- a **config generator** that emits only allowlisted event names and handler types per host, and
  **reads its own bytes back** — `json.loads` accepts a BOM and cursor does not
- a **liveness canary** requiring three observations: the hook fired, the evaluator ran, and a synthetic
  verdict was delivered and observed being consumed
- the **`DelegationRequest` contract**, validated at the gate on every host and server-side for clink

**One rule binds all of it:** every host blocks the turn while a hook runs — measured at 22 s, 21 s,
24.9 s and a 30 s cap. **No model call may sit inside a hook**, including the cheap native one.

---

## Not established

**Closed 2026-08-16:** a `PreToolUse` matcher fires on an MCP tool name — exact and regex, with the fully-qualified `mcp__<server>__<tool>` in the payload, control in the same run (#219). Still open: codex's spawn path, child hook inheritance and child identity through a real subagent · whether
`injectSteps.toolCall` can inject `invoke_subagent` or `send_message` on agy · whether an idle agy
subagent wakes with its context · whether a hook can spawn a detached child on codex, cursor or agy · a
global off switch for cursor.

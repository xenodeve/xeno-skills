# The compliance-hook surface on codex, cursor-agent and agy (2026-08-14)

**Commissioned for [#176](https://github.com/xenodeve/xeno-skills/issues/176) and [#208](https://github.com/xenodeve/xeno-skills/issues/208).** Answers one question per client: can it run a compliance reviewer the way Claude Code can?

## Provenance, and the one limitation that shapes how to read this

Produced by a delegated `codex` agent against the brief in this repository's session of 2026-08-13. **The research environment had none of the three CLIs installed** — the closing section records `codex`, `cursor-agent`, `agent` and `agy` all resolving to `NOT_FOUND`. So every finding below rests on vendor documentation, vendor changelogs, open-source implementation where it exists, and clearly-labelled forum or issue evidence. **It is not binary-grade**, which is the standard the brief asked for first, precisely because a previous investigation on this same question reached a wrong conclusion from `--help`.

**One claim was upgraded locally.** `codex` is installed on the developer's machine, and its shipped binary carries these strings verbatim:

```
prompt hooks are not supported yet
agent hooks are not supported yet
async hooks are not supported yet
failed to resolve parent transcript path for subagent hook
```

That corroborates the central architectural finding for codex — the handler types exist in the schema and **do not execute** — at binary grade, and confirms the subagent hook and its transcript path are real. Everything else in this document remains documentation-grade until probed.

## Why it matters here

Three findings change design already filed:

- **Only Cursor has a built-in evaluator.** Codex and Antigravity parse no `prompt` handler, so on those hosts the model call is ours to make — which is the case for putting the reviewer inside PAL rather than in the hook layer.
- **Cursor's transcript deliberately omits tool outputs.** A reviewer restricted to session history cannot judge a rule about what a command returned on that host, so evidence has to be captured separately at `postToolUse`.
- **`SubagentStop` on codex and cursor is a native worker-side continuation point**, carrying the child's transcript path. That is a place to challenge a worker inside its own lifecycle rather than inferring compliance afterwards from the master's side.

Its closing recommendation — normalise the *capabilities* rather than branching on client names — is the same shape as the enforcement tiers in `pal-mcp-server#89`, and the two should be reconciled rather than built twice.

---

| CLI | 1. Hook system | 2. Lifecycle events | 3. Stop / redirect | 4. Mid-turn text | 5. Prompt-hook equivalent | 6. Agent-hook equivalent | 7. Session transcript | 8. Cheap hook model | 9. Global gate |
|---|---|---|---|---|---|---|---|---|---|
| **Codex CLI** | **yes — layered config** | **yes — 11 events** | **yes — block continue** | **yes — context inject** | **no — runtime skipped** | **no — runtime skipped** | **yes — rollout JSONL** | **no — external model** | **yes — hash trust** |
| **Cursor Agent / CLI** | **yes — four scopes** | **yes — 21 events** | **yes — followup loop** | **yes — context inject** | **yes — fast model** | **no — no agent** | **yes — partial JSONL** | **yes — fast override** | **yes — workspace trust** |
| **Antigravity CLI (`agy`)** | **yes — command hooks** | **yes — five events** | **yes — continue reason** | **yes — invocation inject** | **no — command only** | **no — command only** | **yes — fixed JSONL** | **no — external model** | **UNKNOWN — global gate** |


## Addendum — codex verified live, 2026-08-14

**The reviewer loop works on `codex exec`.** Probed against `codex-cli 0.147.0-alpha.6.5` in an isolated directory, with a project-level `.codex/hooks.json` and a `Stop` command hook returning `{"decision":"block","reason":"…"}`:

```
hook: Stop
hook: Stop Blocked
CXPROBE7            <- the agent acted on the hook's reason
hook: Stop
hook: Stop Completed
```

The hook fired twice, blocked on the first and allowed on the second, and the agent used the reason as its next instruction. That is the same shape verified on Claude Code the day before, and it means **codex needs no built-in evaluator for the loop itself** — only for the judgement, which PAL supplies.

### Two prerequisites, both invisible from outside

**The sandbox blocks hook execution, silently.** Without `--dangerously-bypass-approvals-and-sandbox` the hook never ran and **no `hook:` line appeared at all** — indistinguishable from having no hook configured. Every earlier probe in this session failed for this reason and was misread as a trust problem.

**On Windows the hook needs `commandWindows`, and backslashes are eaten.** The handler schema, read from the shipped binary — `HookHandlerConfig::Command` carries `command`, `commandWindows`, `timeoutSec`, `async`, `statusMessage`, `additionalContextLimit`, and `command` is a **string, not an array** (`invalid type: sequence, expected a string`). A Windows path written with backslashes is mangled before execution. What works:

```json
"commandWindows": "cmd.exe /c \"C:/Program Files/Git/bin/bash.exe\" .codex/stop.sh"
```

This is the same defect class as the PAL config gotcha and as `xeno-skills#207` — with the difference below.

### Two corrections to earlier conclusions in this session

**Project-level hooks *are* loaded under `codex exec`.** An earlier probe concluded they were not, on the grounds that a deliberately broken file produced no warning. That was wrong: the file it broke was structurally valid enough to parse. With a genuinely invalid value codex names the exact path — `failed to parse hooks config C:\…\.codex\hooks.json: invalid type: sequence, expected a string at line 20 column 9`.

**Trust was not the blocker.** `--dangerously-bypass-hook-trust` is still required for an unreviewed hook, but the repeated failures were the sandbox and the path form, not the project trust layer.

### Where codex is better than Claude Code

**codex reports an unparseable hook config; Claude Code does not.** A malformed hooks file on codex produces a warning naming the file and the line. The same class of mistake on Claude Code produces nothing anywhere — no session error, no transcript record, nothing from `claude doctor` — which is `xeno-skills#207`.

### Still unverified on codex

Whether `PostToolUse` `additionalContext` reaches the model mid-turn; whether `SubagentStop` fires and carries `agent_transcript_path` in practice; and whether any of this holds when PAL drives codex rather than a bare shell.

---

# Codex CLI

## 1. Does a hook system exist?

**Answer: yes.** Codex has a first-class lifecycle hook system. The current release documentation and the shipped open-source implementation agree on the main shape.

### Configuration surfaces

Codex discovers hooks next to active config layers in either form:

- `hooks.json`
- inline `[hooks]` tables in `config.toml`
- plugin-bundled hook manifests / `hooks/hooks.json`
- managed hooks supplied through managed/system configuration

The four most useful user/project locations documented by OpenAI are:

```text
~/.codex/hooks.json
~/.codex/config.toml
<repo>/.codex/hooks.json
<repo>/.codex/config.toml
```

Multiple hook sources are additive rather than replacement-only. If a single config layer contains both `hooks.json` and inline `[hooks]`, Codex merges them and warns.

**Primary documentation:**
- https://developers.openai.com/codex/hooks
- Relevant release-behavior sections: “Where Codex looks for hooks”, “Review and trust hooks”, “Config shape”.

### Scope / trust model

Project-local hooks are loaded only when the project `.codex/` layer is trusted. Non-managed command hooks are reviewed by definition hash; changed hook definitions become untrusted again until reviewed. `/hooks` is the intended CLI UI for inspection/trust/disable. Managed hooks are policy-trusted and can be restricted with `allow_managed_hooks_only = true`.

OpenAI also documents a global feature gate:

```toml
[features]
hooks = false
```

Admins can force hooks on/off through managed `requirements.toml` policy.

### Invalid configuration behavior

**Not silent by design.** Current source discovery records warnings for unreadable or unparsable hook files and the release docs describe configuration warnings for unsupported fields/options. Runtime hook errors are surfaced as hook failures. For non-managed hooks, trust state also prevents execution until reviewed.

The source schema uses strict/descriptive parsing in several hook structures, and the discovery engine records load failures instead of silently pretending a handler loaded.

**Primary source:**
- https://github.com/openai/codex/blob/main/codex-rs/config/src/hook_config.rs
- https://github.com/openai/codex/blob/main/codex-rs/hooks/src/engine/discovery.rs

### Handler types: important distinction between schema and runtime

The source schema recognizes handler shapes for `command`, `mcp_tool`, `prompt`, and `agent`, but the **current release behavior is only `type: "command"`**. OpenAI's release docs explicitly say `prompt` and `agent` are parsed but skipped. The current discovery source likewise records load failures saying prompt, agent, and MCP-tool hook handlers are not supported yet.

This matters for a compliance reviewer: Codex has the lifecycle/control surface, but **does not currently provide Claude Code's built-in “harness calls a cheap evaluator model for the hook” path**.

---

## 2. Which lifecycle events exist?

**Answer: 11 currently documented / implemented hook events.**

| Event | Timing | Reviewer relevance |
|---|---|---|
| `SessionStart` | session/subagent startup path | inject initial discipline/context |
| `SessionEnd` | main thread end | final audit/cleanup; advisory |
| `UserPromptSubmit` | before user prompt enters model turn | route/inject/block prompt |
| `PreToolUse` | **before** supported local tool execution | deterministic policy gate |
| `PermissionRequest` | before Codex would request approval | allow/deny approval request |
| `PostToolUse` | **after** supported local tool produces output | inspect action/result; inject feedback |
| `PreCompact` | before compaction | preserve state / audit boundary |
| `PostCompact` | after compaction | reinject state / audit boundary |
| `SubagentStart` | subagent starts | lineage/policy observation |
| `SubagentStop` | subagent attempts to finish | worker compliance continuation |
| `Stop` | **end of turn** / root agent stopping point | main compliance continuation |

The exact current event list is also represented in Codex source hook enums/config structures.

### Does `PostToolUse` mean every tool call?

**No. Do not treat it as a universal enforcement boundary.** OpenAI's release docs say it covers shell commands, unified exec, `apply_patch`, MCP calls, and most local function tools. Hosted tools such as `WebSearch` do not traverse this local hook path, and specialized tool paths can opt out.

For a PAL/OpenClink policy engine this means:

```text
PreToolUse/PostToolUse = strong local guardrail
                      != exhaustive observation of every possible agent action
```

**Primary documentation:** https://developers.openai.com/codex/hooks

---

## 3. Can a hook stop or redirect the agent?

**Answer: yes, with strong semantics.**

### `PreToolUse`: block before side effect

Current release supports a hook-specific deny decision such as:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Destructive command blocked by hook."
  }
}
```

It also accepts the legacy-compatible shape:

```json
{
  "decision": "block",
  "reason": "Destructive command blocked by hook."
}
```

Exit code `2` with the reason on `stderr` is another blocking path.

`PreToolUse` can also rewrite a supported tool input by returning `permissionDecision: "allow"` plus `updatedInput`.

### `PostToolUse`: feedback after side effect

A post-tool block cannot undo an action that already happened. Instead it can replace the model-visible tool result with hook feedback and continue the model from that feedback.

### `Stop`: reviewer-style continuation

This is the key parity surface. A `Stop` command hook can return:

```json
{
  "decision": "block",
  "reason": "Run one more pass over the failing tests."
}
```

OpenAI documents that this does **not** reject/terminate the turn. Codex automatically creates a continuation prompt that acts as a new user prompt, with the hook `reason` as the prompt text, and keeps the agent working.

The open-source implementation confirms this mechanically: `StopOutcome` carries `continuation_fragments`; the turn loop converts them into a hook prompt and records/emits it before continuing.

**Primary documentation:**
- https://developers.openai.com/codex/hooks

**Primary source:**
- https://github.com/openai/codex/blob/main/codex-rs/hooks/src/events/stop.rs
- https://github.com/openai/codex/blob/main/codex-rs/core/src/session/turn.rs

### `SubagentStop`

`SubagentStop` supports the same reviewer pattern:

```json
{
  "decision": "block",
  "reason": "Run one more focused pass inside the subagent."
}
```

It receives `agent_id`, `agent_type`, `agent_transcript_path`, `stop_hook_active`, and the latest assistant message.

That is particularly useful for PAL/OpenClink: a worker can be challenged **inside its own subagent lifecycle**, rather than waiting for the master to infer worker compliance later.

---

## 4. Can a hook deliver text the agent reads mid-turn without ending the turn?

**Answer: yes.**

Several event paths can create model-visible context:

- `PreToolUse` can return `hookSpecificOutput.additionalContext` without blocking.
- `PostToolUse` can return `additionalContext`; it is added as extra developer context after the tool result.
- a blocked `PostToolUse` can replace the original result with feedback and continue the model.
- `SessionStart` and `UserPromptSubmit` can inject additional developer context.
- after root-session compaction, a `SessionStart(source="compact")` hook can inject context into the immediate continuation, including when automatic compaction happens mid-turn.

Example:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "The command updated generated files; re-run the generator before editing outputs."
  }
}
```

Codex also has output spilling for oversized model-visible hook context. The full hook output can be saved under a temporary `hook_outputs/<session_id>/...` path while the model sees a bounded preview plus file path.

**Primary documentation:** https://developers.openai.com/codex/hooks

---

## 5. Is there an equivalent to Claude Code `type: "prompt"` hooks?

**Answer: no in current release behavior.**

The config/source schema can parse prompt-shaped hook handlers, but the current release docs explicitly state:

```text
Only type: "command" handlers run today.
prompt and agent handlers are parsed but skipped.
```

The current discovery implementation likewise reports that prompt hooks are not supported yet.

Therefore Codex currently has **no built-in hook evaluator model**, no documented default cheap hook model, and no per-hook model override equivalent to Claude Code's prompt hook.

For compliance review, a command hook must call an evaluator itself, for example through PAL/OpenClink or another local service.

**Primary documentation:** https://developers.openai.com/codex/hooks

**Primary source:** https://github.com/openai/codex/blob/main/codex-rs/hooks/src/engine/discovery.rs

---

## 6. Is there an equivalent to a Claude Code `type: "agent"` hook?

**Answer: no in current release behavior.**

An `agent` handler shape is parsed in source/config but skipped by the runtime today. There is no supported hook-owned subagent that is automatically given tools/file access to investigate before deciding.

Do not confuse this with `SubagentStart` / `SubagentStop`: those are **events about Codex subagents**, not a hook handler type that launches its own investigating agent.

---

## 7. Where is the session transcript? Is it complete? Is compaction marked? Can a hook receive the path?

**Answer: yes, hooks receive `transcript_path`.**

Every command hook receives a common `transcript_path: string | null`. `SubagentStop` additionally receives `agent_transcript_path` for the child.

OpenAI explicitly warns that the transcript format is a convenience surface rather than a stable hook API and may change over time.

### Observed local path convention

Codex's local durable rollout files are observed under:

```text
$CODEX_HOME/sessions/YYYY/MM/DD/rollout-YYYY-MM-DDTHH-MM-SS-<thread-id>.jsonl
```

with default `CODEX_HOME` normally `~/.codex`.

This path convention is visible repeatedly in the official `openai/codex` issue tracker and is consistent with the open-source rollout/thread-store implementation. Example reports reference paths such as `~/.codex/sessions/.../rollout-....jsonl`.

**Evidence strength note:** the existence/format of the rollout store is strongly supported by source; exact user filesystem examples above are also corroborated by issue reports, but issue reports are user-provided evidence, not a versioned public API contract.

### Completeness

The rollout JSONL is a rich execution/session record, not merely a final prose summary. It can contain response items, tool-call records, token events and other session state. However:

- OpenAI does **not** promise that it is a stable, exhaustive compliance API.
- provider-redacted or unavailable reasoning is not magically recoverable.
- hook code should parse defensively and version its projection rather than couple policy to every internal field.

### Explicit compaction marker inside JSONL

**UNKNOWN as a stable public contract.**

Codex exposes explicit `PreCompact` and `PostCompact` lifecycle events and `SessionStart(source="compact")`, which are sufficient to establish compaction boundaries externally. The release docs do not promise a stable transcript record that should be consumed as “the compaction marker”; they explicitly warn that transcript format may change.

For a production compliance system, record compaction boundaries from hook events rather than depending on an undocumented JSONL record type.

**Primary documentation:** https://developers.openai.com/codex/hooks

**Supplementary official-repo issue evidence:**
- https://github.com/openai/codex/issues/27131
- https://github.com/openai/codex/issues/37419
- https://github.com/openai/codex/issues/37515

---

## 8. Which cheap model is available to a hook, and how is it selected?

**Answer: no built-in hook model today.**

Because only command handlers execute, a hook does not get a native “small fast evaluator” selection surface. A command hook can invoke any external/local evaluator that the environment permits.

For PAL/OpenClink, model choice should therefore be owned by the PAL reviewer adapter rather than Codex itself:

```text
Codex Stop hook
  -> command reviewer bridge
  -> PAL model router
  -> cheap evaluator
  -> verdict
  -> Codex continuation JSON
```

---

## 9. What gates the hook system?

**Answer: multiple explicit gates exist.**

1. **Feature gate**

```toml
[features]
hooks = false
```

2. **Project config trust** — project `.codex/` config layers must be trusted.
3. **Per-hook definition trust** — non-managed command hooks are trusted by current definition hash; changes require review again.
4. **Per-hook enable/disable** — `/hooks` can disable individual non-managed hooks.
5. **Managed policy** — admins can force hooks off/on, restrict execution to managed hooks only, or force managed hooks enabled.
6. **One-off bypass** — `--dangerously-bypass-hook-trust` exists for automation that vets hooks out-of-band; it should not be treated as a normal installation/trust mechanism.

### PAL / headless caveat

This needs a **release-specific live probe** before PAL treats it as guaranteed.

The official open-source runtime and current release docs show a substantial hook surface, but the official `openai/codex` issue tracker contains recent reports of `codex exec` hook-dispatch/trust regressions. One report for CLI 0.144.1 says a persisted trusted project `UserPromptSubmit` hook was skipped in `codex exec` unless `--dangerously-bypass-hook-trust` was passed; other releases have had hook discovery regressions.

These reports are not stronger than current source/docs, but they are strong enough that **PAL must not assume “interactive TUI parity = headless exec parity” without a probe of the exact Codex build it is driving**.

**Lower-confidence runtime evidence (official repo issue reports):**
- https://github.com/openai/codex/issues/32491
- https://github.com/openai/codex/issues/30835
- https://github.com/openai/codex/issues/24211

---

# Cursor Agent / Cursor CLI

## 1. Does a hook system exist?

**Answer: yes.** Cursor documents hooks as spawned processes that communicate over stdio with JSON and can observe, control, block, or modify the agent loop.

### Configuration sources

Current Cursor docs define four priority layers for local/managed use:

1. **Enterprise / MDM**
   - macOS: `/Library/Application Support/Cursor/hooks.json`
   - Linux/WSL: `/etc/cursor/hooks.json`
   - Windows: `C:\ProgramData\Cursor\hooks.json`
2. **Team / cloud-distributed** — Enterprise dashboard
3. **Project** — `<project-root>/.cursor/hooks.json`
4. **User** — `~/.cursor/hooks.json`

Priority is:

```text
Enterprise > Team > Project > User
```

All matching hooks from every source run; responses are merged with higher-priority sources winning conflicts.

Project hooks require a trusted workspace.

### Handler types

Cursor supports two first-class handler types locally:

- `command` — shell process, JSON stdin/stdout
- `prompt` — LLM-evaluated natural-language condition

Cloud agents currently run command-based hooks only; prompt hooks are unavailable there because the necessary authentication wiring is not available in the cloud execution environment.

### Failure / validation behavior

Per-script option:

```json
{"failClosed": true}
```

causes a crash, timeout, or invalid JSON response to block rather than fail open. Default is `false`.

Cursor provides a **Hooks tab** and a **Hooks output channel** to inspect configured/executed hooks and errors.

**Exact behavior for a structurally malformed top-level `hooks.json` file is not explicitly specified in the public docs; mark that narrow question UNKNOWN rather than assuming a validation policy.**

**Primary documentation:** https://cursor.com/docs/hooks

---

## 2. Which lifecycle events exist?

**Answer: 21 documented hook events across Agent, Tab, and app lifecycle.**

### Agent hooks — 18

1. `sessionStart`
2. `sessionEnd`
3. `preToolUse`
4. `postToolUse`
5. `postToolUseFailure`
6. `subagentStart`
7. `subagentStop`
8. `beforeShellExecution`
9. `afterShellExecution`
10. `beforeMCPExecution`
11. `afterMCPExecution`
12. `beforeReadFile`
13. `afterFileEdit`
14. `beforeSubmitPrompt`
15. `preCompact`
16. `stop`
17. `afterAgentResponse`
18. `afterAgentThought`

### Tab hooks — 2

19. `beforeTabFileRead`
20. `afterTabFileEdit`

### App lifecycle — 1

21. `workspaceOpen`

### Timing classification

**Before action / interceptable:**
- `preToolUse`
- `subagentStart`
- `beforeShellExecution`
- `beforeMCPExecution`
- `beforeReadFile`
- `beforeSubmitPrompt`
- `beforeTabFileRead`
- `preCompact` is before compaction, but observational only

**After each generic supported tool:**
- `postToolUse` on success
- `postToolUseFailure` on failure/timeout/permission denial

**End of root agent loop:**
- `stop`

**Subagent completion:**
- `subagentStop`

**Primary documentation:** https://cursor.com/docs/hooks

### Cloud caveat

Cloud agents support a subset. User-level local hooks do not exist in cloud VMs; project/team/enterprise sources do. `sessionStart`, `sessionEnd`, MCP hooks, Tab hooks and `workspaceOpen` have environment-specific limitations or do not apply. The research target here is principally local Cursor Agent / CLI as used behind PAL, not Cursor Cloud Agents.

---

## 3. Can a hook stop or redirect the agent?

**Answer: yes. Cursor has strong action and loop control.**

### Generic `preToolUse`

It can return:

```json
{
  "permission": "allow",
  "updated_input": {"command": "npm ci"}
}
```

or deny:

```json
{
  "permission": "deny",
  "user_message": "Blocked by policy",
  "agent_message": "Read the file before modifying it."
}
```

`agent_message` is fed back to the agent on denial. `updated_input` rewrites the tool request.

The schema accepts `ask` but current docs say `ask` is not enforced by generic `preToolUse` today.

Exit code `2` from a command hook blocks the action as a compatibility path.

### `stop`

A Cursor stop hook receives:

```json
{
  "status": "completed",
  "loop_count": 0
}
```

and can return:

```json
{
  "followup_message": "Continue: verify the failing test and repair it."
}
```

A non-empty `followup_message` is automatically submitted as the **next user message**, continuing the loop.

Default per-script loop limit is 5 for Cursor stop/subagentStop hooks, configurable by `loop_limit`; `null` removes the cap.

### `subagentStop`

`subagentStop` receives rich worker completion metadata including:

- status
- task / description
- summary
- duration
- message/tool-call counts
- modified files
- `agent_transcript_path`
- `loop_count`

It can return its own `followup_message`, giving Cursor a native worker-side continuation point.

**Primary documentation:** https://cursor.com/docs/hooks

---

## 4. Can a hook deliver text the agent reads mid-turn without ending the turn?

**Answer: yes.**

The cleanest generic path is `postToolUse`:

```json
{
  "additional_context": "The test output indicates schema drift; inspect migrations before retrying."
}
```

Cursor documents `additional_context` as extra context injected into the conversation after the tool result.

Other useful paths:

- `preToolUse` denial can send `agent_message` back to the agent.
- `sessionStart` can inject `additional_context` into the initial system context.
- `stop`/`subagentStop` can auto-submit follow-up user messages between loop iterations.

**Primary documentation:** https://cursor.com/docs/hooks

---

## 5. Is there a prompt-hook equivalent?

**Answer: yes, locally. This is the closest native equivalent among the three researched CLIs.**

Cursor prompt hooks:

- use an LLM to evaluate a natural-language condition
- receive hook input through `$ARGUMENTS` or automatic appended input
- return structured:

```json
{"ok": true, "reason": "optional"}
```

- use a **fast model** by default
- support an optional per-hook `model` override

Example shape:

```json
{
  "type": "prompt",
  "prompt": "Does this command look safe to execute? $ARGUMENTS",
  "timeout": 10,
  "model": "<optional override>"
}
```

### What is the default model?

**UNKNOWN.** Public docs say “a fast model” but do not name the exact model/slug as a stable default.

### Whose quota/billing does it use?

**UNKNOWN from the public hook docs.** Do not infer a billing bucket from the fact that Cursor runs the evaluator.

### Crucial compliance-reviewer limitation

A prompt hook receives the **hook input JSON**, which includes `transcript_path`, but the docs do **not** say that Cursor automatically reads/dereferences that path and sends the entire session transcript to the prompt evaluator.

Therefore this is not yet enough evidence to claim:

```text
Cursor prompt hook == Claude /goal history reviewer
```

For a reviewer that must judge **session history only**, the safe design is a command wrapper that explicitly reads the transcript (and any sidecar evidence) and then calls the evaluator, unless a live probe proves the prompt-hook runtime expands transcript content automatically.

**Primary documentation:** https://cursor.com/docs/hooks

---

## 6. Is there an agent-hook equivalent?

**Answer: no.**

Cursor documents `command` and `prompt` as hook execution types. It does not document a hook handler that launches a tool-using subagent with its own file/command access before returning a decision.

`subagentStart` and `subagentStop` are lifecycle events about the main agent's subagents, not an `agent` hook type.

---

## 7. Where is the session transcript? Is it complete? Is compaction marked? Can a hook receive it?

**Answer: yes, with an important completeness limitation.**

All agent hooks receive a base field:

```json
{"transcript_path": "string | null"}
```

and hook subprocesses receive `CURSOR_TRANSCRIPT_PATH` when transcripts are enabled.

Cursor's February 18, 2026 CLI changelog states that agent sessions are saved as **JSONL transcripts** and that **headless mode also writes transcripts**.

**Primary documentation:**
- https://cursor.com/docs/hooks
- https://cursor.com/changelog/cli-feb-18-2026

### Observed local path convention

A real Windows hook payload posted in Cursor's own community forum showed:

```text
C:\Users\<user>\.cursor\projects\<workspace-slug>\agent-transcripts\<conversation-id>\<conversation-id>.jsonl
```

The corresponding POSIX storage root is commonly observed under:

```text
~/.cursor/projects/<workspace-slug>/agent-transcripts/...
```

**Evidence classification: lower confidence than formal docs.** The formal hook docs guarantee the `transcript_path` field, so production code should consume the provided path rather than reconstructing it from this convention.

### Completeness: deliberately partial

Cursor staff stated in the official community forum that the JSONL transcripts include:

- user messages
- assistant text responses
- tool-call inputs (tool name + arguments)

and **intentionally do not include tool-call outputs**, because they can be very large.

Cursor staff recommends using `postToolUse` to log full tool outputs separately when needed.

That means a compliance reviewer cannot assume the transcript alone proves assertions such as:

```text
"the command returned exit code 0"
"the test output contained X"
"the file-read result contained Y"
```

unless that evidence is otherwise present in model text or a separate trace.

**Lower-confidence but vendor-staff evidence:**
- https://forum.cursor.com/t/accessing-the-full-agent-transcript-in-cursor/157311/5

### Explicit compaction marker inside transcript

**UNKNOWN.** Cursor provides a rich `preCompact` event containing `trigger`, context usage, token count, messages-to-compact, and `is_first_compaction`, but public docs do not promise a stable explicit compaction record inside the JSONL file itself.

For compliance state, capture the `preCompact` event directly.

---

## 8. Which cheap model is available to a hook?

**Answer: yes, a native fast-model evaluator exists.**

Prompt hooks use a fast model and allow an optional `model` override.

What remains unknown from public docs:

- exact stable default model slug
- exact billing/quota bucket
- whether default selection can change dynamically by Cursor version/account/model policy

For a cross-CLI PAL runtime, treat Cursor's prompt-hook model as a host capability rather than hard-coding a model name.

---

## 9. What gates the hook system?

**Answer: project hooks require workspace trust.**

Other relevant controls:

- per-script `failClosed` determines fail-open/fail-closed behavior on hook crash/timeout/invalid JSON
- Enterprise/Team/Project/User source priority controls conflicting policy
- local user hooks are not available to cloud agent VMs
- headless CLI `--force` is documented as implicitly trusting the workspace in Cursor's CLI changelog

**Global “disable all hooks” switch:** **UNKNOWN from the current public hook docs.** Do not invent a Claude-style `disableAllHooks` equivalent.

**Primary documentation:**
- https://cursor.com/docs/hooks
- https://cursor.com/changelog/cli-feb-18-2026

---

# Antigravity CLI (`agy`)

## 1. Does a hook system exist?

**Answer: yes.** Antigravity exposes JSON hooks that run custom shell commands at specific points in the agent execution loop.

### Configuration

Current Antigravity hook docs place `hooks.json` in customization directories, including:

```text
<workspace>/.agents/hooks.json
~/.gemini/config/hooks.json
```

Antigravity plugins can also bundle a root-level `hooks.json`.

The Antigravity CLI changelog records a fix where `/hooks` previously wrote to `~/.gemini/antigravity-cli/hooks.json`; the corrected shared location is `~/.gemini/config/hooks.json`.

### Handler type

Only one execution type is currently documented:

```json
{
  "type": "command",
  "command": "./script.sh",
  "timeout": 30
}
```

`type` defaults to `command`, and default timeout is 30 seconds.

### Per-hook enable

A named hook block can set:

```json
{"enabled": false}
```

to disable it without deleting the configuration.

### Invalid config behavior

**UNKNOWN.** The current public hook documentation specifies the schema and `/hooks` management surface but does not state a complete contract for malformed top-level `hooks.json`: whether every schema validation error is surfaced, whether a bad block is skipped while others load, or whether any cases are silent.

Do not infer validation semantics from `--help` or from unrelated customization loaders.

**Primary documentation:**
- https://www.antigravity.google/docs/hooks
- https://www.antigravity.google/docs/plugins
- https://antigravity.google/changelog

---

## 2. Which lifecycle events exist?

**Answer: exactly five events in the current Antigravity JSON-hooks documentation.**

| Event | Timing | Reviewer relevance |
|---|---|---|
| `PreToolUse` | **before** tool execution | deterministic gate |
| `PostToolUse` | **after** tool completion | observation / trace |
| `PreInvocation` | immediately before model invocation | inject context/steps |
| `PostInvocation` | after invocation/tool-call phase | inject context; force continue/terminate |
| `Stop` | execution loop termination | final compliance continuation |

This is a smaller event vocabulary than Cursor or Codex, but the invocation-level controls are unusually powerful.

**Primary documentation:** https://www.antigravity.google/docs/hooks

---

## 3. Can a hook stop or redirect the agent?

**Answer: yes.**

### `PreToolUse`: hard gate

The documented decision vocabulary includes:

```text
allow
deny
ask
force_ask
deny_unless_prior_grant
```

and current docs also describe `permissionOverrides`. `deny_unless_prior_grant` denies unless the resource was previously approved in an earlier user grant. The hook receives the proposed `toolCall` including tool name/args before execution.

Example deny/approval policy shape:

```json
{
  "decision": "deny",
  "reason": "Read receipt missing for this file."
}
```

This is directly suitable for deterministic OpenClink/PAL invariants such as read-before-write.

### `PostInvocation`: control execution flow

A post-invocation hook can return:

```json
{
  "injectSteps": [],
  "terminationBehavior": "force_continue"
}
```

or `"terminate"`.

### `Stop`: reviewer-style continuation

A `Stop` hook can return:

```json
{
  "decision": "continue",
  "reason": "Not done yet; verify the required evidence."
}
```

When `decision` is `continue`, Antigravity prevents termination and re-enters the execution loop. The `reason` is injected as a **system message** into the conversation.

This is a very strong native surface for an external compliance reviewer.

**Primary documentation:** https://www.antigravity.google/docs/hooks

---

## 4. Can a hook deliver text the agent reads mid-turn without ending the turn?

**Answer: yes, primarily at model-invocation boundaries.**

### `PreInvocation`

Can return `injectSteps`, where an injected step may be:

- `toolCall`
- `userMessage`
- `ephemeralMessage` — transient system message

Example:

```json
{
  "injectSteps": [
    {"ephemeralMessage": "Read-before-write policy remains active for this phase."}
  ]
}
```

### `PostInvocation`

Can inject the same step types and separately choose `terminationBehavior`.

### `PostToolUse`

Important limitation: current docs define its output as just `{}`. It is useful for logging/observation, but it does **not** directly inject model-visible feedback at every individual tool completion.

Therefore the natural Antigravity split is:

```text
PreToolUse       -> deterministic hard gate
PostToolUse      -> evidence capture
PreInvocation    -> context injection before model
PostInvocation   -> feedback + continue/terminate
Stop             -> final reviewer challenge
```

**Primary documentation:** https://www.antigravity.google/docs/hooks

---

## 5. Is there a prompt-hook equivalent?

**Answer: no.**

Antigravity's current JSON-hook handler type is command-only. There is no documented equivalent where the harness itself calls a cheap model on behalf of the hook and interprets `{ok, reason}`.

An external command hook can call PAL/OpenClink or another model service, but that is application logic, not a native prompt hook.

---

## 6. Is there an agent-hook equivalent?

**Answer: no.**

There is no documented hook handler type that launches a tool-using investigator/subagent on the hook's behalf. Antigravity has subagents as an agent capability, but that is distinct from an `agent` hook execution type.

---

## 7. Where is the session transcript? Is it complete? Is compaction marked? Can a hook receive it?

**Answer: yes; Antigravity documents an exact transcript path contract.**

Every hook receives:

```json
{
  "conversationId": "...",
  "workspacePaths": ["..."],
  "transcriptPath": "...",
  "artifactDirectoryPath": "..."
}
```

The hook docs describe `transcriptPath` as the absolute path to persistent `transcript.jsonl` conversation logs.

For Antigravity CLI, the documented path resolves under:

```text
~/.gemini/antigravity-cli/brain/<conversationId>/.system_generated/logs/transcript.jsonl
```

The docs distinguish this from Antigravity 2.0's separate app-data root.

**Primary documentation:** https://www.antigravity.google/docs/hooks

### Completeness

**UNKNOWN as an exhaustive execution trace.**

The docs call it persistent conversation logs but do not publish a stable guarantee that every tool input/output, internal reasoning item, permission interaction, or background-task event appears in JSONL. A compliance system should inspect/normalize the format by version instead of assuming “persistent” means “complete”.

### Compaction marker

The Antigravity CLI changelog states that version 1.1.3 added an indicator at each context-compaction boundary in the UI. That **does not prove** that `transcript.jsonl` contains a stable explicit compaction record suitable as a machine interface.

Therefore:

**explicit JSONL compaction marker = UNKNOWN.**

If a reviewer needs durable compaction boundaries, PAL should record them from observable runtime signals when available rather than infer a field that is not documented.

---

## 8. Which cheap model is available to a hook?

**Answer: no native hook evaluator model is documented.**

The hook input may include execution/model context through the surrounding harness, but command hooks do not receive a built-in `prompt` evaluator facility comparable to Claude Code or Cursor prompt hooks.

For OpenClink/PAL:

```text
agy Stop / PostInvocation hook
  -> PAL reviewer bridge
  -> capability/model router
  -> cheap evaluator
  -> Antigravity JSON decision
```

---

## 9. What gates the whole hook system?

**Answer: the complete global gating contract is UNKNOWN from current public hook docs.**

What is verified:

- individual named hooks can be disabled with `enabled: false`
- plugin disable state affects whether plugin hooks run; a July 2026 changelog fix specifically addressed disabled plugins still running hooks
- Antigravity CLI has an explicit workspace-trust step on first launch
- a July 2026 CLI fix says workspace-local `.agents/hooks.json` hooks were not loading after trusting a folder and changed hook reload behavior when workspaces change, which strongly ties workspace hook loading to folder trust
- tool permissions/sandbox configuration are separate controls; they should not be conflated with a global hook-enable switch

What was **not** verified in current public docs:

- a single supported `hooks=false` / `disableAllHooks` global setting equivalent to Codex/Claude
- a managed enterprise setting that forcibly disables all JSON hooks
- exact behavior of hooks under every `--dangerously-skip-permissions` / headless combination

Thus the table marks the global-gate question `UNKNOWN` rather than inventing a stronger contract.

**Primary evidence:**
- https://www.antigravity.google/docs/hooks
- https://www.antigravity.google/docs/cli-getting-started
- https://antigravity.google/changelog

### PAL / headless caveat

The Antigravity changelog explicitly maintains `agy -p` headless behavior and contains multiple headless fixes. However, the public hook docs do not state a formal “all five hook events fire identically under every headless/ConPTY launch mode” guarantee.

Because PAL drives Antigravity through a specific subprocess/ConPTY path, production parity should be confirmed with a small versioned probe that logs all five events under the exact PAL launcher.

---

# What would have to be built per CLI

The target reviewer is constrained to:

1. judge from session history/evidence rather than re-reading the repository as its primary source of truth;
2. deliver a finding that the running agent actually reads;
3. keep bounded state between turns;
4. return `UNKNOWN` when the host does not expose enough evidence;
5. never replace the master/developer as final authority.

## Shared PAL/OpenClink abstraction

A cross-host reviewer should normalize host-specific events into an internal contract instead of letting compliance logic branch directly on every CLI schema.

Suggested internal shape:

```text
ComplianceEvent
  host
  session_id
  turn_id / generation_id / execution_id
  actor_id
  event_kind
  transcript_ref
  worker_transcript_ref?
  evidence_refs[]
  host_capabilities

ComplianceDecision
  verdict: satisfied | violated | partial | delegated | unknown
  reason
  evidence_refs[]
  model_visible_feedback?
  state_patch?
```

Persist reviewer state separately from vendor transcripts:

```text
<PAL state>/compliance/<host>/<session-id>.json
```

Use atomic write/lock or a single-writer queue. Do not make the vendor transcript itself the mutable state store.

---

## Codex: required construction

### What is already native

- root `Stop` continuation with model-visible reason
- `SubagentStop` continuation and child transcript path
- `PreToolUse` deterministic blocking/rewrite
- `PostToolUse` feedback and developer-context injection
- `UserPromptSubmit` / compact lifecycle context injection
- rich local rollout JSONL path delivered to hooks
- per-definition trust and global feature gate

### Missing native piece

**Model evaluator handler.** `prompt`/`agent` hook handler types do not execute today.

Build:

```text
Codex Stop command hook
  -> read bounded projection of transcript_path
  -> read PAL compliance state
  -> PAL selects cheap evaluator
  -> evaluator returns structured verdict
  -> if violated:
       {"decision":"block","reason":"..."}
     else:
       {}
  -> update PAL state
```

For worker review, mirror it at `SubagentStop` using `agent_transcript_path`.

### Deterministic invariants

Do not ask the evaluator to judge rules that can be enforced mechanically. Use `PreToolUse` first, e.g. read-before-edit receipt, allowed path, continuation provenance, required tool sequence where the event data is sufficient.

### Special PAL requirement

Run a startup capability probe against the **exact Codex binary and launch mode** used by `clink`, particularly `codex exec` trust/dispatch behavior. If the probe fails, return host capability `hook_runtime_unverified` and do not advertise enforced reviewer parity.

---

## Cursor: required construction

### What is already native

- very broad lifecycle vocabulary
- generic tool pre/post hooks plus explicit failure event
- root and subagent stop continuation
- prompt hooks using a fast model
- `transcript_path` passed into every agent hook
- headless CLI transcript persistence

### Main evidence gap

The built-in JSONL transcript intentionally omits tool outputs according to Cursor staff. Therefore “session history only” is insufficient for compliance rules that depend on the actual outputs of tools.

Build a reviewer-safe sidecar:

```text
postToolUse/postToolUseFailure
  -> append bounded normalized evidence
     {generation_id, tool_use_id, tool_name, result_class,
      exit/status if exposed, hashes/pointers, timestamp}
```

Avoid dumping huge raw outputs unless the rule requires them; keep hashes/pointers or bounded excerpts.

### Prompt-hook limitation

Although Cursor has native prompt hooks, public docs do not prove the prompt evaluator automatically dereferences `transcript_path` into history. Therefore the most reliable first implementation remains:

```text
Cursor stop command hook
  -> read JSONL transcript
  -> merge PAL/Cursor evidence sidecar
  -> call evaluator (PAL-selected, or a proven Cursor-hosted model path)
  -> violated => {"followup_message":"..."}
```

If a live probe later proves the native prompt hook can be supplied a bounded transcript projection efficiently, the command bridge can delegate the final yes/no judgment to that native prompt hook.

### Worker reviewer

Use `subagentStop.agent_transcript_path` plus the same sidecar strategy. `subagentStop` can return a `followup_message`, so the worker can be challenged before the parent accepts its output.

---

## Antigravity: required construction

### What is already native

- strong `PreToolUse` policy gate
- `PostToolUse` observation
- invocation-level injection before and after model calls
- `PostInvocation.terminationBehavior`
- `Stop {decision:"continue", reason:...}` where reason becomes a system message
- exact `transcriptPath` supplied to every hook

### Missing native piece

No prompt/agent evaluator handler. Build an external PAL reviewer bridge:

```text
agy Stop command hook
  -> read bounded transcript projection
  -> read PAL compliance state/evidence sidecar
  -> PAL selects cheap evaluator
  -> evaluator verdict
  -> violated:
       {"decision":"continue","reason":"..."}
     satisfied:
       return the release-verified non-continuation/no-op shape
  -> update state
```

The exact non-continue decision value need not be semantically special: Antigravity docs state that `continue` prevents stopping; other values allow the stop. Use the most conservative documented/no-op shape accepted by the tested release.

### Mid-turn repair

Antigravity has a useful separation:

```text
PreToolUse       = hard invariant enforcement
PostToolUse      = evidence collection
PreInvocation    = inject required context before next model call
PostInvocation   = challenge / force another model step
Stop             = final reviewer check
```

That maps naturally onto OpenClink's intended `Route -> Inject -> Execute -> Observe -> Challenge -> Repair -> Continue` control loop without relying on skills alone.

### Special PAL requirement

Probe all five events under the exact Windows ConPTY/headless launch path PAL uses. Treat event retention and transcript completeness as capabilities discovered at runtime/version install time, not timeless assumptions.

---

## Cross-CLI result for the compliance-reviewer design

A Claude-like reviewer is feasible on all three, but the missing pieces differ:

```text
Codex
  lifecycle/control: strong
  built-in evaluator: absent
  transcript: rich but unstable internal format
  main risk: headless release parity / hook trust regressions

Cursor
  lifecycle/control: strongest breadth
  built-in evaluator: present (fast prompt hook)
  transcript: stable path surface, but tool outputs intentionally omitted
  main risk: evidence completeness; prompt hook does not document transcript dereference

Antigravity
  lifecycle/control: smaller event set, very strong invocation control
  built-in evaluator: absent
  transcript: exact persistent path documented, completeness unspecified
  main risk: exact headless/ConPTY event parity and undocumented global kill switch
```

For PAL/OpenClink, the cleanest architecture is therefore not to emulate Claude's hook implementation literally. Normalize the **semantic capabilities**:

```text
CAP_PRE_ACTION_GATE
CAP_POST_ACTION_OBSERVE
CAP_MODEL_CONTEXT_INJECT
CAP_END_TURN_CONTINUE
CAP_WORKER_END_CONTINUE
CAP_TRANSCRIPT_PATH
CAP_BUILTIN_MODEL_EVALUATOR
CAP_TOOL_OUTPUT_IN_TRANSCRIPT
CAP_COMPACTION_BOUNDARY
CAP_GLOBAL_HOOK_GATE
```

Then the reviewer policy depends on capabilities, not client names. A host with no built-in evaluator can use PAL's evaluator. A host with incomplete transcript evidence gets a PAL sidecar. A deterministic invariant is always enforced at the earliest pre-action software gate available.

# Commands actually run

```bash
for c in codex cursor-agent agent agy; do printf '%-14s ' "$c"; command -v "$c" || echo NOT_FOUND; done
```

Observed in the research environment:

```text
codex          NOT_FOUND
cursor-agent   NOT_FOUND
agent          NOT_FOUND
agy            NOT_FOUND
```

No CLI binary was installed or mutated for this research. Findings therefore come from shipped/open-source schemas where available, vendor documentation, vendor changelogs, and clearly labeled lower-confidence vendor issue/forum evidence; direct live behavior on the target machine remains a required follow-up for release-specific PAL integration.

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

## Addendum — cursor-agent and agy probed, 2026-08-14: not demonstrated

**Neither fired a hook in headless mode in this environment.** Stated as *not demonstrated* rather than *absent*, because the failure mode and the evidence differ from codex in a way that matters.

### cursor-agent 2026.08.11-e8db854

Probed with a project `.cursor/hooks.json`, run as `cursor-agent -p --force --trust`. Two config shapes were tried — the documented `{"version":1,"hooks":{"stop":[{"command":…}]}}` and the same with an explicit `"type":"command"` — and finally a command with no external program at all (`cmd.exe /c echo FIRED>hook.log`), the exact form that succeeded on codex. **Nothing ran**, and cursor's own per-project `worker.log` contains no occurrence of the word *hook*.

What the shipped bundle does confirm, at binary grade:

- the project path is `<project>/.cursor/hooks.json`, alongside a user path, a team path, and `C:\ProgramData\Cursor\hooks.json` on Windows
- a separate **`claudeUserConfigPath`**, and a translation table from Claude Code's event names to cursor's own — `PreToolUse→preToolUse`, `Stop→stop`, `UserPromptSubmit→beforeSubmitPrompt`, and **`PermissionRequest→null`**, meaning cursor has no equivalent of that event
- `shouldSkipHookDueToLoopLimit` applies to `stop` and `subagentStop` only, reading `loop_count` against `loop_limit`
- the continuation path is real: `[hooks] Stop hook returned followup_message, queueing (loop …)`, queued as a `userMessageAction`
- injected context is size-capped, with a dedicated `HookAdditionalContextTooLargeError`

So the machinery exists in the binary. What is not established is the **entry schema of the project config file**, and without a diagnostic channel — cursor printed no warning for any of the three attempts — a wrong shape and an unloaded file look identical.

### agy 1.1.12

Probed with `<workspace>/.agents/hooks.json` and `agy --print "…"`. The turn ran and answered; **no hook ran**, and `agy hooks list` produced no output. As with cursor, the config shape came from vendor documentation rather than from the binary, and no diagnostic was emitted.

### Why this is a finding rather than a gap

**codex told us when we were wrong.** Every failed codex attempt produced either a parse warning naming the file and the line, or a `hook: Stop Failed` line. That is what made four failed probes converge on a working configuration in one session.

**cursor and agy said nothing at all.** The same class of mistake produces silence, so a wrong config and an absent capability are indistinguishable from outside — which is precisely the defect `xeno-skills#207` records for Claude Code, appearing here on two more clients.

**Consequence for the reviewer design.** A per-client capability probe cannot be *"configure a hook and see if it fires"* on a host that stays silent, because a negative result there is uninformative. It has to be a probe with a **positive control** — a configuration known to fire — before any negative can be trusted.

---

## Addendum — cursor and agy verified live with a positive control, 2026-08-14

**The addendum above is superseded on its central claim, and the "both are silent" finding is refuted.** Both clients run hooks headless. The earlier probes failed on the config's **shape** and, for agy, its **location** — and both clients do report, just not to stdout: cursor collects parse errors into a structure it never prints, and agy writes them to `--log-file`, which the earlier probe never opened.

The rule that addendum derived still stands, and is what produced this one.

### The method that changed the outcome

**The positive control was a hook whose only job is to append a line to a file** — no dependency on any output contract, any exit-code convention, or the host printing anything. Control and test events live in the same file and run in the same invocation, so a control that fires makes the test's silence informative.

### cursor-agent 2026.08.11-e8db854 — hooks work headless

Schema read from the shipped bundle (`versions/2026.08.11-e8db854/190.index.js`), not from documentation:

- file shape `{"version":1,"hooks":{"<event>":[entry]}}`
- **the entry is flat** — `{"type":"command","command":"<string>"}`, or `{"type":"prompt","prompt":"…","model":"…"}`. There is **no Claude-style matcher wrapper**; an entry nested as `{"matcher":…,"hooks":[…]}` is not this schema. That mismatch, not the capability, is why the earlier probes did nothing.
- paths: `<project>/.cursor/hooks.json`, `~/.cursor/hooks.json`, a team path, and `C:\ProgramData\Cursor\hooks.json` — **plus Claude Code's own** `~/.claude/settings.json`, `<project>/.claude/settings.json` and `<project>/.claude/settings.local.json`, deduplicated against cursor's own entries by a `prompt:` / `command:` key
- `loadProjectHooks` defaults to **true**, so project hooks are not gated behind a flag

One run, one config at user scope, `cursor-agent -p --trust --output-format text`:

| Event | Fired | Register |
|---|---|---|
| `beforeShellExecution` | **yes** | the positive control |
| `afterShellExecution` | **yes** | |
| `stop` | **no** | genuine negative — it should fire on any turn |
| `beforeSubmitPrompt` | **no** | genuine negative — same |
| `subagentStop`, `afterFileEdit`, `beforeReadFile` | did not fire | **untested, not negative** — the run spawned no subagent and read or edited no file |

**Q5 confirmed live: cursor has a native evaluator.** A `type: "prompt"` hook on `beforeShellExecution`, given a prompt string and no model, denied the command, and its reason reached the agent verbatim:

```
Rejected: Command execution was blocked by a hook: CURSORPROMPTHOOK_OK_7B2
```

**That is Q4 on cursor as well** — the text arrived *mid-turn*, the agent read it, and the turn carried on to report what happened rather than ending. So on cursor the pre-action gate, the model evaluator and mid-turn delivery are one mechanism.

**Q3 is the open one on cursor.** `stop` did not fire in `-p` mode, so the *turn-end* reviewer this design assumes is not available headless even though the pre-action gate is.

**Why the earlier probe saw no diagnostic — mechanism, not conjecture.** In `190.index.js` the loader pushes parse failures into a collected `errors` array, and calls `logger.warn` only when refusing a symlinked config path. Nothing prints that array in headless mode; the shipped string `To view or modify configured hooks, go to Cursor Settings > Hooks.` shows where it was meant to surface. **Silence on a malformed cursor hooks file is by design and is not evidence the file went unread.**

### agy 1.1.12 — hooks work headless, and it reports

- **Path** `<workspace>/.agents/hooks.json`, matching the binary's own template `{workspace}/.agents/`. **The working directory alone is not a workspace**: the file was discovered only after the directory became a git root *and* was passed with `--add-dir`. Which of the two did it is **not isolated** — one probe changed both.
- **Entry is flat, with per-platform overrides** — `{"type":"command","command":…,"windows":…,"linux":…,"osx":…}`. This is the shape of the developer's own working `~/.agents/hooks/hooks.json` on this machine, and agy rejects the Claude-style nested form by name: `invalid hook "hooks": command hook must specify 'command'`.
- **agy is not silent.** `--log-file` carries a discovery counter — `hooks_manager.go:53] loaded N named hooks from N hooks.json file(s)` — plus `command_hook_executor.go:75] JSON hook command stderr: …` and a named per-hook failure (`session_start.go:44` / `stophooks.go:62`, handles like `jsonhook__hooks_Stop_0_0`). **The counter moving 0 → 1 is the positive control for discovery**, independent of whether the hook's own command works.
- **A flag-parsing trap that voided one probe.** `--dangerously-skip-permissions` is a Go bool flag: written bare before the prompt it swallows the prompt, and the agent answers a question about the flag itself. It needs `--dangerously-skip-permissions=true`.

Fired: `SessionStart` ✔, `Stop` ✔. `PreToolUse` and `PostToolUse` did not fire — **and the reason was
the config's shape, not the host. Corrected below; all four fire.**

**Q3 confirmed live on agy, with a hazard worth more than the confirmation.** A `Stop` hook returning `{"decision":"block","reason":"…state the token…"}` on its first call and **nothing** on the second produced `PONG`, then the demanded token exactly once, then a clean end. Returning `{"decision":"continue"}` on every later call instead ran **168 extra turns** and died on `Error: timeout waiting for response`.

**Silence releases the turn; `"continue"` does not, and no loop limit intervened.** A blocking `Stop` hook on agy therefore needs its own release condition in the hook, or it will spend the entire turn budget. Note this is the opposite of what the loop-limit machinery does on cursor (`shouldSkipHookDueToLoopLimit`, `loop_count` vs `loop_limit`), which is a difference the capability normalisation has to carry rather than hide.

### Still untested on both

Q2 in full, Q6, Q7, Q8 and Q9 — and on agy, Q4 and Q5 as well. Nothing above establishes any of them.

### The four-way matrix, live grade only

Added after probing the remaining gaps, including Claude Code itself — which had never been tested on
the two capabilities the whole design rests on. Every cell below was produced by a run with a positive
control in the same configuration; anything not probed is written as such rather than inferred.

| | Claude Code | codex | cursor 2026.08.11 | agy 1.1.12 |
|---|---|---|---|---|
| **Q2 event names** | **[L]** **31** in the binary, **9** documented — undocumented ones configurable and firing | **[L+B]** **10 and that is all** — an exhaustive `HookEventName` enum, and an unknown key proven inert live | **[L+B]** **21** in the bundle's map; **8 fired live** from one project-level config — `preToolUse` 6×, `postToolUse` 6×, `afterAgentThought` 3×, `beforeReadFile` 2×, plus `beforeShellExecution`, `afterShellExecution`, `sessionStart`, `workspaceOpen` | **[L/D]** **5** documented + `SessionStart`, which fires and is not in the docs |
| **Q3 block at turn end** | **[L]** yes | **[L]** yes | **[L+B]** **no** — `stop` never fires under `-p`; the bundle shows it wired only to UI sites | **[L]** yes, and `decision:"continue"` means *keep going*, not *release* |
| **Q4 deliver text mid-turn** | **[L]** yes — `PostToolUse` command hook, once per tool call | **[L]** yes — `additionalContext`; **[B]** `{decision:"block"}` replaces the tool result | **[L]** yes — via the pre-action gate's reason | **[L]** yes — `PreInvocation` + `injectSteps`; **[D]** `PostToolUse` ingests no return |
| **Q5 evaluator in the harness** | **[L]** yes — `type: "prompt"`, and it is **Haiku 4.5**, named in `modelUsage` | **[B]** no — `prompt hooks are not supported yet` | **[L]** yes — **[B]** queued only if a `promptHookClient` exists | **[L]** no — `prompt hooks are not currently supported`, its own log |
| **Q6 tool-using hook** | **[L]** yes — `type: "agent"` read a file off disk and blocked with its contents | **[B]** no | **[L]** no — and the entry **voids the whole file**, silently | **[L]** no — `unsupported hook type: "agent"`, file named |
| **Q7 transcript path to a hook** | **[L]** yes | **[L]** yes; **[B]** `SubagentStop` carries the child's own transcript | **[L]** yes — but the file holds `tool_use` and **no `tool_result`**; the `output` is in the payload | **[L]** yes — `transcriptPath` + `artifactDirectoryPath` |
| **Q8 per-hook `model`** | **[L]** read — a wrong value kills the hook silently | n/a | **[L]** read — same silent death | n/a |
| **Q9 global gate** | **[L]** `disableAllHooks` — control fired 2× without it, 0× with it; no env var and no flag found | **[L]** `[features] hooks=false` — control fired 1× without it, 0× with it · **[B]** `requirements.toml`, project trust, per-handler `enabled`, `--ignore-user-config` · **[L]** plus a sandbox flag on `0.147`, unexplained | **[B]** no kill switch; a team headless policy of `disabled` blocks `-p` entirely | **[L]** per-hook `enabled:false` works — two named hooks in one file, only the enabled one fired · **[D]** nothing global, after a search whose locations are listed |
| **What makes a directory eligible** | **[L]** the settings file it is given | **[B]** `.codex/` walked up the working-directory ancestry | **[L]** `<project>/.cursor/hooks.json`, loaded and fired — an earlier miss here was testing events that never fire, not a path problem | **[L+D]** a `.git` root, or a path in `trustedWorkspaces` — a plain directory is not a workspace |
| **Pre-action gate** | **[L]** `PreToolUse` | **[B]** `PreToolUse` + `PermissionRequest` | **[L]** `beforeShellExecution` | **[L]** `PreToolUse` — fired 2× once the structure was right |
| **Does a hook block the agent loop?** | **[L]** no | **[B]** no — handlers carry `async` | **[L]** **yes** — a 20 s hook added 24.9 s to the turn | **[L]** **yes, but capped** — an 8 s hook completed, a 30 s one was killed mid-run and the turn still answered; default `timeout` is 30 s |
| **Ways the config dies silently** | **[L]** wrong `model` · **[L]** a prompt hook on `PostToolUse` burns a Haiku call and kills the turn either way | **[L]** an unknown **event key** is ignored with no diagnostic, even under `--strict-config` · **[L]** `--ignore-user-config` also drops the *project* layer | **[L]** wrong `model` · **[L]** unknown type · **[B]** unknown event key · **[L]** a UTF-8 BOM · **[B]** trailing commas, bad `version`, bad `matcher` regex | **[L]** a flat handler list on a tool event, dropped with no diagnostic · **[L]** a malformed `injectSteps` kills the turn |

**Every cell carries its evidence grade, so nothing here needs re-testing unless the method improves.**

| Mark | Means | Re-test? |
|---|---|---|
| **[L]** | **Live** — run on this machine with a positive control in the same configuration | No, unless the client version changes |
| **[B]** | **Binary / bundle** — read out of the shipped artifact, not executed | Only if behaviour is what you need, not the schema |
| **[D]** | **Documentation** — vendor or bundled docs, not tested | **Yes — this grade has been wrong twice today** |
| **[U]** | **Unknown** — searched and not established, or never probed | Yes |

**The reason the [D] grade is called out.** Three documented statements were checked against behaviour
today. Claude Code's docs list 9 hook events and the binary carries 31, with the undocumented ones
configurable and firing — **a subset presented as a list**. agy's docs list 5 events and omit
`SessionStart`, which fires — **same shape**. And agy's per-event structure rule, which no probe had
read, was the actual cause of three wrong negatives. Against that, one documented restriction held:
prompt hooks really are unusable outside their four listed events, though *not* for the reason the doc
implies. **A [D] cell is a hypothesis with a citation, and on this evidence it is wrong about as often
as it is right.**

**The last two rows are the ones that change designs.** agy is the only host where a hook is on the
critical path by construction, so judgement cannot live inside one there. And the silent-death row is
why `#212` comes before anything else: on cursor there are four separate ways to end up with a
configuration that reads correctly and does nothing.

### Correction — agy has a mid-turn channel after all, and a richer one than the others

**This overturns the `Q4 = no` this document carried for agy, and the correction was found by a review
panel rather than by the probe.** A panellist pointed out that vendor documentation names
`PreInvocation` / `PostInvocation` events, which had never been probed — every agy run above tested
`PreToolUse` / `PostToolUse`, names carried over from Claude Code. **The events do not exist under those
names; they exist under agy's own.** The negative was real for the events tested and useless as a
statement about the host.

The binary carries the whole contract:

```
PreInvocationHookArgs   { invocation_num, initial_num_steps }
PreInvocationHookResult { repeated HookInjectedStep inject_steps }
PostInvocationHookArgs  { invocation_num, initial_num_steps, model_output, model_thinking }

HookInjectedStep = oneof {
  tool_call | user_message | ephemeral_message | system_message
  | error_message | hook_user_message | hook_ephemeral_message }
```

Probed live, with a `Stop` control in the same file: **`PreInvocation` and `PostInvocation` each fired
twice in one turn** — once per model invocation — while `Stop` fired once. Then a `PreInvocation` hook
returning

```json
{"inject_steps":[{"user_message":"COMPLIANCE NOTICE …"}]}
```

produced `PONG` followed by the notice, quoted back verbatim. **Mid-turn delivery works on agy.**

Three things follow, and the third is a hazard:

- **agy's channel is the richest of the four.** The others deliver a string; agy's oneof can inject a
  user message, an ephemeral message, a system message, or **a tool call** the model then executes.
- **The accepted step variants are three, and they are not the seven in the proto.** `toolCall`,
  `userMessage`, `ephemeralMessage` — nothing else. **Corrected:** an earlier revision of this file said
  the JSON must be snake_case because a camelCase attempt was rejected. That was the wrong diagnosis of
  the right observation. The rejected payload used `hookUserMessage` and `systemMessage`, which exist in
  the proto descriptor and **are not accepted by the implementation**. Retested with a documented
  variant, `{"injectSteps":[{"userMessage":"…"}]}` works, and so does the snake_case form. **The casing
  was never the problem; the variant name was.** A descriptor is not a contract.
- **A malformed injection kills the turn.** The camelCase attempt returned
  `unknown injected step type: <nil>` and the run ended with `Error: Agent execution terminated due to
  error`. Everywhere else in this document a bad hook fails open and silently; **on agy's injection path
  it fails closed and takes the developer's turn with it**, which is a direct violation of the
  fail-open principle and must be handled by the layer, not by the hook author.

**The method note, since this is the second time it has bitten in one session.** Both wrong negatives
here came from testing the event names one host uses against a host that names them differently. A
positive control proves the *mechanism* is reachable; it says nothing about whether the *name* you
chose is the one that host uses. Enumerate the host's own event names from its own artifact first —
which is exactly what was done for codex and cursor, and skipped for agy.

### agy documents all of this itself, in a file shipped with the CLI

**Found by asking agy to inventory its own hook surface, not by searching for it.** The file is
`~/.gemini/antigravity-cli/builtin/skills/agy-customizations/docs/hooks.md`, 10,421 bytes, and it
carries the complete contract: five events (`PreToolUse`, `PostToolUse`, `PreInvocation`,
`PostInvocation`, `Stop`), the config search order, the input payload per event, and the output contract
per event. Every probe above would have been shorter if it had been read first.

Three things in it that the probes did not reach, and one that reframes a probe result:

- **`PostInvocation` carries `terminationBehavior`** — `"force_continue"` forces the execution loop to
  continue, `"terminate"` forces it to stop. A second control point the matrix does not have a column for.
- **Config discovery walks `.agents/` from the working directory up to the repository root**, with
  `~/.gemini/config/` as the global layer. That is why the earlier probe found the file only once the
  directory was a git root — the walk needs a root to terminate at, and `--add-dir` was incidental.
- **`Stop`'s `decision: "continue"` is documented as "block the stop and re-enter the loop"**, with any
  other value allowing the stop and `reason` injected as a system message when continuing. **So the
  168-turn runaway recorded above is the documented contract working exactly as specified, not a bug** —
  the mistake was mine, reading `continue` with Claude Code's sense of the word. It remains a hazard for
  anyone carrying that assumption across, which is the reason to keep it written down.

And the line that matters most to any design built on this:

> *Hooks run synchronously and block the agent loop (no async execution).*

**On agy a reviewer hook is on the critical path by construction.** There is no detached form. Any design
whose first principle is *nothing waits on the reviewer* cannot put judgement inside an agy hook at all —
the hook may only read a verdict that is already sitting in a file, and must be fast enough to be
invisible. The same document also states plainly that only `type: "command"` is supported, *"no HTTP or
prompt hooks yet"*, which independently confirms the two live refusals recorded above.

### codex documents itself too — ten events, and a version trap

**Produced by asking codex to inventory its own hook surface.** It worked from the release source matching
its installed build (`rust-v0.144.4`), explicitly declining `main` because unreleased schema fields would
not apply, and it proved one event live rather than claiming all ten.

**Read the version line first.** It probed `codex-cli 0.144.4` — the build on `PATH` — while every live
probe elsewhere in this document ran against `0.147.0-alpha.6.5` under `%LOCALAPPDATA%\OpenAI\Codex\bin\`.
**Two builds, one machine**, so nothing below transfers to the newer one without checking.

**Ten events**, from `codex-rs/config/src/hook_config.rs`: `PreToolUse`, `PermissionRequest`,
`PostToolUse`, `PreCompact`, `PostCompact`, `SessionStart`, `UserPromptSubmit`, `SubagentStart`,
`SubagentStop`, `Stop`. **`SessionEnd` is not among them in this release although current online
documentation lists it** — a concrete instance of the version trap, found because the worker pinned its
source to its own build.

All ten dispatch from shared core paths rather than TUI-only code, so all ten are reachable headless.
**Only `SessionStart` was live-proven** — configured, fired, marker read back verbatim — and the worker
said so rather than generalising, which is the distinction this document keeps needing.

**The output contract, which is richer than the probes reached:**

- **Common to all:** `continue`, `stopReason`, `systemMessage`, `suppressOutput` (parsed, unsupported).
- **`SessionStart` / `SubagentStart` / `UserPromptSubmit`** inject via
  `hookSpecificOutput.additionalContext` — **and plain stdout also injects context**, which is a simpler
  path than the structured form used in the probe above.
- **`PreToolUse`** carries `permissionDecision` (`deny` / `allow`) plus **`updatedInput`, which rewrites
  the tool call** rather than merely denying it. Legacy `{decision:"block",reason}` and exit `2` with
  stderr also deny.
- **`PostToolUse`'s `{decision:"block",reason}` replaces the completed tool result with the hook's
  feedback.** That is a stronger mid-turn mechanism than `additionalContext` — the model reads the
  objection *as the tool's output*, in the place it is already looking.
- **`Stop` / `SubagentStop`:** `{decision:"block",reason}` requests another continuation; exit `2` with
  stderr is equivalent.

**Input payloads** always carry `session_id`, `transcript_path`, `cwd`, `hook_event_name`, `model`, plus
per-event fields. **`SubagentStop` carries `agent_transcript_path`** — the child's own transcript, which
is the seam a worker-side reviewer needs.

**Q9 answered for codex**, and it is a list rather than a single switch: `[features] hooks=false` (alias
`codex_hooks=false`); an admin `requirements.toml` that can force hooks off or set
`allow_managed_hooks_only=true`; project layers being untrusted, with unreviewed handlers skipped unless
`--dangerously-bypass-hook-trust`; `hooks.state.<key>.enabled=false` per handler; and `--ignore-user-config`.

**One claim in this document is contested by that answer, and the isolation test says both are right.**
The worker searched for `CODEX_.*HOOK` and `hook.*sandbox` and reports **no hook-disabling environment
variable and no sandbox-policy gate** in `0.144.4` source. The first addendum here states the opposite
from measurement — but that probe varied sandbox and trust together, so the mechanism was attributed
rather than isolated.

Isolated afterwards on `0.147.0-alpha.6.5`, one condition changed: `codex exec
--dangerously-bypass-hook-trust --skip-git-repo-check` with **no sandbox flag**. The turn ran, `echo hi`
executed, the agent answered `DONE` — and **the `PostToolUse` hook did not fire.** With the sandbox
bypass added and nothing else changed, the same hook fires twice.

So the observation stands on the newer build and the source claim stands on the older one. **What is
still unresolved is the mechanism** — it may be a change between the two releases, or a gate the source
search did not match because it is not spelled with the word *sandbox*. Recorded as version-scoped rather
than explained.

### cursor documents itself too — twenty-one events, and a third way to die silently

**Produced by asking cursor-agent to inventory its own hook surface**, reading its own bundle at
`versions/2026.08.11-e8db854/`. It proved two events live and marked the rest by grade.

**Twenty-one event names**, from the `_E` map in `index.js`: `beforeShellExecution`,
`beforeMCPExecution`, `afterShellExecution`, `afterMCPExecution`, `beforeReadFile`, `afterFileEdit`,
`beforeTabFileRead`, `afterTabFileEdit`, `stop`, `beforeSubmitPrompt`, `afterAgentResponse`,
`afterAgentThought`, `sessionStart`, `sessionEnd`, `preCompact`, `subagentStart`, `subagentStop`,
`preToolUse`, `postToolUse`, `postToolUseFailure`, `workspaceOpen`. The probes above found eight.

**`sessionStart` fires headless — proven live**, which the probes never tested. So cursor has a
session-level hook in `-p` even though `stop` does not fire there, and that is a place to seed state at
the start of a run.

**The entry schema is larger than the probes used:** `command`, `type`, `timeout`, `matcher`,
`failClosed`, `loop_limit`. `version` is a required positive integer. Config order is enterprise → team →
user → project, plus the Claude-compat sources.

**`type: "prompt"` is conditional** — implemented only when a `promptHookClient` exists; otherwise the
entry is simply not queued. That is worth knowing before relying on the native evaluator, because its
absence looks like a hook that did nothing.

**Two file-level invalidation rules, both silent**, which explain and extend the finding above: an
unknown `type` produces `Invalid hook type: "…"`, and an unknown **event key** produces `Unknown hook
type: …` — and either **fails the whole file for that source**, while other sources still load.

**And a third silent-death mechanism, found by the worker's own failed first attempt:** a `hooks.json`
written with a **UTF-8 BOM** loads as nothing — *"agent OK, no hook file, no CLI diagnostic"*. Rewritten
without the BOM, the same config loaded. **This is the default output of Windows PowerShell's
`Set-Content -Encoding utf8`**, so it is a mistake anyone scripting hook installation on Windows will
make, and it produces no signal anywhere. Filed with the other two on `#212`.

**Q9 for cursor:** no dedicated kill switch found. `enableTeamHooks` and `enableWorkspaceOpenHook` gate
their own scopes; a team **headless policy of `disabled` blocks `-p` entirely** rather than hooks alone;
a symlinked config path is refused. Whether untrusted workspace fully kills hooks is `UNKNOWN` — they ran
under `--trust`.

**Output contract**, per-event validators in `index.js`: gate events take
`permission: allow|deny|ask` with `user_message` / `agent_message`; `beforeSubmitPrompt` and
`sessionStart` take `continue: false`; **exit code 2 is treated as a block on every event**;
`additional_context` and `agent_message` are the mid-turn text paths; `stop` and `subagentStop` take
`followup_message`; `failClosed: true` makes a hook failure block. Command hooks receive
`CURSOR_PROJECT_DIR`, `CURSOR_VERSION`, `CURSOR_TRANSCRIPT_PATH` and `CLAUDE_PROJECT_DIR` in their
environment.

### The agy schema, read properly — and the third wrong negative it retires

`hooks.md` gives a file format none of the probes above used. **The top-level key is a hook *name*, not
the literal string `hooks`:**

```json
{ "lint-checker": {
    "enabled": true,
    "PostToolUse": [ { "matcher": "run_command", "hooks": [ { "type": "command", "command": "…" } ] } ] },
  "reminder": {
    "PreInvocation": [ { "type": "command", "command": "…" } ] } }
```

Every probe here wrote `{"hooks": {...}}`, which worked **by accident** — `hooks` was read as a hook
name. That is also what `loaded 1 named hooks from 1 hooks.json file(s)` was reporting all along: one
name, one file, regardless of how many events were under it.

**And the structure differs per event, which is what actually broke the tool-event probes.** From the
document's own table:

| Event | Structure |
|---|---|
| `PreToolUse`, `PostToolUse` | **grouped** — a `matcher` regex wrapping a `hooks` array |
| `PreInvocation`, `PostInvocation`, `Stop` | **flat** — handler objects directly in the array |

Every attempt above gave the tool events a **flat** list, and the one that added `matcher` added it as a
sibling of `command` rather than as the wrapper. Rewritten to the documented grouped form, one run:

```
2x  PreToolUse-GROUPED      2x  PostToolUse-GROUPED
3x  CONTROL-PreInvocation-FLAT      1x  CONTROL-Stop-FLAT
```

**So agy fires all four, and the "`PreToolUse`/`PostToolUse` never fire" finding above is retired.** agy
has a pre-action gate like the other three.

**This is the third negative about agy in this document that was mine and not the host's**, and all three
have the same shape: the mechanism was reachable and the name or structure was not the one that host
uses. Wrong event names, then a wrong step-variant name, now a wrong per-event structure. **The
positive-control rule catches a probe that could not have worked; it does not catch a probe that is
testing the wrong spelling of a real thing.** Only the host's own document does that — and on agy it was
sitting on disk the whole time.

It also adds a silent-death path to agy's column, which had read *none*: **a flat handler list on a tool
event is dropped with no diagnostic at all.** The counter still reports the file as loaded.

### Claude Code inventoried against its own binary — 31 events, of which 9 are documented

**Done here rather than delegated, on the same principle: the host reads its own artifact, and this
host is the one running.** Source is `~/.local/bin/claude.exe` (266 MB) — its bundled plugin
documentation is embedded as UTF-16, and the event names appear as `hook_event_name` values in ASCII.

**Its own documentation lists nine** for plugin `hooks/hooks.json`: `PreToolUse`, `PostToolUse`, `Stop`,
`SubagentStop`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `PreCompact`, `Notification`.

**The binary carries thirty-one.** Beyond the nine: `PostToolBatch`, `PostToolUseFailure`, `StopFailure`,
`PermissionRequest`, `PermissionDenied`, `SubagentStart`, `PostCompact`, `InstructionsLoaded`,
`UserPromptExpansion`, `TaskCreated`, `TaskCompleted`, `TeammateIdle`, `Elicitation`,
`ElicitationResult`, `MessageDisplay`, `ConfigChange`, `CwdChanged`, `DirectoryAdded`, `FileChanged`,
`Setup`, `WorktreeCreate`, `WorktreeRemove`.

**The undocumented ones are configurable, not internal.** One run, one settings file, with a documented
`PostToolUse` as the control:

```
1x  CONTROL-PostToolUse      1x  TEST-PostToolBatch      1x  TEST-InstructionsLoaded
```

`SubagentStart` and `TaskCompleted` did not fire — **untested rather than negative**, since the run
spawned no subagent and created no task.

**Two of these matter directly to the compliance design:**

- **`InstructionsLoaded`** fires when instructions are loaded. `#184` exists to read the transcript for
  which skills were invoked; this is an event that fires at the moment it happens, which is a stronger
  seam than reconstructing it afterwards. Worth probing before that slice is built.
- **`PostToolBatch`** is a batch-level counterpart to `PostToolUse`. The mid-turn delivery design costs
  one hook invocation *per tool call*; if this fires once per batch it is the cheaper anchor for the same
  job. Semantics not yet established — it fired once against a single tool call, which does not
  distinguish the two.

**A constraint that changes the reviewer's shape**, from the same embedded documentation:

> **Prompt-based** … Supported events: `Stop`, `SubagentStop`, `UserPromptSubmit`, `PreToolUse`.

`PostToolUse` is not on that list. **Tested rather than inherited, because this same document
under-reports events by 22 — and the answer is more specific than either "supported" or "not".**

A `type: "prompt"` hook on `PostToolUse`, with a `command` hook beside it as the control:

| Prompt hook returns | Control | Haiku in `modelUsage` | `terminal_reason` | `result` |
|---|---|---|---|---|
| `ok:false` | fired | **yes** — 637 in / 35 out | `hook_stopped` | empty |
| `ok:true` | fired | **yes** — 646 in / 90 out | `hook_stopped` | empty |

**The hook executes on `PostToolUse` — and the turn dies either way.** `ok:true` stops it exactly as
`ok:false` does. So the event is not rejected, it is simply not wired to a continuation, and attaching a
prompt hook there costs a real evaluator call and then destroys the turn.

**The documentation's list is therefore correct about usability and wrong about mechanism**, and both
halves matter: an implementer reading only the doc would not know the call is still billed, and an
implementer reading only the probe would conclude it works.

**The same run settles `#205` at live grade.** `modelUsage` names the evaluator outright:

```
claude-opus-5[1m]              in 2      out 153   costUSD 0.2392515
claude-haiku-4-5-20251001      in 637    out 35    costUSD 0.000812
```

**The native evaluator is Haiku 4.5, and one judgement costs about three tenths of one percent of the
main model's turn.** `#205` asks which model the reviewer calls and how a hook reaches it; on Claude Code
the answer is that the harness makes the call itself, on Haiku, and `modelUsage` is a receipt that it
happened. That receipt is also the cleanest liveness detector available for `#212` — **if a prompt hook
ran, a second model appears in the usage breakdown.**

**Q9 for Claude Code: `disableAllHooks`**, a settings key present 25 times in the binary. No
`CLAUDE_CODE_DISABLE_HOOKS` environment variable and no `--no-hooks` flag were found.

### "Is your own documentation a limit or a subset?" — asked of all four, answered three different ways

The question was put to each host after Claude Code's documentation turned out to under-report its events
by 22. **The answers do not generalise, which is itself the result.**

| Host | Verdict | Evidence |
|---|---|---|
| **Claude Code** | **subset** — 9 documented, 31 in the binary, undocumented ones configurable and firing | **[L]** control + two undocumented events fired |
| **agy** | **subset** — 5 documented, `SessionStart` fires and is not among them | **[L]** fired; **[D]** for anything further, it cannot grep its own binary |
| **codex** | **accurate** — ten is the whole configurable surface | **[B]** exhaustive `HookEventName` enum at `protocol.rs:1483`; **[L]** an unknown key produced no marker while its sibling control did |
| **cursor** | **larger than any doc** — 21 names read straight from the bundle's own map | **[B]** |

**codex is the one that checked out, and it checked out for a reason worth copying:** its event list is an
exhaustive Rust enum, so the documentation is generated from a closed set rather than curated from an open
one. Its worker also ruled out the false positives by hand — `HookStarted` / `HookCompleted` are
app-server notifications, and the `SessionEnd` string in the binary belongs to
`flushTranscriptTailOnSessionEnd`, a realtime transcript setting, not a hook.

**Two behaviours separate codex from cursor in a way that matters to a config generator:**

- **An unsupported handler type on codex skips only that handler**, with an exact diagnostic naming the
  file — `skipping prompt hook in …: prompt hooks are not supported yet` — and the sibling `command`
  hook still fires. **On cursor the same mistake voids the entire file, silently.**
- **But an unknown *event key* on codex is silently ignored**, because `HookEventsToml` has no
  `deny_unknown_fields`, and **`--strict-config` does not catch it either.** So codex is the strictest
  host about handler types and among the loosest about event names.

**And a flag trap worth recording:** `--ignore-user-config` removed the *project* hook layer as well as
the user layer in that probe, which cost the worker a run it correctly declined to draw conclusions from.

### What asking each CLI about itself actually bought

Three self-probes, one per host, each told to read its own artifact and prove one claim by side effect.
Set against a day of external probing, they produced:

- **agy's own 10.4 KB hook contract**, which no external search found, plus the two corrections above
- **codex's ten event names pinned to its installed release**, and `SessionEnd` documented online but
  absent from that build
- **cursor's twenty-one event names against the eight found externally**, `sessionStart` proven headless,
  and the BOM failure

**The pattern is one thing, and it is the same failure the positive-control rule addresses one level
up.** Every external probe tested names and shapes carried from another vendor. Each host, asked about
itself, answered from its own vocabulary — which is the only place that vocabulary exists.

Two costs worth stating rather than burying. The codex worker ran **797 seconds** and returned a result
whose transport blob was **59,685 characters**, of which 9,026 was the answer; cursor ran **904 seconds**.
And **agy cannot run shell commands through this transport at all** — its first attempt was auto-denied
headless, and it only succeeded once the prompt forbade commands outright and told it to read files. Its
answer was still the most valuable of the three.

### What a software layer has to supply, per client

### What a software layer has to supply, per client

Follows directly from the matrix; recorded here so the design does not have to re-derive it.

| Client | What the layer supplies | The constraint that shapes it |
|---|---|---|
| **codex** | **the model, and nothing else** | Block, mid-turn delivery and a rich payload (`tool_response`, `transcript_path`, `turn_id`, `tool_use_id`) are all native. Thinnest integration of the four. |
| **cursor** | **nothing — but the design must move** | It has the evaluator *and* mid-turn delivery in one mechanism, and no turn-end callback. The reviewer belongs at the pre-action gate. Capture evidence **at the hook**, since `afterShellExecution` hands over the command's `output` that the transcript omits. Cross-segment state can key off the `turn_ended` record, which the transcript carries even though the `stop` hook does not fire. |
| **agy** | **the model only** | Mid-turn delivery is native after all — `PreInvocation` + `inject_steps`, snake_case — so no stdin injection and no process-wrapper channel is needed. Two hard constraints instead: a blocking `Stop` must carry its own release condition (`{"decision":"continue"}` loops to timeout with no limit), and **a malformed injection terminates the turn**, so the layer must validate its own payload before emitting it. |
| **all four** | **a liveness self-check, first** | On two of four hosts a plausible config edit — one mistyped model name — disables the layer with no signal anywhere. Tracked as `#212`. |

**Claude Code is the only host with all four**, and until this probe none of its four had been verified
here — Q5 and Q6 in particular were carried on vendor documentation while the design leaned on them.

**Q6 matters more than its row suggests.** `#208` frames the reviewer as needing three things no single
hook type has — a model, a file read, a file write. A `type: "agent"` hook has the first two: it read
`rule.txt` from disk, judged the transcript against it, and blocked. That removes the need to inline the
rule census into a prompt, which is the constraint that issue is blocked on.

**Two negatives that are genuinely negative**, because a control fired in the same run:

- **cursor** — `beforeShellExecution` fired while `stop` and `beforeSubmitPrompt` did not.
- **agy** — the `Stop` control fired while `PreToolUse` and `PostToolUse` did not, **with and without a
  `matcher`**, across a file read *and* a shell command whose output could not be fabricated
  (`(Get-Date).Ticks`).

### Q6 and Q7 closed on cursor and agy

**Q6 — a tool-using hook type exists on neither.**

- **agy** says so itself, naming the file: `failed to parse hooks.json at …\.agents\hooks.json: unsupported hook type: "agent"`.
- **cursor** does not say so, and the way it fails is the finding. A config with a `command` entry *and* an `{"type":"agent"}` entry on the same event ran **neither**; removing the `agent` entry and changing nothing else brought the `command` hook back. **An unrecognised entry voids every hook in the file, silently.** Filed as its own issue with the liveness self-check.

**Q7 — both hosts hand a hook the transcript path, and the payloads are richer than expected.**

cursor, `afterShellExecution`:

```json
{"conversation_id":"…","model":"grok-4.5","command":"echo PAYLOAD_PROBE",
 "output":"PAYLOAD_PROBE\r\n","duration":5788.364,"sandbox":false,
 "hook_event_name":"afterShellExecution","cursor_version":"2026.08.11-e8db854",
 "workspace_roots":["…"],"user_email":"…",
 "transcript_path":"C:\\Users\\…\\agent-transcripts\\<id>\\<id>.jsonl"}
```

agy, `Stop`:

```json
{"artifactDirectoryPath":"…/brain/<id>","conversationId":"<id>",
 "modelName":"gemini-3.7-flash-high","terminationReason":"NO_TOOL_CALL",
 "fullyIdle":true,"executionNum":0,
 "transcriptPath":"…/brain/<id>/.system_generated/logs/transcript_full.jsonl",
 "workspacePaths":["…"]}
```

**The "cursor omits tool outputs" claim holds — and its consequence inverts.** Reading the transcript that payload names: four records, containing the user query, an assistant `tool_use` with the command, the assistant's final text, and `{"type":"turn_ended","status":"success"}`. **There is no `tool_result` record.** So a history-only reviewer on cursor cannot see what a command returned.

But **the hook payload carries `output` directly**, so the evidence is not missing — it is only missing *from the transcript*. The design consequence is therefore not a PAL sidecar to reconstruct it, but **capture at the hook**, where it is already handed over for free.

One more thing that transcript shows: cursor writes a `turn_ended` record **even though the `stop` hook never fires headless**. The turn boundary exists in the file; only the callback is absent.

### A new silent-failure path, on Claude Code's prompt hook

Two runs differing **only** in the hook's `model` field:

| `model` | Result |
|---|---|
| absent | the prompt hook evaluated, blocked, and the agent obeyed |
| `"definitely-not-a-real-model-xyz"` | **nothing** — no block, no error, no diagnostic; the turn ended normally and the command control fired once instead of twice |

So the field is read and routes the call — and **a prompt hook whose model is wrong is indistinguishable
from no hook at all.** That is `#207`'s defect class on a new path, and it is worse here than for a
command hook, because a typo in a model name is a plausible edit that leaves the reviewer silently
disabled while the configuration still looks correct.

**cursor behaves identically, which answers Q8 for it.** The same probe — a `prompt` hook carrying
`"model": "definitely-not-a-real-model-xyz"` beside a `command` hook on `beforeShellExecution` — left
the command hook firing and the prompt hook dead, with the command allowed and no diagnostic. So the
`model` field is read on cursor too, and the same silent-death applies. **Two independent vendors, the
same failure, on the field most likely to be edited.** Filed as `#212`.

### Windows quoting, a third form

Each host mangles it differently, and each cost a probe:

- **codex** — `commandWindows` required, backslashes eaten; quote the interpreter path
- **agy** — splits the command itself and **rejects a quoted path**: `'\"C:\…\mark.cmd\"' is not recognized as an internal or external command`. Pass the path bare.
- **cursor** — no problem observed with either form

Plus one flag trap: agy's `--dangerously-skip-permissions` is a Go bool flag, and written bare before the
prompt it **swallows the prompt** — the agent then answers a question about the flag itself, and any
tool-event hook has nothing to fire on. It must be `--dangerously-skip-permissions=true`.

### Corrections owed to the summary table at the top of this file

The table is the delegated research's output and is left as written, so its provenance stays legible. Two of its cells are now known to be wrong for headless use, and this addendum is the correction layer:

- **Cursor, "3. Stop / redirect: yes — followup loop"** — the `stop` event did not fire under `-p`; what works there is the pre-action gate.
- **Cursor, columns 4 and 5** — right in substance, but they were documentation-grade and are now live-grade.
- **Antigravity, "9. Global gate: UNKNOWN"** — still unknown, but discovery is now observable through the log counter, so it is measurable rather than opaque.

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

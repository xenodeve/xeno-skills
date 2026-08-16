# Claude Code CLI — Tools Reference

**Research date:** 2026-08-14  
**Scope:** Claude Code terminal CLI built-in tools, what each tool does, when it is available, and important limitations.  
**Primary source class:** Anthropic official Claude Code documentation.

## Evidence notation

- **[DOC]** — explicitly documented by Anthropic.
- **[COND]** — documented, but availability depends on version, platform, provider, plan, settings, or session state.
- **[EXT]** — extension surface rather than a fixed built-in tool.

Anthropic currently describes its Tools reference as the **complete reference** for built-in Claude Code tools, and says the names below are the exact strings used by permission rules, subagent tool lists, and hook matchers. The exact set loaded in a running session can still vary by provider, platform, settings, plan, and session state.

---

## 1. Core file, search, and execution tools

| Tool | What it does | Permission / availability | Important limitations |
|---|---|---|---|
| `Read` | Reads file contents. | [DOC] No prompt for files inside allowed working directories; paths outside them can require permission. | Subject to path permissions. A partial read may not satisfy edit eligibility where read-before-edit rules apply. |
| `Write` | Creates or overwrites files. | [DOC] Permission normally required. | Subject to Edit/Write path permission rules and Read-deny interaction. |
| `Edit` | Performs targeted file edits. | [DOC] Permission normally required. | Exact-string replacement, not regex/fuzzy matching. Match must be sufficiently unambiguous. Read-before-edit rules can apply. |
| `Glob` | Finds files using path/pattern matching. | [DOC] No prompt inside allowed directories. | Subject to Read-style path restrictions. |
| `Grep` | Searches file contents for patterns. | [DOC] No prompt inside allowed directories. | Subject to Read-style path restrictions. |
| `Bash` | Executes shell commands. | [DOC] Normally permissioned, although a built-in set of read-only commands can run without prompting. | Each call is a separate process. Environment variables exported in one call do not persist. See detailed limits below. |
| `PowerShell` | Executes PowerShell natively. | [COND] Permission required; availability depends on platform/settings. | Preview has platform limitations; Windows sandboxing is not supported for the PowerShell preview. Profiles are not loaded. |
| `NotebookEdit` | Modifies Jupyter notebook cells. | [DOC] Permission required. | Notebook-specific editing surface; subject to file access permissions. |
| `LSP` | Language-server code intelligence: definitions, references, type info, symbols, implementations, call hierarchy, diagnostics. | [COND] No per-call permission normally. | Inactive until a suitable code-intelligence plugin and language-server binary are installed. |

### `Bash` behavior and limits

- Each tool call runs in a **separate process**.
- Main-session `cd` can carry forward only while the resulting directory remains inside the project or an explicitly added directory. Subagent working-directory changes do **not** persist across calls.
- Shell environment variables exported by one command do not persist to later calls.
- Default command timeout is controlled by `BASH_DEFAULT_TIMEOUT_MS` (two minutes out of the box); the normal maximum ceiling is controlled by `BASH_MAX_TIMEOUT_MS` (ten minutes out of the box).
- Command output is streamed to a working file. Output exceeding 5 GB causes the command to be killed.
- Inline output is bounded; large successful output is represented by a saved file path plus preview, while large failures return a bounded excerpt.
- Background commands are supported. In non-interactive `-p` mode, background tasks end shortly after the run's final result.

### `Edit` behavior and limits

- Uses exact `old_string` → `new_string` replacement, not fuzzy matching.
- The old text must match current file content exactly and sufficiently uniquely unless `replace_all` is used.
- Claude Code applies read-before-edit checks depending on model/version and whether reading would require permission.
- Read/Edit deny rules cover recognized file operations, but **do not provide OS-level containment for arbitrary subprocesses** such as Python/Node programs opening files themselves. Use sandboxing for process-level enforcement.

---

## 2. Planning, worktree, and conversation-control tools

| Tool | What it does | Availability / limitations |
|---|---|---|
| `EnterPlanMode` | Switches the agent into planning mode before implementation. | [DOC] Built-in. |
| `ExitPlanMode` | Presents a plan for approval and leaves plan mode. | [DOC] Approval is required. |
| `EnterWorktree` | Creates or enters an isolated Git worktree and moves the session working directory there. | [COND] Paths outside `.claude/worktrees/` can prompt. Nested-repository behavior is version-sensitive. Subagents pinned to their own worktree have tighter path rules. |
| `ExitWorktree` | Leaves a worktree session and returns to the original directory. | [COND] Not available to subagents already running in their own pinned working directory. |
| `EndConversation` | Ends the current session in narrowly defined situations. | [COND] Requires Claude Code v2.1.213+. Intended only for sustained abusive interaction after warning, or an explicit demonstration request. `PreToolUse` does not run for it. |

---

## 3. User interaction and structured-result tools

| Tool | What it does | Important limitations |
|---|---|---|
| `AskUserQuestion` | Asks one or more multiple-choice clarification/decision questions. | Questions normally wait indefinitely. Optional auto-continue timeout can be configured to 60s, 5m, or 10m; permission prompts do not auto-resolve this way. |
| `ReportFindings` | Emits structured code-review findings with file, summary, and failure scenario. | [COND] Requires Claude Code v2.1.196+. Newer versions can attach a finding category. It appears when active review instructions call for it. |
| `Artifact` | Publishes an HTML/Markdown artifact to a private interactive page on claude.ai. | [COND] Requires supported Claude subscription and `/login`; organization/public sharing rules apply. |
| `SendUserFile` | Delivers a generated file to the user/device, optionally rendered inline or attached. | [COND] Requires Remote Control or a managed cloud environment; unavailable on several third-party provider paths. |
| `ShareOnboardingGuide` | Uploads `ONBOARDING.md` and returns a teammate share link. | [COND] Subscription availability restrictions apply. |
| `PushNotification` | Sends desktop and, where connected, phone notifications. | [COND] Uses Anthropic-hosted delivery and is unavailable through some third-party providers. |

---

## 4. Subagent and multi-agent tools

| Tool | What it does | Important limitations |
|---|---|---|
| `Agent` | Spawns a subagent with a separate context window to perform a task. | Parent receives the subagent's final result, not its intermediate tool calls/outputs. Subagent tool access is restricted by its `tools` / `disallowedTools` configuration and global permissions. |
| `ListAgents` | Lists agents addressable by `SendMessage`, including session subagents and eligible other Claude Code sessions. | [COND] Requires v2.1.224+ and cross-session messaging enabled. Team teammates are reached via the team roster rather than this list. |
| `SendMessage` | Sends a message to an agent-team teammate, a subagent by ID/name, or eligible other Claude Code sessions. Can resume a completed subagent. | [COND] Cross-session messaging requires v2.1.224+ and relevant feature enablement. A subagent manually stopped from `/tasks` refuses auto-resume. Agent messages never count as user approval. |
| `Workflow` | Runs a dynamic workflow that orchestrates many subagents in the background and returns a consolidated result. | [COND] Dynamic-workflow availability/configuration applies. |

### `Agent` subagent model

- Named subagents use a separate context window and normally return one final text result.
- A forked subagent can inherit the full parent conversation instead of starting fresh.
- `tools` can allowlist a subset; `disallowedTools` removes tools and wins on conflicts.
- Even an allowlisted tool must belong to the subset Claude Code permits inside subagents.
- Background subagents surface permission requests to the main session in current versions.
- Tool calls made inside the subagent are still checked against permission rules.

---

## 5. Task and background-work tools

| Tool | What it does | Important limitations |
|---|---|---|
| `TaskCreate` | Creates a task in the session task list. | Built-in orchestration state. |
| `TaskGet` | Retrieves details of a task. | Requires a task identifier. |
| `TaskList` | Lists tasks and statuses. | Session/task-state dependent. |
| `TaskUpdate` | Updates task status, dependencies/details, or deletes tasks. | Session/task-state dependent. |
| `TaskStop` | Stops a running background task or eligible named/background agent. | Behavior and target coverage have expanded across versions. |
| `TaskOutput` | Retrieves background-task output. | **Deprecated**; Anthropic recommends `Read` on the task output file path. |
| `TodoWrite` | Manages a simpler session task checklist. | Disabled by default in newer interactive releases in favor of Task* tools; availability differs by mode/version. |
| `Monitor` | Runs a command in the background and emits line/WebSocket events back into the conversation. | [COND] Requires supported version/platform rollout; permission required. Useful for logs, watch tasks, CI polling. |

---

## 6. Scheduling tools

| Tool | What it does | Important limitations |
|---|---|---|
| `CronCreate` | Creates a recurring or one-shot prompt in the current session. | Session-scoped; restored by resume/continue only while still valid. |
| `CronDelete` | Cancels a session cron by ID. | Requires an existing scheduled task. |
| `CronList` | Lists scheduled tasks in the session. | Session-scoped. |
| `ScheduleWakeup` | Schedules the next iteration of self-paced `/loop`, or stops it. | Next wake must be 1 minute–1 hour out. Provider availability restrictions apply. |
| `RemoteTrigger` | Creates/updates/runs/lists cloud Routines on claude.ai. | [COND] Subscription and provider restrictions; backs `/schedule`. |

---

## 7. Web and external-resource tools

| Tool | What it does | Important limitations |
|---|---|---|
| `WebSearch` | Searches the public web. | Permission required. Availability/policy depends on provider/session. |
| `WebFetch` | Fetches and parses a specified URL. | Permission required; domain permission patterns are supported. |
| `ListMcpResourcesTool` | Lists resources exposed by connected MCP servers. | Only useful when MCP servers expose resources. |
| `ReadMcpResourceTool` | Reads a specific MCP resource by URI. | Requires a connected resource provider. |
| `WaitForMcpServers` | Waits for MCP servers that are still connecting. | Appears only when tool search is disabled; otherwise `ToolSearch` handles deferred discovery/waiting. |
| `ToolSearch` | Searches for and loads deferred tools on demand. | Appears when tool-search functionality is enabled. Tool availability after search still depends on configured servers/plugins. |

### Extension surface: MCP

MCP servers add **custom tools** beyond this built-in inventory. Those names are server-specific and therefore cannot be exhaustively listed in a Claude Code built-in-tools document. `/mcp` is the authoritative way to inspect exact MCP tool names in a running session.

---

## 8. Skill tool

| Tool | What it does | Important limitations |
|---|---|---|
| `Skill` | Loads/executes a reusable Claude Code skill inside the main conversation. | Permissionable by skill name. A skill does not create a new built-in tool; it runs through this single `Skill` entry. |

---

## 9. Permission and availability model

Claude Code tool names are configuration-facing identifiers. They can be referenced by:

- `permissions.allow` / `permissions.deny`
- `--allowedTools` / `--disallowedTools`
- subagent `tools` / `disallowedTools`
- skill `allowed-tools`
- hook conditions/matchers

Common permission-rule shapes include:

- `Bash(npm run *)` / `Monitor(...)` — command matching
- `PowerShell(Get-ChildItem *)` — PowerShell command matching
- `Read(path/**)` — applies to `Read`, `Grep`, `Glob`, and `LSP`
- `Edit(path/**)` — applies to `Edit`, `Write`, and `NotebookEdit`
- `Skill(name *)`
- `Agent(type)`
- `WebFetch(domain:example.com)`
- `WebSearch` — whole-tool enable/deny

**Important:** permission rules are not a substitute for OS/process isolation. Arbitrary subprocesses can sometimes access resources outside what tool-name/path matching can introspect; sandboxing is the stronger enforcement boundary.

---

## 10. Minimal / restricted CLI modes

`claude --bare -p ...` intentionally starts a minimal environment: auto-discovery of hooks, skills, plugins, MCP, memory, and `CLAUDE.md` is skipped. Anthropic documents this mode as retaining only the core shell/read/edit capability set. Do not infer normal-session tool availability from a bare-mode run.

---

## 11. Completeness statement

For **Claude Code built-ins**, the official Tools reference is explicitly presented as complete. However, a runtime session may expose fewer tools because of platform, provider, plan, version, feature flags, mode, or configuration. It may expose **additional external tools** through MCP/plugins.

If you need a runtime census, inspect the exact running session rather than treating this static document as proof that every listed tool is currently loaded.

---

## Official sources

- Claude Code Tools reference: https://code.claude.com/docs/en/tools-reference
- Claude Code CLI reference: https://code.claude.com/docs/en/cli-usage
- How Claude Code works: https://code.claude.com/docs/en/how-claude-code-works
- Claude Code extensions / MCP / subagents: https://code.claude.com/docs/en/features-overview


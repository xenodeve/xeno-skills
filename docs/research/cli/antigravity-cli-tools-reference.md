# Google Antigravity CLI — Tools Reference

**Research date:** 2026-08-14  
**Scope:** Standard Antigravity CLI tools documented by Google, their arguments/capabilities, subagent behavior, and important limitations.  
**Primary source class:** Google Antigravity official documentation.

## Evidence notation

- **[DOC]** — explicitly documented by Google.
- **[COND]** — documented but dependent on policy, workspace, model, or configuration.
- **[EXT]** — extensible/external surface such as MCP.
- **[NOT-ENUMERATED]** — capability class exists, but the official page does not enumerate every concrete runtime tool name.

Google's Hooks documentation exposes a particularly useful list of **standard tool names** because `PreToolUse` and `PostToolUse` match against those names. This is the closest official wire-name inventory currently published for Antigravity CLI.

---

## 1. File and directory operations

| Tool | What it does | Documented arguments | Important limitations |
|---|---|---|---|
| `view_file` | Reads/views file contents. | `AbsolutePath`, optional `StartLine`, `EndLine`, `IsSkillFile` | Subject to workspace/read permissions and inherited subagent scopes. |
| `write_to_file` | Creates a new file / writes file content. | `TargetFile`, `Overwrite`, `CodeContent`, `Description`, optional artifact metadata | Write permission/sandbox rules apply. `Overwrite` makes destructive behavior explicit. |
| `replace_file_content` | Edits one contiguous region in a file. | `TargetFile`, `Instruction`, `Description`, `AllowMultiple`, `TargetContent`, `ReplacementContent`, `StartLine`, `EndLine`, optional lint-error IDs | Intended for a contiguous edit; exact applicability depends on current file content. |
| `multi_replace_file_content` | Applies multiple non-contiguous edits to the same file. | `TargetFile`, `Instruction`, `Description`, `ReplacementChunks`, optional lint-error/artifact metadata | Still scoped to one target file per tool call. |
| `list_dir` | Lists directory contents. | `DirectoryPath` | Workspace/file-access scope applies. |
| `find_by_name` | Finds files/directories using glob-like patterns and filters. | `SearchDirectory`, `Pattern`, optional `Type`, `Excludes`, `Extensions`, `FullPath`, `MaxDepth` | Search constrained by available filesystem scope. |

---

## 2. Search and research tools

| Tool | What it does | Documented arguments | Important limitations |
|---|---|---|---|
| `grep_search` | Fast text search in selected paths. | `SearchPath`, `Query`, optional regex/case/include/match controls | Local accessible paths only. |
| `search_web` | General web search. | `query`, optional `domain` | Network/provider/policy availability can constrain it. |
| `read_url_content` | Fetches text from a public URL. | `Url` | Public/reachable URLs only; not a generic authenticated-browser session. |

### Browser tooling caveat

The hook docs show that matcher patterns such as `browser_.*` are meaningful, and Antigravity has a built-in **browser subagent** invoked via `/browser`. However, the standard-tool table does **not** enumerate every browser-specific tool identifier. Treat browser-internal tool names as **not exhaustively documented by this page** rather than inventing names.

---

## 3. System and execution tools

| Tool | What it does | Documented arguments | Important limitations |
|---|---|---|---|
| `run_command` | Proposes/executes a Bash command. | `CommandLine`, `Cwd`, `WaitMsBeforeAsync`, optional `RunPersistent`, `RequestedTerminalID` | Command execution policy, sandbox, and approval scope apply. Can transition long work into async/background execution. |
| `manage_task` | Manages background tasks. | `Action` = `list`, `kill`, `status`, `send_input`; optional `TaskId`, `Input` | Only controls tasks known to the Antigravity task runtime. This is distinct from native subagent management. |
| `schedule` | Creates timer/cron-style scheduled prompts. | optional `DurationSeconds`, `CronExpression`, `MaxIterations`; required `Prompt` | Requires a valid duration/cron configuration; scheduling lifecycle is runtime/session dependent. |
| `list_permissions` | Lists current resource access grants. | none | Observation only. |
| `ask_permission` | Requests additional scoped permission. | `Action`, `Target`, `Reason` | User/policy may refuse; cannot be treated as implicit consent. |

---

## 4. Native agent-collaboration tools

| Tool | What it does | Documented arguments | Important limitations |
|---|---|---|---|
| `invoke_subagent` | Spawns one or more specialized subagents. | `Subagents[]` containing `Prompt`, `Role`, `TypeName`, optional `Workspace` | Child starts with isolated conversation context. Workspace mode and inherited permission scope matter. Multiple children can run concurrently. |
| `define_subagent` | Defines a transient/custom subagent. | `name`, `description`, `system_prompt`, optional `enable_mcp_tools`, `enable_write_tools`, `enable_subagent_tools` | Custom configuration must use valid mapped tool names. |
| `send_message` | Sends a message to another agent. | `Recipient`, `Message` | Requires a known recipient/conversation identity. Messaging an idle subagent wakes it. |
| `manage_subagents` | Lists or terminates subagents. | `Action` = `list`, `kill`, `kill_all`; optional `ConversationIds` | Killed agents cannot be resumed; use messaging for an idle agent you may need again. |

### Native subagent model

Official Antigravity documentation establishes the following:

- A subagent starts with **context isolation**: it does not inherit the parent's existing conversation history.
- Workspace modes can include `inherit`, isolated Git-worktree-style `branch`, or shared directory storage `share`.
- Multiple subagents can run concurrently.
- Built-in specialized subagents include:
  - `research` — codebase/file structural research
  - `browser` — browser testing, invoked through `/browser`
  - `self` — clone of the caller's system instructions/toolset
- Custom Markdown agents can declare:
  - `tools`
  - `model`: `inherit`, `flash`, or `pro`
  - `commandExecutionPolicy`: `off`, `auto`, `eager`, `sandbox`
  - `mcpServers`
  - skills/plugins
  - whether they can be primary agents and/or subagents
- Subagents have `Running`, `Idle`, and `Killed` lifecycle states.
- **Idle agents automatically wake when messaged and retain their previous context.**
- Agents can message parents, children, or peers by conversation ID.
- Agents can read one another's conversation transcripts.
- Maximum documented nesting depth is **10**.
- Subagents inherit parent safety boundaries such as terminal-prefix permissions, file scopes, and sandbox settings; permission requests bubble to the primary UI.

### Known custom-agent tool-validation issue

Google documents a known issue where a misspelled or unmapped name in a custom agent's `tools` list can cause the subagent to hang. Use exact documented tool names and validate generated agent definitions.

---

## 5. User interaction and media

| Tool | What it does | Documented arguments | Important limitations |
|---|---|---|---|
| `ask_question` | Asks multiple-choice questions, including multi-select. | `questions[]` with `question`, `options`, `is_multi_select` | Requires user interaction to obtain the answer. |
| `generate_image` | Generates or edits images. | `Prompt`, `ImageName`, optional `ImagePaths` | Model/service availability applies; `ImagePaths` is used when editing/conditioning on existing images. |

---

## 6. MCP and custom agent extensions

Custom subagents can declare `mcpServers`, and transient agents can enable MCP tools. Therefore the standard tool list is **not the total runtime tool universe**. MCP servers may add arbitrary server-specific tools.

This document lists Google's standard Antigravity tool names; externally supplied MCP tools require a runtime census of the actual configured session.

---

## 7. Tool-hook relationship

Antigravity's `PreToolUse` / `PostToolUse` hook matchers use tool-name regexes. Examples from the official docs include:

- `run_command`
- `run_command|view_file`
- `browser_.*`
- `*` / empty string for all tools

This makes the documented standard-tool table useful not only as an agent feature list, but as a policy-enforcement vocabulary.

Hook handler type is currently documented as **command-only** and the default handler timeout is **30 seconds**. The synchronous hook runtime should therefore be treated separately from potentially long-running agent/tool work.

---

## 8. Important limitations and non-obvious boundaries

1. **Exact standard names matter.** Custom agent `tools` lists and hook matchers are name-sensitive.
2. **File/tool access is inherited and policy-bound.** A child agent does not get to exceed the parent safety scope simply because its Markdown file names a tool.
3. **Subagent context isolation is deliberate.** A fresh child does not automatically know the parent's full chat history; the delegation prompt must carry necessary context.
4. **Idle is not dead.** Idle native agents preserve context and can be reawakened by messages; killed agents cannot.
5. **Background task management and subagent management are different surfaces.** `manage_task` controls background tasks; `manage_subagents` controls agents.
6. **The standard tool table is not proof of all browser/MCP-specific runtime names.** Browser patterns and extension tools can exist outside the enumerated list.
7. **Availability remains configuration-dependent.** Sandbox, permission settings, workspace trust/configuration, model tier, and installed MCP/plugin content affect what actually succeeds.

---

## 9. Completeness statement

The Hooks documentation gives a strong **official inventory of standard Antigravity tool names** used by hook matchers. It should not be read as a promise that every possible runtime tool from browser internals, MCP servers, plugins, or future feature rollouts appears in that static table.

For a production capability registry, combine this static standard list with a runtime tool census for the exact CLI version/configuration being launched.

---

## Official sources

- Antigravity Hooks / Supported Tools: https://antigravity.google/docs/hooks
- Antigravity Subagents: https://antigravity.google/docs/subagents
- Antigravity CLI background tasks & subagents: https://antigravity.google/docs/cli/subagents
- Antigravity `/agents` command: https://antigravity.google/docs/cli/commands/agents


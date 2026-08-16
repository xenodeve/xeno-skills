# OpenAI Codex CLI — Tools Reference

**Research date:** 2026-08-14  
**Scope:** Codex CLI model-visible tool families, current official-source tool registry, multi-agent V1/V2 tools, dynamic extension tools, and feature/configuration constraints.  
**Primary source class:** OpenAI Codex official documentation plus the official `openai/codex` source tree.

## Evidence notation

- **[DOC]** — documented on official OpenAI Codex documentation.
- **[SRC]** — registered/defined in the current official `openai/codex` source tree.
- **[GATED]** — source-visible, but only exposed under a feature/config/model/environment condition.
- **[EXT]** — externally/dynamically supplied (MCP, extension, plugin, hosted tool).
- **[RUNTIME]** — exact availability must be checked in the launched build/session.

## Critical distinction: source registry != every running session

Codex has a **tool registry/router** that builds the model-visible set per turn. The current source explicitly applies exposure modes such as direct, deferred, code-mode-only, hidden, provider-hosted, extension-provided, and feature-gated. Therefore a tool being present in `main` source is not proof that it is visible in a specific released binary, model, account, or session.

This document is an authoritative **source-capability inventory**, not a claim that every row appears simultaneously.

---

## 1. Shell and process execution

| Tool / family | What it does | Exposure conditions / limitations |
|---|---|---|
| `exec_command` | Unified command execution through the selected environment, with session/PTY support. | [SRC][GATED] Used when the selected model/features choose Unified Exec. Permission/sandbox policy applies. Can expose environment IDs when multiple environments exist. |
| `write_stdin` | Sends input to or polls an existing unified-exec session. | [SRC][GATED] Registered alongside `exec_command`. Requires a live session/process context. |
| `shell_command` | Legacy/local shell-command interface. | [SRC][GATED] Registered when the selected shell tool type is compatible and a local environment exists. May remain registered but hidden when Unified Exec is model-visible. |

### Shell constraints

- Tool selection depends on model metadata, feature flags, and selected execution environment.
- Additional permissions/network/file access can be constrained by the sandbox/approval policy.
- Codex supports a permission-request path rather than treating command execution as unrestricted host access.
- A model/session may see one shell interface while another remains hidden for compatibility.

---

## 2. File mutation and image inspection

| Tool | What it does | Exposure conditions / limitations |
|---|---|---|
| `apply_patch` | Freeform grammar-based file patching/editing. | [SRC][GATED] Registered only when an execution environment exists and model metadata says an apply-patch tool type is supported. Input is a freeform patch, not JSON. |
| `view_image` | Reads/views a local image for model inspection. | [SRC][GATED] Requires `ViewImage` feature and compatible model/image budget. Multiple environments may require an environment ID. |

### `apply_patch` format

Current source defines `apply_patch` as a **freeform tool** backed by a Lark grammar. The agent should send patch text directly rather than wrapping it in JSON. This distinction matters for interceptors and prompt/tool-schema validators.

---

## 3. Plan and user-interaction utilities

| Tool | What it does | Exposure conditions / limitations |
|---|---|---|
| `update_plan` | Updates the agent's structured plan/progress. | [SRC][GATED] Added when `update_plan_enabled` is true. Plan semantics normally permit at most one active/in-progress item at a time. |
| `request_user_input` | Requests structured input/choices from the user. | [SRC][GATED] Added when the experimental user-input capability is enabled; available modes depend on features/session. |
| `request_permissions` | Requests additional network/filesystem permission for the turn/environment. | [SRC][GATED] Requires an execution environment and `RequestPermissionsTool` feature. Policy can refuse requests. |
| `wait_for_environment` | Waits for deferred/starting execution environments to become ready. | [SRC][GATED] Added with the Deferred Executor feature. It can block other tool work while waiting. |

---

## 4. Context-budget and time utilities

| Tool | What it does | Exposure conditions / limitations |
|---|---|---|
| `new_context` | Starts a new context window while preserving environment/session state. | [SRC][GATED] Added under token-budget capability and exposed direct-model-only. This is not a full environment reset. |
| `get_context_remaining` | Reports remaining model context/token budget. | [SRC][GATED] Added with token-budget capability. |
| `clock.curr_time` | Returns current time through the `clock` namespace. | [SRC][GATED] Requires `CurrentTimeReminder`. |
| `clock.sleep` | Sleeps/waits for a duration. | [SRC][GATED] Requires CurrentTimeReminder configuration with sleep enabled. Source bounds the sleep interval and lets new user input interrupt it. |

---

## 5. MCP resource tools

When at least one MCP server is configured, current source can register:

| Tool | What it does | Limitations |
|---|---|---|
| `list_mcp_resources` | Lists MCP resources. | [SRC][EXT] Only resources, not an exhaustive list of callable MCP tools. |
| `list_mcp_resource_templates` | Lists resource templates from MCP servers. | [SRC][EXT] Requires MCP server support. |
| `read_mcp_resource` | Reads an MCP resource by URI/server identity. | [SRC][EXT] Requires the corresponding server/resource. |

Codex also registers **MCP callable tools themselves** dynamically. Those names/schemas are server-specific and may be direct, deferred, hidden, or code-mode-only depending on exposure policy.

### `tool_search`

Codex current source defines a `tool_search` facility that:

- searches metadata for **deferred tools** using BM25
- returns matching tools for exposure on the next model call
- accepts `query` and optional `limit`
- is specifically intended for deferred/MCP tool discovery when tool search is enabled

This means a model-visible tool list can be **lazy/dynamic**, not a static complete schema dump at session start.

---

## 6. Plugin / extension discovery tools

| Tool | What it does | Exposure conditions / limitations |
|---|---|---|
| `list_available_plugins_to_install` | Lists installable plugin candidates known to the session. | [SRC][GATED] Only added when ToolSuggest + Apps + Plugins are enabled and candidate presentation uses the list-tool path. |
| `request_plugin_install` | Requests installation/connection of a plugin candidate. | [SRC][GATED] Only candidates selected by the tool-suggest pipeline; installation remains a user/permission-controlled action. |

Codex can also register **extension tools** and **dynamic tools** contributed to the session. These are not finite core names and must be inspected at runtime.

---

## 7. Native multi-agent tools — V1

Current source supports a V1 multi-agent tool family when collaboration is enabled.

| Tool | What it does | Important behavior / limitations |
|---|---|---|
| `spawn_agent` | Creates a subagent and returns its agent ID (and optional nickname). | [SRC][GATED] Model/service-tier/agent-type overrides depend on configuration. Spawn depth is bounded by configured max depth. |
| `send_input` | Sends text/items to an existing agent. | [SRC][GATED] `interrupt=true` redirects the child immediately; false/omitted queues input. Source explicitly encourages reusing an agent when follow-up work depends on its previous context. |
| `resume_agent` | Reopens a previously closed agent so it can receive input/wait operations. | [SRC][GATED] V1 behavior; requires an agent ID that can be resumed. |
| `wait_agent` | Waits for target agents to reach final state and/or returns status. | [SRC][GATED] Timeout bounded by configured min/default/max. Completion can also arrive as notification. |
| `close_agent` | Closes an agent and open descendants. | [SRC][GATED] Completed agents can still count against concurrency until closed, so lifecycle cleanup matters. |

### V1 lifecycle implication

V1 has an explicit **close + resume** model. A controller can preserve an agent for context-dependent follow-up work via `send_input`, or close it and later use `resume_agent` if supported by that runtime path.

---

## 8. Native multi-agent tools — V2

Current source also contains a distinct V2 collaboration surface.

| Tool | What it does | Important behavior / limitations |
|---|---|---|
| `spawn_agent` | Creates a named/task-scoped subagent. | [SRC][GATED] V2 requires `task_name` and `message`. Optional model/reasoning/service-tier exposure is configuration-controlled. |
| `send_message` | Queues a message to an existing agent. | [SRC][GATED] Delivers promptly but **does not trigger a new turn** by itself. |
| `followup_task` | Sends follow-up work and triggers execution if the target is idle. | [SRC][GATED] If already running, delivery occurs at appropriate sampling/message/tool boundaries. This is the V2 primitive most relevant to “wake and continue” workflows. |
| `wait_agent` | Waits for mailbox activity / agent updates. | [SRC][GATED] Optional in V2 via `wait_agent_enabled`. Does not necessarily return message content; returns activity/update summary. |
| `interrupt_agent` | Interrupts an agent's current turn without destroying the agent. | [SRC][GATED] Agent remains available for messages/follow-up work. |
| `list_agents` | Lists live agents in the current root agent tree, optionally by task-path prefix. | [SRC][GATED] Live/root-tree scope; not a global process list. |

### V2 is semantically different from V1

Do **not** collapse V1 and V2 tool names into one behavior table:

- V1 `send_input(interrupt=true)` can immediately redirect work.
- V2 separates ordinary `send_message` from `followup_task` and `interrupt_agent`.
- V1 has `close_agent`/`resume_agent`; V2 source uses a different lifecycle/control vocabulary.
- V2 may namespace these tools depending on provider namespace support/configuration.

---

## 9. Multi-agent enablement constraints

Current source checks whether collaboration tools are enabled and whether spawn depth is exceeded. Behavior depends on `MultiAgentVersion`:

- `Disabled` — no native collaboration tools
- `V1` — available until configured spawn-depth limit is exceeded
- `V2` — availability follows V2 model/session rules and source/session type

OpenAI's Codex product documentation also warns about normal multi-agent operational constraints:

- subagents consume tokens
- parallel writers can conflict with one another
- sandbox/approval policy is inherited/enforced
- noninteractive execution cannot magically satisfy new human approval requirements

For production orchestration, read the **actual model-visible tool schema** of the launched binary rather than assuming source `main` exactly matches the installed release.

---

## 10. Hosted web search and external model tools

Codex can expose hosted web search when:

- the provider supports web search
- session/model configuration enables it
- a standalone extension-provided web search is not taking precedence

The exact hosted tool schema is provider/model-dependent, so it belongs to the **hosted/extension capability layer**, not the invariant core registry.

Current source can also add extension-provided tools such as standalone web search and image generation when account/provider/model/feature checks pass.

---

## 11. Guardian / reviewer-restricted tool set

An important source-level special case exists for managed Guardian reviewer sessions: the generic tool universe is intentionally suppressed, and only a restricted execution/image subset is registered when the managed sandbox can enforce parent filesystem restrictions.

Current source specifically permits the restricted reviewer path to receive:

- `exec_command`
- `write_stdin`
- optionally `view_image`

This is a strong example of why **session source and policy context matter as much as tool implementation existence**.

---

## 12. Tool exposure modes

Codex's registry distinguishes several exposure states. A tool can be:

- hidden
- direct-model-only
- direct
- deferred-model-only
- deferred
- code-mode-only / code-mode-visible

Tool Search can move deferred tools into later model calls. Code Mode can remap/augment nested tools. Namespace support also changes how tools are presented to the model.

Therefore, a capability database should separately track:

```text
implemented_in_source
registered_for_turn
exposure_mode
advertised_to_model
invoked_successfully
```

---

## 13. Important limitations

1. **`main` source can be newer than the installed CLI release.** Pin source/tag/build when you need exact guarantees.
2. **Feature-gated tools are not universal.** `request_user_input`, permission tools, token-budget tools, time/sleep, plugin discovery, image inspection, etc. depend on feature/model/configuration state.
3. **Multi-agent V1 and V2 are different APIs.** Do not generate one generic prompt schema without an adapter.
4. **MCP/extension/dynamic tools make the runtime set open-ended.** A static list can only cover core source tools.
5. **Some tools can be deferred/hidden.** “Implemented” does not equal “model-visible this turn.”
6. **Environment selection matters.** Shell, patch, image, and permission tools may disappear when no compatible execution environment exists.
7. **Sandbox/approval constraints remain authoritative.** Having `exec_command` or `request_permissions` does not imply unrestricted filesystem/network/process access.

---

## 14. Completeness statement

This document covers the major **core tool families registered by the current official Codex source router**, plus the V1/V2 native multi-agent surfaces and dynamic extension mechanisms. Because Codex builds its visible tool set dynamically from model/provider/features/environment/MCP/extensions, there is no single static list that proves what an arbitrary running Codex session exposes.

For an exact installed-build inventory, capture the tool schemas from that build/session or probe the exact binary and launch mode.

---

## Official sources

- Codex documentation: https://developers.openai.com/codex/
- Official Codex source repository: https://github.com/openai/codex
- Core tool registry/router: https://github.com/openai/codex/blob/main/codex-rs/core/src/tools/spec_plan.rs
- Tool handler module inventory: https://github.com/openai/codex/blob/main/codex-rs/core/src/tools/handlers/mod.rs
- Multi-agent tool schemas: https://github.com/openai/codex/blob/main/codex-rs/core/src/tools/handlers/multi_agents_spec.rs
- Apply-patch tool schema: https://github.com/openai/codex/blob/main/codex-rs/core/src/tools/handlers/apply_patch_spec.rs
- Deferred tool-search schema: https://github.com/openai/codex/blob/main/codex-rs/core/src/tools/handlers/tool_search_spec.rs
- MCP documentation: https://developers.openai.com/codex/mcp


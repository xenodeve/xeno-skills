# Cursor Agent CLI — Tools Reference

**Research date:** 2026-08-14  
**Scope:** Cursor Agent / Cursor CLI tool capabilities, native subagent features, extension surfaces, and limitations.  
**Primary source class:** Cursor official documentation and official changelog.  
**Important methodological note:** Cursor does **not currently publish a version-pinned exhaustive wire-level registry of every model-visible CLI tool name** comparable to Claude Code's Tools reference. This document therefore separates vendor-documented capabilities from exact runtime identifiers.

## Evidence notation

- **[DOC]** — explicitly documented by Cursor.
- **[DOC-NAME]** — official product/tool label, not necessarily the model's raw wire identifier.
- **[RUNTIME-LOCAL]** — observed in the companion local probe on Cursor Agent CLI 2026.08.11-e8db854; useful evidence, but not a vendor API contract.
- **[EXT]** — dynamically added extension surface.
- **[UNKNOWN]** — no stable public exact name/contract established.

---

## 1. What Cursor officially calls its Agent tools

Cursor's official Agent Tools page groups its tool capabilities as follows.

### Search / context tools

| Official label | What it does | CLI/wire-name status | Limitations |
|---|---|---|---|
| `Read File` | Reads source/file content. | [DOC-NAME] Exact raw CLI tool identifier is not guaranteed by the public page. | File/sandbox/rule permissions apply. |
| `List Directory` | Lists directory contents. | [DOC-NAME] | Workspace/access scope applies. |
| `Codebase` | Semantic/codebase search and retrieval. | [DOC-NAME] | Backend/indexing/mode availability may differ between editor and CLI. |
| `Grep` | Searches text/code. | [DOC-NAME] | Workspace/search scope applies. |
| `Search Files` | Finds files. | [DOC-NAME] | Workspace/search scope applies. |
| `Web` | Searches/browses web information. | [DOC-NAME] | Network/policy/model availability applies. |
| `Fetch Rules` | Loads relevant Cursor rules. | [DOC-NAME] | Depends on configured `.cursor/rules` / rule discovery. |

### Edit tools

| Official label | What it does | Limitations |
|---|---|---|
| `Edit & Reapply` | Applies code/file edits and can reapply changes. | Mutation permission/sandbox/rule constraints apply. Plan/Ask modes can restrict writes. |
| `Delete File` | Deletes a file. | Destructive action; permission/sandbox scope applies. |

### Execution

| Official label | What it does | Limitations |
|---|---|---|
| `Terminal` | Runs commands using the configured terminal profile. | Command approval/sandbox/network/file constraints apply. Cursor 2.5 added granular sandbox network/file controls. |

### MCP

| Surface | What it does | Limitations |
|---|---|---|
| Configured MCP tools | Connects the agent to external services via MCP. | [EXT] Tool names and schemas are server-specific. Cursor discovers MCP definitions/tools on demand in newer releases. |

### Product controls that are **not tool names**

Cursor's Tools page also presents `Auto-apply Edits`, `Auto-run`, `Guardrails`, and `Auto-fix Errors` as advanced options. These are behavioral controls/settings and should **not** automatically be recorded as model-visible raw tool identifiers.

---

## 2. CLI-specific documented capability set

Cursor's CLI documentation says the CLI agent currently has tools for:

- file operations
- searching
- running shell commands
- MCP integrations configured through `mcp.json`

The documentation also explicitly says **more tools are being added, similar to the IDE agent**. This is why a static product page should not be treated as a complete versioned wire registry.

Cursor CLI also consumes the same rules ecosystem, including `.cursor/rules` and compatible project instruction files.

---

## 3. Native subagents

Cursor 2.4 introduced native subagents in both the editor and Cursor CLI.

### Documented properties

- Independent agents handle discrete portions of a parent task.
- They run with their **own context**.
- They can run in parallel.
- They can be configured with:
  - custom prompts
  - tool access
  - models
- Cursor ships default subagents for:
  - codebase research
  - terminal-command work
  - parallel work streams
- Custom subagents are supported.

Cursor 2.5 expanded this model:

- subagents can run **asynchronously**, so the parent continues working
- subagents can **spawn their own subagents**, forming an agent tree
- stopping the parent stops child subagents
- subagent permission flow was improved

### Runtime spawn identifier observed in the companion probe

For the locally tested headless build `cursor-agent 2026.08.11-e8db854`, native delegation was observed through a tool whose runtime name was:

```text
Task
```

and `preToolUse` received the spawn input before execution. Treat `Task` as **[RUNTIME-LOCAL]**, not as a stable vendor-documented API name, because Cursor's public tool documentation does not currently promise it as an exact permanent wire identifier.

---

## 4. Clarification / question capability

Cursor 2.4 documents an interactive Q&A capability usable by agents beyond Plan/Debug mode. Agents may continue reading files, editing, or running commands while awaiting the user's response, then consume the answer when it arrives.

Cursor's changelog refers to this as the **ask question tool**, but the current general Tools page does not publish a stable raw wire schema/name. Record it as a documented capability unless a specific runtime build is being censused.

---

## 5. Image generation

Cursor 2.4 added direct image generation to the agent:

- accepts a textual description and/or reference image
- returns an inline preview
- saves output under the project's `assets/` directory by default
- suitable for UI mockups, product assets, and architecture visualizations

The changelog names Google Nano Banana Pro as the underlying generation model for that release. Model/provider implementation can change over time, so do not encode the model name as the tool contract.

The public docs do not provide a stable raw CLI wire-tool identifier for image generation in the same way Claude documents `Write` or Antigravity documents `generate_image`.

---

## 6. MCP and lazy tool discovery

Cursor supports MCP in the CLI and automatically reads the same `mcp.json` configuration used by the IDE. Newer Cursor releases moved MCP server definitions/tools into `.cursor` JSON configuration and support **on-demand discovery/loading** to reduce context use.

Consequences for a tool census:

1. MCP tool names are not part of a finite Cursor built-in list.
2. The set visible to the model may be lazily materialized rather than preloaded.
3. A runtime capture must distinguish built-in tools from MCP-provided tools and plugin-provided tools.

---

## 7. Skills, rules, and plugins — not the same as tools

### Skills

Cursor supports Agent Skills in editor and CLI. A `SKILL.md` adds instructions/workflows and may contain scripts, but a skill should not be automatically counted as a built-in wire tool unless the runtime exposes an explicit invocation tool in that build.

### Rules

Rules provide context/instructions. They are not execution tools.

### Plugins

Cursor plugins can bundle:

- skills
- subagents
- MCP servers
- hooks
- rules

A plugin can indirectly expand tool availability through MCP/subagents, so plugin installation changes the runtime capability universe without changing the static core tools page.

---

## 8. Sandbox and permission constraints

Cursor 2.5 added granular sandbox controls for:

- network domains
- local files/directories

Network policy can be configured as:

- user allowlist only
- user allowlist plus Cursor defaults
- allow all

Enterprise admins can enforce organization-level network policies.

Additional important behavior:

- common package/network operations such as `git clone`, `npm install`, and `pip install` were made usable in the sandbox with defaults that can be overridden
- Ask mode is enforced read-only in the sandbox, even when a broad run permission is enabled
- subagents participate in permission flow rather than silently escaping parent restrictions

---

## 9. Headless / CLI completeness limitations

This is the most important section for using Cursor as a programmable MasterAgent.

### The public docs do not currently guarantee an exhaustive raw tool registry

Cursor documents **capabilities and product labels**, while the agent runtime can have build-specific raw identifiers. Therefore:

- `Read File` on a product page is not automatically proof that the raw model tool is literally named `Read File`.
- a raw identifier seen in a transcript/bundle (for example `Task`) should not be promoted to a permanent public contract without vendor documentation.
- subagent, image, clarification, browser, MCP, and plugin capabilities can add runtime tools not represented as fixed rows on the generic Tools page.

### Editor behavior must not be silently projected onto `agent -p`

Cursor advertises features across editor and CLI, but callback/tool behavior may differ by launch mode. For production orchestration, capability-probe the **exact Cursor build + exact headless launch mode** rather than assuming an editor callback/tool is reachable in CLI headless mode.

---

## 10. Recommended runtime-census categories for Cursor

A reliable machine-readable Cursor tool inventory should record each item at one of these evidence levels:

```text
DOC_CAPABILITY     vendor says the capability exists
DOC_NAME           vendor publishes a product/tool label
RUNTIME_ADVERTISED exact build advertised the raw tool to the model
RUNTIME_INVOKED    exact build successfully invoked it
EXTENSION          MCP/plugin-provided rather than core
```

This prevents a product label, a bundle string, and a live wire name from being incorrectly treated as equivalent.

---

## 11. Completeness statement

This document is comprehensive for the **officially documented Cursor Agent capability groups** found in the current docs/changelog, but **is intentionally not presented as an exhaustive raw model-tool-name registry**, because Cursor does not publish one as a stable, version-pinned reference today.

For enforcement, routing, or prompt-contract software, generate a runtime census from the exact CLI build and keep that census separate from this vendor documentation reference.

---

## Official sources

- Cursor Agent Tools: https://docs.cursor.com/en/agent/tools
- Cursor CLI usage/capabilities: https://docs.cursor.com/en/cli/using
- Cursor 2.4 — Subagents, Skills, Image Generation: https://cursor.com/changelog/2-4
- Cursor 2.5 — Plugins, Sandbox Access Controls, Async Subagents: https://cursor.com/changelog/2-5


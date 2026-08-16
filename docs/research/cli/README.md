# CLI Tool Surface Research — 2026-08-14

This folder contains four vendor-specific Markdown references:

1. `claude-code-tools-reference.md`
2. `codex-cli-tools-reference.md`
3. `cursor-agent-cli-tools-reference.md`
4. `antigravity-cli-tools-reference.md`

## Why they are not formatted identically

The vendors expose different levels of tool-contract detail:

- **Claude Code:** official documentation explicitly presents a complete built-in tools reference with exact configuration-facing names.
- **Antigravity CLI:** official hook docs enumerate standard tool names and arguments, making a strong standard-tool census possible; browser/MCP/plugin extensions can still add more runtime tools.
- **Codex CLI:** the official open-source router is the strongest inventory, but exposure is highly dynamic and feature/model/provider/environment gated; V1 and V2 multi-agent APIs differ.
- **Cursor Agent CLI:** official docs primarily publish product-level tool capabilities, not a version-pinned exhaustive raw wire registry, so exact runtime names must be captured from the specific CLI build.

Use these files as **vendor documentation references**, then layer a separate live capability census on top for the exact binaries used by an enforcement/orchestration system.

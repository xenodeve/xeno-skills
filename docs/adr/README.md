# Architecture Decision Records

Each ADR captures one significant, hard-to-reverse decision: its context, what was chosen, the alternatives rejected, and the consequences. They document decisions **already in the codebase** (unless marked *pending*), so a new maintainer — human or agent — can recover the *why* without re-deriving it. A decision that overturns an earlier one marks the old ADR **Superseded**.

| # | Title | Area | Status |
|---|-------|------|--------|
| [0001](0001-hook-based-workflow-enforcement.md) | Hook-based workflow enforcement (soft dispatcher + hard gate + CI) | Infra | Accepted |

## Conventions

- Filename: `NNNN-kebab-title.md`, zero-padded. **Numbers must be unique** across *all* branches.
- Body: title line, a status/context bullet block, then `## Context`, `## Decision`, `## Alternatives considered`, `## Consequences`.
- Ground every claim in the code as it is **now**; cite `file:line`.

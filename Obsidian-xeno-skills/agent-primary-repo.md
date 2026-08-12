---
name: agent-primary-repo
description: This repo is agent-primary — the coding agent is the main developer, so repo docs are the agent's operating manual, not team paperwork.
type: feedback
---

xeno-skills is an agent-primary repo: the coding agent is the primary developer, and the repo's
docs are its operating manual. Context survives across sessions through the memory layer
(`docs/OPEN-WORK-LEDGER.md`, `DONE.md`, this vault) — not through anyone's recollection.

**Why:** this is the T4 team standard the repo itself ships (`using-t4`, `t4-agent-memory`).
Working here any other way — trusting memory over the ledger, skipping the session-start read —
violates the standard the repo exists to enforce.

**How to apply:** every session starts with `Home.md` → `docs/OPEN-WORK-LEDGER.md` → the issue.
Ship units append to `DONE.md`; new open work gets a ledger row and (if non-trivial) an issue.

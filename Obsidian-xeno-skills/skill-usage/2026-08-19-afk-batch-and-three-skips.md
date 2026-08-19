---
date: 2026-08-19
repo: xeno-skills
skills: [t4-afk, ask-xeno, t4-agent-memory, t4-dev-workflow, simplify, code-review, scrutinize]
gates: simplify=ran code-review=ran scrutinize=ran security-review=n-a verify=ran
---

## What the session did

An AFK batch under a standing `/goal`: clear the work that is AFK-able or a small reversible decision,
follow `t4-dev-workflow`, then merge. Built the four sub-issue trees `#251`–`#254` (`#215`→3, `#129`→4,
`#165`→10, `#176`→42, every count read back from `sub_issues_summary`), created the two plan tracking
issues `#256`/`#257` for `#255`, and merged **PR #259** and **PR #261** to `main`. Implemented `#244` on
`feat/185-turn-end-wiring`. Filed `#258`, `#260`, `#262`.

**Gate note, with its proof.** `security-review=n-a` on both merged PRs: `git diff main...HEAD --name-only`
was `docs/plans/README.md`, `tests/skills/test-plan-index.sh`, `.gitignore`,
`tests/guards/test-check-tree-budget.sh`, `DONE.md` — no hook, no gate, no auth or secret path reachable
from any of them. `verify` ran before and after every commit.

## Three skips, and the embarrassing one first

**`t4-bro` was never invoked — in the session that implemented `#244`, which is the issue about `t4-bro`
and `using-t4` failing to load.** Every Thai report this session was written without it. The log
(`#143`'s) has **10 rows across every session it has ever recorded and `t4-bro` appears in none of them**.
Recorded on `#209`.

**`karpathy-guidelines` was skipped at session start.** `using-t4`'s protocol is ordered
`karpathy-guidelines` → `t4-agent-memory` → route. The session invoked `t4-afk`, `ask-xeno`,
`t4-agent-memory` and `t4-dev-workflow` within 18 seconds and never item 1. An agent that opens by asking
*"what work is there?"* enters the list at item 2 and never goes back. It cost something small and real:
two `/simplify` findings were about exactly what the guideline leads with. Recorded on `#134`.

**`/simplify` and `/code-review` were run inline, not as sub-agents** — a standing session instruction
forbade the Agent tool and neither skill names a fallback. Declared in both PR bodies rather than left
implied, and filed as `#262`, because the trailer said `ran` for a gate that ran in a form the skill does
not describe.

## The finding the session exists for

**A rule can be skipped while writing its own fix, and nothing notices.** `#244` says a bootstrap that
skipped the disciplines produces byte-identical files to one that followed them. The same is true one
level up: this session's commits, PRs and issue bodies are indistinguishable from ones written with
`t4-bro` loaded. Prose that reads fine is not evidence the register rule was applied.

The asymmetry worth keeping: `security-review` **is** in the log and `t4-bro` is not, and both are
condition-triggered. The difference is that `security-review` fires on a *noun in the diff* and `t4-bro`
fires on *every reply* — **a trigger that fires constantly is one an agent stops seeing.** That is the
same thing `using-t4` had to defend against by writing *"a check at task start does not discharge a later
trigger"* in those words.

## What the tooling could not tell me

`.invocations.log` records `t4-afk`, `ask-xeno`, `t4-agent-memory`, `t4-dev-workflow` and **not**
`simplify`, `code-review`, `scrutinize` or `handoff`. So an absence in that file is `unknown`, not `no` —
and it is currently being read as `no`. Measured on `#145`. For `t4-bro` the `no` happens to be right, and
it was confirmed independently rather than inferred from the log.

## Parked, with the reason

- **`#246`** — the ship gate runs a verify command the PR author wrote. Three options, none picked: a
  trust-boundary design choice on both sides, so it is the developer's. Blocks PR #235.
- **`#260`** — 20 of 24 files in `hooks/` are committed CRLF. The fix rewrites 20 files of the enforcement
  layer, so `t4-afk`'s boundary rule parks it. The `tr -d CR` diffs prove the content is identical, but
  that is the agent reviewing its own boundary change unattended, which is the named anti-pattern.

## Not written

**No note for 2026-08-17.** The tracker half of that session's report was filed at the time; the local note
was not, and writing it now would be a reconstruction. This file records only what happened in this
session.

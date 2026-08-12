---
date: 2026-08-12
repo: xeno-skills
skills: [handoff, clink-brainstorm, to-prd, t4-dev-workflow, scrutinize, code-review]
gates: simplify=not-run code-review=ran scrutinize=ran security-review=n-a verify=ran
---

## What the session did

Built `t4-bro` (#139 → PR #140), benchmarked it with a subagent, and turned the result plus a re-read of the guards into #141-#144. See `DONE.md` for the shipped units.

## Rules that did not hold

- **Survey the change sites before writing the plan** (`t4-dev-workflow`) — #139's change inventory listed `docs/OPEN-WORK-LEDGER.md` as a change site with a "ledger row" to add. There is no such file on `main`; `t4-project-bootstrap/references/governance-docs.md:25` shows it is a file the bootstrap installs into a *target* repo. The survey itself was run (`grep -rln "t4-engineering-records"` across `*.md`, `*.json`, `*.sh`, `*.cmd`) and did **not** produce that row — it came from memory of a handoff written earlier the same session. **A survey does not protect a line the plan added from somewhere else.** Caught by `/scrutinize`, not by the survey.

- **No verdict before evidence** (`t4-dev-workflow`) — the handoff written earlier in this session opened with "read `docs/OPEN-WORK-LEDGER.md` first" and called it stale. Neither claim was checked. Both were carried from an earlier context where the file had been seen — on `chore/93-bootstrap-self`, where it does exist. **A path verified on one branch was asserted about another.**

- **Structure only when the content is structured** (`t4-bro`) — a subagent given the skill and four questions answered with four `##` headings, two tables and bold on most lines. Every word-level rule held: identifiers byte-exact, concepts in Thai, hedges kept on an unverified claim, an unprompted "what I did not check" section. Only the shape rule failed, and it was the one rule in the file with no example attached. Fixed on PR #140 by giving it three. `[[example-beats-principle]]`

- **Delegation scope** (`t4-dev-workflow`, delegation guardrail) — the developer asked for a subagent to *read* the project. The prompt written for it asked four audit questions, and the subagent ran the test suite, `git fetch`, `diff`, and GitHub API calls. 114k tokens and seven minutes for what was meant to be a style check. Nothing was damaged (tree clean, only `.git/FETCH_HEAD` written), but **the prompt, not the subagent, chose the scope.**

## Rules followed that still produced the wrong thing

- **`/code-review` step 4 — spawn two parallel sub-agents.** A standing instruction in this session forbade spawning agents unless the developer asked, so the mandated mechanism was unavailable. Both axes ran in one context and it was disclosed in the commit and PR. The skill names no fallback for its mechanism being unavailable, so following it as written was impossible rather than merely expensive.

## Wording that was unclear, or that contradicted another skill

- `t4-agent-memory`'s add/update threshold says "do NOT persist … one-off task notes", which forbids this entry. Resolved in #143 by making the skill-usage log a **separate layer** rather than a vault note, and saying so explicitly — a feedback database needs the unremarkable entries, because the rate is the signal.

- `check-gate-ledger:8-11` says an AFK batch opened "**nine** PRs" and then that a defect was found in "seven of the **ten**". The list enumerates ten. Reported on #135.

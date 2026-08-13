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

- **No verdict before evidence** (`t4-dev-workflow`), second instance — before opening #141-#145 I ran `gh issue list --state open` and concluded "no prior issue covers this". `gh issue list` defaults to `--state open`; the repo has 82 issues, 26 of them open. Two of the five overlapped closed issues: #142's predecessor is **#115**, whose file header (`tests/audit-anchor-quality.sh:2`) names it on a line I had read aloud in the same session, and #141's skip was *created* deliberately by **#12**. Neither was a duplicate, but #115 already contains the allowlist #142 asks someone to derive, and without #12 the skip in #141 reads as an oversight rather than a fix. **A default flag narrowed the search and the conclusion was stated as if it had not.** The developer caught it by asking. `[[survey-protects-only-what-it-produced]]`

- **Write one precise question** (`clink-brainstorm`, step 1) — a panel was convened on 2026-08-13 to judge an implementation plan. The prompt described the reviewer's job as *"asks whether the invoked skills' rules were followed"*. That phrase does not separate **process** from **outcome**. All three panellists resolved it toward outcome, correctly concluded that session history cannot establish outcome, and unanimously recommended moving the reviewer to pre-push. Two of them refused to build parts of the design. The developer corrected it in one sentence: the reviewer checks the prescribed *workflow*, and code correctness is CI's job. **The prompt was not vague — it carried measured constraints, file paths, three named options and a word count. One noun with two readings was enough.** Filed as #160. Distinct from #131, which is a *leading* prompt; this one supplied nothing and bounded nothing.

- **No verdict before evidence** (`t4-dev-workflow`), third instance — I told the same panel the session transcript lags **108 seconds**, presented as a verified constraint. It was a single sample carried in from an earlier workflow that I never re-measured. Measured properly across 7,268 timestamped records: `p50 0.2s · p90 15.7s · p99 189.7s`, with 230 of 7,267 gaps over a minute (3.2%). **A tail figure was handed over as the typical case, and two panellists used it as the deciding reason to refuse a layer.** The failure is not that the number was wrong — it is that I passed on someone else's measurement with my own confidence attached.

- **Claiming enforcement that does not exist** (`docs/adr/0001`) — PRD #159 stated that the master agent *"may not answer with silence"* as though it were a rule of the mechanism. Nothing enforces it: a non-blocking hook cannot compel a response. Caught by a panellist independently of everything else, and it is the same defect this repository documents as its worst failure mode. `[[no-verdict-before-evidence]]`

## Rules followed that still produced the wrong thing

- **`/code-review` step 4 — spawn two parallel sub-agents.** A standing instruction in this session forbade spawning agents unless the developer asked, so the mandated mechanism was unavailable. Both axes ran in one context and it was disclosed in the commit and PR. The skill names no fallback for its mechanism being unavailable, so following it as written was impossible rather than merely expensive.

## Wording that was unclear, or that contradicted another skill

- `t4-agent-memory`'s add/update threshold says "do NOT persist … one-off task notes", which forbids this entry. Resolved in #143 by making the skill-usage log a **separate layer** rather than a vault note, and saying so explicitly — a feedback database needs the unremarkable entries, because the rate is the signal.

- `check-gate-ledger:8-11` says an AFK batch opened "**nine** PRs" and then that a defect was found in "seven of the **ten**". The list enumerates ten. Reported on #135.

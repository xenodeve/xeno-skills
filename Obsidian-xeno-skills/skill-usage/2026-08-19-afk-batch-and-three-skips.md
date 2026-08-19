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

## What the review found, in two passes, after the batch

The batch ended and the branch still had no `/code-review`. Running it produced the finding this note
would otherwise not contain, and it is a better argument for the gate than any of the prose is.

**Pass one found raw control bytes in `hooks/t4-gate`** — in code committed hours earlier the same day.
A generator emitted a `tr` character range as raw bytes instead of the escape text `tr` expects, so the
script carried NUL, BS, VT, US and DEL, and `bash` cannot hold NUL in a string. **The 94-assertion gate
suite passed both before and after.** That is the whole case for a review existing next to a suite: a
behavioural assertion cannot tell a set that works from one that happens to work.

**Root cause, and it is a rule for this environment:** a heredoc here processes backslash escapes *even
with a quoted delimiter*, so a generator writing an escape into a file emits the byte. Build backslashes
with `chr(92)`. The same bug then bit the test written to catch the first one, which is how the mechanism
was identified rather than guessed.

**Pass one also declared what it had not read** — ~2,300 lines of unwired component logic. **Pass two read
it, and #265 was in there:** eight hooks passed unbounded input through `argv`, capped at ~32 KB. In
`.invocations.log` a dropped record reads as *"the skill was not invoked"* — the opposite of the truth,
in the mechanism built to measure truthfully.

**The generalisable part, and it repeated twice in one day:** a guard written as a *list* misses the item
added after it. The `.gitattributes` pin listed four filenames and twenty hooks arrived; the argv guard
listed five variable names and missed two. Both were fixed by deriving the set instead — a glob, and a
scan for `x="$(cat)"`. **When a check enumerates, ask what adds the next member and whether the check
would see it.**

## The fourth skip, and it is the one the other three were symptoms of

`t4-afk`'s per-item loop, step 4: *"Run the gates unattended — `/simplify`, then `/verify` …,
`/code-review` + `/scrutinize`"*. It sits inside a loop that opens *"For each independent item on the
worklist"*. **The gates are per item.**

`/simplify` did run per item. **`/code-review` and `/scrutinize` ran once, at the very end, against 62
commits** — and only because the stopping condition would not accept the batch without them. Filed as
**#270**.

**What the deferral cost, measured.** The one late run found three defects, all already committed:
raw control bytes in `hooks/t4-gate` (written by this session hours earlier), the argv cap in eight
hooks (#265), and a guard listing 4 of 24 files (#268). **One of the three is this session's own
per-item miss**; the other two are inherited from a branch whose 54 commits *declared* the gates ran.
Two of the three fixes had to be written after the branch merged, so `main` carried them for a period.

**The mechanism, because "be more disciplined" is not one.** The batch opened with tracker operations —
#251–#254 are sub-issue links with no code, so `code-review=n-a` is correct and step 4 legitimately
produces nothing. By the time the batch reached code the *habit* was "gates at the reporting boundary",
and the reporting boundary was the digest.

**And the two that were deferred are the two with no artifact.** `/verify` leaves a green suite;
`/simplify` leaves a diff. `/code-review` and `/scrutinize` leave nothing unless the reviewer writes it
down — so deferring them costs nothing visible until something is found. That is the same asymmetry
`#247` records from the trailer side, which is why a deferred gate and a falsely-declared one produce
the same artifact: none.

**The generalisable line for the next session:** a rule attached to a loop fires while you are in the
loop. Once the work changes shape — tracker ops to code, one item to a branch — the loop is not where
you are any more, and the rule goes quiet without being broken on any single step.

## The fifth, and it is the rule I had written that afternoon

The pass that closed 37 issues after the merge **derived its list from the trailing `(#N)` of each commit
subject.** That sees only the last issue a commit names — so a slice landing under its PRD (`... (#176)`),
or four adapters in one commit, was invisible to it. **Fourteen issues stayed open with nobody having
decided they should**, and `#176` read 25/42 when it was 37/42.

**#268 — "derive the set a guard checks; never list it" — was written and merged hours earlier, by me,
on the same day.** It did not fire here because I had filed it as a rule about *guards*, and this was a
one-off closing task. The shape was identical: a pattern that matches one member per commit, applied to a
population where commits carry several.

**So the rule's own scope was too narrow on the day it was written.** Not "a guard that enumerates" —
**any derivation that assumes one match per source.** Re-derived by searching the full commit message
instead of the subject's tail, which moved the open count 79 → 65 and the rollup to 88%.

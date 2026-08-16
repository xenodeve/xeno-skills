---
name: 2026-08-16-compliance-reviewer-queue-cleared
description: Eight slices on PR #235 clearing the reviewer's ready-for-agent queue; four rules did not hold, one of them a park this session refuted.
metadata:
  type: feedback
---

# 2026-08-16 — the compliance reviewer's queue, cleared

Session `179dfafc`, branch `feat/185-turn-end-wiring`, PR #235. This window landed
**eight issues**: #187 · #192 · #193 (the classifier), #191 (the router), #194 (traces),
#198 (the reviewer call), #200 (skill version), #201 (following a delegation),
#202 (the clink boundary), #203 (receipts). Branch total **42 commits, 34 issues**.

## Rules that did not hold

Filed on the tracker; this note is the local copy and does not restate the bodies.

| Rule | Where | Issue |
|---|---|---|
| `tdd` — red before green; check the red fails for the reason named | implementation before test once (#187); a red where **15 assertions passed with no script** | comment on [#132](https://github.com/xenodeve/xeno-skills/issues/132) |
| `t4-afk` — the park test | **#194 was parked in a previous window with a reason no plan supported**, and closed here in one slice | comment on [#78](https://github.com/xenodeve/xeno-skills/issues/78) |
| bilingual tracker bodies | PR #235's body was English-only across 42 commits | [#238](https://github.com/xenodeve/xeno-skills/issues/238) |
| `karpathy-guidelines` §3 | two `.pyc` files committed by `git add -A` | [#239](https://github.com/xenodeve/xeno-skills/issues/239) |

**Rules that held and were exercised:** evidence before verdict (every issue comment
names the artifact); root cause before fix (#194's 21-owed traces were traced to a
data-carrying bug in the census, not patched around); proof before skipping (the
expiry span in #203 stayed unset because #178 reserves it); one commit per issue.

## The two findings worth carrying forward

**A park inherited across a handoff is a claim with a timestamp, and nothing re-tests it.**
#194 sat in the handoff's "Parked, with the reason each needs" list beside five genuine
trust-boundary parks, where it borrowed their credibility. Fifteen minutes of reading
refuted it. See [[survey-protects-only-what-it-produced]] — same shape: an inherited
artifact treated as if it had been produced by the session holding it.

**Two issues in this queue were wrong about the facts, and both were caught by measuring
rather than by reasoning.** #201 said the agent id appears in the master transcript and
the join costs a glob — it appears **zero** times; the sidecar's `toolUseId` appears
four. #187 was written for a classifier inside a hook, which the four-harness
measurement forbids. An issue body is evidence about intent, not about the machine.

## Suggested reads for the next session on this track

`docs/OPEN-WORK-LEDGER.md` Track 7 — every remaining row is parked or blocked, and each
names what it needs. The parks are trust-boundary (`t4-gate`), two reserved decisions
(#177, #178, #179) and one whose evidence is outside the repo (#156).

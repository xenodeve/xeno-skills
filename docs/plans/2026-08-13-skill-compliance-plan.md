# Skill-compliance plan — 2026-08-13

**Implements [#159](https://github.com/xenodeve/xeno-skills/issues/159).** That PRD carries the problem and the evidence; this file carries the order of work, the seams, and the two things that were measured while writing it.

**Status:** plan only. No slice has been cut. `/to-issues` has not been run on #159.

---

## The shape

Four slices, in this order. The middle one is a precondition for the last, which is the only reason the order is not the obvious one.

| | | Fixes |
|---|---|---|
| **0** | Stop injecting `using-t4` at session start — it is the wrong router and its measured effect is zero | 33 KB per session spent on one family's map |
| **1** | Before the turn: name the skill this task needs, if it has not been loaded | #134 — the reminder fired every prompt and the skill was never loaded |
| **2** | Write into each rule the trace it leaves in the sequence of work | nothing on its own; makes slice 3 possible |
| **3** | At turn end: the skill was loaded — did its steps appear? | #130 — both skills invoked, in context, step still never ran |

Code correctness is not in this plan at any point. That is CI's job and the tier already exists.

---

## Slice 0 — stop injecting the T4 map at session start

`hooks/t4-session-start` injects `using-t4` verbatim on `startup`, `clear` **and** `compact`. Measured: **8,222 B per injection**, and this session took four of them (one start, three compactions) — roughly 33 KB spent on one family's map.

Two things are wrong with that. It is the **wrong router**: `using-t4` covers the seven T4 skills and none of the nine under `clink-*` and `design*`, which is the gap `ask-xeno` was built to close. And its only measured effect is #134 — the rules were in context, injected, and the agent still did not follow them.

**Stop injecting it.** What `using-t4` uniquely carries — the non-negotiable rules and the red-flags table — arrives instead when a task needs it, through slice 1, which can also verify that it arrived. That is strictly better than injecting it unconditionally and never knowing.

**The seam** is `tests/hooks/test-dispatcher-content.sh`, which today pins a 9000-byte budget and five exact phrases against `using-t4`. Whatever is injected instead inherits that test; the budget and the pinned phrases move with it. `.claude/hooks/using-t4.snapshot.md` and `tests/skills/test-repo-self-bootstrap.sh` move too, or a plugin-less install ships the wrong file.

---

## Slice 1 — say what is missing, before the work

Replace the constant text in `hooks/t4-prompt-reminder` with a check: match the user's prompt against a small routing table, read which skills this session has actually invoked, and emit one short line naming a required skill only when it is absent. Emit nothing otherwise.

**The hook does the routing; it does not hand over a map.** An earlier draft of this plan injected a compact route table on every prompt so the agent could route itself. That is the wrong shape twice over: a table short enough to be cheap (335 B) cannot say that recording a decision, running unattended and writing to the developer are all T4 work, and a table long enough to say it (711 B, or 1,287 B for the whole of `ask-xeno`) costs more per session than everything being replaced. Measured against this session's 55 turns: 18 KB, 39 KB and 71 KB respectively, against 57 KB today.

The hook already matched the prompt. It should emit the **answer**, not the map:

- matched, and the skill is loaded → **emit nothing**
- matched, not loaded → *"this is feature work; `t4-dev-workflow` has not been loaded this session"*
- **no match** → emit the compact route list, because this is the one case where the agent has to route itself

So the route list is paid for on unmatched turns only. `ask-xeno` stays the file an agent reads when it wants the full picture, and it is what slice 0 leaves reachable rather than resident.

**The routing decision is made twice, by two mechanisms, and their answers are unioned.** A single mechanism that fails to fire produces exactly the silence this slice exists to remove, so neither is allowed to be the only one:

- **a deterministic table** — fast, no model, and it **must carry Thai trigger terms**: the developer writes in Thai, and 2,060 lines of this session's transcript contain Thai text, so a table built from English keywords matches almost nothing. It would not merely fail to fire — it would fall through to the unmatched branch on nearly every turn, which is the branch that emits the route list, and the per-turn cost this slice was designed to avoid comes back in full.
- **a classifier**, run only when the table did not match — a small model given the user's prompt and the closed list of skills from `ask-xeno`, returning a skill id, a confidence, and the phrase it matched. **A closed list and a structured return, never prose**: it selects from the routes that exist, it does not describe what it thinks the task is. Below the threshold it returns nothing, and nothing is emitted.

**Union, not intersection.** If either names a skill, the skill is named. Requiring both would mean each is a single point of failure for the other's coverage.

`ask-xeno` stays what it was: the file the master reads when it wants to route itself, and the source of the closed list both mechanisms select from. Three layers, and a task has to slip all three to go unrouted.

**The cost lands where the developer feels it**, and that is the constraint on the classifier: prompt-time is the one moment a hook makes a person wait. It runs only on a table miss, under a stated time cap, and on expiry the turn proceeds unrouted rather than delayed.

**Why it can work when the current reminder does not.** The current hook emits the same four sentences every turn regardless of state; after the first turn it carries no new information. This one speaks only when there is something to say, and what it says is derived from **what happened**, not from what the agent claims: the transcript is written by the harness, and the only way to produce a `Skill` `tool_use` block is to make the call.

**It must not claim** to enforce loading. It reports an absence.

**The seam** is the hook's emitted JSON, as with every suite in `tests/hooks/`. Cases: skill present → empty stdout; absent → exactly one `additionalContext` naming it; transcript missing, moved or unparseable → exit 0, empty; a large fixture inside a stated time budget, asserted rather than described.

### The compaction problem, and why slice 1 has to solve it

**Measured on this repository's own session, 2026-08-13.** The session had been compacted **three times** — `compact_boundary` records at lines 2951, 3013 and 6529 of a 10,177-line transcript. Compaction does **not** start a new transcript; it appends a boundary and a summary to the same file, and every record before it stays.

That breaks the naive check. Counting skill invocations across the whole file:

```
invoked before the last compaction (11):  clink-brainstorm clink-masteragent
                                          karpathy-guidelines simplify tdd
                                          t4-dev-workflow t4-engineering-records using-t4
invoked after  the last compaction  (6):  clink-brainstorm clink-debug clink-subagents
                                          code-review scrutinize t4-dev-workflow
```

`using-t4`, `karpathy-guidelines`, `tdd` and `simplify` appear **only before**. A whole-file check reports them as loaded. They are not: their content was compacted out of the model's context, and the model no longer holds the rules. **The hook would fall silent exactly when the reminder is most needed** — in a long session, which is where drift lives.

**So the check counts from the last `compact_boundary`, not from the start of the file.** The marker is explicit (`subtype: "compact_boundary"`, alongside `isCompactSummary: true` and `compactMetadata`), so this costs one extra condition, not a new mechanism. It also bounds the read: the slice after the last boundary is a fraction of the file.

A session that is never cleared and only ever compacted is therefore **the normal case, not an edge case**, and it is the case the naive version gets wrong.

---

## Slice 2 — write the trace each rule leaves

Most rules are written as instructions with no stated shape. *"Survey the change sites before writing the plan"* does not say what a reader would see if it had been done.

Each rule in scope gains a line naming its trace **in the sequence of work**:

> a message listing the files to be changed appears **before** the message containing the plan

That is a sequence fact. It is not a quality criterion, and the difference is the whole point: we are not asking whether the survey was good, only whether one happened before the plan. A small model matches that directly.

The census in #159 sorts 126 rules into 33 already machine-decidable, 68 needing a trace, and 25 not decidable from a transcript at any effort. **Only the 68 are in scope.** The 25 get a line saying they are out of scope, because an unmarked gap reads as coverage.

**Traces do not go in the skill body.** They go in a sibling file that only the reviewer reads. The master gains nothing from a machine-readable trace declaration and would pay for it on every load — and a load is not free: measured on this session, `/tdd` was invoked three times and each invocation re-injected the whole skill, 3,744 / 3,712 / 3,715 bytes. Sixty-eight declarations inline would be charged to the master, repeatedly, for data only the reviewer consumes.

The rule's prose stays where it is; the sibling file references it by id, and a test pins the two together so a rule cannot be reworded out from under its trace.

**And they certainly do not go in `using-t4`**, which is injected verbatim against a 9000-byte budget with roughly 26 bytes spare, with five exact phrases pinned by `tests/hooks/test-dispatcher-content.sh`.

**The seam** is the shipped skill text, as with every `tests/skills/test-*-rule.sh`. A trace that is added and then softened by a later rewrite must fail — so the test needs a negative assertion, not only a positive one.

---

## Slice 3 — check the trace at turn end

A `Stop` hook of `type: "command"` reads the transcript slice since the last compaction, exits silently when no skill was invoked, and otherwise asks a **small model**: for each skill invoked, do the traces it declares appear?

**It reads the session history only.** No diff, no test output, no repository access. Both of its inputs are short and fixed — the skill's text and a bounded slice — which is what makes a small model a safe choice rather than a cheap one.

**It does not block.** It raises a finding. The master agent decides whether the finding is correct or the reviewer misread, because the master is the stronger model.

**Two things must be stated plainly rather than implied.** A non-blocking hook **cannot compel an answer** — asking the master to respond is a convention, not a mechanism, and #159's original wording claimed otherwise. And a finding raised on the last turn of a session reaches nobody, so either it is carried forward on the next `UserPromptSubmit` or the design says the final turn is unreviewed.

**A reviewer holds no memory of the previous segment**, which is what bounds its input by the segment rather than the session. The state it must still carry forward — a trace whose halves land in different prompts, an `unknown` the transcript had not yet written, a finding the master overruled — moves through a small schema a script maintains, not through the reviewer's own prose. Design: [`2026-08-13-review-handoff.md`](2026-08-13-review-handoff.md).

**Absence near the tail is never a violation.** The transcript is written asynchronously; measured across 7,268 records the gap between them is `p50 0.2s`, `p90 15.7s`, with 3.2% over a minute. Usually current, occasionally a whole turn behind. Evidence that would fall in that window resolves to `unknown` and is recorded as `unknown` — never as "no finding", never as "violated".

---

## What is not known, and will not be assumed

- **Whether a small model matches traces reliably.** Untested. It must be measured against real sessions before it is allowed to raise a finding at all.
- **Whether `type: "prompt"` or `type: "agent"` works from a plugin's `hooks/hooks.json`.** The vendor reference neither permits nor forbids it. Verified only from a settings file — which is the path `t4-project-bootstrap` writes, so bootstrapped repos are covered either way.
- **Whether a blocking `Stop` hook has a retry ceiling.** Untested, and it only matters if the non-blocking decision is ever revisited.

---

## What this plan does not touch

The four gate bypasses (#83, #84, #126, #141) and the CI tier (#158) are separate tracks. Neither is blocked by this work and this work is not blocked by them.

**And the honest ceiling is unchanged:** #130 is a session where both skills were invoked, both were in context, and the step still never ran. Slice 3 is aimed at exactly that failure and will catch only the part of it that leaves a trace. Nothing here enforces that a rule was followed *well*.

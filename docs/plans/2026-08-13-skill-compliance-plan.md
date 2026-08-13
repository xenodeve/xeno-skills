# Skill-compliance plan — 2026-08-13

**Implements [#159](https://github.com/xenodeve/xeno-skills/issues/159).** That PRD carries the problem and the evidence; this file carries the order of work, the seams, and the two things that were measured while writing it.

**Status:** plan only. No slice has been cut. `/to-issues` has not been run on #159.

---

## The shape

Four slices, in this order, **after the baseline below is counted**. The middle one is a precondition for the last, which is the only reason the order is not the obvious one.

| | | Fixes |
|---|---|---|
| **0** | Stop injecting `using-t4` at session start — it is the wrong router and its measured effect is zero | 33 KB per session spent on one family's map |
| **1** | Before the turn: name the skill this task needs, if it has not been loaded — routed twice, by a Thai-carrying table and by a classifier, unioned | #134 — the reminder fired every prompt and the skill was never loaded |
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
- **a classifier** — a small model given the user's prompt and the closed list of skills, returning a skill id, a confidence, and the phrase it matched. **A closed list and a structured return, never prose**: it selects from the routes that exist, it does not describe what it thinks the task is. Below the threshold it returns nothing, and nothing is emitted.

**When the classifier runs, and why "only on a table miss" was wrong.** An earlier draft of this section claimed the two mechanisms were unioned so that neither was a single point of failure, and then ran the classifier only when the table did not match — which makes the table authoritative whenever it fires, including when it fires **wrongly**. *"ตรวจ UI ที่ทำเสร็จแล้วว่ามีปัญหาอะไร"* matching `t4-dev-workflow` is a match, so under that rule the second mechanism never gets to disagree. That is a fallback, not redundancy, and calling it redundancy is the more expensive mistake because it stops anyone looking for the gap.

So the classifier runs whenever the deterministic answer is **not trustworthy**, which is a broader condition than "absent":

- the table did not match
- it matched more than one route
- it matched across families (a `t4-*` route and a `clink-*` route at once)
- it matched on a weak or generic term
- the prompt carries a phase word — *เสร็จแล้ว · ก่อน merge · แก้บั๊ก* — that implies a route different from the matched one

**Union on the result.** Where both run and disagree, both are named; the master is the one that picks, and it is the stronger model. Suppressing one answer to look decisive is how a routing bug becomes invisible.

**And the table is compiled, never hand-maintained.** `ask-xeno` → `using-t4` / `using-clink` / `using-design` → leaf is the routing hierarchy, and it stays the single source of truth. A second table written by hand in a hook is a second routing universe that drifts from the first the day someone edits one and not the other — the same duplicate-site defect `t4-dev-workflow`'s survey rule is written to catch, built in deliberately. The hook's table and the classifier's closed list are both **generated from the skill graph**, with a test asserting the generated artifact matches the source. Runtime stays cheap; the knowledge stays in one place.

**A classifier that fails must be counted, not merely tolerated.** The turn proceeding unrouted is the right behaviour and an invisible one — a dead classifier looks exactly like a session with nothing to route, which is precisely how #134 stayed unnoticed. Every skipped invocation increments the same counters the baseline section establishes.

**The cost lands where the developer feels it**, and that is the constraint on the classifier: prompt-time is the one moment a hook makes a person wait. It runs only on a table miss, under a stated time cap, and on expiry the turn proceeds unrouted rather than delayed.

**Why it can work when the current reminder does not.** The current hook emits the same four sentences every turn regardless of state; after the first turn it carries no new information. This one speaks only when there is something to say, and what it says is derived from **what happened**, not from what the agent claims: the transcript is written by the harness, and the only way to produce the record is to make the call.

**There are two such records, and only one of them is obvious.** Measured on this session: `Skill` `tool_use` blocks name 12 distinct skills, and `<command-name>` records name four more that produce **no `tool_use` block at all** — `/t4-bro` twice, `/handoff` twice, `/to-prd` and `/t4-afk` once each. A detector that greps only `"name":"Skill"` reports `t4-bro` as never loaded in a session that loaded it three times, and would then emit a reminder for a skill already in context — the false positive that costs the most trust. **Both record types count, everywhere a skill's presence is decided.**

**It must not claim** to enforce loading. It reports an absence.

**The seam** is the hook's emitted JSON, as with every suite in `tests/hooks/`. Cases: skill present via `tool_use` → empty stdout; **present only via a slash command → also empty stdout**; absent → exactly one `additionalContext` naming it; table miss with the classifier unavailable or over its cap → the turn proceeds, nothing emitted, exit 0; transcript missing, moved or unparseable → exit 0, empty; a large fixture inside a stated time budget, asserted rather than described.

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

`using-t4`, `karpathy-guidelines`, `tdd` and `simplify` appear **only before**. A whole-file check reports them as loaded. **The hook would fall silent exactly when the reminder is most needed** — in a long session, which is where drift lives.

**What survives a compaction is a carry, and a carry is not a load.** The claim that compaction simply removes a skill from context is too strong, and was corrected by measurement on this session's fourth boundary: the harness re-injects the bodies of recently invoked skills after compacting — but **truncated**, and `clink-subagents` and `clink-brainstorm` came back cut mid-file with an explicit truncation marker, while the four skills listed above did not come back at all. Truncation removes the end of a file, and in several of these skills the rules and red-flag tables sit in the middle and the end. **So a carried skill can be missing exactly the section under test while appearing present.** Treating a carry as a load is therefore the more expensive error of the two: it reports loaded, stays silent, and never re-reminds. The boundary resets the set. No partial credit.

**So the check counts from the last `compact_boundary`, not from the start of the file.** The marker is explicit (`subtype: "compact_boundary"`, alongside `isCompactSummary: true` and `compactMetadata`), so this costs one extra condition, not a new mechanism. It also bounds the read: the slice after the last boundary is a fraction of the file.

A session that is never cleared and only ever compacted is therefore **the normal case, not an edge case**, and it is the case the naive version gets wrong.

---

## Slice 2 — write the trace each rule leaves

Most rules are written as instructions with no stated shape. *"Survey the change sites before writing the plan"* does not say what a reader would see if it had been done.

Each rule in scope gains a line naming its trace **in the sequence of work**:

> a message listing the files to be changed appears **before** the message containing the plan

That is a sequence fact. It is not a quality criterion, and the difference is the whole point: we are not asking whether the survey was good, only whether one happened before the plan. A small model matches that directly.

The census in #159 sorts 126 rules into 33 already machine-decidable, 68 needing a trace, and 25 not decidable from a transcript at any effort. **Only the 68 are in scope.** The 25 get a line saying they are out of scope, because an unmarked gap reads as coverage.

**Those three numbers are inherited, not verified here.** They were taken before the delegation finding below existed, and no one has re-counted them since; treat them as a hypothesis carrying the register they were written in, and make the re-count part of the work rather than a formality after it.

**The census has to be re-cut for delegated work**, and this was not known when it was taken. Nothing a delegate does is written to the master's transcript — measured, 35 `clink` calls and 5 native `Agent` calls this session against zero `isSidechain: true` records in any of the six transcripts in the project directory. A rule whose trace would be produced *inside* the delegate is undecidable here no matter how it is worded, so each of the 68 needs a second question asked of it: **is this trace produced by the master, or by whoever the master handed the work to?** The ones in the second group are rewritten to the part that is the master's — what it put in the delegate's prompt, and what it did with the result — or they move to the undecidable pile with a stated reason.

**Traces do not go in the skill body.** They go in a sibling file that only the reviewer reads. The master gains nothing from a machine-readable trace declaration and would pay for it on every load — and a load is not free: measured on this session, `/tdd` was invoked three times and each invocation re-injected the whole skill, 3,744 / 3,712 / 3,715 bytes. Sixty-eight declarations inline would be charged to the master, repeatedly, for data only the reviewer consumes.

The rule's prose stays where it is; the sibling file references it by id, and a test pins the two together so a rule cannot be reworded out from under its trace.

**And they certainly do not go in `using-t4`**, which is injected verbatim against a 9000-byte budget with roughly 26 bytes spare, with five exact phrases pinned by `tests/hooks/test-dispatcher-content.sh`.

**The seam** is the shipped skill text, as with every `tests/skills/test-*-rule.sh`. A trace that is added and then softened by a later rewrite must fail — so the test needs a negative assertion, not only a positive one.

---

## Slice 3 — check the trace at turn end

A `Stop` hook of `type: "command"` spawns the reviewer **detached** and returns immediately. The reviewer reads the segment — **the slice from the previous `Stop` to this one**, because the developer does not start every turn: 51 task-notification records and 10 `TaskCreate` calls in this session woke the agent to work with no prompt submitted, and those turns are where delegated results land — and asks a **small model**: for each skill invoked, do the traces it declares appear? It writes its verdict to the state file, and the finding is delivered at the **next `UserPromptSubmit`**, which is the moment before the master takes on the next task.

**Nothing waits on it.** The reviewer works while the developer reads and types, so its cost to the developer is zero rather than a few seconds on every turn forever. If the next prompt arrives first, the hook waits a stated fraction of a second and then proceeds without it; the verdict lands one segment later. That placement also ends the race against the transcript writer, which is why the staleness question below is no longer load-bearing.

**It does not run when there is nothing to review.** A segment with no tool use is a question answered, not work done — the precondition is checked in the script, before any model is spawned, so an idle turn costs nothing at all.

**It reads the session history only.** No diff, no test output, no repository access. Both of its inputs are short and fixed — the declared traces and a bounded slice — which is what makes a small model a safe choice rather than a cheap one. It never sees the skill bodies: the traces live in a reviewer-only sibling file (slice 2).

**Adding a `Stop` hook is itself a change site, and this repository guards it.** No `Stop` hook is wired today — `.claude/settings.json` carries `SessionStart`, `UserPromptSubmit` and `PreToolUse` and nothing else — so the new event lands in three files in the same change: the repo's own settings, `hooks/hooks.json` for the plugin, and the bootstrap's `references/hooks/settings.json`. `test-wiring-parity.sh` and `test-bootstrap-sync.sh` fail on any one of them being missed. An unlisted change site is what the survey rule exists to catch, and this plan does not get an exemption from it.

**Both model-calling layers get an off switch, defaulting off.** `.claude/t4.json` already carries `autoMerge` and `requireGreenCI`, so the pattern exists and the marker is already read by every hook. The classifier and the reviewer each get a flag, and each stays off until the baseline says it earns its place. A layer that spends a model call on every turn with no way to stop it short of editing hooks is not something to hand a developer.

**The slice excludes what the hooks themselves wrote.** Hook output is persisted into the transcript — 142 copies of the current reminder's text in this session alone — so an unfiltered reviewer reads its own predecessor's finding inside its segment and either counts it as evidence or raises it again. Filtering `attachment` and hook-written records removes the whole class.

**It does not block.** It raises a finding. The master agent decides whether the finding is correct or the reviewer misread, because the master is the stronger model.

**Two things must be stated plainly rather than implied.** A non-blocking hook **cannot compel an answer** — asking the master to respond is a convention, not a mechanism, and #159's original wording claimed otherwise. And a finding raised on the last turn of a session reaches nobody, so either it is carried forward on the next `UserPromptSubmit` or the design says the final turn is unreviewed.

**A reviewer holds no memory of the previous segment**, which is what bounds its input by the segment rather than the session. The state it must still carry forward — a trace whose halves land in different prompts, an `unknown` the transcript had not yet written, a finding the master overruled — moves through a small schema a script maintains, not through the reviewer's own prose. Design: [`2026-08-13-review-handoff.md`](2026-08-13-review-handoff.md).

**Absence near the tail is never a violation** — and the rule that guarantees it does not rest on a latency figure.

The figure this plan previously quoted (`p50 0.2s`, `p90 15.7s`, 3.2% over a minute, across 7,268 records) measures **the interval between consecutive records** — largely how long turns run and how long the developer is away — **not how far behind the file is when a hook opens it.** It was carried into the design as though it were the second thing. It is not, and it is the second time a number has been used here without checking what it measures; the first was the 108-second claim that #159's correction comment already retracts.

The quantity this design would need is `now − timestamp(last record)`, sampled by a hook on real sessions. **It has never been measured, and the design is built so that it does not have to be.** The transcript is append-only and ordered, so a segment is judged only once its **closing record is present** — and that record's presence proves everything before it is present too. No latency figure enters the argument. If the closing record has not arrived by the time the answer is needed, the verdict is `unknown`, recorded as `unknown`, and re-asked on the next segment — never "no finding", never "violated".

---

## Before any of it: the baseline

**This plan has no success number, and the failure it is fixing is exactly the failure of shipping without one.** The current reminder hook fires on every prompt, its measured effect is zero (#134), and that went unnoticed for a long time because nothing was counted before or after.

So the first work is not slice 0. It is a measurement, and the material for it already exists: six transcripts in this repository's project directory, 12,507 lines.

**It has to be taken twice, because one of the three numbers cannot exist yet.** Trace absence is not measurable before slice 2 declares the traces, so a single "baseline before slice 0" would quietly skip it — and a metric nobody could have taken is worse than one nobody took, because the plan reads as though it were covered.

**Baseline A — before slice 0.** Everything decidable from transcripts as they stand:

- how often a turn's work matched a route and the skill was **not** loaded — the rate slice 1 claims to reduce
- how often the routing decision is wrong or absent, table and classifier counted separately
- the delegation census: how many of the 68 traces are produced by the master and how many inside a delegate

**Baseline B — after slice 2 freezes the trace declarations, before slice 3 is switched on.** Replayed over the same historical transcripts, now that there is something to look for:

- how often a declared trace is absent when the skill was loaded — the rate slice 3 claims to surface
- the reviewer's accuracy against a hand-labelled gold set drawn from those transcripts, **including its false-positive rate**, which is the number that decides whether it may raise a finding at all

Then the matching counts after each slice lands. **A slice that cannot move its own number is not finished, it is unfalsifiable** — and this is a repository whose own rule is that a documented claim without a test is a defect.

---

## What is not known, and will not be assumed

- **Whether a small model matches traces reliably**, and in particular whether it returns `partial` correctly — the verdict the entire cross-segment mechanism rests on. Untested. It must be measured against real sessions before it is allowed to raise a finding at all.
- **The reviewer's false-positive rate.** It is the number that decides whether this layer is usable at all: nothing here blocks anything, so a reviewer that cries wolf has spent the only asset it has. Baseline B measures it; nothing ships past it unmeasured.
- **How well the classifier routes a Thai prompt**, and at what latency. Both are the deciding facts for slice 1's second layer, and neither has been sampled.
- **Whether the master will use the receipt.** `F-019 DISMISS` is checkable once written, but nothing compels it to be written, and an unresolved finding is a legal outcome by design. How often it actually gets used is a fact about behaviour that only real sessions can supply.
- **How far behind the transcript is at read time.** Never measured; see slice 3 for why the design is arranged not to depend on it.
- **Whether `type: "prompt"` or `type: "agent"` works from a plugin's `hooks/hooks.json`.** The vendor reference neither permits nor forbids it. Verified only from a settings file — which is the path `t4-project-bootstrap` writes, so bootstrapped repos are covered either way.
- **Whether a blocking `Stop` hook has a retry ceiling.** Untested, and it only matters if the non-blocking decision is ever revisited.

---

## What this plan does not touch

The four gate bypasses (#83, #84, #126, #141) and the CI tier (#158) are separate tracks. Neither is blocked by this work and this work is not blocked by them.

**And the honest ceiling is unchanged:** #130 is a session where both skills were invoked, both were in context, and the step still never ran. Slice 3 is aimed at exactly that failure and will catch only the part of it that leaves a trace. Nothing here enforces that a rule was followed *well*.

# Review handoff — the state one reviewer leaves for the next

**Component of slice 3 in [`2026-08-13-skill-compliance-plan.md`](2026-08-13-skill-compliance-plan.md), which implements [#159](https://github.com/xenodeve/xeno-skills/issues/159).** That plan says the reviewer runs once per segment with no memory of the last one. This file is how it keeps no memory and still decides correctly.

**Status:** design only. Nothing here is built, and the open questions at the end are not rhetorical.

---

## Why a memoryless reviewer needs anything at all

A **segment** is one unit of review: from a `UserPromptSubmit` record to the `Stop` that ends that turn. A fresh reviewer takes one segment and nothing else, which is what bounds its input by the segment rather than by the session — a master agent at 800k tokens still produces a reviewer input of one segment. That property is the reason a small model is a safe choice here rather than merely a cheap one, and nothing in this file may cost it.

Three things break under that isolation. They look like three problems and are one: **evidence that outlives the segment it appeared in.**

1. **A rule whose trace spans segments.** The plan's own worked example — *a message listing the files to be changed appears before the message containing the plan* — routinely straddles two prompts. Each reviewer sees half. One stays silent, the other accuses.
2. **Evidence not yet written.** The transcript is appended asynchronously, so a reviewer that reaches the tail before the writer does must answer `unknown`. An `unknown` that is never re-asked is a silent pass wearing a hedge.
3. **A finding the master already rejected.** The design gives the master the last word, deliberately, because it is the stronger model. A memoryless reviewer re-raises the same rejected finding every segment — and since nothing here blocks anything, its credibility is the only thing it has to lose.

One mechanism carries all three.

---

## What it borrows from `/handoff`, and what it must not

The idea transfers: **a fresh reader starts at zero, so give it exactly what exists nowhere else, and reference everything that exists somewhere else.** The format must not transfer — `/handoff` is prose written once by a strong model for a human-supervised reader; this is written every segment by a small model for another small model.

| `/handoff` rule | Here |
|---|---|
| Write so a fresh agent can continue | Same. The next reviewer has no memory of any prior segment. |
| Don't duplicate what other artifacts hold; reference by path | **Reference transcript records by line and uuid.** Never quote the work. The transcript is the artifact; this file points into it. |
| Save outside the workspace | `.claude/state/`, gitignored. It is derived state, and a stale copy read as truth is worse than its absence. |
| Redact anything sensitive | Stronger: it carries **no content at all** — no code, no diffs, no message text. Only rule ids, record pointers and verdicts. Redaction becomes structural rather than a judgment the small model has to make. |
| A "suggested skills" section | The **`loaded` set** — which skills the next reviewer is still checking, and from which segment. |
| Prose, written once, by the strongest model in the session | **A fixed schema, written every segment, by a script.** See below. |

---

## The model judges; the script records

**The reviewer never writes this file.** It returns a fixed-shape verdict; the hook script merges that verdict into the file.

That split is the load-bearing decision. A small model writing free text into a file it will re-read twenty segments later is a machine for compounding its own errors — each pass treats the previous pass's guess as an established premise, which is the laundering failure `t4-dev-workflow` names, running unattended in a loop. Keeping the model out of the persistent layer removes the path entirely: it can be wrong about a segment, but it cannot be wrong *cumulatively*.

It is also what makes the file testable. A schema a script writes can be asserted on; prose a model writes can only be read.

---

## Where it lives

`.claude/state/review-<hash of transcript path>.json`

**Keyed on the transcript path the hook is handed, not on a session id.** The path arrives in the hook's own payload, so the key needs no assumption about whether a session id survives a resume or a rename — the question stops being one that has to be answered.

One per session. Gitignored. Removed when its session ends. Never in the workspace and never committed. Written to a temporary file and renamed into place, so a crash mid-write leaves the previous state rather than a truncated file that reads as *no state at all* — which would silently drop every open row.

---

## The file

```json
{
  "version": 1,
  "session_id": "179dfafc-c425-4bb5-8def-273bd8cae7a6",
  "segment": 7,
  "last_boundary_record": 10441,

  "loaded": [
    { "skill": "t4-dev-workflow", "since_segment": 5, "record": 10460, "via": "skill_tool" },
    { "skill": "t4-bro",          "since_segment": 7, "record": 10529, "via": "slash_command" }
  ],

  "pending": [
    {
      "rule": "t4-dev-workflow/survey-before-plan",
      "seen":     [ { "part": "survey", "segment": 5, "record": 10473 } ],
      "awaiting": "plan",
      "expires_after_segment": 9
    }
  ],

  "unknown": [
    {
      "rule": "tdd/red-before-implementation",
      "segment": 6,
      "reason": "segment not closed at read time",
      "recheck_from_record": 10501
    }
  ],

  "dismissed": [
    { "rule": "simplify/after-code-change", "segment": 4, "by": "master", "record": 10488 }
  ]
}
```

Four lists, and each one answers exactly one of the problems above. `loaded` says who is being checked; `pending` carries a half-seen trace across the boundary; `unknown` re-asks what the writer had not yet flushed; `dismissed` remembers what the master overruled.

**`via` exists because there are two ways to invoke a skill and only one of them is obvious.** Measured on this repository's session `179dfafc`, 2026-08-13: `Skill` `tool_use` blocks name 12 distinct skills, while `<command-name>` records name four more that produce no `tool_use` block at all — `/t4-bro` twice, `/handoff` twice, `/to-prd` and `/t4-afk` once each. A detector that greps only `"name":"Skill"` reports `t4-bro` as never loaded in a session that loaded it three times. Both record types count.

---

## Delegated work — what is visible and what is not

**Measured on session `179dfafc`, 2026-08-13:** the master delegated 35 times through `mcp__pal__clink` and 5 times through the native `Agent` tool. **No file under the project's transcript directory contains a single `isSidechain: true` record** — six transcripts, 12,507 lines, zero. The delegate's internal steps are not written anywhere the reviewer can reach, for either channel.

So a rule whose trace would be produced *inside* a delegate — the worker ran the test first, the worker surveyed before editing — is not decidable from the master's transcript at any effort. A reviewer that treats its absence as a violation accuses the master of skipping a step a delegate performed, systematically, in a repository that delegates constantly.

**Two things are visible, and they are the same for both channels:** the prompt the master sent out, and the result that came back. That is enough for the rules that are actually the master's:

- **what the master handed over** — the clink prompt text is a `tool_use` input and is in the transcript verbatim, so *"the worker was given `debug-mantra`"* or *"the worker was told to return a sentinel proving the command ran"* is directly checkable
- **what the master did with what came back** — *"verify everything a subagent returns"* leaves a trace in the master's own segment: a tool call after the result, not a paraphrase of it

**A fifth verdict, `delegated`,** covers the rest. It is neither a pass nor a violation: it records that the trace's site moved outside the transcript, names the delegation record it moved to, and is counted separately. Silence would read as compliance; `violated` would be a false accusation; `delegated` is the true statement.

---

## When the reviewer runs — never while the developer is waiting

The reviewer is spawned at `Stop`, **detached**, and the turn ends immediately. It writes its verdict into the state file. The finding is delivered at the **next `UserPromptSubmit`**, which is the moment before the master takes on the next task — the only moment at which a correction is any use.

That placement is not just a latency saving, though it is that: the reviewer runs during the developer's own reading and typing time, which is dead time, so the cost per turn to the developer is zero rather than a few seconds forever.

**It also disposes of the staleness problem.** The reviewer is no longer racing the transcript writer — it has the whole of the developer's think time, and by the time the next prompt arrives the segment's records are long written. The anchor rule still governs (judge only once the segment's closing record is present), but the case where the wait expires becomes rare rather than routine.

If the developer replies faster than the reviewer finishes, the prompt hook waits a stated fraction of a second, then proceeds without it; the verdict lands one segment later through the same `unknown` carry-forward that already exists. **Nothing blocks on the reviewer, ever.**

## The slice must exclude what the hooks themselves wrote

Hook output is persisted into the transcript — measured, 142 copies of the current reminder's text in this one session. Left unfiltered, each reviewer reads the previous reviewer's finding inside its own segment and either counts it as evidence or raises it again.

**Filter by record type before the slice reaches the model:** `attachment` records and hook-injected context are the system talking to itself, not the master doing work. This is a two-line filter and an entire class of self-contamination.

---

## What the reviewer receives, and what it returns

**Receives exactly three things.** No repository access, no diff, no test output — the constraint from #159's correction, unchanged:

1. this file,
2. the transcript slice for its own segment,
3. the declared traces of the skills in `loaded`.

**Returns one fixed shape**, per rule it evaluated:

```json
{ "rule": "...", "verdict": "satisfied | violated | partial | delegated | unknown",
  "evidence": [ { "record": 10473, "uuid": "..." } ],
  "awaiting": "plan" }
```

The declared traces are **not** read out of the skill body. They live in a sibling file the reviewer alone reads, because the master would otherwise pay for them on every load — and a load is not free: `/tdd` was invoked three times in this session and each invocation re-injected the full skill, 3,744 / 3,712 / 3,715 bytes.

`partial` is the verdict that makes cross-segment rules work: it says *this much appeared, this much has not yet*, and the script turns it into a `pending` row. Without it the reviewer must choose between a false pass and a false accusation on every straddling rule.

---

## The write rules

**1. Only five transitions are legal.** `pending` → satisfied (row removed) · `pending` → violated (row removed, finding emitted) · a new `pending` added · `unknown` → re-evaluated · a finding → `dismissed`. The reviewer cannot edit a prior row, so an earlier segment's verdict is never rewritten by a later one's guess.

**2. Every row cites a record.** Line number and uuid. The next reviewer can then *check* the claim rather than inherit it — the register rule from `t4-dev-workflow` applied to the reviewer itself: a claim's register does not improve by being carried forward.

**3. The file does not grow with the session.** One row per open trace, not one per segment. Closed traces are deleted, not archived. Cap `pending` at a stated number; on overflow the oldest row expires to `unknown` and is **logged** — a silently dropped row would read as coverage that never happened.

**4. Every `pending` row expires.** `expires_after_segment` is set when the row is created. At expiry it becomes a finding or an `unknown` — never nothing. Otherwise *awaiting: plan* sits open forever and no rule ever concludes.

**5. A `dismissed` rule is not re-raised for the rest of the task.** This is the only rule whose purpose is the master's trust rather than correctness, and it is the one most likely to be dropped as an optimisation.

---

## Lifecycle — one worked example

The rule is *survey before plan*, and the work takes three prompts.

**Segment 5.** The master lists the files it will change. Reviewer 5 sees the survey and no plan, and returns `partial` with `awaiting: "plan"`. The script writes one `pending` row citing record 10473, expiring after segment 9.

**Segment 6.** The master is still reading code. Reviewer 6 receives the `pending` row, finds nothing bearing on it, and returns nothing. The row is untouched — *no news is not a verdict*.

**Segment 7.** The master writes the plan. Reviewer 7 sees the plan, sees the `pending` row saying the survey was already observed at 10473, and returns `satisfied`. The script deletes the row. **No finding is raised, and that is the correct outcome** — which a per-segment reviewer without this file could not have reached from either half alone.

**The failure branch:** at segment 7 the plan appears and there is no `pending` row. Then the survey did not happen before the plan, and *that* is the finding — which is only a sound conclusion because the absence of the row is itself evidence the script maintains, rather than something the reviewer failed to remember.

---

## What this design accepts rather than solves

- **A rule can still straddle a compaction boundary.** The boundary resets `loaded`, deliberately: what the harness carries across a compaction is **truncated** — measured on this session, `clink-subagents` and `clink-brainstorm` returned cut mid-file — and truncation removes the end of a skill, where several of ours keep their rules. A skill that looks present may be missing exactly the section under test, so a carry is not a load. `pending` rows survive the boundary; the skills they belong to may not, in which case those rows expire to `unknown` and say so.
- **Findings on the final segment of a session reach nobody.** Either the next `UserPromptSubmit` carries them, or the design states plainly that the last turn is unreviewed. Silence is not an option here.
- **The master is never compelled to answer a finding.** A non-blocking hook cannot compel a response — stating otherwise is the fictional enforcement `docs/adr/0001` warns about, and #159's first draft did exactly that.

---

## Seams and tests

The seam is the merged file, exactly as every suite in `tests/hooks/` asserts on a hook's emitted JSON.

- each of the five legal transitions, one case apiece
- an illegal transition (a reviewer verdict that would rewrite a prior row) → rejected, file unchanged
- a missing, empty or corrupt state file → treated as empty, exit 0, no finding
- the `pending` cap → oldest expires to `unknown` **and the drop is logged**
- an expired row → becomes a finding or an `unknown`, never silently vanishes
- a `dismissed` rule → not re-emitted on a later segment
- a skill invoked as a slash command → appears in `loaded` with `via: "slash_command"`
- a segment containing a delegation → the delegated rule returns `delegated`, never `violated`
- a segment containing hook-injected text that names a rule → filtered out, no verdict derived from it
- a reviewer that has not finished when the next prompt arrives → the prompt is not blocked, the row carries forward
- an interrupted write → the previous state survives intact, never a truncated file
- file size across a long synthetic session → bounded, asserted as a number rather than described

---

## Not known, and not assumed

- **Whether a small model returns `partial` reliably.** It is the verdict the whole cross-segment mechanism rests on, and it is the subtlest of the four. Untested. It has to be measured against real transcripts before the reviewer is allowed to raise anything.
- **What the transcript's staleness actually is at read time.** The figure quoted in the plan (3.2% of gaps over 60s) measures the interval between consecutive records — largely how long turns and idle periods are — not how far behind the file is when a hook opens it. The quantity this design needs is `now − timestamp(last record)`, sampled by a hook on real sessions. It has not been measured. **Until it is, the anchor rule stands on its own:** a segment is judged only once its closing record is present, because the file is append-only and ordered, so that record's presence proves everything before it is there. That argument does not depend on any latency figure — which is the reason to prefer it.
- **The right value for the `pending` cap and for `expires_after_segment`.** Both are policy, both need real sessions, and a guessed number written as though it were derived is the failure this section exists to prevent.

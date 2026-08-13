# Review handoff — the state one reviewer leaves for the next

**Component of slice 3 in [`2026-08-13-skill-compliance-plan.md`](2026-08-13-skill-compliance-plan.md), which implements [#159](https://github.com/xenodeve/xeno-skills/issues/159).** That plan says the reviewer runs once per segment with no memory of the last one. This file is how it keeps no memory and still decides correctly.

**Status:** design only. Nothing here is built, and the open questions at the end are not rhetorical.

---

## Why a memoryless reviewer needs anything at all

A **segment** is one unit of review: **from the previous `Stop` to this `Stop`.**

The obvious definition — from a `UserPromptSubmit` to the `Stop` that ends that turn — is wrong, and measurably so. **The developer does not start every turn.** Measured on session `179dfafc`: 51 task-notification records and 10 `TaskCreate` calls, each of which wakes the agent to work with no prompt submitted. Under the prompt-to-stop definition those turns are either never reviewed or their records are attached to the previous segment, and they are not idle turns — they are where delegated results land and get acted on. Anchoring on `Stop` at both ends covers both cases with no special-casing, because every turn ends the same way regardless of what began it.

A fresh reviewer takes one segment and nothing else, which is what bounds its input by the segment rather than by the session — a master agent at 800k tokens still produces a reviewer input of one segment. That property is the reason a small model is a safe choice here rather than merely a cheap one, and nothing in this file may cost it.

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
| A "suggested skills" section | The **`active` set** — which skills the next reviewer is still checking, and from which segment. |
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

  "active": [
    { "skill": "t4-dev-workflow", "since_segment": 5, "record": 10460, "via": "skill_tool",
      "skill_sha": "8c72a1f", "trace_schema": 3 },
    { "skill": "t4-bro",          "since_segment": 7, "record": 10529, "via": "slash_command",
      "skill_sha": "d41e903", "trace_schema": 3 }
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

  "resolved": [
    { "finding": "F-019", "rule": "simplify/after-code-change", "decision": "dismiss",
      "by": "master", "segment": 4, "record": 10488 }
  ]
}
```

Four lists, and each one answers exactly one of the problems above. `active` says who is being checked; `pending` carries a half-seen trace across the boundary; `unknown` re-asks what the writer had not yet flushed; `resolved` remembers what the master decided.

**`skill_sha` and `trace_schema` are not bookkeeping.** A skill can be edited mid-session — this repository edits its own skills constantly — and without them a reviewer at segment 6 checks version B's declared traces against behaviour produced under version A. Recording which version was loaded makes the check deterministic and makes a mismatch visible instead of silent: when the sha of the loaded skill differs from the sha the traces belong to, the verdict is `unknown` with that reason, not a finding.

### `active` expires — it is not "everything this session loaded"

The list is named `active`, not `loaded`, because the invariant is the point:

> **active for segment N = skills invoked or routed in segment N + skills referenced by an open `pending` row + skills referenced by an open `unknown` row.**

At the end of each segment, any skill with no open row is dropped. **Nothing stays in scope merely because it was once invoked.**

Without this the isolation is decorative: a session that used `tdd` at segment 5, `design` at 8 and `debug-mantra` at 15 would have its segment-15 reviewer still holding all three, and the reviewer's input would grow with the **age of the session** — exactly the property the per-segment design exists to prevent. With it, the input grows only with **work that has not finished**, which is bounded by how much the master leaves open, not by how long anyone has been working.

**`via` exists because there are two ways to invoke a skill and only one of them is obvious.** Measured on this repository's session `179dfafc`, 2026-08-13: `Skill` `tool_use` blocks name 12 distinct skills, while `<command-name>` records name four more that produce no `tool_use` block at all — `/t4-bro` twice, `/handoff` twice, `/to-prd` and `/t4-afk` once each. A detector that greps only `"name":"Skill"` reports `t4-bro` as never loaded in a session that loaded it three times. Both record types count.

---

## Delegated work — the two channels are not alike, and an earlier draft of this file got it wrong

**Correction, recorded rather than quietly edited.** An earlier version of this section stated that a delegate's internal steps reach no file the reviewer can read, for either channel. It was concluded from a listing that did not descend into subdirectories, and it is **false for native subagents**. The measurement below replaces it.

**Native subagents are fully readable.** Measured on session `179dfafc`, 2026-08-13:

```
projects/<slug>/<session_id>.jsonl                          the master, 10,517 lines
projects/<slug>/<session_id>/subagents/agent-<id>.jsonl     one per Agent call — 5 files, 20-90 lines
projects/<slug>/<session_id>/subagents/workflows/wf_*/      workflow agents, same shape
```

Each file carries `isSidechain: true`, an `agentId`, the full prompt the master sent, and every tool call the delegate made — one of the five shows 11 `Read` calls and a `Glob`. **The join needs nothing invented:** the same `agentId` appears in the master's transcript, five distinct ids for five `Agent` calls, and it is also the filename. A reviewer that meets a delegation in its segment follows the pointer and reads the delegate's own record, and the read stays cheap — the largest of the five is 90 lines against the master's 10,517.

**So for native delegation the segment extends through the pointer, and `delegated` does not apply.** The rules keep their ordinary verdicts; the evidence simply lives one file over. Which side of the boundary each trace was produced on is recorded, because *"the worker ran the test first"* and *"the master ran the test first"* are different facts and only one of them is the master's.

**clink is different, but far less blind than an earlier draft of this file claimed** — and *"and stays one"* was wrong outright, because PAL is ours. 35 of this session's 40 delegations went through `mcp__pal__clink` to a foreign CLI — `codex`, `cursor`, `antigravity` — each its own product running its own process, so what the worker did in private is not written under `.claude/`. That much holds. What does not hold is the conclusion that the boundary therefore carries little.

**The single most load-bearing clink rule is a fact about the master's own prompt, and it is in the transcript verbatim.** `clink-subagents:140` requires the master to hand the worker its skills — `karpathy-guidelines` on every call, `tdd` whenever the worker writes code — and `clink-brainstorm:243` names pasting the skill's content directly into the prompt as the reliable method, with the absolute-path form at `:249` as the alternative. Either way **the handoff is inside the `tool_use` input**, which means:

- *was the worker given `karpathy-guidelines`* → a string match on a record the harness wrote
- *was it given `tdd` on a call that changed code* → the same, conditioned on the same record
- *was it given the current version* → the pasted content can be hashed against the shipped file, so a stale paste is detectable, not merely present

That is the strongest class of trace this design has — deterministic, no model, nothing to hallucinate — and it lands on exactly the rule that decides whether the delegate had any discipline at all. **A whole family of rules that looked undecidable is decidable at the top tier, because the skill handoff is the master's action, not the worker's.**

**What is visible at the clink boundary**, then, is three things, all in the master's own transcript:

- **which skills the worker was handed** — pasted content or absolute path, both inside the `tool_use` input; and for a bug hunt, whether `debug-mantra` went with it, which `clink-debug` requires of every Observe and Falsify seat
- **what discipline the prompt imposed** — the sentinel a worker can only produce by having run the command; and whether a falsify or repair seat got a **fresh `continuation_id`**, which `clink-debug`'s provenance rule requires and which is a parameter on the call, therefore a fact about the call
- **what the master did with what came back** — *"verify everything a subagent returns"* leaves a trace in the master's own segment: a tool call after the result, not a paraphrase of it

**A fifth verdict, `delegated`, and it narrows to what the worker did in private.** Not to the clink call as a whole — the three facts above are ordinary verdicts. `delegated` records that *this particular trace's* site left the readable surface, names the record it left at, and is counted, so the blind spot is a number rather than a silence. Silence would read as compliance; `violated` would be a false accusation; `delegated` is the true statement.

**And that residue is the same ceiling the master already has.** Whether a worker followed a skill it was handed is exactly the question #130 leaves open about the master itself — a skill invoked, in context, and the step still not run. It is not a clink weakness; it is the honest limit of the whole approach, showing up one level down.

### A reviewer inside clink — the tier that closes the residue

The residue above is *whether the worker followed what it was handed*, and it is only unreachable because nothing inside the delegation is watching. **PAL can put something there**, and the shape mirrors the tiers that already exist: the master has a reviewer, so the clink worker gets one too, and the two reviewers talk.

```
masteragent            ── reviews ──>  master-side reviewer   (segment, per Stop)
    │ delegates                              ▲
    ▼                                        │ compliance record
clink worker           ── reviews ──>  clink-side reviewer    (inside the delegation)
```

The clink-side reviewer answers one narrow question and reports it upward: **did the worker follow the skills it was handed, how many times was it corrected, and what were the corrections?** It may object to the worker in-thread and let it fix the work; what it may not do is decide anything. The record returns with the result, the master-side reviewer reads it as ordinary evidence in its segment, and **the masteragent judges** — including judging the clink reviewer wrong. If the worker still did not comply, that is the master's problem to solve, which is where it belonged all along.

**PAL must return the record as data, not prose**, because it is consumed by a script and then by a small model:

```json
{ "skills_handed": ["karpathy-guidelines", "tdd"],
  "verdicts": [ { "skill": "tdd", "followed": false,
                  "observed": "edited src/x.ts at event 41; no test file written before it" } ],
  "corrections": 2,
  "final": "complied | not-complied | unknown",
  "reviewer": { "cli": "cursor", "model": "...", "continuation_id": "fresh" } }
```

**The deciding constraint is what the reviewer can actually see, and it differs per client — verified in the PAL source, not assumed.** `clink/parsers/codex.py`, `claude.py` and `opencode.py` each retain the worker's full event stream in `metadata["events"]`. `cursor` and `antigravity` both run the `antigravity_text` parser, which keeps none — cursor has no parser module of its own at all — so those two carry **final text only**.

**And on no client does the stream reach the master today**: `_prune_metadata` strips `events` from every response before it leaves the tool. That is why this reviewer belongs *inside* PAL rather than in the hook layer — see the section below.

That split decides where this tier is real:

- **codex, claude, opencode** — the reviewer reads what the worker *did*. A genuine trace, and the same class of evidence the master-side reviewer works from.
- **cursor, antigravity** — the reviewer can read only what the worker *said about itself*. That is a self-report, and reviewing it produces a verdict about a claim.

**On those two clients this tier must not be built as-is, and the reason is not fastidiousness.** `docs/adr/0001` warns about a receipt the agent authors itself; wrapping a self-report in a review loop does not fix that, it **launders** it — the same failure `clink-debug` names, where ceremony manufactures confidence the process never earned. A verdict that arrives with a reviewer's name on it is harder to reopen than a bare claim. So either the client's parser is extended to retain events first, or its record is returned with `final: "unknown"` and a stated reason.

**Three rules the tier has to carry**, all of them ours already:

- **Provenance.** The reviewer seat is a **fresh `continuation_id`**, and a different client where the lane allows it. A worker asked to review itself defends itself; `clink-debug` says this about falsify seats and it is the same seat here.
- **Observation travels with the verdict.** Every entry carries what was seen — the event, the quote — not only the judgment. Without it the master cannot disagree, and a tier the master cannot overrule is not advisory, whatever the document says.
- **Bounded.** It runs only on delegations that were handed skills, correction rounds are capped at a stated number, and the reviewer takes the cheap house lane. A clink call already costs 20–530 seconds; an unbounded review loop multiplies the slowest thing in the system.
- **It never stands between the master and its work.** Delegation is a main path here — 35 of this session's 40 — so a review loop wrapped *around* the return would put the slowest, newest and least proven component directly in front of the work the developer is waiting for. The worker's result goes back the moment it is ready; the review runs alongside and its record arrives when it arrives, late or not at all. **A reviewer that can stall the main path is a worse failure than the drift it was built to catch**, and the same rule already governs the master-side reviewer for the same reason.

### The boundary is ours to change — PAL is developed alongside this repo

The fork at `xenodeve/pal-mcp-server` is the same project's other half, so *"a foreign CLI writes formats we cannot depend on"* is a statement about today's implementation, not a constraint. Two changes there would move clink from *boundary-readable* to *first-class*:

**The trace already exists and is discarded at the last step.** `tools/clink.py:690` — `_prune_metadata` drops `events`, `raw` and `raw_events` from every response, success and error alike, leaving `events_removed_for_normal: true` in their place. It is deliberate and correct as a caller-facing decision: those fields passed through no size bound at all, so a large CLI response was capped in the field a caller reads and unbounded in the field beside it (#37).

**So the worker's event stream is present inside PAL and never reaches the master.** That does not weaken the case for the reviewer tier — it decides *where* it belongs. **The reviewer runs inside PAL, before the prune**, consuming the events at the one point they exist, and what crosses to the master is the small structured record rather than the stream. #37's bound is untouched, because nothing unbounded moves.

### Most of this is already tracked there, and this plan should have checked first

**The survey rule applies to another repository's tracker as much as to this one's, and it was not run before the pieces above were proposed.** `pal-mcp-server` carries epic **#11** — *supervised subagent sessions: master-approved permissions and evidence-based liveness* — with phases **#14** (per-client trust at spawn), **#15** (supervised session: non-blocking call, registry, evidence-based status) and **#16** (interrupt-and-resume per-action approval), plus the Phase 0 spike **#12** and its report, `docs/reports/2026-08-04-clink-phase0-spike-host-followup-and-cli-capability.md`.

**#16 is the same machinery as the reviewer tier above, for a different purpose.** It exists so the master can approve or deny one privileged action; this exists so a reviewer can see whether a skill was followed. Both need the identical seam: a control endpoint the child's hook can reach, a session registry with an `awaiting_decision`-shaped state, resume by the **CLI's own session identifier**, and a per-client capability gate. **So the reviewer is a sibling deliverable of epic #11, not a parallel track**, and it inherits #16's blocking status: *gated, do not start* until #12 returns.

It also inherits the two hazards that epic already names, and neither had occurred to this design:

- **The orphan hazard.** A subagent orphaned by a transport timeout may still be running; resuming its session identifier while it is alive puts two processes on one session state. #16 calls it the epic's highest-risk item. A review loop that resumes a worker to correct it is exposed to exactly this.
- **Silent no-op across clients.** #12's capability table shows a blocking pre-tool hook proven on **Claude Code alone** — `codex` has hooks whose event vocabulary is unverified, `cursor` advertises none locally, `agy`'s route is speculative. #11 story 24 already requires a per-client capability probe. This matches the conclusion reached independently above, and #12 got there first.

**What is genuinely new, and cheap, and blocked by none of it:**

1. **Consume the events before they are pruned.** The data is already assembled; this is one hook point ahead of an existing function. Covers `codex`, `claude` and `opencode`, whose parsers retain `events` today. Independent of the #11 chain.
2. **A `skills` parameter** so the master names the skills and the server resolves, attaches and records them — the handoff becomes a structured fact with the version recorded rather than inferred from a hash. Independent of the #11 chain.
3. **Event retention for `cursor` and `antigravity`** — both run `antigravity_text` (`clink/constants.py:55,65`), which keeps nothing, and cursor has no parser module of its own. This is a precondition for the reviewer on those two clients, and until it lands they must return `final: "unknown"` rather than a laundered verdict.

**A fourth idea from an earlier draft — a call log in our own format — is largely #15's registry** and should be raised there rather than filed again.

**One more from the same report that this design would otherwise have walked into:** `agy --print-timeout` defaults to **5 minutes**, inside clink's 1800 s child timeout, so an antigravity run can be cut by the CLI itself — tracked as **#65**. Any review loop that lengthens a delegation meets that ceiling first on that client.

**All of it belongs in that repository's tracker, and the first action there is to read #11 and #12 rather than to file anything.** They are a separate track with a separate review, and naming them here is the point at which this design stops treating the clink wall as given. Until one of them lands, the string match on the pasted prompt is the mechanism, and it is a good one.

### Five constraints from the PAL code scan that this design must respect

A twelve-reader scan of the PAL fork was recorded on 2026-08-13 as [`pal-mcp-server/docs/reports/2026-08-13-deep-scan-architecture-safety-and-direction.md`](https://github.com/xenodeve/pal-mcp-server/blob/main/docs/reports/2026-08-13-deep-scan-architecture-safety-and-direction.md). Five findings bear directly on the reviewer tier, and each changes something above rather than merely informing it.

- **The clink timeout cannot report.** `clink/agents/base.py:284-292` wraps `communicate()` in `wait_for`, then on timeout calls `process.kill()` and awaits `communicate()` again **with no deadline** — and a grandchild inheriting the stdout pipe makes that second call never return, so `CLIAgentError("timed out")` is never raised. **A review loop that lengthens a delegation is stacked on a timeout that does not fire.** The bound has to come from the reviewer's own budget; PAL's cannot be relied on until that is fixed.
- **The reviewer must not be a synchronous provider call.** The scan's largest event-loop finding is not in clink at all: `provider.generate_content(...)` is a plain synchronous HTTP call from an `async def execute` (`tools/simple/base.py:444`, plus three more sites), freezing the loop for the whole round trip. A reviewer implemented that way would stall every other in-flight delegation. It has to be a subprocess or an offloaded call.
- **There is no concurrency control of any kind** — no semaphore, queue or admission cap anywhere in production code — so a tier that adds a second call per delegation doubles an unbounded number, not a bounded one.
- **Read the events, never the stored turn.** clink writes the **post-limit** text into conversation memory (`tools/clink.py:343-347, 367`), so a 25,000-character answer leaves the thread holding only its `<SUMMARY>` block. The stored turn is a lossy copy carrying no marker that it is one; the reviewer's evidence must come from the event stream, before the prune.
- **PAL's threads die with the client session.** Storage is a process-local dict and the transport is stdio, so the server is a subprocess of the host. There is no persistence in PAL to build reviewer state on — which is why the state in this document lives on our side.

**And one that changes the enforcement story rather than the design:** `clink` advertises `readOnlyHint: True` (`tools/clink.py:156-157`) while its shipped configs launch foreign agents with approvals bypassed. A host that auto-approves on that annotation is auto-approving arbitrary execution — so the delegation path the master uses most is the one carrying the least host-side scrutiny.

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
3. the declared traces of the skills in `active`, at the sha those skills were loaded at.

**Returns one fixed shape**, per rule it evaluated:

```json
{ "rule": "...", "verdict": "satisfied | violated | partial | delegated | unknown",
  "evidence": [ { "source": "master", "record": 10473, "uuid": "..." },
                { "source": "agent-a287239d03a82fc75", "record": 12 } ],
  "awaiting": "plan" }
```

**`source` names which transcript the evidence came from** — the master, or a native subagent followed through its `agentId`. Without it a trace produced by a delegate and a trace produced by the master are indistinguishable in the record, and the distinction is the whole point of following the pointer.

The declared traces are **not** read out of the skill body. They live in a sibling file the reviewer alone reads, because the master would otherwise pay for them on every load — and a load is not free: `/tdd` was invoked three times in this session and each invocation re-injected the full skill, 3,744 / 3,712 / 3,715 bytes.

`partial` is the verdict that makes cross-segment rules work: it says *this much appeared, this much has not yet*, and the script turns it into a `pending` row. Without it the reviewer must choose between a false pass and a false accusation on every straddling rule.

---

## The write rules

**1. Only five transitions are legal.** `pending` → satisfied (row removed) · `pending` → violated (row removed, finding emitted) · a new `pending` added · `unknown` → re-evaluated · a finding → `dismissed`. The reviewer cannot edit a prior row, so an earlier segment's verdict is never rewritten by a later one's guess.

**2. Every row cites a record.** Line number and uuid. The next reviewer can then *check* the claim rather than inherit it — the register rule from `t4-dev-workflow` applied to the reviewer itself: a claim's register does not improve by being carried forward.

**3. The file does not grow with the session.** One row per open trace, not one per segment. Closed traces are deleted, not archived. Cap `pending` at a stated number; on overflow the oldest row expires to `unknown` and is **logged** — a silently dropped row would read as coverage that never happened.

**4. Every `pending` row expires.** `expires_after_segment` is set when the row is created. At expiry it becomes a finding or an `unknown` — never nothing. Otherwise *awaiting: plan* sits open forever and no rule ever concludes.

**5. A dismissed finding is not re-raised for the rest of the task.** This is the only rule whose purpose is the master's trust rather than correctness, and it is the one most likely to be dropped as an optimisation. It requires a receipt — below.

**6. At most one finding is delivered per turn.** A segment can fail several traces at once, and injecting all of them turns a correction into a wall of text that gets skimmed. Rank by the position of the missing step in the workflow, deliver the earliest, and leave the rest as `pending` rows. If the earliest one was a misread, the master says so and the next reviewer moves on to the second; if it was real, fixing it usually resolves the rest anyway.

---

## The finding must be resolved by a receipt, not by prose

Rule 5 needs the script to know that the master decided. **It must never infer that from natural language** — *"this one isn't right, because…"* is a sentence a classifier would have to judge, which puts a model back in the persistent layer that this design just removed it from.

So a finding is delivered with an id, and the master resolves it with a stated, checkable action:

```
F-019 DISMISS  reason: the survey is in the issue body, not the transcript
F-019 ACCEPT
```

The script greps for the id and the verb. That is a deterministic check on a record the harness wrote, in the same class as the skill-invocation check that the whole plan rests on — no model, nothing to hallucinate, and the transcript carries the receipt:

```json
{ "finding": "F-019", "decision": "dismiss", "by": "master", "record": 10882 }
```

**This is also what makes the authority real rather than rhetorical.** The design says the reviewer may object and the master decides. Without a receipt the objection has no terminating state: the master ignores it, the reviewer raises it again, and the loop ends only when someone turns the reviewer off. With one, the cycle closes — reviewer objects, master considers, master resolves, script records — and the master's decision is the thing that ends it.

**Silence is a legal outcome and must be named as one.** A non-blocking hook cannot compel a resolution, so a finding with no receipt after a stated number of segments expires as `unresolved` and is counted. It is not re-raised, and it is not recorded as agreement.

---

## Lifecycle — one worked example

The rule is *survey before plan*, and the work takes three prompts.

**Segment 5.** The master lists the files it will change. Reviewer 5 sees the survey and no plan, and returns `partial` with `awaiting: "plan"`. The script writes one `pending` row citing record 10473, expiring after segment 9.

**Segment 6.** The master is still reading code. Reviewer 6 receives the `pending` row, finds nothing bearing on it, and returns nothing. The row is untouched — *no news is not a verdict*.

**Segment 7.** The master writes the plan. Reviewer 7 sees the plan, sees the `pending` row saying the survey was already observed at 10473, and returns `satisfied`. The script deletes the row. **No finding is raised, and that is the correct outcome** — which a per-segment reviewer without this file could not have reached from either half alone.

**The failure branch:** at segment 7 the plan appears and there is no `pending` row. Then the survey did not happen before the plan, and *that* is the finding — which is only a sound conclusion because the absence of the row is itself evidence the script maintains, rather than something the reviewer failed to remember.

---

## What this design accepts rather than solves

- **A rule can still straddle a compaction boundary.** The boundary clears `active`, deliberately: what the harness carries across a compaction is **truncated** — measured on this session, `clink-subagents` and `clink-brainstorm` returned cut mid-file — and truncation removes the end of a skill, where several of ours keep their rules. A skill that looks present may be missing exactly the section under test, so a carry is not a load. `pending` rows survive the boundary; the skills they belong to may not, in which case those rows expire to `unknown` and say so.
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
- a skill invoked as a slash command → appears in `active` with `via: "slash_command"`
- a turn opened by a task notification rather than a prompt → still forms a segment, still reviewed
- a skill with no open `pending` or `unknown` row → dropped from `active` at segment end
- a skill edited mid-session → sha mismatch resolves to `unknown`, never to a finding
- `F-019 DISMISS` in the transcript → the finding is not re-raised; no receipt after the stated span → expires `unresolved` and is counted, not treated as agreement
- two traces failing in one segment → exactly one finding delivered, the other left `pending`
- a segment containing a **native** delegation → the `agentId` is followed, the subagent file is read, evidence carries `source: agent-<id>`
- an `agentId` in the segment with no matching file → `unknown`, never a finding
- a segment containing a **clink** delegation → `delegated`, never `violated`, and counted
- a segment containing hook-injected text that names a rule → filtered out, no verdict derived from it
- a reviewer that has not finished when the next prompt arrives → the prompt is not blocked, the row carries forward
- an interrupted write → the previous state survives intact, never a truncated file
- file size across a long synthetic session → bounded, asserted as a number rather than described

---

## Not known, and not assumed

- **Whether a small model returns `partial` reliably.** It is the verdict the whole cross-segment mechanism rests on, and it is the subtlest of the four. Untested. It has to be measured against real transcripts before the reviewer is allowed to raise anything.
- **What the transcript's staleness actually is at read time.** The figure quoted in the plan (3.2% of gaps over 60s) measures the interval between consecutive records — largely how long turns and idle periods are — not how far behind the file is when a hook opens it. The quantity this design needs is `now − timestamp(last record)`, sampled by a hook on real sessions. It has not been measured. **Until it is, the anchor rule stands on its own:** a segment is judged only once its closing record is present, because the file is append-only and ordered, so that record's presence proves everything before it is there. That argument does not depend on any latency figure — which is the reason to prefer it.
- **The right value for the `pending` cap and for `expires_after_segment`.** Both are policy, both need real sessions, and a guessed number written as though it were derived is the failure this section exists to prevent.

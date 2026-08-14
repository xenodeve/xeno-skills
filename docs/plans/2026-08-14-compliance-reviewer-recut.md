# The compliance reviewer, re-cut against the measured hook surface (2026-08-14)

Supersedes the architecture in `2026-08-13-skill-compliance-plan.md` where they disagree. It does not
supersede that plan's *rules* — what the reviewer judges is unchanged.

**Evidence:** `docs/research/2026-08-14-compliance-hook-surface-across-harnesses.md`. Every capability
claim below is live-graded there.

**Judged by a three-seat panel** (`gpt-5.6-sol` medium · `Gemini 3.1 Pro (High)` · `cursor-grok-4.5-high`)
after two of the previous panel's premises were falsified: agy *does* have a mid-turn channel, and *all
four* hosts block the turn while a hook runs, not only agy.

## The finding that reorganises the plan

**A hook is a synchronous barrier on every host.** Measured in-run, so model latency cannot confound it:
Claude Code delayed a tool by 22 s for a 21 s hook, codex by 21 s for 20 s, cursor's turn grew 24.9 s,
and agy's is capped only by a 30 s per-handler timeout.

**Therefore no reviewer model call may run inside a hook — on any host, including Claude Code's own cheap
native evaluator.** All three panellists reached this independently. The previous design put the
judgement in a `Stop` prompt hook; that is a model call on the critical path, and the fail-open principle
does not survive it.

**Principle 1 stops being a rule and becomes a mechanism:**

| Component | Where it runs | Latency budget |
|---|---|---|
| **Evidence capture** | inside the hook | milliseconds — write, do not read back |
| **Judgement** | a detached worker in the MCP server | unbounded; nothing waits on it |
| **Delivery** | inside the hook | milliseconds — one file stat and read |

A hook that finds no ready verdict returns immediately. A crashed, slow or absent reviewer therefore
costs the developer nothing, which is what the principle actually asked for.

**The cost of a hook invocation is not zero, and now has a number.** A no-op `PostToolUse` hook across
five tool calls added **2.56 s** — about **0.5 s per invocation**. That is the budget the delivery hook
has to fit inside, and it is why the batch question below is a real question.

## What the panel converged on, 3 of 3

- **No model call in a hook.** Above.
- **Phase 1 first**, unchanged from the previous panel, and for the same reason: a reviewer on a dead
  wire is worse than no reviewer, and silent death is now measured on every host.
- **Keep cursor in v1** — and all three rejected the framing that a pre-action-gate-only reviewer is
  degraded. *"Process compliance inherently polices actions; a pre-action gate is the optimal
  intervention point because it prevents the side-effect before it occurs."* What must be labelled
  honestly is the *semantics*, not the host.
- **Next-turn delivery is legitimate — and becomes a rationalisation the moment it is sold as
  prevention.** Two of three said this in almost the same words. The plan must say *retrospective
  enforcement with bounded delay*, and reserve same-turn prevention for deterministic checks that need
  no model.

## Where they split: the undocumented batch event

Claude Code has an undocumented per-batch event — three tool calls produced three per-call firings and
**one** batch firing.

| Seat | Position |
|---|---|
| Gemini | **refuse it** — async delivery removes the performance problem it solves, so it buys fragility for nothing |
| Grok | **take the saving**, pinned by the Phase 1 detector, falling back to the documented event on a miss |
| GPT-5.6 | **never a required dependency** — and it is the *wrong* enforcement point regardless of cost, because it cannot fire on a tool-free turn and an end-of-turn verdict has no already-finished batch to attach to |

**Resolution.** Gemini's premise is wrong on the measurement: at 0.5 s per invocation a twenty-call turn
pays about ten seconds, which is not nothing. But GPT-5.6's objection is independent of cost and
decides it. **Use the batch event as a delivery optimisation where it fires, always with the documented
per-call event as the fallback, and never as the only path** — because a turn with no tool calls at all
must still be reachable.

## The gap all three found, from three directions

None of them named the same thing, and the three compose into one missing component.

- **Gemini:** the plan never says how the server **assembles session context**. Hooks deliver localised
  payloads; judging a *sequential* rule needs a stitched chronological transcript.
- **GPT-5.6:** there is no **objection receipt protocol** — nothing proves the right verdict reached the
  right agent. It asks for a durable state machine with deduplication, expiry, restart recovery,
  final-turn carry-forward and fail-open corruption handling.
- **Grok:** the same machine, named as a missing **Phase 1.5**, plus the mechanism that makes
  retrospective enforcement bite — **sticky unpaid debt** that gates the *next* action rather than
  blocking the turn that produced the finding.

**So: `evidence → verdict → delivery → consumption` has no specified state between its arrows, and that
is the plan's real hole.** Grok's TOCTOU example is the sharpest statement of why it matters: for *write
the failing test first*, a next-turn verdict arrives after the code exists. Sticky debt gating the next
write or PR is what converts a late finding into enforcement instead of a complaint.

## Phases

**Phase 1 — capability and compulsory-read canary.** A config generator emitting only allowlisted event
names and handler types per host, reading its own bytes back to compare. A detector requiring **three**
observations, not two: the hook fired, the evaluator ran, **and a synthetic verdict was delivered and
observed being consumed**, then cleared. Per-host, and a host that fails its canary is disabled without
delaying the session.

**Phase 1.5 — the verdict state machine.** Latency budget, verdict store, one-shot delivery tokens,
expiry, restart recovery, sticky debt. **Before any host wiring**, because Phase 2 without it puts the
model back in-band.

**Phase 2 — per-host delivery adapters.** Claude Code: batch event with per-call fallback. codex:
replace the tool result. cursor: pre-action gate. agy: `PreInvocation` injection.

**Phase 3 — the hazards**: agy's `Stop` release condition, agy's turn-killing malformed payload, and the
three incompatible Windows quoting rules.

## The clink tier — carried forward unchanged, and one constraint removed

**This re-cut covers the four host CLIs and dropped the clink tier. That was an omission, not a
decision.** `2026-08-13-review-handoff.md` §157–197 specifies it in full and none of it is superseded:
a reviewer inside the delegation that answers *did the worker follow the skills it was handed, how many
times was it corrected, and what were the corrections*, returns that as **data** —
`skills_handed`, per-skill `verdicts` with the observation attached, `corrections`, `final`,
`reviewer.continuation_id` — objects to the worker in-thread and lets it fix the work, and **decides
nothing**. The master reads the record as ordinary evidence and judges, including judging the reviewer
wrong.

**That reporting is the tier's whole point, and the master-side reviewer has no equivalent.** A count of
corrections and a per-skill outcome is the one thing the host-side reviewer cannot produce about itself.

**Today's finding does not constrain this tier — it exempts it.** The rule "no model call inside a hook"
binds the four hosts because their hooks are synchronous barriers. The clink reviewer runs **inside PAL**,
never in a hook, and the 2026-08-13 plan already forbids it standing between the master and its work. So
it is the one place in the design where judgement may simply take as long as it takes.

**And one of its stated blockers is now removable.** That plan says cursor and antigravity carry
**final text only** — their parser retains no event stream — so a reviewer there would be reviewing the
worker's self-report, which `docs/adr/0001` rules out. The fix it proposes is extending PAL's parser.
There is a second route, and it is measured:

- **PAL spawns the worker, so PAL can install a hooks config into the worker's own workspace.**
- **cursor loads a project-level `<cwd>/.cursor/hooks.json` and fires eight events from it** — verified,
  including `afterShellExecution`, whose payload **carries the command's `output` verbatim**, which is
  exactly what its transcript omits.

So on cursor the worker's real trace is obtainable **without touching the parser**: the worker writes its
own evidence to a file PAL reads. That converts `final: "unknown"` into a real verdict on the client the
plan had written off.

**It does not yet transfer to agy.** Its `PostToolUse` input carries `stepIdx` and `error` and no tool
output, and its `PostToolUse` return is not ingested at all. agy keeps `final: "unknown"` until something
better is measured — the honest state, not a gap to paper over.

## When the master is not Claude Code

The design assumes Claude Code as the master and the other three as workers. Asked the reverse — **cursor
as master, delegating through clink to agy, codex and Claude Code** — it holds, with one asymmetry that
is a property of the *rules*, not of the plumbing.

**The clink tier does not care who the master is.** It watches the worker from inside PAL. The record it
returns — corrections, per-skill verdicts, final — is identical whichever CLI is driving.

**The master-side reviewer fires on the delegation itself, verified.** cursor has `pal` configured as an
MCP server, and a project-level hooks config caught the call: `beforeMCPExecution` and
`afterMCPExecution` each fired once on an MCP tool call, alongside `preToolUse` and `postToolUse`. So
*"delegated without handing over the skills"* is catchable **before the delegation runs**, which is
earlier than Claude Code's turn-end reviewer can manage.

**The asymmetry is which rules remain judgeable.** On Claude Code the master reviewer sees a whole
segment at `Stop`. On cursor it only ever sees *about to do X*, because `stop` does not fire headless.
So a rule of the form *the turn ended and verify was never run* **has no moment to fire when cursor is
the master.** Those rules do not degrade gracefully — they simply have no trigger.

**The route out is already measured and not yet in the plan:** cursor writes a `turn_ended` record into
its transcript even though the callback is absent. A PAL-side tail of that file restores the turn
boundary without a hook. That is the same component Phase 1.5 needs anyway, pointed at a different file.

**Workers are the easy half.** codex and Claude Code retain a full event stream in PAL, so the clink
reviewer reads what the worker *did*. agy remains the weak seat for the reasons stated above.

## The native-subagent tier, per host

The plan leans on hooks firing around a harness's **own** subagents, not only around clink workers. That
tier was never probed until now, so what follows separates the one host that is settled from the three
that are not.

| Host | Subagent events | Grade |
|---|---|---|
| **Claude Code** | `SubagentStart` **and** `SubagentStop` both fired around a real `Task` subagent, with `PreToolUse` and `Stop` as controls in the same run | **[L]** |
| **codex** | `SubagentStart` **and** `SubagentStop` both fired around a real subagent, control firing twice in the same run; **[B]** `SubagentStop` carries `agent_transcript_path` | **[L]** |
| **cursor** | wiring is real — `hookExecutor.executeHookForStep(subagentStart, …)` sits behind a **server-driven request case**, not a local tool call. A probe asking for a subagent returned an answer while `sessionStart` and `preToolUse` fired and the subagent events did not; **whether a subagent actually ran is unestablished**, so this is not a clean negative | **[B]** |
| **agy** | **none.** Its five events contain no subagent event of any kind | **[L/D]** |

**So the tier is proven on two of four.** It is *absent by construction* on agy — no subagent event of any
kind — which means a native-subagent reviewer cannot exist there whatever else is built. cursor is the
open one, and the shape of its wiring is the reason: the hook is driven by a **request from cursor's own
backend**, so making it fire is not a matter of prompting harder. Until a probe sees it, treat cursor's
native-subagent tier as unavailable and let the clink tier cover delegation there.

## Feature coverage, per host — the question this plan has to answer

Not raw capability: **the features this plan actually needs.**

### Master side

| Feature the plan needs | Claude Code | codex | cursor | agy |
|---|---|---|---|---|
| Capture evidence in a hook | **[L]** | **[L]** | **[L]** | **[L]** |
| Turn boundary to segment and trigger on | **[L]** `Stop` | **[L]** `Stop` | **[L] no hook** — `turn_ended` in the transcript instead | **[L]** `Stop` |
| Deliver text the agent reads mid-turn | **[L]** | **[L]** | **[L]** | **[L]** |
| Block so the objection cannot be ignored | **[L]** | **[L]** | **[L]** pre-action only | **[L]** |
| Pre-action gate, for sticky debt | **[L]** | **[L]** | **[L]** | **[L]** |
| A transcript to judge from | **[L]** | **[L]** | **[L]** no tool results in it | **[L]** |
| Evaluator supplied by the harness | **[L]** Haiku 4.5 | **[L]** none — PAL supplies | **[L]** yes | **[L]** none — PAL supplies |
| Liveness canary | **[L]** | **[L]** | **[L]** | **[L]** |
| A clean global off switch | **[L]** `disableAllHooks` | **[L]** feature flag | **[B]** none found | **[L]** per-hook only |

**Every master-side feature is available on all four hosts, with one exception**: cursor has no turn-end
hook, so the boundary comes from tailing `turn_ended` in its transcript rather than from a callback. That
is a different implementation of the same feature, not a missing one — and it is the same file-watching
component Phase 1.5 already requires.

The two soft spots are cursor's transcript carrying no tool results — answered by capturing at
`afterShellExecution`, whose payload does — and cursor having no global off switch, which affects
uninstall rather than operation.

### Native-subagent side

| Feature the plan needs | Claude Code | codex | cursor | agy |
|---|---|---|---|---|
| A hook around the subagent's life | **[L]** `SubagentStart` + `SubagentStop` | **[L]** both fired | **[B]** wiring exists, backend-driven, never seen to fire | **[L] yes, by another route** — no subagent-named event, but `invoke_subagent` / `send_message` are **ordinary tools**, so the tool hooks cover them; `Stop` fired **3×** in a run with a subagent against 1× normally |
| The child's **own** transcript | **[L]** `agent_transcript_path`, distinct from the parent's | **[L]** a separate rollout file, distinct from the parent's | — | — |
| Deliver an objection **into the subagent** | **[L]** blocked at `SubagentStop`; **the subagent itself emitted the demanded token** | **[L]** same — the payload's `last_assistant_message` came back as `SUBPING3 CXSUBBLOCK_8W4` | — | — |
| A loop guard for the correction count | **[L]** `stop_hook_active` in the payload | **[L]** `stop_hook_active` | — | — |
| Identity to attribute a finding to | **[L]** `agent_id`, `agent_type`, `effort.level` | **[L]** `agent_id`, `agent_type`, `turn_id`, and the child's `model` | — | — |

**The subagent tier is complete on Claude Code and codex.** The block reaching the *child* rather than the
parent is the part that matters: it makes the tier an enforcement point rather than a reporting one, and
both hosts demonstrated it the same way — the token the hook demanded came back inside the subagent's own
last message.

One incidental fact worth carrying: codex spawned its subagent on **`gpt-5.6-luna`**, its small tier, not
on the parent's model. A reviewer judging that child is judging a cheaper model's work, which is an
argument for the tier rather than against it.

**And the same probe produced the tier's hazard, by making the mistake a hook author would make.** The
`SubagentStop` hook blocked unconditionally. codex re-spawned the subagent — later payloads carry a
different `agent_id` and a different child rollout file — and the parent ended with **`No reply was
returned`** after **71,527 tokens**. Same shape as agy's `Stop` runaway, on a different host and a
different event.

**The guard was in the payload the whole time.** `stop_hook_active: true` is what says *you have already
blocked this one*, on both hosts that carry the tier. So the rule for Phase 3 is concrete rather than
cautionary: **a `SubagentStop` hook must read `stop_hook_active` and release on it**, and the correction
counter increments exactly where that flag flips. A blocking hook without that check does not degrade —
it destroys the turn and bills for it.

**Correction — agy does have this tier, and the earlier entry here was wrong.** It was written from the
absence of a `Subagent*` **event name**, which is the wrong thing to look for on that host: agy exposes
`invoke_subagent`, `define_subagent`, `send_message` and `manage_subagents` as **ordinary tools**
(69, 4, 60 and 13 occurrences in the binary), so the tool hooks already cover the subagent lifecycle.
Probed live: a `PreToolUse` hook captured a `send_message` call between agents, and `Stop` fired **three
times** in a run containing a subagent where every single-agent run today fired it once.

**That makes `PreToolUse` with a matcher on `invoke_subagent` a delegation gate** — a software seam
*before* a delegation happens, which no other host in this table has as cleanly, and which is where a
required-shape check on the delegation request would sit.

**And hooks fire *inside* the subagent, each carrying that agent's own identity.** One run, every payload
kept, two distinct `conversationId`s:

| Conversation | Events it fired |
|---|---|
| `317f8229` — the **master** | `SessionStart`, `Pre`/`Post` on `invoke_subagent`, `Stop` ×2 |
| `7edbb319` — the **child** | its **own** `SessionStart`, `Pre`/`Post` on `run_command` (the shell command the child was asked to run), `Pre`/`Post` on `send_message`, its **own** `Stop` |

**So agy gives recursive enforcement nearly free**, keyed on `conversationId`: the same hook config
applies to every agent in the tree, each agent's payload identifies itself, and the child's own tool
calls are gated by the same rules as the parent's. No other host in this table has been shown to do that.

**This reverses agy's position on this tier from worst to arguably best.** It has the delegation gate
(`PreToolUse` on `invoke_subagent`, with the arguments visible before the call runs), per-agent hook
firing, per-agent identity, and a `Stop` per agent. What it lacks — a model evaluator *inside a hook* —
is now clearly the wrong thing to have been measuring it on, because its judgement can run as a **native
subagent** rather than as a hook handler.

**On cursor this tier is still not available**, and the clink tier covers delegation there instead.

**What the clink tier can see, from the earlier PAL source review** (`2026-08-13-review-handoff.md`,
verified in source rather than measured here): `codex`, `claude` and `opencode` parsers retain the
worker's event stream; `cursor` and `antigravity` share a parser that retains none. So the clink
reviewer's evidence is real on three clients and a self-report on two — and today's finding gives cursor
a way out that needs no parser change.

## What plays PAL's part on the master and native-subagent side

clink has PAL: a long-running process that owns the worker and can host a judge. The master side has no
such process — a hook is a short-lived script with no shared memory and nothing supervising it. That is
the real asymmetry, and it has a smaller answer than it looks.

**The hook writes a pointer and returns. It talks to no service.**

Every host hands the hook a `transcript_path` in its payload, and `SubagentStop` hands over
`agent_transcript_path` — the child's own file, distinct from the parent's. **So the evidence never has to
travel through the hook.** It records a path, a read offset and the event name — a few bytes — and the
judge opens the transcript itself. That is also the answer to *"the plan never says how the server
assembles session context"*: the host already assembled it, and the payload names the file.

**The one host that needs more is cursor**, whose transcript carries `tool_use` and no `tool_result`. There
the hook additionally spools the `output` field that `afterShellExecution` hands it. That is the only
place evidence passes through a hook at all.

**Who runs the judge, given that no long-running process is guaranteed.** A hook *can* start one:
verified — a `PreToolUse` hook spawned a detached child, returned immediately, and the child completed
**8 s after the hook had returned**, with the turn not extended. So the options are real rather than
theoretical:

- **PAL when it is running.** It already hosts the clink judge, so one judge serves all three tiers —
  one rule set, one model choice, one liveness check. It needs no MCP call from the hook, only a spool
  directory both sides agree on.
- **A detached worker the hook starts when none is alive.** No install, no service, no new dependency,
  and self-healing. The measurement above is what makes this viable.

**Recommendation: the spool is the interface, and the consumer is interchangeable.** The hook's contract
is two filesystem operations and knows nothing about who drains the queue. PAL drains it when present; a
hook-spawned worker drains it otherwise. Neither is a dependency of the hook.

**The native-subagent tier needs nothing extra.** `SubagentStop` gives the child's transcript path, so the
same pointer mechanism covers it — plus the release rule: read `stop_hook_active`, release on it, and
increment the correction count where it flips.

**What this does not solve, stated rather than smoothed over:**

- **cursor still needs one genuinely long-running component**, because its turn boundary is a record in a
  file rather than a callback. That watcher cannot be hook-driven.
- **agy's hook is on the critical path with a 30 s cap.** Two filesystem operations fit; nothing else may
  be added there.
- **Nobody owns the worker's lifetime**, and a spool that no one drains has no defined behaviour. That is
  the next decision, and it is Phase 1.5's, not this section's.

## Two native tiers that want different shapes — agy and cursor

Both hosts have a real agent runtime, and the temptation is to give them the same design. **Their
primitives point in opposite directions, and the difference is about lifecycle rather than capability.**

**agy suits a peer reviewer.** Its collaboration verbs are tools, subagents go idle rather than dying,
and a message wakes one with its context intact. So the natural shape is a **persistent reviewer agent**
that the master or the layer messages when there is something to judge:

```text
Master ──► Worker            Master ──► Reviewer (idle ↔ awake)
```

**cursor suits a lifecycle reviewer.** Its `subagentStop` is a worker-completion seam that already
carries the child's transcript path, and `followup_message` sends the **same worker** back to work
rather than starting a new one. So judgement belongs *between the worker finishing and the master
seeing the result*:

```text
Worker ──► subagentStop ──► review ──► followup_message ──► same Worker ──► Master
```

**That is a better correction loop than routing through the master**, because the worker never leaves
its own lifecycle and no context is reconstructed. cursor also documents a loop limit on
`stop`/`subagentStop` — default 5 — so the runaway this document recorded twice has a native guard here.

**What both share is the gate, and it is the same contract in two seams.** A delegation request should be
required to carry its own shape — objective, evidence, permissions, scope, questions — *before* the
delegation runs. On agy that is `PreToolUse` matching `invoke_subagent`; on cursor it is `preToolUse`,
which can deny with a message and can rewrite `updated_input`; for a clink call it is a server-side
validator, since PAL is ours. **One contract, three enforcement points** — and it replaces the current
arrangement where `clink-brainstorm` asks a skill to persuade the master to write a good prompt.

**Probed. Half of the cursor proposal holds and the half it was built on does not.**

A `-p` run asked for two independent jobs in parallel, with every subagent event hooked and
`preToolUse`/`postToolUse` as controls. Payloads from that single run:

| Observation | Result |
|---|---|
| Does `-p` spawn native subagents? | **yes** — five distinct `session_id`s in one run |
| Does the gate see the spawn? | **yes** — `preToolUse` fired with **`tool_name: "Task"`**, three times |
| Do hooks fire *inside* each subagent? | **yes** — each child's `Read` and `Grep` calls hooked under its **own** `session_id` / `conversation_id` |
| Does `subagentStart` fire? | **no** |
| Does `subagentStop` fire? | **no** |

**So the seam the cursor design was built on is not available headless.** `subagentStop` did not fire in
a run where subagents demonstrably ran and the controls fired beside them — which makes this a genuine
negative rather than an untested cell. The `followup_message` correction loop, and the loop limit that
came with it, are unreachable in `-p` today.

**What survives is the better half anyway.** cursor gets the *same* shape agy has, for the same reason:
the gate sees the delegation before it runs, and hooks fire inside every child with per-agent identity.
So compliance on cursor is enforced **at the tool level inside each subagent**, keyed on `session_id`,
rather than at a worker-completion seam. The correction loop loses the *resume-the-same-worker* property
and has to run through the master — which is the arrangement the rest of this plan already assumes.

**Two of codex's six probes remain**, and both are now moot for the design rather than open: whether
`agent_transcript_path` is the child's, and whether `followup_message` resumes the same worker, are
properties of an event that does not fire.

## Stated uncertainties

- Whether a delivered objection can be proved consumed exactly once across retries and restarts on every
  host. Named by two seats; unresolved.
- Whether the undocumented batch event survives a Claude Code upgrade. Mitigated by the fallback, not
  removed.

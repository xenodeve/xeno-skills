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

## Stated uncertainties

- Whether a delivered objection can be proved consumed exactly once across retries and restarts on every
  host. Named by two seats; unresolved.
- Whether the undocumented batch event survives a Claude Code upgrade. Mitigated by the fallback, not
  removed.

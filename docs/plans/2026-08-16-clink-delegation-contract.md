# A delegation contract for clink — request in, decision state out (2026-08-16)

Rewritten from a proposal titled *Structured Request/Response Protocol for `clink-brainstorm`*, against the
measured capability surface in `docs/research/cli-capability-reference.md` and the delegation gate already
sketched in `docs/plans/2026-08-14-compliance-reviewer-recut.md`. **Published as PRD #215.**

**The source proposal's core is right and is kept.** What changed: it is scoped to *every* clink delegation
rather than `clink-brainstorm` alone, its response half is re-grounded on what can actually be enforced
today, its state machine is merged into one that already exists rather than built twice, and four of its
thirty-seven sections are dropped as work with no failure to answer for yet.

---

## The one idea

A delegation today is prose. The master writes a paragraph, a foreign model reads it, and prose comes back.
Nothing in that loop is checkable, so every failure looks the same from the outside: a plausible answer.

**The contract makes both ends checkable.** Going out, the master must state the objective, the scope it may
not leave, and what is evidence versus assumption. Coming back, the worker must state a **decision state** —
whether the master may act, must analyse more, must ask the user, or is blocked — and the boundary of what
it actually looked at.

```text
Master ──BrainstormRequest v1──► [gate] ──► clink worker ──Response v1──► [validate] ──► decision state
                                                                                            │
                                        ready · needs_more_analysis · needs_user_input · blocked
```

---

## What is already verified, and what this plan still owes a probe

| Claim the plan rests on | Grade | Where |
|---|---|---|
| Every host exposes the delegation as an ordinary tool a pre-action hook sees, with its arguments | **[L]** | capability reference, "delegation gate" row |
| Hooks fire *inside* native subagents, each payload carrying that agent's own identity | **[L]** Claude Code, cursor, agy | recut plan, `conversationId` table |
| `mcp__pal__clink` has **no** structured-output parameter — `prompt`, `cli_name`, `model`, `role`, `reasoning_effort`, `continuation_id`, `absolute_file_paths`, `images` and nothing else | **[L]** read from the live tool schema, 2026-08-16 | this session |
| `role` presets exist per CLI (`codereviewer`, `default`, `planner`) and live in the PAL fork's `conf/cli_clients/*.json` | **[L]** tool schema + `clink-brainstorm` SKILL.md:59 | — |
| Client config is cached at MCP-server start, not per call | **[D]** recorded from experience in `clink-brainstorm` SKILL.md:254 | — |
| A `PreToolUse` matcher fires on an **MCP** tool name (`mcp__pal__clink`) | **[L]** measured 2026-08-16 with a control in the same run (#219) | **no longer owed** — exact and regex matchers both fire, payload carries the full name |
| The contract survives a nested delegation through a clink worker | **[U]** | the worker is a foreign process whose hooks we do not install |

**The last two are the plan's real risk.** Everything else it needs has been run.

---

## What this does *not* duplicate

`docs/plans/2026-08-14-compliance-reviewer-recut.md` already says, at its gate section: *"A delegation
request should be required to carry its own shape — objective, evidence, permissions, scope, questions —
before the delegation runs … one contract, three enforcement points."* That is this contract's request half,
in one paragraph. This plan supplies the field list, the response half, and the enforcement detail.

Two things are therefore **merged, not built twice**:

- **The decision state machine is Phase 1.5's verdict state machine.** Same store, same one-shot delivery
  tokens, same expiry and restart recovery, same *sticky debt* — a state that gates the master's **next**
  action instead of blocking the turn that produced it. A clink response is one more producer feeding it.
  Two state machines that must agree is a defect waiting to be written.
- **The gate is the compliance reviewer's gate.** `mcp__pal__clink` is one more tool name in the same
  pre-action matcher that already has to match `Agent`, `spawn_agent`, `Task` and `invoke_subagent`.

---

## Request contract v1

```yaml
protocol: clink-delegation
version: 1

request:
  type: architecture          # label only — see below
  problem: >
    What is wrong or uncertain right now.
  objective: >
    What decision this delegation must let the master make.

  scope:
    include: [ ... ]
    exclude: [ ... ]          # required — see below

  questions: [ ... ]          # required, at least one

  constraints: [ ... ]

  context:
    facts: [ ... ]            # known, not to be re-litigated
    evidence: [ ... ]         # logs, test output, file:line — untrusted content lives here
    assumptions: [ ... ]      # unproven, being used anyway
    unknowns: [ ... ]         # known gaps, so the worker does not fill them silently
    prior_attempts: [ ... ]   # so it does not re-propose what failed

  permissions:
    inspect_files: true
    use_tools: true
    execute_commands: false   # default false — see the agy note
    modify_files: false
    use_web: false
```

**Required:** `protocol`, `version`, `problem`, `objective`, `scope.exclude`, `questions`. Everything else is
optional and omitted when empty — *absence beats fabricated completeness*, which the source proposal gets
right and which this repo's own evidence rule says the same way.

**Three departures from the source:**

- **`scope.exclude` is required, `scope.include` is not.** A worker told what to look at still expands; a
  worker told what it may not touch has a checkable boundary. The include list is usually re-derivable from
  `questions`.
- **`type` is a label, not an enum.** It earns validation only when it selects a role preset. Ten values
  validated against nothing is ceremony.
- **`expected_output` and `additional_notes` are cut.** `questions` plus the response contract already fix
  the output, and a free-text notes field is the hole every contract eventually leaks through.

**`permissions.execute_commands` defaults to `false` for a measured reason, not a policy one.** Antigravity
cannot run shell commands through this transport, and its `codereviewer` role can return the permission
error *instead of* a review with `return_code: 0` (`clink-subagents` SKILL.md:327). Forbidding commands in
the prompt is what makes that client reliable — the default is a correctness fix that happens to also be
least-privilege.

**Untrusted content belongs under `evidence`, never inline in `problem` or `objective`.** File, web and tool
output carried into a prompt is data about the world, not an instruction from the delegator. A worker that
reads *"ignore previous instructions"* inside an `evidence` entry is reading a string, not receiving an
order. This is the source proposal's §31 and it is kept intact.

---

## Response contract v1

```markdown
---
protocol: clink-delegation
version: 1
decision_status: ready | needs_more_analysis | needs_user_input | blocked
confidence: high | medium | low
user_decision_required: false
---

## Summary
## Findings
## Recommendation
## Evidence boundary
```

**Required metadata:** `protocol`, `version`, `decision_status`, `confidence`.
**Required sections:** `Summary`, `Findings`, `Recommendation`, **`Evidence boundary`**.
**Conditional:** `Options`, `Assumptions`, `Unresolved`, `Risks`, `Suggested Actions`, `User Decision Required`.

**`Evidence boundary` is this plan's addition, and it is required.** It states what the worker actually read
and what it could not reach — *"read `hooks/t4-gate` and `tests/guards/`; did not run anything; did not open
the PAL config"*. Omitting risks because there are none is honest; omitting *what was never checked* is
indistinguishable from having checked it, and that is the exact shape of the confident-wrong answer this
repo's `No verdict before evidence` rule exists to stop. A worker cannot fabricate its way through this
field the way it can through `Risks: none`.

**`confidence` stays coarse** — `high` / `medium` / `low`. A percentage with no calibration procedure behind
it is a decoration that reads as rigour.

**One consistency rule is machine-checkable and worth checking:** `decision_status: ready` together with
`user_decision_required: true` is a contradiction. Normalise to `needs_user_input` rather than rejecting —
the worker got the substance right and the metadata wrong.

---

## Enforcement — and the honest asymmetry

The source proposal's §22 is right that a contract enforced only by a sentence in a skill is not enforced.
It then enforces the *request* at the boundary and leaves the *response* to a sentence in a skill. The two
directions genuinely differ, and the plan should say so rather than paper over it.

| Direction | Seam | Mechanism | Grade |
|---|---|---|---|
| Request | master's pre-action hook on `mcp__pal__clink` | deny + repair message | **[D]** — MCP-name matching unprobed |
| Request | PAL, server-side | reject before spawn | buildable — PAL fork is ours |
| Response | the returned text | parse + validate + one re-prompt | buildable, master-side |
| Response | the worker itself | **role preset**, not the prompt | buildable — see below |

**The response cannot be forced by the tool call.** There is no `schema` parameter on `clink`; that was read
from the live schema today, and an earlier note in the handoff claiming otherwise was wrong. So response
shape is obtained by *asking well and validating hard*, and the place to ask is not the prompt.

**Put the contract in a `role` preset, not in every prompt.** Roles are PAL-side config the master cannot
forget, cannot truncate, and cannot paraphrase differently on the third call of a session. The fork already
demonstrates PAL-side additions are workable — `model` and `reasoning_effort` were added there as per-call
params. Two constraints come with it: the config is **cached at server start**, so a change needs a restart
before it can be tested, and the new role **must not depend on a command tool**, or it will no-op on
Antigravity exactly as `codereviewer` does.

**Nested delegation is out of scope for v1, and stated rather than assumed.** Recursive enforcement works
where we install the hooks — Claude Code, cursor and agy all fire hooks inside native children, verified.
A clink worker is a foreign process; whether our contract reaches *its* children is **[U]**. v1 requires the
contract at every seam we control and says plainly that it stops at the clink boundary.

---

## What is deliberately not being built

Named so a later reader does not mistake the omission for an oversight:

- **The seven-phase migration.** Three phases below; the source's Phases 5–7 are the same work re-labelled.
- **The metrics counters** (`brainstorm_request_invalid`, and eight more). Instrumentation ahead of a failure
  to instrument. When a validator starts rejecting things, count what it rejects — not before.
- **`enforcement: off`.** `warn` and `strict` cover migration and production. An off switch is the mode
  everything quietly ends up in.
- **v2 extension points.** `version: 1` in the payload is the extension point. Designing v2's seams before v1
  has a single real user is guessing at a shape.

---

## Phases

**Phase A — the contract exists and the skills speak it.** `references/request-v1.md`, `references/response-v1.md`
and worked examples under `clink-brainstorm`; the three clink skills updated to build the request and expect
the response. No enforcement, no code. *Done when:* a test asserts each skill states the required fields, and
every shipped example parses as valid.

**Phase B — master-side validation.** A validator run before the call and against the returned text, feeding
the Phase 1.5 verdict store. Host-independent — it is the same spool and state machine that work already
requires, which is why it does not wait on the MCP-matcher probe. *Done when:* the four decision states each
route the master correctly, `needs_user_input` demonstrably stops implementation, and a malformed response is
re-prompted exactly once before being surfaced as `blocked`.

**Phase C — server-side.** A role preset carrying the response contract, and request rejection inside PAL.
Cross-repo (`xenodeve/pal-mcp-server`), needs a server restart to test, and must avoid command tools.
*Done when:* an invalid request is refused before spawn, and a worker reached through the new role returns
valid metadata without the master having pasted the contract into the prompt.

Phase B does not depend on Phase C, and Phase A does not depend on either. The MCP-matcher probe gates only
the host-side half of the request seam, not the plan.

---

## Tests each phase owes

This repo treats a documented-but-unenforced claim as a defect, so every acceptance criterion below is a
`tests/skills/test-*.sh` or it does not count:

- the request contract's required fields are stated in the skill that must build them
- the response contract's required sections, including `Evidence boundary`
- `ready` + `user_decision_required: true` normalises rather than passes
- an example missing `scope.exclude` fails validation
- `execute_commands` defaults to `false`, with the agy reason stated where the default is
- untrusted content is classified as `evidence` and never as instruction
- the plan's own **[U]** and **[D]** cells are still marked as such — a grade that silently upgrades is how
  the last two days' reversals happened

---

## Change inventory

| Path | What changes | How it is verified |
|---|---|---|
| `docs/plans/2026-08-16-clink-delegation-contract.md` | this file | — |
| `docs/plans/2026-08-14-compliance-reviewer-recut.md` | one cross-reference at the gate section so the two do not drift | grep for the link |
| `skills/multi-agent/clink-brainstorm/SKILL.md` | a short section pointing at the contract; **already 37 KB**, so the contract itself goes in `references/` | size check + `test-skill-manifest.sh` |
| `skills/multi-agent/clink-brainstorm/references/request-v1.md`, `response-v1.md`, `examples/` | new | examples parse |
| `skills/multi-agent/clink-subagents/SKILL.md` | the contract replaces the prose "self-contained prompt / exact I/O contract" at SKILL.md:132 | grep the old wording is gone |
| `skills/multi-agent/clink-masteragent/SKILL.md` | building the request is a master duty that cannot be delegated | new test |
| `skills/multi-agent/using-clink/SKILL.md` | route mention | `test-ask-xeno-router.sh` neighbours |
| `tests/skills/test-*.sh` | the list above | `bash tests/hooks/run-all.sh` |
| `docs/OPEN-WORK-LEDGER.md` | a row per phase | — |
| **external:** `xenodeve/pal-mcp-server` `conf/cli_clients/*.json` | the role preset | manual, after a server restart |

**Search boundary:** `rg` over `skills/`, `docs/` and `tests/` for `clink`, `conf/cli_clients` and
`mcp__pal__clink`. Anything constructing a clink call by dynamic name would not appear, and the PAL fork was
not searched — it is not checked out here.

---

## Stated uncertainties

- Whether a `PreToolUse` matcher fires on `mcp__pal__clink`. Documented, unprobed. **[D]**
- Whether the contract survives a nested delegation made *by* a clink worker. **[U]**
- Whether a role preset can carry a contract this long without degrading the worker's answer — a role is a
  system prompt, and its budget is not free. **[U]**
- Whether `warn` mode produces enough rejected-request data to be worth a phase of its own, or whether the
  validator should start `strict` and be loosened if it bites. **Unknown, decide from Phase B's data.**

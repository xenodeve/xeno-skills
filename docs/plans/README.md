# docs/plans — index & status

Implementation / remediation plans. Status: `LIVING` = keep current · `SNAPSHOT` = point-in-time (don't edit, add new) · `ARCHIVED` = superseded · `TEMPLATE` · `REALIZED` = the work landed.

**Four of these overlap, and one supersedes another in part — read this before treating any of them as authoritative.** `2026-08-14-compliance-reviewer-recut.md` **supersedes the architecture** in `2026-08-13-skill-compliance-plan.md` where they disagree, and **does not** supersede that plan's rules: what the reviewer judges is unchanged. `2026-08-13-review-handoff.md` expands one component of it and is not superseded. `2026-08-16-clink-delegation-contract.md` specifies a contract both of them use. So: **rules from 08-13, architecture from 08-14, contract from 08-16.** Where a fourth reading is needed, the evidence is `docs/research/2026-08-14-compliance-hook-surface-across-harnesses.md` and its distillation `docs/research/cli-capability-reference.md`.

**Each plan that produced a PRD has a *tracking issue*** — the plan level's presence on the tracker,
added by #255 (a slice of #248). The issue carries its PRDs as native sub-issues, so `plan → PRD → slice`
is a tree GitHub can read; this table is the other direction, tracker back to the file. **A plan with no
PRD gets no tracking issue** — the cell says `none` and why, because an empty tree on the board reads as
stalled work. `tests/skills/test-plan-index.sh` refuses a blank or an unexplained one.

| File | Status | Tracking issue | What it planned |
|------|--------|----------------|-----------|
| `2026-08-04-composition-remediation-plan.md` | SNAPSHOT | none — no PRD names it; #99 filed the audits and #220 holds the ADR it waits on | Fixing the defects the 2026-08-04 composition audits found |
| `2026-08-13-review-handoff.md` | LIVING | none — a component of slice 3 of the compliance plan, not a plan with a PRD of its own | The state one per-segment reviewer leaves for the next: how a memoryless reviewer still decides a rule whose trace spans two prompts, re-asks what the transcript had not yet written, and does not re-raise a finding the master overruled. Component of slice 3 of the compliance plan. |
| `2026-08-14-compliance-reviewer-recut.md` | LIVING | none — re-cuts #176, which hangs from the 08-13 plan; a PRD has exactly one parent | The compliance reviewer re-cut against a day of live probing across four CLI harnesses: a hook blocks the turn on every host, so judgement moves out of the hook and runs detached. One architecture with four adapters, the phases in order, and what each host gives natively. Re-cuts #176. |
| `2026-08-16-clink-delegation-contract.md` | LIVING | **#257** | A typed contract for every clink delegation — objective/scope/evidence going out, a decision state and an evidence boundary coming back. Merges its state machine into the recut plan's Phase 1.5 rather than building a second one. |
| `2026-08-13-skill-compliance-plan.md` | LIVING | **#256** | Making the skills enforceable: gap-only injection before a turn, sequence traces written into each rule, and a small-model reviewer at turn end. Implements #159. Carries the compaction finding — a session that only ever compacts keeps every old record, so a whole-file check reports skills as loaded whose content is gone or came back truncated — and the delegation finding: nothing a subagent does reaches the master's transcript. |
| `2026-08-21-t4-compact.md` | LIVING | **#310** | T4-Compact: a compaction that cannot happen without a handoff. The concept's middle step cannot be built here — `/compact` is a user command with no tool behind it and the harness owns auto-compaction — so the plan inverts it: the layer does not trigger compaction, it makes every compaction arrive at a session that already holds a valid handoff. `PreCompact` can block, verified from the shipped binary's own error strings. PRD #304, slices #305–#309. |

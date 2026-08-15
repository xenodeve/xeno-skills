# Open Work Ledger — consolidated single source (2026-08-09)

> **Why this file exists:** open work was scattered across GitHub issues, ADRs, plans, and
> DONE.md. Agents read issues but often miss the MD. This ledger consolidates **everything
> still open** — GitHub-tracked **and** MD-only — into one place, deduped, with a phased plan.
> **Read this file at session start (it is linked from CLAUDE.md).** When you finish an item,
> update its row here AND its GitHub issue; when you discover new work, add a row here and
> (for anything non-trivial) file an issue so it doesn't vanish into MD again.

**Legend:** ✅ done, pending merge · 🟢 buildable now · 🟡 gated (needs merge / resource /
decision) · 🔴 **UNTRACKED** (MD-only, no GitHub issue — highest miss-risk)

---

## Track 1 — hooks enforcement gaps (the gate itself)

| Item | Status | Gate | Next action |
|---|---|---|---|
| #123 fix comment strip drops a mixed prose+trailing-note line | ✅ | — | **Closed COMPLETED** — verified 2026-08-16. This row said "the one ready-for-agent, non-blocked hooks bug" and was sending agents at finished work. |
| #85 a repo missing `.claude/t4.json` is silently ungated | 🟢 | — | Fix detection; security, Major. |
| #84 absolute/quoted command path escapes gate detection | 🟢 | — | Fix detection; security, Major. |
| #83 every GitHub-mutating MCP tool bypasses the gate | 🟢 | — | Fix detection; security, Major. |
| #218 sticky debt — an unpaid finding gates the next action (#176 Phase 1.5) | 🟢 | ready-for-agent | The piece that makes a late verdict enforceable. #199 delivers a finding and its own body says a non-blocking hook cannot compel an answer; nothing gated until this. |

## Track 2 — CI / branch protection

| Item | Status | Gate | Next action |
|---|---|---|---|
| #109 no ruleset, no branch protection on main — checks are advisory | ✅ | — | **Closed COMPLETED** — verified 2026-08-16. Superseded by #158, which carries the live gap: the ruleset requires a PR but not a green one, and CI has never executed. |

## Track 3 — repository bootstrap (T4 operating layer)

| Item | Status | Gate | Next action |
|---|---|---|---|
| #93 bootstrap this repo | 🟢 | ready-for-human; **this session does it (Active tier)** | CLAUDE.md + memory + agents + hooks + guards + ruleset + domain docs. |

## Track 4 — clink delegation / cost routing (#73 epic)

| Item | Status | Gate | Next action |
|---|---|---|---|
| #73 route on measured cost — refresh figures, name every scale, contract test | 🟡 | ready-for-human, epic root | Wait for the human to decide scope/priorities. |
| #74 clink-masteragent generated tier list over score table | 🟡 | ready-for-human | Part of #73 family. |
| #75 contract test pinning skill figures to their source | 🟡 | ready-for-human | Part of #73 family. |
| #88 trust boundary — the second routing axis (#73 slice 5) | 🟡 | blocked | Unblocks when #73 is approved. |
| #89 cost as representative value + spread (#73 slice 6) | 🟡 | blocked | Unblocks when #73 is approved. |
| #90 consume the per-call cost report (#73 slice 7) | 🟡 | blocked | Unblocks when #73 is approved. |
| #71 enforcement layer for supervised clink delegation | 🟡 | ready-for-human | Pairs with pal-mcp-server#11. |
| #215 PRD: a typed delegation contract for clink — request in, decision state out | 🟢 | ready-for-agent | Plan: `docs/plans/2026-08-16-clink-delegation-contract.md`. Not yet cut into slices. Phase A (contracts + skills) and Phase B (master-side validation) depend on no host; Phase C is cross-repo into `xenodeve/pal-mcp-server`. Its decision states merge into the recut plan's Phase 1.5 verdict store — do not build a second state machine. |
| #216 the delegation contract as artifacts, three skills speak it (#215 Phase A) | 🟢 | ready-for-agent | Unblocked by everything. Produces what #217 validates against and openclink#118 implements. |
| #217 validate the clink request and response into the existing verdict store (#215 Phase B) | 🟢 | ready-for-agent | Needs #216's artifacts. Does **not** wait on #219 — master-side validation runs before the call and needs no hook. |
| #219 does a PreToolUse matcher fire on an MCP tool name? (#215) | 🟢 | ready-for-agent | Gates only the host-side half of the request seam. The plan grades this **[D]**: documented, never probed here. |

## Track 5 — cross-repo conventions

| Item | Status | Gate | Next action |
|---|---|---|---|
| #79 ready-for-agent means two different things in two repos | 🟡 | ready-for-human | Decide a canonical meaning, then document. |

**The `openclink` half of the plans, filed 2026-08-16.** These live in `xenodeve/openclink` and no plan here ships without them. Repo renamed from `pal-mcp-server`; older rows and issue bodies still use the old name and GitHub redirects it.

| Item | Status | Gate | Next action |
|---|---|---|---|
| openclink#116 consume the retained event stream before `_prune_metadata` drops it | 🟢 | — | The one still-untracked item of the three the 2026-08-13 handoff called new, cheap and unblocked. Covers codex/claude/opencode. Independent of the #11 chain. |
| openclink#117 install a generated hooks config into the worker's own workspace | 🟢 | — | The measured cursor route to real evidence without touching the parser. Narrows openclink#115 if it lands. |
| openclink#118 the delegation contract server-side — a role preset, and rejection before spawn | 🟡 | needs #216's artifacts | Phase C of #215. The tool has no structured-output parameter, so the response contract rides in a `role` preset. |
| openclink#119 the compliance reviewer as a deliverable of openclink#11 | 🟡 | openclink#15 / #16 | The 2026-08-13 plan called it a sibling deliverable of that epic, gated until openclink#12 returned. **#12 is now closed**, so the gate has lifted. |
| openclink#120 drain the master-side spool so one judge serves all three tiers | 🟡 | blocked on #218 | Optional by design — the spool's consumer is interchangeable. Blocked on the spool's ownership and expiry rules, which are Phase 1.5's. |

## Track 6 — MD-only / untracked

| Item | Status | Gate | Next action |
|---|---|---|---|
| #72 research re-fetch — branch merged in #122 but issue never closed | 🟡 | awaiting the owner's go-ahead to close | Still open on 2026-08-16. Close with the merge evidence, or reopen if the re-verify is incomplete. |
| #220 the ownership test and the five owner decisions the 2026-08-04 plan waits on | 🟡 | ready-for-human | `docs/plans/2026-08-04-composition-remediation-plan.md` Phase 2 is one ADR and says *"nothing in Phase 3 starts before it lands"*. `docs/adr/` holds only `0001`, so the whole plan has been stalled since 2026-08-04 with no issue naming the blocker. |

---

## Management Plan — phased execution order

**Phase 0 — this bootstrap (#93).** The repo runs the standard it ships; installing the operating
layer (CLAUDE.md, memory, agents, hooks, guards, ruleset) is the unblock everything else reads.
**Phase 1 — tracking hygiene.** **#109 and #123 are closed as of 2026-08-16** and the rows above are
corrected; #109's live remainder is #158. #72 is still open and still wants the merge evidence.
**Phase 2 — the three security gate-detection fixes (#85/#84/#83).** Unblocked, same surface, batch them.
**Phase 3 — #73 family.** Needs the human's decision on scope; the blocked slices (5–7) wait on it.

**Gating summary:** Phase 1 is pure hygiene; Phase 2 is buildable now; Phase 3 is human-gated.

**The compliance-reviewer track is separate and has its own order**, set by
`docs/plans/2026-08-14-compliance-reviewer-recut.md`: **#212** (the liveness canary) and **#218**
(sticky debt, Phase 1.5) first, because neither depends on any host and Phase 2's per-host adapters
without Phase 1.5 put the model back on the critical path. **#216** starts in parallel — it is
unblocked by everything and produces what #217 and openclink#118 both build against.

**Staleness note.** Three rows in this file claimed open work that was already closed, found on
2026-08-16 by comparing against the live tracker rather than by reading the file. This file is only a
single source while something checks it against reality; nothing does that automatically today.

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
| #123 fix comment strip drops a mixed prose+trailing-note line | 🟢 | — | The one ready-for-agent, non-blocked hooks bug. Pick up with /debug-mantra + TDD. |
| #85 a repo missing `.claude/t4.json` is silently ungated | 🟢 | — | Fix detection; security, Major. |
| #84 absolute/quoted command path escapes gate detection | 🟢 | — | Fix detection; security, Major. |
| #83 every GitHub-mutating MCP tool bypasses the gate | 🟢 | — | Fix detection; security, Major. |

## Track 2 — CI / branch protection

| Item | Status | Gate | Next action |
|---|---|---|---|
| #109 no ruleset, no branch protection on main — checks are advisory | 🟡 | ruleset installed 2026-08-09 (`T4 main gate`: deletion + non_fast_forward + pull_request, `main protected=True`); **required status checks (`tests`/`skill-discovery`) NOT yet added** | CI is billing-locked — every run fails at provisioning ("account is locked due to a billing issue", 0 steps). Fix the GitHub billing, get a green run, then add the two check contexts to the ruleset (`required_status_checks`) and close #109 with evidence. |

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

## Track 5 — cross-repo conventions

| Item | Status | Gate | Next action |
|---|---|---|---|
| #79 ready-for-agent means two different things in two repos | 🟡 | ready-for-human | Decide a canonical meaning, then document. |

## Track 6 — MD-only / untracked

| Item | Status | Gate | Next action |
|---|---|---|---|
| #72 research re-fetch — branch merged in #122 but issue never closed | 🟡 | 🔴 was untracked; now a tracked issue | Close #72 with the merge evidence, or reopen if the re-verify is incomplete. |

---

## Management Plan — phased execution order

**Phase 0 — this bootstrap (#93).** The repo runs the standard it ships; installing the operating
layer (CLAUDE.md, memory, agents, hooks, guards, ruleset) is the unblock everything else reads.
**Phase 1 — close #109 + #72 (tracking hygiene).** Verify the ruleset landed; close #109 with
evidence; close #72 citing the merged PR. Both are already-done work with open issues.
**Phase 2 — the ready-for-agent hooks bug (#123).** Small, unblocked, TDD-able.
**Phase 3 — the three security gate-detection fixes (#85/#84/#83).** Same surface as #123;
batch them after the pattern is proven.
**Phase 4 — #73 family.** Needs the human's decision on scope; the blocked slices (5–7) wait on it.

**Gating summary:** Phase 0 and Phase 1 are pure hygiene with no external dependency beyond a
human merge; Phase 2–3 are buildable now; Phase 4 is the only genuinely human-gated track.

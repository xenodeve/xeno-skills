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
| #222 every state row cites the record it rests on | 🟢 | ready-for-agent | Write rule 2. `#189` gives the transitions and not this. Without it a `pending` row is a bare assertion the next memoryless reviewer must trust or discard. |
| #223 deliver at most one finding per turn, ranked by the earliest missing step | 🟢 | ready-for-agent | Write rule 6. `#199` delivers; nothing selects. Four failing traces would fire four objections, which the plan says becomes a wall of text that gets skimmed. |
| #224 turn the four stopping rules into checked gates | 🟢 | ready-for-agent | The plan wrote them *"now rather than after the work"*. `#180` measures; nothing turns a count into a stop, so slice 2 and 3 can be paid for unexamined. |
| #225 release on `stop_hook_active` at `SubagentStop`, count corrections where the flag flips | 🟢 | ready-for-agent | A blocking hook without it *"destroys the turn and bills for it"*. The related runaway was measured at 168 extra turns. No issue in either tracker mentioned the flag. |
| #226 a config generator with per-host allowlists and a byte readback | 🟢 | ready-for-agent | Phase 1. Prevents the class of silent death `#212` detects. `openclink#117` should consume it rather than build a second one. |
| #227 the canary's third observation - a synthetic verdict delivered and seen consumed | 🟢 | ready-for-agent | Phase 1. `#212` stops at *the hook fired*, which reports green through every failure between the evaluator and the master. |
| #228 Claude Code delivery adapter | 🟢 | after #218 | Phase 2. Batch event with the documented one as fallback; the batch event is undocumented so it may never be the only path. |
| #229 codex delivery adapter | 🟢 | after #218 | Phase 2. `{decision:"block"}` replaces the tool result, which is a stronger channel than appending context. The easiest of the four. |
| #230 cursor delivery adapter | 🟡 | after #218 | Phase 2, and the one needing the most built: no turn-end event headless, so the boundary is a `turn_ended` tail needing the design's only long-running component. |
| #231 antigravity delivery adapter | 🟢 | after #218 | Phase 2. Richest mid-turn channel of the four, and the only host where a malformed payload is fatal. Carries the three wrong negatives recorded during design. |
| #232 the delegation gate on all four spawn tool names, and enforcement inside the children | 🟢 | ready-for-agent | The one seam all four hosts share, verified live, and named nowhere in either tracker but #176's body. Share the matcher with `#168`. |

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
| #204 / PR #206 — the clink MCP prefix | 🔴 | **blocked** | **Do not merge PR #206** until `claude mcp list` shows an `openclink` entry. The prefix comes from the client's registration key, not the server's name; this machine has only `pal`, so the rename would make all four clink skills call a tool that does not resolve. Server-side half is `openclink#122`. |

**The `openclink` half of the plans, filed 2026-08-16.** These live in `xenodeve/openclink` and no plan here ships without them. Repo renamed from `pal-mcp-server`; older rows and issue bodies still use the old name and GitHub redirects it.

| Item | Status | Gate | Next action |
|---|---|---|---|
| openclink#116 consume the retained event stream before `_prune_metadata` drops it | 🟢 | — | The one still-untracked item of the three the 2026-08-13 handoff called new, cheap and unblocked. Covers codex/claude/opencode. Independent of the #11 chain. |
| openclink#117 install a generated hooks config into the worker's own workspace | 🟢 | — | The measured cursor route to real evidence without touching the parser. Narrows openclink#115 if it lands. |
| openclink#118 the delegation contract server-side — a role preset, and rejection before spawn | 🟡 | needs #216's artifacts | Phase C of #215. The tool has no structured-output parameter, so the response contract rides in a `role` preset. |
| openclink#119 the compliance reviewer as a deliverable of openclink#11 | 🟡 | openclink#15 / #16 | The 2026-08-13 plan called it a sibling deliverable of that epic, gated until openclink#12 returned. **#12 is now closed**, so the gate has lifted. |
| #221 consume the clink compliance record, so a delegation resolves past `delegated` | 🟢 | pairs openclink#119 | **The master-side half of the arrow the 2026-08-13 plan drew.** The producer was filed and the consumer was not: #202 stops at the boundary on purpose and #71 is a different layer, so a delegation would resolve to `delegated` forever even once records existed. |
| openclink#120 drain the master-side spool so one judge serves all three tiers | 🟡 | blocked on #218 | Optional by design — the spool's consumer is interchangeable. Blocked on the spool's ownership and expiry rules, which are Phase 1.5's. |
| openclink#124 **epic** — the server-side half of the compliance reviewer | 🟢 | — | Roots openclink#116–#120, which had none when they were filed. #116 and #117 can start now; #116 is what the rest read from. |

## Track 6 — MD-only / untracked

| Item | Status | Gate | Next action |
|---|---|---|---|
| #72 research re-fetch — branch merged in #122 but issue never closed | 🟡 | awaiting the owner's go-ahead to close | Still open on 2026-08-16. Close with the merge evidence, or reopen if the re-verify is incomplete. |
| #220 the ownership test and the five owner decisions the 2026-08-04 plan waits on | 🟡 | ready-for-human | `docs/plans/2026-08-04-composition-remediation-plan.md` Phase 2 is one ADR and says *"nothing in Phase 3 starts before it lands"*. `docs/adr/` holds only `0001`, so the whole plan has been stalled since 2026-08-04 with no issue naming the blocker. |

---

## Track 7 — the compliance reviewer, being built (#176)

**Thirty-four slices implemented 2026-08-16 on PR #235** — 42 commits, one issue each, TDD, tree
green after every one and idempotent across two consecutive suite runs. Not closed: this repo closes
with evidence, and the PR is open.

**The ready-for-agent queue on this track is now clear except for what is parked or blocked**, and
every park below names the thing it needs rather than the fact that it stopped.

| Item | Status | Gate | Next action |
|---|---|---|---|
| #185 turn-end wiring · #189 state file · #222 row citations | ✅ | PR #235 | Close on merge. |
| #184 transcript reader · #183 generated routing table | ✅ | PR #235 | Close on merge. |
| #186 the gap notice · #190 the route list on a miss | ✅ | PR #235 | **The chain works end to end**: prompt → generated table → what the session actually invoked → speak only about the difference. |
| #197 segment extraction, hook-written records filtered | ✅ | PR #235 | Close on merge. Unblocks #198, #201, #202. |
| #207 quoting check · #155 ADR 0001 corrected | ✅ | PR #235 | Close on merge. |
| #181 rule census · #188 trace file · #195 out-of-scope markers | ✅ | PR #235 | **123 rules: 41 machine / 35 trace / 47 undecidable**, against the inherited 33/68/25. The needs-a-trace bucket is about half what every downstream slice assumed. |
| #182 stop injecting the family map | ✅ | PR #235 | 8,974 B → 1,368 B per injection; **30,424 B saved across a four-injection session**, measured by the suite. |
| **#194** write the trace for every in-scope rule | ✅ | PR #235 | **The park was wrong, and the reason is worth keeping.** 17 of the 21 were never hard: the census stores the bolded LABEL as the rule but classifies on label + sentence, so the trace generator was judging four words that said no order while the sentence that classified them said "before". Carrying the full line through: 21 → 9. Five traces written, four reclassified with individual reasons. `untraced` is **0**, and the zero is pinned — the blanket-reason population may not grow to absorb them. |
| #198 the reviewer call · #200 skill version · #201 follow a delegation · #202 clink boundary · #203 receipts | ✅ | PR #235 | The whole reviewer half. #201 corrected the issue's stated join **by measurement**: against a real 39-delegation session the agent id appears **0** times in the master transcript and the sidecar's `toolUseId` appears **4** — the glob it asked for would have found nothing forever while looking like a harness that does not delegate. |
| #187 · #192 · #193 the classifier, its counts, its off switch | ✅ | PR #235 | Re-cut and said so: #187 was written for a classifier inside a hook, and a hook is a synchronous barrier on every host. It is a component the detached judge calls, and the suite asserts it is **not** in `hooks.json`. |
| #191 the router | ✅ | PR #235 | Five untrustworthiness conditions, weakness **derived** rather than listed, both answers unioned. The gap notice now calls it instead of keeping a second matching loop. |
| **#236 · #84 · #83 · #141** | ✅ | PR #235, **with the developer present** | The four gate defects, done the moment the reviewer `t4-afk` requires was in the room. Each one's stated cause was checked before it was fixed, and **two of the four issues were wrong about their own mechanism**: #236 blamed the `gh` anchor (it is anchored; quotes were never stripped), and the real trigger is one separator character inside quoted prose. |
| **#241** three divergent gate copies | 🔴 | **NEW — `ready-for-human`** | Found while verifying #236: `hooks/t4-gate`, the plugin cache and the marketplace copy are three different files, and **the one enforcing is not the one `tests/` drives**. The #236 fix was green and the very next commit was still denied by the stale installed copy. Every gate change is inert for the session making it. |
| **#85 · #171 · #173 · #174 · #175** | 🔴 | **PARKED — still trust boundary** | The remaining `t4-gate` work. #85 is a *design* decision by #129's own ruling ("slice 4 delivers a design decision, not a patch"); #174 is behind #171. |
| **#196** expiry, cap, logged drop | 🟡 | **PARKED — #178** | The cap and expiry values are a decision the plan reserved to the developer: *a guessed number written as though it were derived is the failure this section exists to prevent.* |
| #216 · #217 · #219 (#215) · #218 · #221 · #223 · #224 · #225 · #226 · #227 · #228–#232 · #142 · #145 | ✅ | PR #235 | The rest of the queue. |
| **#199** deliver the finding at the next prompt | 🔴 | **PARKED — #177 and #179** | Both are `ready-for-human`: whether a finding raised on the last turn is carried forward or declared, and whether a small model returns the partial verdict reliably. Neither is the implementer's to answer. |
| **#174** correct the six Bash-only scope claims | 🔴 | **PARKED — behind #171** | Its own acceptance says "in the same change as the behaviour", and the behaviour is a `t4-gate` edit. |
| **#168** widen the PreToolUse matcher · **#236** the gate's prose false-deny | 🔴 | **PARKED — trust boundary** | Both change what `t4-gate` sees or denies. Same rule as the five above. |
| **#156** the thai-token-optimizer write-up | 🔴 | **PARKED — the evidence is not reachable** | Its source is a 2026-08-12 session transcript and two temp files outside the repo. Writing it from here would be a reconstruction, and this repo's own rule is that a reconstructed retrospective is a hypothesis wearing a log's clothing. |
| **#169 · #170 · #172** | 🔴 | **PARKED — behind #166** | An ADR that is `ready-for-human`. |
| **#88 · #89 · #90 · #204** | 🔴 | labelled `blocked` | Not this track. |

## Track 8 — the tracker hierarchy, and what it found (#248)

**The rule landed in `a2f1dba`; the five slices that apply it are done and closed** (2026-08-19). PR
**#259 is merged to `main`** — the only thing this session shipped that did not have to wait for #235.

| Item | Status | Gate | Next action |
|---|---|---|---|
| #248 the rule — a sub-issue tree, not prose | 🟡 | PR #235 | All five children closed; the rule itself ships with #235. Close on merge. |
| #251 · #252 · #253 · #254 the four trees | ✅ | — | **Closed with evidence.** #215→3, #129→4, #165→10, #176→42. Every count read back from `sub_issues_summary`. |
| #255 a tracking issue per plan | ✅ | merged | **#256** (08-13 compliance plan → #176) and **#257** (08-16 clink contract → #215). Three plans get none, each with its reason in `docs/plans/README.md`, pinned by `tests/skills/test-plan-index.sh`. |
| #258 the invocation log blocked every push | ✅ | merged | `.gitignore` + an assertion in `tests/guards/test-check-tree-budget.sh`. Found by the guard refusing #259's push. |
| **#260** the line-ending pins are a glob on one side and a filename list on the other | ✅ | PR #235 | **Fixed in `e7b7c24`, and the issue's own measurement was wrong.** It claimed the CR was in the committed blobs, with counts of 182/163/36 — those are LINE COUNTS: `grep -c $'
'` matched the empty string. `od -c` on the blobs shows `bash 
`. Every blob is LF; the CRLF is produced at checkout on the files `.gitattributes` did not pin. So no hook byte changed, and the boundary concern that parked this was smaller than the park argued. `tests/hooks/test-line-ending-pins.sh` asserts the class, not a filename list. |
| **#246** the ship gate ran a verify command the PR author wrote | ✅ | PR #235 | **Developer chose option 3** — the head's and the local `verify` must be identical, a mismatch is denied and neither runs. `f3f367b`. The exploit reproduces in the suite: before the fix the marker file the head's command would create existed. `/security-review` added a fourth case — the refusal quotes attacker-controlled text, so it is sanitised — and **its first fixture was a false pass**, because `json.dump` cannot carry a raw ESC. `test-gate.sh`: 94 passed, 0 failed. |
| #244 the bootstrap session has no T4 wiring | ✅ | PR #235 | Implemented in `ed01ed6` — the procedure now opens by invoking `using-t4` and `t4-bro`, with the audit of what else runs pre-wiring. Close on merge. |

**#141 has no parent, deliberately.** #252 reserved the call; #129's own body names #83, #84, #85,
#126 as its four bypasses, and #141's title says *"the fifth bypass, not in #129"*. A root with no
parent is the accurate answer, not a gap.

**#165 has no plan file, checked rather than assumed.** Nothing under `docs/plans/` names it and its
own body names none — so its plan was never written rather than predating the directory. `#255`
recorded that as `none` instead of inventing one.

**LANDED, 2026-08-19.** `feat/185-turn-end-wiring` merged to `main` as **`4c4dbf3`** (PR #235,
62 commits squashed). **37 issues closed with evidence; 107 open → 78.** `bash tests/hooks/run-all.sh`
is ALL TESTS PASSED on the merged tree.

**The rollup now answers the question #248 was filed for**, without anyone maintaining it: **#176 reads
25/42**, **#129 2/4**, **#215 1/3**, **#165 0/10**. On 2026-08-17 the same question cost an export of
107 issues, numbers scraped from 54 commit subjects, and a set difference in a shell pipeline.

**#176 and #129 stay open** — their trees are not finished, and closing a parent whose children are open
is what the rollup exists to make visible.

**The review that #247 says the branch never had is now done, in two passes, and both found things.**
Pass one (`35a4e09`) found **raw control bytes** in `hooks/t4-gate` committed the same day — bytes the
94-assertion gate suite passed both before *and* after, which is precisely the gap a review covers and a
green suite does not. Pass one also declared what it had **not** read: ~2,300 lines of unwired component
logic.

**Pass two read that, and #265 is what was in it** — eight hooks handed an unbounded input to `python`
through `argv`, which is capped at ~32 KB. Bisected on the one hook that is wired: 32,000 bytes logged,
33,000 dropped, hook exit 0 either way. In `.invocations.log` that reports the **opposite** of the truth,
inside the mechanism built to measure truthfully. Fixed in `e3cdde8`; the guard **derives** the check from
`x="$(cat)"` assignments rather than listing names, which is what caught the last two after the first
version listed five and missed them.

**Treat the branch's 54 `scrutinize=ran` trailers as unverified regardless** — that is what #247 is for.

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

**Coverage note, 2026-08-16.** A body-level audit of the plans against both trackers found **eleven**
requirements with no owner, filed as `#222`-`#232`. The structural cause: of the 32 slices `#177`-`#208`,
exactly one names a host other than Claude Code. They were cut from the single-harness architecture of the
2026-08-13 plan; the 2026-08-14 re-cut says four harnesses share one loop with four adapters, and none of
those adapters had an issue. The audit is recorded as a comment on `#176`.

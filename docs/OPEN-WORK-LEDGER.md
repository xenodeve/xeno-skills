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
| #79 ready-for-agent means two different things in two repos | 🟡 | ready-for-human | **Half applied 2026-08-20, from evidence rather than a new convention.** The label carried 16 issues and **15 could not be started by an agent** by the tracker's own recorded blockers — four edit `hooks/t4-gate`, four sit behind ADR #166 / #167, two behind #177–#179, three (#88 #89 #90) held `ready-for-agent` **and** `blocked` at once, and #215 is an epic root with 3/3 children closed. All 15 relabelled, each with its blocker named; **#145 is the only one left, and it is genuinely agent-workable.** No new convention was invented — the labels were made to match the meaning `t4-afk` already relies on. **Still open:** the two repositories disagree, and a canonical cross-repo definition is the decision this issue actually asks for. |
| #204 / PR #206 — the clink MCP prefix | ✅ | — | **Resolved 2026-08-20 by removing the assumption, not by waiting for the machine.** `claude mcp list` now reports `pal: openclink` — the SERVER was renamed and the REGISTRATION KEY is still `pal`, so `mcp__pal__clink` is still correct here and the rename would have broken all four skills. **Both spellings are wrong on some machine**, so PR #206 was closed as superseded and `using-clink` gained a resolution step instead (`#275`). The hooks already derived the name (`^mcp__[A-Za-z0-9_.-]+__clink$`); only the prose assumed. Server-side half is still `openclink#122`. |

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
| **#88 · #89 · #90** | 🔴 | labelled `blocked` | Not this track. `#204` closed 2026-08-20, see Track 5. |

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

**LANDED, 2026-08-19/20.** `feat/185-turn-end-wiring` merged to `main` as **`4c4dbf3`** (PR #235,
62 commits squashed), plus eight follow-up PRs. **53 issues closed with evidence; 107 open → 65.**
`bash tests/hooks/run-all.sh` is ALL TESTS PASSED on `main`.

**#176 reads 37/42 (88%)**, #129 2/4, #215 1/3, #165 0/10 — the rollup answering, unmaintained, the
question that on 2026-08-17 cost an export of 107 issues and a set difference in a shell pipeline.
**#176's five remaining children are all decisions or research**: #177, #178, #179 (`ready-for-human`)
and #196, #199 parked behind them.

**THE CLOSING PASS ITSELF GOT THIS WRONG FIRST, and it is the third instance of #268 in one day.** It
derived its list from the **trailing** `(#N)` of each commit subject, so it saw only the last issue a
commit named — and every slice landing under its PRD, or four adapters in one commit, was invisible.
**Fourteen issues stayed open with nobody having decided they should.** The rule was written for guards
that afternoon; this was a one-off task and went wrong the same way anyway. Re-derived by searching the
full commit message, which is how the count moved 79 → 65.

**The review the branch never had is now done, in two passes, and both found things.** Pass one
(`35a4e09`) found **raw control bytes** in `hooks/t4-gate` committed the same day — bytes the
94-assertion gate suite passed both before *and* after. Pass two read the ~2,300 lines pass one declared
uncovered and found **#265**: eight hooks losing input to the ~32 KB argv cap, silently. **Treat the
branch's 54 `scrutinize=ran` trailers as unverified regardless** — #247, and now #270 for why a deferred
gate leaves the same record as a falsely-declared one.

## Track 10 — intake, the first contract on the developer's own prompt (2026-08-20)

**#301 closed by PR #302.** `t4-dev-workflow` now carries an **Intake** rule: map a new directive onto
the five CRISPE slots, ask about **at most two**, and pick the moment yourself — before the first action
that commits, one batch, and **never under AFK**.

**What is deliberately not built:** no hook, and none is possible — a transcript shows the question that
was asked and never the one that was not. The guard is the suite holding the **ceiling** (five rows, two
askable, personality and experiment refused), not a mechanism that judges a question.

**Open follow-up, none.** The remaining CRISPE slot the repo defers — a validated `role` preset in the
delegation contract — is a different layer and still unfiled; it is named in `request-v1.md` as earning
validation "the day it selects a `role` preset".

## Track 9 — the skill-feedback queue, cleared (2026-08-19/20)

**`ready-for-agent` is 0 and `needs-triage` is 0, and both are true answers rather than empty ones.**
Every open issue carries a triage role; **none can be started by an agent alone.**

| | |
|---|---|
| open issues | 107 → **45** |
| open PRs | 4 → **0** |
| `ready-for-agent` | 16 (15 of them false) → **0** |
| `needs-triage` | 16 → **0** |
| `ready-for-human` / `blocked` | 33 / 17, each with its blocker named on the issue |

**Sixteen `skill-feedback` issues were fixed as skill prose plus a suite** — #130 #131 #132 #133 #135
#136 #137 #138 #160 #209 #210 #211 #233 #237 #238 #239 #249 — each with positive controls that were
**run and shown red**. Four of the fixes are **triggers**, because the rule was unambiguous and still
not applied: a rule that fires on *every* message or *every* delegation has no moment at all.

**#93 closed.** Its last unmet criterion was *"existing issues triaged so `ready-for-agent` returns a
usable worklist here"* — the seven satisfied by files had been satisfied since August. `verify` timed
at **186 s, 1,207 passing assertions**.

**And a seventeenth, filed by the session against itself.** #297 — a close that ran twice while its PR
was unmerged, both times chained with `&&` after the merge command — landed as a rule and a suite
(#299). **Its own filing repeated the defect:** the record PR carried `Closes #297` and the merge closed
an issue no rule change had yet answered, so it was reopened with the reason on it and closed again only
after `gh pr view 299` returned `MERGED`.

**Six `skill-feedback` issues remain open and none is fixable here.** #240 #250 #262 are about skills
this repo does not ship (`tdd`, `test-driven-development`, `simplify`, `code-review`); #242 and #270
have their skill halves landed and their remaining halves are enforcement-layer work; #213 is blocked
on a `agy` binary that does not resolve on this machine.

**Still blocked on evidence this machine cannot reach:** #213 — `agy` resolves nowhere here
(`command -v`, `where`, and both install roots), so the check that issue names as decisive is not
runnable. A fourth candidate cause is recorded on it.

**Everything else open is a decision, an ADR, a PRD, a trust boundary, or something parked behind
one.** The full list with per-issue reasons is on the issues themselves.

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

# Subagent delegation log (2026-07-16 AFK batch)

Empirical notes on delegating menial work to cheap subagents during the clear-backlog
AFK run, so the team can tune the setup. Tools under test: **qwen** (`claude-9arm`,
qwen3.6-35b-a3b via 9arm gateway) and **clink** (`mcp__pal__clink` → codex GPT-5.6 /
antigravity Gemini 3.x). Discipline: every delegated output is verified by me before use.

Columns: task · agent · mode · wall-clock · followed constraints? · correct? · verify result · verdict.

## Runs

_(appended as each delegation completes)_

| # | Task | Agent | Mode | Wall-clock | Constraints | Correct | Verify | Verdict |
|---|---|---|---|---|---|---|---|---|
| 1 | E1+E2 nestjs cleanup | qwen (`claude-9arm`) | headless `-p` + `--allowedTools Bash Read Edit Write Glob Grep` | n/a | n/a | n/a | **BLOCKED** | ⛔ blocked by Claude Code auto-mode classifier before launch (shell+write, no gate) |
| 2 | gather: exports of 2 rag files | qwen (`claude-9arm`) | headless `-p` + `--allowedTools Read Grep Glob` (read-only) | 130s | — | — | **524** | ⚠️ classifier PASSED (read-only), but 9arm gateway returned HTTP 524 (origin timeout at 120s) |
| 3 | gather: exports of retrieval.service.ts | qwen (`claude-9arm`) | headless `-p` + `--allowedTools Read Grep Glob` (read-only) | 185s | ✅ | ✅ | **PASS** | ✅ retry succeeded; listed both exports correctly + honestly (cited "8 lines, no default export"), matched ground truth exactly |
| 2 | code-review the 5-commit backlog batch (`62b7777..HEAD`) | clink → codex (GPT-5.6) | MCP `mcp__pal__clink`, role `codereviewer`, `--dangerously-bypass-approvals-and-sandbox` | **354 s** | ✅ read-only as asked (no edits) | ✅ high — findings verified true | ✅ ran its own `git diff` + lint + targeted `bun test` | ⭐ excellent — 1 real Medium + 2 valid Low, all confirmed & fixed |
| 4 | verify freshness epic #16–24 (7 deliverables) vs `master` before closing | **Explore (CC in-harness Task subagent)** | read-only Glob/Grep/Read; "return report only, not file contents" | not measured (parallel, 1 round) | ✅ terse structured report | ✅ | **PASS+** | ⭐ caught 2 real gaps a ledger-trust close would have missed: #18 RLS not in any committed migration, #20 `pushed_at`-delta unimplemented (deferred in-code) |
| 5 | verify chat epic #37/#38–43 (6 deliverables) vs `master` | Explore (CC Task subagent) | read-only; report-only | not measured (parallel) | ✅ | ✅ | **PASS** | ✅ all 6 VERIFIED with file:line + test-presence noted; no false "done" |
| 6 | verify #33 (a–e) + #35 acceptance vs `master` | Explore (CC Task subagent) | read-only; report-only | not measured (parallel) | ✅ | ✅ | **PASS** | ✅ #33 all criteria + #35-delivered-by-#42 confirmed with file:line |
| 7 | gather commit SHAs + evidence per issue for close comments | qwen (`claude-9arm`) | — (**declined**) | — | — | — | **N/A** | ⏭️ declined to delegate: the ledger was already in my context → round-trip cost > benefit (the skill's own economics rule: don't delegate a task smaller than the round-trip) |

## Per-run detail

### Run 1 — qwen, E1+E2 (BLOCKED, not executed)
- **What:** delegate two surgical nestjs edits (remove dead `StubRetrievalService`; fix a stale `DatabaseModule` comment).
- **Outcome:** the harness **auto-mode classifier denied the Bash launch** of `claude-9arm -p ... --allowedTools Bash Read Edit Write Glob Grep`. Reason given: launching a third-party coding-agent binary in headless mode with shell+file-write and **no per-action approval gate**, which the user's "try qwen-agent" instruction named but did not explicitly authorize (the dropped approval/sandbox).
- **Fix needed to use qwen unattended:** the user must add a Bash allow rule, e.g. `"permissions": { "allow": ["Bash(claude-9arm:*)"] }` (the qwen-agent skill's "one-time setup"), OR approve the launch interactively. Narrowing `--allowedTools` to drop `Bash` (edit-only: `Read Edit Write Glob Grep`) *might* clear it but was not retried to avoid repeated denials during AFK.
- **Action taken:** parked the qwen experiment; did E1+E2 myself (trivial). qwen remains untested this run — pending the permission rule above.

### Run 2 — clink → codex, code-review the backlog batch (SUCCESS)
- **What:** `mcp__pal__clink` (`cli_name: codex`, `role: codereviewer`) to adversarially review the 5 commits `62b7777..HEAD` — asked it to run its own `git diff` and assess the C2 lint downgrade, C4 hermetic test, E1 dead-code removal, C3 extraction, C5 e2e changes.
- **Mechanics:** clink is a first-class MCP tool (NOT a Bash-launched binary), so it was **not** blocked by the classifier that stopped qwen. codex ran with `--dangerously-bypass-approvals-and-sandbox` internally but only read (as instructed). Took **354 s**; consumed ~1.08M input tokens (mostly cached) / 5.5k output.
- **Return-contract gotcha:** the result was **91,583 chars on one line** → exceeded the tool-result token cap and was spilled to a file (`…/tool-results/mcp-pal-clink-*.txt`) whose lines are too long for Read's offset/limit. Had to slice with `python read()[a:b]` + `.encode('ascii','replace')` (Windows cp1252 console can't print its Unicode). Budget for this: **codex echoes every file it reads**, so the transcript is huge; the actual review + `<SUMMARY>` is a small slice near the front.
- **Quality:** genuinely good. Found 1 Medium (e2e console filter matched 5xx/429 by status alone → could mask same-origin regressions; allowlist cross-origin instead) + 2 Low (inaccurate eslint comment; cert regex didn't pin the Supabase origin). **All three were real and all three were fixed** (commit `2c87dd5`). It also independently confirmed the parts I claimed sound (env-restore finally, StubRetrieval 0 refs, runLiveRefresh behavior-preserving) and re-ran lint + targeted `bun test` to verify. Its own `bun run lint` shell call failed (`bun` not on codex's PowerShell PATH — same PATH gotcha as this repo) but it fell back to reading committed results.

## Real-task sandbox experiments (→ fed into xeno-skills `clink-subagents`)

Using T4-Fastwork as a live sandbox to calibrate the delegation skill with *real* code, not synthetic toys. Full economics writeup: `2026-07-16-subagent-vs-self-token-economics.md`.

**Exp A — same summarize task, 3-way** (30,696-char ledger → 5 bullets):
| Agent | input_tok | out | latency | result→my ctx | notes |
|---|---|---|---|---|---|
| codex (GPT-5.6) | 50,020 (20k cached) | 371 | 37s | ~240 tok | terse, obeyed "only 5 bullets" |
| antigravity (Gemini 3.x) | n/r | — | 38s | ~375 tok | appended `<SUMMARY>` despite instruction |
| qwen (`claude-9arm`, local) | 130,791 (0 cached) | 565 | 64s | ~464 tok | accurate + honest; 130k = free local compute |

**Exp B — adversarial review of a real fn** (`nextjs/lib/live-snapshot.ts` `tagForKey`; ground truth = no bug):
- **codex** (`codereviewer`): `NO BUGS FOUND` in **19s** (144 out) — **correct**, no hallucinated false-positive, terse. ✅
- **antigravity** (`codereviewer`): **failed** — `jetski: no output produced — a tool required the "command" permission that headless mode … auto-denied`. Returned the error with `return_code: 0` → **check content, not just code**. Its `default` role (Exp A) worked fine.

**Skill changes shipped to `D:/Github/xeno-skills/skills/multi-agent/clink-subagents/SKILL.md`:** (1) new **Token economics** section (two-pool model: your metered tokens vs free-local / flat-subscription; delegate to shrink *your* context; result-echo is your tokens); (2) **Benchmark of record** updated with Exp A/B real numbers; (3) new **Gotcha** for antigravity's `codereviewer` headless no-op.

## Rolling takeaways

- **qwen (`claude-9arm`) — the classifier gate is capability-shaped, not name-shaped (RETESTED, now works read-only).** `--allowedTools Bash … Write` (unsupervised shell+write) is **blocked**; the *same binary* with **read-only** `--allowedTools Read Grep Glob` **passes the classifier with no rule** (runs 2–3). So read/gather delegations work out of the box; **write/edit delegations still need** the `Bash(claude-9arm:*)` allow rule (skill's "one-time setup") or interactive approval — decide that **before** AFK.
- **qwen quality (read task): good + honest.** Asked to list a file's exports, it matched ground truth exactly and volunteered concrete detail ("8 lines, no default export") — the fingerprint of an actually-read answer, not a fabrication. `READ_FAILED` escape-hatch included; not triggered.
- **9arm gateway is slow + flaky right now.** ~130–185 s per *small* call; one call hit HTTP **524** (origin timeout at 120 s) and only succeeded on retry. Budget for retries + long waits; unfit for latency-sensitive loops. A harmless `ANTHROPIC_API_KEY takes precedence` connector warning prints every run.
- **clink → codex works well for read-only review/second-opinion** and is the better fit for *judgment-light but context-heavy* checks (adversarial review, diff sanity). It is not blocked by the classifier because it's an MCP tool. Cost: slow (~6 min) + a giant one-line result that must be sliced from the spill file. Worth it for a real review gate; overkill for trivial edits.
- **Prompt pattern that worked:** give codex the commit range + explicit per-file concerns + "do the `git diff` yourself" + "review only, do not edit." It followed all of it.
- **Net for this batch:** the delegation *experiment* paid off via clink (caught 3 real issues); qwen never ran. For trivial mechanical edits (E1/E2) doing them inline was faster than fighting the qwen gate.

## Clear-backlog Phase 0 — close-out verification (2026-07-16, second batch)

Context: before closing 19 "done" GitHub issues, the developer required *real* verification against `master` (not ledger-trust). Delegated the verification as **three parallel in-harness Explore (Claude Code Task) subagents**, one per epic, each handed the issue's acceptance criteria and told to return a terse VERIFIED/PARTIAL/MISSING report with `file:line` — "report only, not file contents."

- **A new delegation channel worth logging: the in-harness Task/Explore subagent.** The prior runs only covered clink (codex/antigravity) + qwen (`claude-9arm`). Explore agents are a different lever: same-vendor, metered, but they *shrink my context* the same way — I received three compact structured verdicts instead of reading ~30 files myself. For a **read-only fan-out verification** across independent areas, this beat both (a) doing it inline (context blowout) and (b) clink (no per-epic parallelism, giant echo). Constrain output ("report only") and they obey.
- **Verify-before-close earns its keep — delegated verification caught 2 real gaps.** Trusting the ledger + "PR merged" would have wrongly closed #18 (RLS existed on prod but **not in any committed migration** — a reproducibility drift the grep-only agent flagged) and #20 (the `pushed_at`-delta / WARM-tier poll was **never implemented**; the code comment defers it). The chat epic (#37/#38–43, #33, #35) verified clean with file:line. Lesson: a subagent auditing acceptance criteria against real code is a cheap, high-value gate before any bulk issue-close.
- **Ground-truth beats a stale ledger (prod DB check).** The ledger claimed a broad "~13 public tables have RLS disabled"; a direct `pg_class`/`pg_policies` query on prod showed RLS **already enabled + policied on the content tables** — only a small remaining set (a handful of chat/RAG tables) still needs the pass. The planned "big security epic" is really a small, focused job. (Exact tables/columns live in the project's private security note, not here.) Verifying against the live system, not the memory doc, re-scoped the work by ~4×.
- **Knowing when *not* to delegate is part of the discipline.** Declined to delegate the SHA/evidence gather to qwen — the source (the ledger) was already in my context, so the round-trip would have cost more than it saved. Logged as a decision (run 7), per the skill's own economics.

## The difficulty ladder — same task at 3 agents, escalating rungs (2026-07-16)

The deliberate experiment the research is *for*: run the **same** task at codex / antigravity / qwen,
starting trivial and climbing difficulty, verifying every output myself, to find **each agent's
breaking point**. Rungs R0–R2 are artifact-mode (return code, I run it); R3 is in-place agentic
(the agent must write files *and* run its own test). All 3 fired in parallel per rung.

| Rung | Task (identical prompt) | codex (GPT-5.6) | antigravity (Gemini) | qwen (`claude-9arm`, 35B) |
|---|---|---|---|---|
| **R0** trivial read — "list the exports of a small file" | ✅ correct, terse, 36s | ✅ correct, 22s, **no `<SUMMARY>`** | ✅ correct, 19s (no 524 today) |
| **R1** easy write — `chunkString` w/ surrogate-pair trap (don't split emoji) | ✅ `Array.from`, 31s | ✅ correct, 27s, **`<SUMMARY>` returned** | ✅ correct, 13s (fastest) |
| **R2** moderate — `mergeIntervals`, must merge *touching* + accept *unsorted* | ✅ correct, **no input mutation** | ✅ correct, **clones to avoid mutation** | ⚠️ **output correct but MUTATES the caller's input** (aliasing: `merged=[sorted[0]]` then writes `last[1]`) |
| **R3** hard multi-step agentic — write `slug.mjs` + `slug.test.mjs`, then **run the test** | ✅ **full loop**: wrote both, first run hit `ERR_MODULE_NOT_FOUND`, **self-corrected**, reported 3/3 PASS (verified by me) | ⚠️ **wrote correct code** (its own test passes when *I* run it) but **could not execute** — headless auto-denied the `command` permission → returned the jetski error instead of a result | ❌ **total failure**: ignored the given cwd, tried to write to the **repo root**, thrashed **13 turns** across Write/PowerShell/Bash, every attempt sandbox-denied, **0 files produced**, burned 729k input tokens |

**The breaking-point curve (verified, not eyeballed — I ran every artifact):**
- **qwen (index ~32):** clean through R1; **first crack at R2** — a *subtle* defect (correct output, hidden input-mutation) that an output-only test passes. **Shatters at R3**: doesn't respect the specified working directory (defaulted to the repo root), can't sequence a multi-step write→run, thrashes. Its failures are quiet at R2 and catastrophic-but-safe at R3 (only the sandbox stopped it polluting the repo).
- **antigravity (weak agentic 21–37):** solid *artifact* quality through R2 (even adds a defensive `typeof` guard at R3). **Breaks at R3's agentic step** exactly as the rubric predicts — its headless harness can't get the `command` permission to *run* anything, so it can produce code but never self-verify. Great single-shot artifact generator; useless for "do it and check it yourself."
- **codex (top tier):** **no break in R0–R3.** The only agent to close the full write→run→self-correct loop autonomously (R3), and separately it sustained a ~11-minute hard read-only adversarial review that surfaced 3 real findings. Its ceiling is above this ladder.

**New, verified findings (fold into `clink-subagents`):**
1. **qwen ignores the target cwd and defaults to the repo root.** In an in-place write via clink it repeatedly tried to write at the repo root despite an explicit scratch path. **The write sandbox / allow-rules are not optional for qwen** — they are the only thing that prevented repo pollution. Never give qwen unsandboxed write.
2. **antigravity can *write* but not *run* in headless.** Its files were correct; the `command`-permission wall (same one that no-ops its `codereviewer` role) blocks execution. So for antigravity, use **artifact mode and run/verify it yourself** — never ask it to "run the tests."
3. **qwen's R2 failure mode = subtle side-effects, not obvious wrongness.** Output-only tests pass; you need an *input-mutation / aliasing* check to catch it. This is the concrete reason the verify-everything rule matters most for the cheapest agent.
4. **codex is the only "delegate the whole leaf and trust-but-verify" agent** here — and even then I re-ran its passing test independently (it was genuinely green).
5. **`<SUMMARY>` tax is task-dependent for antigravity:** absent on the R0 one-word read, present on R1/R2 code returns. Strip it whenever output size matters.

## Codex adversarial review — R4-class, hard read-only agentic (sanitized)

`clink → codex` (`codereviewer`, effort `high`), pointed at a real security-sensitive change and asked to *break* it. **~11 min**, ~1.45M input (mostly cached) / 13.6k output; it connected to the live system for read-only catalog introspection on its own initiative and returned **three genuine, distinct findings** (one higher-severity pre-existing issue, one correctness/UX split-brain, one durability gap in the change itself) — all verified plausible, none hallucinated. **The specific findings are security-sensitive and live in the project's private security note, not this public research log.** The research takeaway (which is what belongs here): codex **sustains hard, context-heavy, genuinely-adversarial review that finds real issues** — its single best-fit delegation lane. Operational notes: the result again spilled to a ~64k-char one-line file (slice by character range, not Read's line offsets); ignore the trailing `bun`/`node` PATH-fail stderr noise.

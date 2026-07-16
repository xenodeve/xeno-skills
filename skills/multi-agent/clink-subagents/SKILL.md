---
name: clink-subagents
description: Delegate a well-scoped chunk of WORK (implementation, refactor, bulk transform, focused research, first-draft) to Codex (GPT-5.6) or Antigravity (Gemini) as a subagent via PAL's clink tool — to offload effort, parallelize, or save your context. Use when you have a self-contained, verifiable subtask a cheaper agent can do while you orchestrate. NOT for gathering opinions/consensus (use clink-brainstorm) and NOT for orchestration/judgment (keep that yourself). Covers which agent fits which task (grounded in Artificial Analysis index data + a local benchmark), how to prompt them, and the mandatory verify-everything discipline.
---

# clink-subagents

> **Requires [PAL MCP server](https://github.com/BeehiveInnovations/pal-mcp-server)** connected, with `clink` configured for `codex` and `antigravity` (see `conf/cli_clients/*.json`; Antigravity needs the [xenodeve/pal-mcp-server](https://github.com/xenodeve/pal-mcp-server) fork for its ConPTY driver on Windows). This skill is an orchestration layer on top of `mcp__pal__clink` — it does nothing standalone.
>
> **Companion, not overlap:** [`clink-brainstorm`](../clink-brainstorm/SKILL.md) fans a *question* out to many agents to gather *opinions*. **This skill delegates *work* to be *done* and *returned*.** Want a second opinion → brainstorm. Want a subtask executed → here.

## The core idea

You (the orchestrator) are the strongest **agentic** model in this setup — keep the decomposition, integration, judgment, and verification. Push the **leaves** of the work (self-contained, checkable subtasks) to a subagent, then verify and stitch. Delegate to *offload effort/context* or to *run independent chunks in parallel* — never to avoid thinking.

## When to delegate — and when not to

**Delegate** a subtask that is:
- **Self-contained** — fully specifiable in one prompt (the agent has *zero* conversation context).
- **Verifiable** — you can prove it right afterward (run a test, read the diff, check against a spec). If you can't verify it, don't delegate it.
- **Worth the latency** — each clink call is **~20–35s of CLI bootstrap** (a real agentic file-edit loop can be **~50s**). Never delegate something you'd finish correctly in less time.
- Good fits: a well-specified function/module, a mechanical refactor across a known site, a bulk format/transform, a first-draft you'll review, focused external-doc research/summarization.

**Never delegate** (keep it yourself):
- Orchestration, decomposition, deciding *what* to build, integration across the whole change.
- **Final verification** — the buck stops with you.
- Security / auth / permission-sensitive changes, or anything needing full session context or taste.
- Anything you can't independently check.

## Which agent — routing rubric

Grounded in **[Artificial Analysis](https://artificialanalysis.ai/models)** indices (2026-07) + a local benchmark. Scores: **Coding Index / Agentic Index**.

| Agent (`cli_name`) | Backend | Coding | Agentic | Delegate to it… | Guardrail |
|---|---|---|---|---|---|
| **`codex`** | GPT-5.6 (Sol/Terra/Luna) | **71–77 (top tier)** | **45–54 (top tier)** | Harder self-contained coding, edge-case-y implementation, focused code review, in-place edits of a known file | Elite *model*, but its **agentic harness is the weaker link** — it can mishandle multi-step tool/state workflows. Give a tight spec; **verify the output**. |
| **`antigravity`** | Gemini 3.x (`agy`) | 68–70 (ok) | **21–37 (weak)** ⚠️ | ONLY simple, **single-shot**, single-file, trivially-verifiable **artifact** tasks — a pure function, boilerplate, one format/transform, a focused lookup | **Weak at multi-step agentic** — never give it work where a wrong early step compounds. **In headless it can *write* files but cannot *run* anything** (any command tool auto-denies) — so use **artifact mode** and run/verify yourself; never ask it to "run the tests". Chatty: appends a `<SUMMARY>` block even when told "output only X" — strip it. |
| **you (orchestrator)** | e.g. Claude Opus 4.8 | ~74 | ~47 | — | Decompose, integrate, verify. Delegate the leaves, own the tree. |

Rule of thumb: **Codex for the hard leaf, Antigravity for the trivial leaf, you for the tree.** If a task needs more than one dependent step of judgment, it isn't a leaf — don't delegate it (least of all to Antigravity).

**Two more channels the rubric doesn't table:**
- **`claude-9arm` / qwen via clink** (the free/unlimited local model — details in `qwen-agent`): fine for **read/gather/format** leaves, but its quality cracks earlier than the others (see the ladder) — at a moderate task it can return **correct output with a hidden side-effect** (e.g. mutating its input) that an output-only test passes. And **it ignores the working directory you specify** — an in-place write defaulted to the *repo root* despite an explicit scratch path, so its **write sandbox / allow-rules are not optional**; never give qwen unsandboxed write. Verify its writes by diff, and its returns by checking for side-effects, not just output equality.
- **In-harness Task/Explore subagents** (your own platform's subagent, not clink): a distinct lever for **read-only fan-out** — dispatch several in parallel over independent areas, each returning a terse structured verdict, so you ingest conclusions not file dumps. Best for *verify-before-you-act* sweeps (e.g. audit N issues' acceptance criteria against real code before a bulk close); it shrinks *your* context the same way clink does, with per-area parallelism clink lacks. Constrain output ("report only, not file contents") and they obey.

## Token economics — what "cheaper" actually means

Measured 2026-07-16 (same tasks, a live repo). The back-ends are **billed differently**, so "count total tokens" is the wrong lens:

- **You (the orchestrator)** are the only **metered, context-window-bound** token pool — the scarce one.
- **`codex` / `antigravity` are subscription** — flat, **rate-limited**, not per-token-billed.
- **A local model** (e.g. Qwen via `claude-9arm` — see the `qwen-agent` skill) is **unlimited + $0**: its tokens cost only electricity + latency.

So **"cheaper" = fewer of *your* tokens**, and delegation wins whenever `(what you'd read + reason yourself) > (prompt + result you ingest + verification)`. Big-input / small-output / cheaply-verifiable → delegate. A 2-line edit in a file already in your context → do it yourself; the round-trip costs more of *your* tokens than the edit.

**The subagent's *returned* text is *your* tokens.** Constrain it hard ("return ONLY X"):
- `codex` obeys + is terse (5-bullet summary of an 8k-token file came back ~240 tok; a `NO BUGS FOUND` review, ~15).
- `antigravity` appends a `<SUMMARY>` block anyway (~+60% ingest) — strip it.
- A read-heavy `codex` **review** once echoed its whole transcript back = **91k chars ≈ 23k of your tokens**. For read-heavy delegations, say "return findings only, not the files."

**Pick the back-end by latency × intelligence × subscription-quota you'll spend — never by its token count** (free or flat). Unlimited menial bulk you don't want to bill to a subscription → the local model (slower, less smart). Must be *right* → `codex` (top intelligence *and* tersest = also cheapest on your pool). The ~130k-token harness overhead a fresh local `claude-9arm -p` call reloads each time is **free compute** — it costs you only latency, nothing metered.

**Antigravity's quota is split by vendor — and the non-Google side drains fast.** Within `agy` there are **two shared subscription pools**:
- **Google pool** — `Gemini 3.5 Flash` + `Gemini 3.1 Pro` share this one.
- **non-Google pool** — `GPT-OSS 120B` + `Claude Sonnet 4.6` + `Claude Opus 4.6` share this one, and it **burns noticeably faster** than the Google side.

So routing `antigravity` to a Claude/GPT route (e.g. for a non-OpenAI second opinion) is fine *occasionally*, but it drains the non-Google allowance quickly; keep bulk/repeated antigravity work on the cheaper Gemini pool and spend the Claude/GPT route only when a different vendor's judgment is the point.

## How to delegate (the call)

`mcp__pal__clink(prompt, cli_name, role?, continuation_id?, images?)`

1. **Self-contained prompt.** The agent has **zero** context from your conversation. Put *everything* in the prompt: absolute paths, the exact I/O contract, constraints, and an explicit "return ONLY X" / "edit in place, don't ask". Vague prompt → it guesses.
2. **Pick a mode:**
   - **Artifact mode (safe default):** ask it to **return** the code/text; *you* review and integrate. Use for anything with any risk.
   - **In-place mode:** clink runs Codex/Antigravity with **bypass-approvals/sandbox** flags, so they *can* read and **mutate the repo directly**. Only let them edit files for **low-risk, well-scoped, verifiable** changes — then **diff + test**.
3. **Parallelize** independent delegations — multiple `clink` calls in one message (bounded by the slowest, not the sum).
4. **`role`** preset: `default` | `planner` | `codereviewer`. Use `codereviewer` when delegating a review; `planner` for a scoped plan you'll execute.
5. **`continuation_id`** (returned each call) — reuse it to follow up with the *same* agent in the *same* thread (≈49 turns) without re-sending context.
6. **File access:** prefer putting the absolute path *in the prompt text* and telling the agent to read it with its own tools. (Some orchestrators' permission classifiers block the `absolute_file_paths` parameter into repo source even with consent — don't fight it; use the prompt-text path instead.)

## Model & reasoning level — per call (this fork) or in config

This [PAL fork](https://github.com/xenodeve/pal-mcp-server) adds two **optional per-call** `clink` params — `model` and `reasoning_effort` — so you can dial capability per delegation without editing config. Support differs by back-end (all verified live 2026-07-16):

| Back-end | `model` (per call) | `reasoning_effort` (per call) | Notes |
|---|---|---|---|
| **`codex`** | ✅ `-m <model>` — **validated** (invalid model → hard 400 error) | ✅ `-c model_reasoning_effort=` — `low\|medium\|high\|xhigh\|max` (reasoning tokens scale with it) | Full support. This account exposes `gpt-5.6-sol`, `gpt-5.6-luna`, `gpt-5.5`. |
| **`antigravity`** | ✅ `--model "<label>"` — **fail-closed** (invalid → exit 1 + catalog) | ➖ no separate flag — effort is **baked into the model label** (`(Low/Medium/High)`, `(Thinking)`) | agy's `--model` **must precede `--print`** (value-taking flag) or it's silently swallowed → default model; the fork's runner handles ordering. See gotchas. |
| **`claude-9arm`** (Claude Code → a gateway model, e.g. Qwen) | ✅ `--model` (last-wins) — **limited to what the gateway serves** | ❌ **no-op** — not a `claude`/gateway flag (this Qwen gateway has only thinking on/off, no graded effort) | Activate by copying `claude-9arm.json.example` → `.json` with your `claude.exe` + `--settings`/`--model`. |

Omit both to use the CLI's **config default** (Codex reads `~/.codex/config.toml`; others use their client `additional_args`). Effort has steep diminishing returns — `medium`/`high` is the sweet spot; reserve `max`/`xhigh` for the hardest leaf.

**Config-based selection (still valid):** pin `-m`/`--model`/`-c` in a client's `additional_args` (every call) or a role's `role_args`, or define multiple pinned clients (`codex-high.json`, `codex-fast.json`) selected via `cli_name`. **Restart PAL after any config edit** (cached at server start).

## The non-negotiable rule: verify everything they return

**A subagent's output is unverified until you prove it.** This is the whole discipline — a strong model behind a weaker agent harness still produces output you cannot trust on faith:
- Ran code? Run the test / execute it yourself.
- Edited files? Read the **diff**, then run the build/tests.
- Made a claim? Check it against the real code.
- **Check for side-effects, not just output equality.** A weaker agent (esp. qwen) can return *correct output* while mutating its input or leaving hidden state — an output-only test passes it. Diff, and assert the input is unchanged where it should be.
- **Run the real thing, not only the unit tests.** Unit tests pass a lot that a real build/boot rejects: a delegated (or your own) edit once passed `bun test` but broke `nest build` (an `import.meta` that the CommonJS build forbids) — only starting the server surfaced it. For anything that compiles/boots/serves, run the actual build + boot after verifying units.
- Antigravity especially: correct-*looking* but weaker — re-check the logic and **strip its `<SUMMARY>`** before using anything.

If your repo has agent operating rules (e.g. an `AGENTS.md`), a delegated subagent is bound by the same rules — and *you* are accountable for enforcing them on its output.

## Benchmark of record (re-run for your setup)

Snapshots that calibrated the rubric — **synthetic** plus **real tasks in a live repo** (T4-Fastwork as sandbox, 2026-07-16):

**Synthetic (coding):** `merge_intervals` + a `median` bug-fix (artifact) → 4/4 correct; Codex ~26–31s (clean), Antigravity ~21–30s (correct, always `<SUMMARY>`). In-place: Codex patched an `average()` empty-list guard, verified by running → ~50s.

**Real-repo (T4-Fastwork):**
- *Summarize a 30,696-char ledger → 5 bullets:* **Codex** 37s, input 50k (20k cached), result **~240 tok**, obeyed "only 5 bullets". **Antigravity** 38s, appended `<SUMMARY>`, ~375 tok. **Qwen/`claude-9arm`** (local) 64s, input **130k** (full CC harness, uncached) but free, ~464 tok, accurate + honest. Doing it myself ≈ **8.5k of *my* tokens**; delegating ≈ 240–464.
- *Adversarial review of a real regex fn (`tagForKey`); correct answer = no bug:* **Codex** (`codereviewer`) → `NO BUGS FOUND` in **19s**, 144 out — **correct** (no hallucinated false-positive), terse. **Antigravity** (`codereviewer`) → **failed**: its harness tried a command tool that headless auto-denied → no review produced (see Gotchas).

**Difficulty ladder — the same task at all three, escalating, every artifact re-run to verify (2026-07-16).** This is the sharpest calibration: it finds *where each agent breaks*.
- **R0 trivial** (list a file's exports) → all three correct + terse (~19–36s). Floor.
- **R1 easy write** (a pure fn with a surrogate-pair trap) → all three correct (all knew the code-point idiom).
- **R2 moderate** (`mergeIntervals`, must merge touching + accept unsorted) → codex + antigravity correct **and side-effect-free**; **qwen correct output but MUTATED the caller's input** (aliasing) — the first crack, and an *invisible* one (output-only tests pass).
- **R3 hard, multi-step agentic** (write two files + run the test) → **codex ✅ full loop** (wrote, first run errored, **self-corrected**, verified); **antigravity ⚠️** wrote correct files but **couldn't run them** (headless command wall) → no self-verify; **qwen ❌ total failure** — ignored the given cwd, thrashed 13 turns writing to the repo root, sandbox-denied all, 0 files.
- **Breaking-point curve:** qwen cracks at R2 (subtle), shatters at R3 (agentic); antigravity is a solid *artifact* generator but breaks at "run it yourself"; **codex holds through R3** and sustained an ~11-min adversarial review that surfaced 3 real findings. Its ceiling is above this ladder.

**Takeaway:** Codex is the reliable default — top intelligence, follows tight output constraints, cheapest on *your* pool, no false-positive on a clean-code review. Antigravity is fine only for the trivial single-shot **`default`-role** leaf; its `codereviewer` role can no-op in headless. A local model is the free/unlimited option when you're offloading bulk, not chasing quality. **Snapshot — re-run if the CLIs/models change.**

## Gotchas

- **clink client config is cached at PAL server start.** Editing `conf/cli_clients/*.json` (e.g. changing a model or args) has no effect until PAL is restarted — don't conclude a change failed before restarting.
- **`command` must resolve from PAL's process env**, not just your shell. If a clink call errors "not found", use the absolute path to the exe in the config. The bare `gemini` CLI is **retired** → use `antigravity`.
- **Harmless Codex noise:** its stderr often shows `rmcp … DELETE returned HTTP 404 session` — ignore it; check `return_code` and the content instead.
- **Antigravity's `codereviewer` role can no-op in headless.** It may invoke a command tool that headless mode auto-denies (`jetski: no output produced … required the "command" permission`) and return that error *instead of* a review — with `return_code: 0`, so check the **content**, not just the code. Safe fix: use `role: default` for Antigravity (its plain-Q&A path doesn't hit this), or grant that one tool a scoped allow-rule in the CLI's own settings. Codex's `codereviewer` role is unaffected.
- **Antigravity `--model` must come BEFORE `--print`.** `agy`'s `--print` is a **value-taking** flag (it consumes the next token as the prompt), so `agy --print --model "X" "<prompt>"` swallows `--model` as the prompt → agy runs with an empty model and **silently falls back to its default** (always reports *Gemini 3.5 Flash* regardless of what you asked). Correct order: `agy --model "X" --print "<prompt>"` (live-verified). This fork's Antigravity runner already emits that order and fails closed on a non-zero exit; if you hand-build an `agy` command, mind the order and check the exit code (an unsupported model exits `1` with a catalog).
- **Don't paste secrets** (`.env` values, tokens) into a clink prompt — you're sending to a third-party CLI/model. (During this work a GitHub PAT was found sitting in `~/.gemini/config/config.json` and echoed by an `agy` diagnostic log — audit those too.)
- **Latency is the real budget**, not (flat-rate) cost — a multi-delegation round is a multi-minute wall-clock operation. Parallelize, and don't delegate the trivial.

## See also

- **[`clink-brainstorm`](../clink-brainstorm/SKILL.md)** — the opinion/consensus counterpart (multi-agent fan-out + adversarial rounds).
- **[`karpathy-guidelines`](../../karpathy-guidelines/SKILL.md)** — the discipline to hold delegated work to (simplicity, surgical, verify).

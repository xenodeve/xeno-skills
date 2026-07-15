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
| **`antigravity`** | Gemini 3.x (`agy`) | 68–70 (ok) | **21–37 (weak)** ⚠️ | ONLY simple, **single-shot**, single-file, trivially-verifiable tasks — a pure function, boilerplate, one format/transform, a focused lookup | **Weak at multi-step agentic** — never give it work where a wrong early step compounds. Chatty: appends a `<SUMMARY>` block even when told "output only X" — strip it. |
| **you (orchestrator)** | e.g. Claude Opus 4.8 | ~74 | ~47 | — | Decompose, integrate, verify. Delegate the leaves, own the tree. |

Rule of thumb: **Codex for the hard leaf, Antigravity for the trivial leaf, you for the tree.** If a task needs more than one dependent step of judgment, it isn't a leaf — don't delegate it (least of all to Antigravity).

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

## The non-negotiable rule: verify everything they return

**A subagent's output is unverified until you prove it.** This is the whole discipline — a strong model behind a weaker agent harness still produces output you cannot trust on faith:
- Ran code? Run the test / execute it yourself.
- Edited files? Read the **diff**, then run the build/tests.
- Made a claim? Check it against the real code.
- Antigravity especially: correct-*looking* but weaker — re-check the logic and **strip its `<SUMMARY>`** before using anything.

If your repo has agent operating rules (e.g. an `AGENTS.md`), a delegated subagent is bound by the same rules — and *you* are accountable for enforcing them on its output.

## Benchmark of record (example — re-run for your setup)

A local snapshot (2026-07-16) that calibrated the rubric above:
- **Artifact mode:** `merge_intervals` + a `median` bug-fix → **4/4 correct**; Codex ~26–31s (clean output), Antigravity ~21–30s (correct, always appends `<SUMMARY>`).
- **In-place mode:** Codex read + patched a file's `average()` (empty-list guard) correctly, verified by running it → ~50s.
- **Takeaway:** both are reliable for simple→moderate coding; Codex follows tight output constraints better; Antigravity is fine only for the trivial single-shot leaf. **These numbers are a snapshot — re-run a quick benchmark if the CLIs/models change.**

## Gotchas

- **clink client config is cached at PAL server start.** Editing `conf/cli_clients/*.json` (e.g. changing a model or args) has no effect until PAL is restarted — don't conclude a change failed before restarting.
- **`command` must resolve from PAL's process env**, not just your shell. If a clink call errors "not found", use the absolute path to the exe in the config. The bare `gemini` CLI is **retired** → use `antigravity`.
- **Harmless Codex noise:** its stderr often shows `rmcp … DELETE returned HTTP 404 session` — ignore it; check `return_code` and the content instead.
- **Don't paste secrets** (`.env` values, tokens) into a clink prompt — you're sending to a third-party CLI/model.
- **Latency is the real budget**, not (flat-rate) cost — a multi-delegation round is a multi-minute wall-clock operation. Parallelize, and don't delegate the trivial.

## See also

- **[`clink-brainstorm`](../clink-brainstorm/SKILL.md)** — the opinion/consensus counterpart (multi-agent fan-out + adversarial rounds).
- **[`karpathy-guidelines`](../../karpathy-guidelines/SKILL.md)** — the discipline to hold delegated work to (simplicity, surgical, verify).

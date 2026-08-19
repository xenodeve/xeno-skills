# Research

Empirical research that calibrated the skills in this repository — how delegation is routed, and how
this library composes with the ecosystems it sits on top of. One dated file per topic.

## Index

- [CLI capability reference](cli-capability-reference.md) — **the distilled answer, kept short enough to
  read before implementing.** Per harness: what is native, what you build yourself, and the traps that
  cost the most time. Claude Code needs almost nothing built; codex needs an evaluator; cursor needs four
  things and carries four separate silent-death paths; agy needs three, one of them mandatory. Plus the
  layer you build once regardless of host. Evidence and method live in the dated file below.
- [2026-08-14 — The compliance-hook surface on codex, cursor-agent and agy](2026-08-14-compliance-hook-surface-across-harnesses.md)
  — can each foreign CLI run a compliance reviewer the way Claude Code can? Nine questions per client,
  commissioned for #176 and #208. **Only Cursor has a built-in model evaluator** (`prompt` hooks, fast
  model, per-hook override); codex parses `prompt` and `agent` handlers and **skips them** — confirmed
  at binary grade against the installed `codex`, which carries `prompt hooks are not supported yet`
  verbatim. Cursor's transcript **deliberately omits tool outputs**, so a history-only reviewer cannot
  judge what a command returned there. `SubagentStop` on codex and cursor is a native worker-side
  continuation point carrying the child's transcript path. Closing recommendation: normalise the
  *capabilities*, not the client names. **Documentation-grade except where noted** — the research
  environment had none of the three CLIs installed, which the file states up front. **Three addenda carry
  the live probes, and the third refutes the second:** all three CLIs run hooks headless. Cursor's native
  `prompt` evaluator is verified live, mid-turn delivery with it — but its `stop` event does not fire
  under `-p`. agy blocks at `Stop` and obeys the reason, and **`{"decision":"continue"}` there loops the
  agent 168 turns to a timeout while silence is what releases it.** Both clients do report their errors,
  just not to stdout, which is why the earlier "both are silent" reading was wrong.
- [2026-07-16 — Subagent delegation log](2026-07-16-subagent-delegation-log.md) — qwen / codex /
  antigravity delegation runs (latency, quality, failure modes) + the real-task sandbox experiments
  + the **graduated difficulty-ladder (R0–R3 breaking points)** that fed the `clink-subagents` skill
  (routing rubric, benchmark, and verify-everything gotchas all folded back in 2026-07-17).
- [2026-07-16 — Subagent vs self: token economics](2026-07-16-subagent-vs-self-token-economics.md) —
  the two-pool cost model (your metered tokens vs free-local / flat-subscription); when delegating
  actually saves your tokens.
- [2026-08-12 — thai-token-optimizer hook architecture](2026-08-12-thai-token-optimizer-hook-architecture.md) —
  a 14-agent read of the nearest working reference for hook-based skill injection. The reusable finding is
  a **mirror image**: TTO injects at the point of action with content computed from the tool call and never
  denies; our gate denies at that same event and injects nothing. Neither project does both, and both are
  available. Also: `preservation 100%` is definitional — it returns 100 when zero technical items are
  extracted, so deleting the whole prompt scores 100 — no published figure comes from a real tokenizer,
  and a `UserPromptSubmit` hook awaits `/dev/tty` with **no timeout** on its default path, which on Windows
  kills the hook silently while emitting no JSON. **Records a defect in the research run itself:** the
  synthesiser never received the refutation payload, so two refuted claims are stated as fact in the report
  it wrote; the corrections sit above it rather than being merged in. Bears on #149, #155, #143 and #145.
- [2026-08-04 — xeno-skills × pbakaus/impeccable composition audit](2026-08-04-xeno-vs-impeccable-composition-audit.md)
  — the fourth ecosystem, which the first three audits did not know existed. Refutes the "design/* is
  genuine delta" conclusion, but not the way a grep suggested: impeccable saw those numerics and
  **declined** them. Also the `PRODUCT.md` collision, a UI trigger that does nothing, and the only
  test suite among the four that asserts on behaviour rather than text.
- [2026-08-04 — xeno-skills × thananon/9arm-skills composition audit](2026-08-04-xeno-vs-9arm-composition-audit.md)
  — the third ecosystem, at `a1fc303`. The smallest library and the most cited: `/scrutinize` earns it,
  `/debug-mantra` does not (it is `diagnosing-bugs` compressed — same random hex in the example). Also:
  the one hand-off the entry map explicitly claims does not exist in the file it names.
- [2026-08-04 — xeno-skills × obra/superpowers composition audit](2026-08-04-xeno-vs-superpowers-composition-audit.md)
  — the same check against the second ecosystem, at `44c9b2d`. Against pocock the defects were mostly
  duplication; against superpowers they are mostly **contradiction** — nine places where the two give
  opposite instructions, two of them enforced mechanically by the T4 gate. Also: the hooks-collision
  hypothesis, stated up front and **disproved**.
- [2026-08-04 — xeno-skills × mattpocock/skills composition audit](2026-08-04-xeno-vs-mattpocock-composition-audit.md)
  — whether this library actually hands technique off to the ecosystem it claims to sit on, checked
  against `mattpocock/skills` at `2ab9580`. Finds self-contradictions, five direct conflicts with
  upstream, the `CONTEXT.md` glossary collision, and two retired skill names still cited here.
- [2026-07-16 — Model × Effort capability matrix](2026-07-16-model-effort-capability-matrix.md) — the
  usable model×effort routing ladder cross-referenced with the Artificial Analysis Intelligence Index.

_(These describe how to **route delegation** — the domain of the `multi-agent` skills here — so they
live with the skills. The clink code itself, and its Antigravity model-override bug, live in the
[pal-mcp-server fork](https://github.com/xenodeve/pal-mcp-server) `docs/reports/`.)_

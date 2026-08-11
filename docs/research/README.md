# Research

Empirical research that calibrated the skills in this repository — how delegation is routed, and how
this library composes with the ecosystems it sits on top of. One dated file per topic.

## Index

- [2026-07-16 — Subagent delegation log](2026-07-16-subagent-delegation-log.md) — qwen / codex /
  antigravity delegation runs (latency, quality, failure modes) + the real-task sandbox experiments
  + the **graduated difficulty-ladder (R0–R3 breaking points)** that fed the `clink-subagents` skill
  (routing rubric, benchmark, and verify-everything gotchas all folded back in 2026-07-17).
- [2026-07-16 — Subagent vs self: token economics](2026-07-16-subagent-vs-self-token-economics.md) —
  the two-pool cost model (your metered tokens vs free-local / flat-subscription); when delegating
  actually saves your tokens.
- [2026-08-11 — OpenCode compatibility survey](2026-08-11-opencode-compatibility-survey.md) — the
  skills already run in OpenCode **unchanged**: `opencode debug skill` (1.18.15) loads all 14 of ours,
  resolved from `~/.agents/skills/`, and `CLAUDE.md` is a documented fallback for rules. It enforces
  the same name-matches-directory and no-nesting constraints that produced #45. Qualifies the premise
  in `guards-layer.md`: OpenCode has its own blocking `tool.execute.before` hook, so Claude is not the
  only agent with a native gate — Tier 0.5 still stands for Codex/Gemini/humans. The T4 dispatcher
  ports on the **compact** leg only (`experimental.session.compacting` → `output.context.push`);
  there is no session-start injection hook. Bears on #83, #85 and #126. Nothing acted on — no plugin
  was written or run.
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

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

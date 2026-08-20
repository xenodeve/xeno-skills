# What compaction actually returns — 113 real compactions, measured

**Measured 2026-08-21** from the session transcripts in `~/.claude/projects/` — ten projects, every
`system` / `compact_boundary` record in a transcript over 200 KB. **Not a benchmark: this is what
happened in work that was done for its own reasons.**

**Why it exists.** The #305 probe measured a compaction that returned **9 %**, and the plan carried that
figure as if it were representative. The developer said he had watched Claude Code go from 90 % of the
window to under 10 %. **He was right and the probe was the pathological case** — it had ~9 K of
conversation sitting on a ~41 K prefix, so there was almost nothing to compress.

## Method

For each `compact_boundary` in a transcript: the **total input** of the last assistant turn *before* it,
against the first assistant turn *after* it, where total input is

```
input_tokens + cache_creation_input_tokens + cache_read_input_tokens
```

**Reading `cache_read` alone is the mistake that produced the 9 % claim** — a compaction moves tokens
from `cache_read` into `cache_creation`, so that field falls much further than the context does.

## Result

| context before | n | median drop | median tokens saved | median context after |
|---:|---:|---:|---:|---:|
| **≥ 500 K** | 70 | **88 %** | 740,539 | 105,471 |
| 250 K – 500 K | 12 | 76 % | 288,123 | 87,096 |
| 150 K – 250 K | 7 | 60 % | 105,827 | 80,885 |
| **< 150 K** | 24 | **−0 %** | **−52** | 101,937 |

**Median across all 113: 85 %, and the median context before compacting was 719 K** — the 88 % row is the
≥ 500 K band, which is 70 of the 113 because auto-compaction fires near the ceiling.

## The two numbers that decide the design

**1. There is a floor, and it is ~70–105 K.** Whatever the session was, a compacted session costs about
that much: the system prompt, the tool definitions, `CLAUDE.md`, the skills, and the summary itself. The
floor is not compressible by compacting again.

**2. Below ~150 K, compaction returns nothing — and 12 % of the sample (13 of 113) came back *larger*.**
Every one of those thirteen was between 90 K and 110 K before, which is the floor. Compacting a session
that is already at the floor pays the summarisation and the cache rewrite for no reduction.

## What this means for T4-Compact (PRD #304)

- **The "context is long" trigger now has a measured threshold rather than a guess:** do not call the
  layer below **~150 K**, and expect a real return only above **~250 K**. That is the shape of the data,
  not a preference.
- **The "task finished" trigger must carry the same floor.** A clean semantic boundary at 80 K is a
  boundary at the floor — the handoff is still worth writing, the compaction is not worth asking for.
- **The developer's observation is the median case, not the optimistic one.** 88 % at ≥ 500 K, and the
  ≥ 500 K band is 70 of 113 compactions, because auto-compaction fires near the ceiling.

## What the floor is made of, and what it means for a small-context worker

Same corpus, two more measurements — 36 sessions, **32,484 turn-to-turn deltas**:

| Quantity | Median | Spread |
|---|---:|---|
| **Fixed prefix** — first assistant turn of a session (system prompt + tool definitions + `CLAUDE.md` + skills) | **62,842** | 31,931 – 399,516; per project 35 K (`Agent-Island`) to 83 K (`TipSpace`); this repo 40,529 |
| **Growth per assistant turn** | **1,223** | mean 2,048 · p90 **4,221** |
| **Post-compaction floor** | **100,514** | of which the session's own prefix was ~47,460 — so **the summary and carried tail are ~50,703** |

**A `/compact` summary is not small. It measures ~50 K.**

### The arithmetic for a 128 K worker

| Setup | Prefix | After a compaction | Room left in 128 K |
|---|---:|---:|---:|
| a session like the ones measured here | ~63 K | ~100 K | **~28 K** |
| a lean worker: few tools, small `CLAUDE.md`, no skill library | ~15 K | prefix + a ~3 K handoff ≈ 18 K | **~110 K** |

**So the answer depends entirely on the prefix, and `/compact` is the wrong instrument at this size.**
Two facts collide: the measured floor is ~100 K, and **every compaction below 150 K returned −0 %**. A
128 K window lies *entirely inside the dead zone* — a worker that fills it and compacts gets back a
session that is still ~78 % full, and it will be full again in **~7 turns** at the mean growth rate.

**The reopen path is therefore not the fallback for a small-context worker; it is the mechanism.**
Ending the session and reopening it with the handoff replaces a ~50 K summary with a handoff the author
controls — a few K — so the cycle resets to *prefix + handoff* rather than to the floor. At 15 K of
prefix and 2,048 tokens per turn, that is **~54 turns per cycle**, indefinitely repeatable.

**And turns are a soft unit.** p90 growth is 4,221 tokens and a single large file read is worth tens of
thousands, so a 128 K worker is one careless `Read` away from the ceiling regardless of the cycle length.
The lever that matters most is not the compaction policy — **it is the prefix**, which is paid on every
turn of every cycle and is the one number a worker's operator fully controls.

## A `clink` leaf worker is a different shape, and does not need compaction at all

The numbers above are for a **session**: one conversation that grows turn after turn. A worker driven by
`clink-subagents` is not that. Its own skill states the constraint: a leaf must be *"fully specifiable in
one prompt (the agent has **zero** conversation context)"*. It starts, does one checkable thing, returns,
and is gone.

**So the master's growth curve never applies to it, and T4-Compact protects the master, not the worker.**

**What actually occupies a leaf's 128 K**, in the order the tokens arrive:

| Component | Size | Note |
|---|---:|---|
| the worker harness's own prefix | **unmeasured here** | this harness's is 35–83 K depending on the project; a `codex`/`antigravity` CLI carries its own, and **nobody has measured it — do that before trusting any budget** |
| skills the master must hand over | `karpathy-guidelines` **~1.3 K**, `tdd` **~0.8 K** | measured from the files. Cheap, and **not** `clink-subagents` itself — that is the master's 14.5 K and must never be pasted into a worker |
| the request payload | **~0.5–1 K** | the `request-v1` shape |
| **what the leaf reads and produces** | **everything else** | the only component that varies by an order of magnitude |

**The binding constraint is leaf sizing, not compaction.** A leaf that must read twenty files at ~3 K
each spends 60 K before it starts working — half a 128 K window — and the delegation economics in
`clink-subagents` push exactly the *big-input* cases toward a worker. The two rules pull against each
other at 128 K, and leaf sizing is the one that has to give:

- **Size a leaf so that reads plus expected tool output stay under ~60 % of the worker's window.**
- **Hand over content, not a search.** Pasting the relevant excerpt costs the master tokens once; making
  the worker find it costs the worker's window every time, and the worker has less of it.
- **A leaf that does not fit is not a leaf.** Split it — that is the decomposition rule, arriving as a
  budget rather than a preference.

**And if the worker is a local model, filling the window is slow as well as tight.** The adjacent
project measured a 114,406-token prompt at **10/10 retrieval quality** — the quality holds — but a cold
prefill at that depth is minutes, so a leaf that fills 128 K pays for it twice.

## What this does NOT measure

**Whether compaction helped.** It measures size before and after — nothing about whether the work
continued as well, whether anything needed re-reading afterwards, or whether errors rose. That question
needs the paired run this repository does not yet have a harness for, and it is the same gap #312 states
in its own body.

**Reproduce:** `scripts/measure-compaction-yield.py` (reads only local transcripts; writes nothing).

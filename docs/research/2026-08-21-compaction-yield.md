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

## What this does NOT measure

**Whether compaction helped.** It measures size before and after — nothing about whether the work
continued as well, whether anything needed re-reading afterwards, or whether errors rose. That question
needs the paired run this repository does not yet have a harness for, and it is the same gap #312 states
in its own body.

**Reproduce:** `scripts/measure-compaction-yield.py` (reads only local transcripts; writes nothing).

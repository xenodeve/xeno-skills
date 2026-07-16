# Model × Effort capability matrix — our clink/local stack (2026-07-16)

Research to inform a future **pal-mcp-server** change (exposing model/effort per call).
Enumerates **every model × effort we can actually invoke** on each platform, cross-referenced
with **live [Artificial Analysis](https://artificialanalysis.ai/models) Intelligence Index**
scores (fetched 2026-07-16, not memory).

> **Scale note (read first):** the numbers below are the **AA Intelligence Index v4.1** — a
> *composite* of 9 evals (GDPval-AA, τ³-Banking, Terminal-Bench v2.1, SciCode, HLE, GPQA
> Diamond, CritPt, AA-Omniscience, AA-LCR), frontier ≈ **60**. This is a **different scale**
> from the "Coding Index 71–77 / Agentic Index 45–54" the `clink-subagents` skill table uses
> (an older sub-index). Don't mix them. Higher = smarter, either way.

## What we can actually invoke

- **Codex** (`~/.codex/config.toml`): models available to this account = **`gpt-5.6-sol`** (default) + **`gpt-5.5`**. Effort = `model_reasoning_effort` ∈ {low, medium, high, xhigh, max}, set via `-c model_reasoning_effort=…` or `-m`. Default: `gpt-5.6-sol` @ `medium`.
- **Antigravity** (`agy models`): Gemini 3.5 Flash (Low/Med/High), Gemini 3.1 Pro (Low/High), **Claude Sonnet 4.6 (Thinking)**, **Claude Opus 4.6 (Thinking)**, GPT-OSS 120B (Medium). Effort is **baked into the model name**; select via `--model "…"`.
- **Local** (`claude-9arm`): **Qwen 3.6 35B A3B** (reasoning). Free + unlimited.

## The matrix (AA Intelligence Index v4.1)

| Platform | Model | Effort | **AA Intel Index** | Source |
|---|---|---|---|---|
| **Codex** | gpt-5.6-sol | **max** | **59** ← our ceiling | AA FAQ / [gpt-5-6-sol](https://artificialanalysis.ai/models/gpt-5-6-sol) |
| Codex | gpt-5.6-sol | xhigh | 58 | AA FAQ |
| Codex | gpt-5.6-sol | high | 56 | AA FAQ |
| Codex | gpt-5.6-sol | medium *(default)* | ~53–54 *(est; not published)* | interpolated |
| Codex | gpt-5.5 | xhigh | 55 | [gpt-5-5](https://artificialanalysis.ai/models/gpt-5-5) |
| Codex | gpt-5.5 | high | 53 | [gpt-5-5-high](https://artificialanalysis.ai/models/gpt-5-5-high) |
| Codex | gpt-5.5 | medium | 50 | [gpt-5-5-medium](https://artificialanalysis.ai/models/gpt-5-5-medium) |
| Codex | gpt-5.5 | low | 42 | [gpt-5-5-low](https://artificialanalysis.ai/models/gpt-5-5-low) |
| **Antigravity** | Claude Opus 4.6 (Thinking) | max | **53** | [claude-opus-4-6](https://artificialanalysis.ai/models/claude-opus-4-6) |
| Antigravity | Claude Sonnet 4.6 (Thinking) | max | 51 | [sonnet-4-6](https://artificialanalysis.ai/articles/sonnet-4-6-everything-you-need-to-know) |
| Antigravity | Gemini 3.5 Flash | high | 50 | [gemini-3-5-flash](https://artificialanalysis.ai/models/gemini-3-5-flash) |
| Antigravity | Gemini 3.1 Pro | high | 46 | [gemini-3-1-pro-preview](https://artificialanalysis.ai/models/gemini-3-1-pro-preview) |
| Antigravity | Gemini 3.5 Flash | medium | 45 *(est)* | AA |
| Antigravity | GPT-OSS 120B | high | 24 | [comparison](https://artificialanalysis.ai/models/comparisons/qwen3-6-35b-a3b-vs-gpt-oss-120b) |
| **Local** | **Qwen 3.6 35B A3B** | reasoning | **32** | [comparison](https://artificialanalysis.ai/models/comparisons/qwen3-6-35b-a3b-vs-gpt-oss-120b) |

*(For reference, not in our stack: Claude Opus 4.8 = 56, Claude Fable 5 = 60, GPT-5.6 Sol max = 59 is the top of what we can call.)*

## What the numbers say (→ routing design for pal-mcp)

1. **Effort is a first-class capability lever, not a footnote.** On a *fixed model*, effort moves the score massively: **gpt-5.5 low → xhigh = 42 → 55 (+13)**; gpt-5.6-sol high → max = 56 → 59. Dialing effort down on a trivial leaf saves latency/quota; dialing it up rescues a hard one — **without changing model**. This alone justifies exposing effort per call.
2. **Our real capability ladder** (best usable at each tier):
   - **Top (56–59):** `gpt-5.6-sol` @ high/xhigh/max — the hard leaf.
   - **Strong (50–55):** `gpt-5.5` @ med/high/xhigh, or Antigravity→**Claude Opus 4.6 (53)** / Sonnet 4.6 (51) — normal leaves + a *non-OpenAI* second opinion.
   - **Mid (45–50):** Gemini 3.5 Flash (high 50 / med 45), Gemini 3.1 Pro (46) — cheap, fast, single-shot.
   - **Low but FREE/UNLIMITED (32):** Qwen 3.6 35B A3B (`claude-9arm`) — mechanical bulk only; ~half the frontier's index.
   - **Avoid (24):** GPT-OSS 120B — dominated by everything above.
3. **Antigravity's default (Gemini Flash, 50) is NOT its smartest route.** `agy` can route to **Claude Opus 4.6 (53)** / Sonnet 4.6 (51) — higher than Flash and ≈ codex gpt-5.5. If pal exposes antigravity model choice, prefer the Claude/Gemini-Pro routes for quality; Flash-low only for speed. (Caveat: routing antigravity→Claude 4.6 delegates to almost the orchestrator's own family — worth it for parallelism/offload, marginal for a "different perspective".)
4. **Qwen's 32 quantifies "dumb but free."** It's ~54% of our ceiling (59). Fine for read/gather/format where correctness is cheaply verifiable; **not** for judgment. The earlier economics doc's "use qwen for free bulk" now has a number behind it.

## Implication for the pal-mcp change (pre-work, not yet done)

- **Add `model` + `effort` params to the `clink` tool** in the `xenodeve/pal-mcp-server` fork, mapping:
  - codex → `-m <model> -c model_reasoning_effort=<effort>`
  - antigravity → `--model "<Model (Effort)>"` (effort is in the name)
- **Or (no-fork path):** predefine client variants — `codex-max.json` (`-c model_reasoning_effort=max`), `codex-fast.json` (`gpt-5.5` `low`), `antigravity-opus.json` (`--model "Claude Opus 4.6 (Thinking)"`) — select via `cli_name`. Restart PAL after edits.
- **Default routing suggestion:** hard leaf → `gpt-5.6-sol` high(56)+; normal → `gpt-5.5` medium(50)/high(53); trivial/bulk you won't bill → Qwen(32); need a non-OpenAI check → antigravity `Claude Opus 4.6`(53).

## Update — AA cost/effort charts (user-supplied, 2026-07-16)

Three AA charts sharpened the picture: the **GPT-5.6 effort ladders** (Sol/Terra/Luna + 5.5), **cost-per-Intelligence-Index-task**, and the **intelligence-vs-cost** scatter (green = "most attractive quadrant" = high intel + low cost).

### GPT-5.6 family — full effort ladder (Intelligence Index @ AA cost/task)

GPT-5.6 ships in **3 size tiers: Sol > Terra > Luna** (we default to `gpt-5.6-sol`; Terra/Luna may need `-m gpt-5.6-terra|luna` — **verify account access**, the NUX only listed sol + 5.5).

| Model | low | medium | high | xhigh | max |
|---|---|---|---|---|---|
| **Sol** (biggest) | 49.5 ($0.20) | 53.5 ($0.31) | **56 ($0.45)** | 58 ($0.68) | **59 ($1.04)** |
| **Terra** (mid) | 40.5 ($0.10) | 45.5 ($0.15) | 49 ($0.24) | 51.5 ($0.33) | **55 ($0.55)** |
| **Luna** (small) | 33 ($0.04) | 38 ($0.05) | 46 ($0.09) | 49 ($0.10) | 51 ($0.21) |
| **GPT-5.5** | 43.5 ($0.20) | 50.5 ($0.35) | 53 ($0.60) | 55 ($0.85) | — |

*(Costs are AA's API-priced weighted cost/task. For us codex is **subscription-flat**, so $ ≈ a proxy for **rate-limit / quota burn**, not money out of pocket — cheaper tier = more calls before the weekly cap.)*

### Three findings this adds

1. **Effort has steep diminishing returns.** Sol: low→medium **+4**, medium→high +2.5, high→xhigh +2, xhigh→max **+1** — but cost roughly *doubles* medium→max ($0.31→$1.04). **medium/high is the value sweet spot; reserve `max`/`xhigh` for the genuinely hardest leaf** (the +1–2 points cost latency + quota).
2. **Only Luna + Sol are on the efficient frontier — Terra AND GPT-5.5 are dominated (corrected).** Computing intelligence-per-$ at each effort, **Luna is the most cost-efficient at *every* effort** (low 825, high 511, max 243 index-pts/$ — roughly 2–4× Terra/Sol). And **Sol(low) 49.5 @ $0.20 beats Terra** (≈ Terra *high* 49 @ $0.24, cheaper). Terra never wins: **Sol(high) 56 @ $0.45 strictly dominates Terra(max) 55 @ $0.55** (higher *and* cheaper). GPT-5.5 is dominated too (5.5-high 53 @ $0.60 loses to Sol-medium 53.5 @ $0.31). So within codex the whole efficient frontier is **Luna for ≤51, Sol for ≥53.5** — skip Terra and 5.5. (Luna's ceiling is 51; above that only Sol climbs.)
3. **But "efficiency" only matters under quota pressure.** Cost here = subscription **quota/rate-limit burn**, not money. For a *one-off hard leaf* you're not near the cap → just pick the intelligence you need (Sol at the right effort); Luna's efficiency edge only pays off for **high-volume / quota-conservation**. Efficiency ranks the *bulk* default, not the *hard-task* default.
4. **Qwen distinction — don't confuse two "Qwens".** The scatter's **Qwen3.7 Max** (46 @ $1.06, Alibaba API) is *not* our local model. Ours is **Qwen 3.6 35B A3B = 32**, free/local. Our free option is the 32, not the 46.

### Refined routing ladder (our stack, by AA Intelligence Index) — Terra/5.5 dropped

| Tier | Pick | Index | When |
|---|---|---|---|
| **Hardest leaf** | codex `gpt-5.6-sol` @ high→max | 56–59 | correctness-critical, edge-casey; ignore efficiency |
| **Quality default** | codex `gpt-5.6-sol` @ low→medium | 49.5–53.5 | normal coding leaf; Sol(low) already beats all of Terra |
| **Quota-thrifty / bulk** | codex `gpt-5.6-luna` @ high→max *(if accessible)* | 46–51 | efficiency frontier — most index per quota-unit, ≤51 ceiling |
| **Non-OpenAI check** | antigravity `Claude Opus 4.6` / `Sonnet 4.6` | 51–53 | second opinion off the OpenAI family |
| **Free/unlimited bulk** | local `claude-9arm` (Qwen 3.6 35B) | 32 | mechanical, cheaply-verifiable, quota-free |
| **Skip (dominated)** | Terra (all), GPT-5.5 (all), GPT-OSS 120B (24), Mistral Medium 3.5 (30) | — | a Luna or Sol point beats each |

## Caveats
- AA v4.1 Intelligence Index is a *composite* — a model can rank higher overall yet trail on a specific axis (e.g. Sonnet 4.6 *leads* Terminal-Bench/agentic despite a lower composite than gpt-5.6-sol). For agentic tool-loops specifically, check Terminal-Bench, not just the index.
- `gpt-5.6-sol` medium/low and Gemini medium are estimates (AA didn't surface per-effort for all). Exact figures: re-fetch the model page.
- Scores are a 2026-07-16 snapshot; AA re-benchmarks. Re-fetch before relying.

# Subagent delegation vs doing it 100% myself — token economics (2026-07-16)

Research follow-up to `2026-07-16-subagent-delegation-log.md`. Question: **delegate to a
subagent vs do it 100% myself — which is cheaper?** Grounded in measured runs (same task on
all three CLIs) + the corrected cost model.

> **Cost-model correction (this is the crux):** the three back-ends are **not** billed the
> same, so "count total tokens" is the wrong lens.
> - **`claude-9arm` (Qwen 3.6-35B-A3B) is a LOCAL LLM → unlimited + $0 marginal cost.** Its
>   tokens (even a 130k-token call) cost *nothing but electricity + latency*.
> - **`codex` (GPT-5.6) and `antigravity` (Gemini 3.x) are SUBSCRIPTION** → flat monthly,
>   **rate-limited**. Their tokens don't bill per-token; they burn *subscription quota*.
> - **My own tokens (Claude Opus) are the one metered, context-window-bound resource.**
>
> So the only token pool that maps to a real, scarce cost is **mine (pool A)**. The
> subagents' pool B is effectively free (qwen) or pre-paid/flat (codex, antigravity).

> **สรุปไทย (TL;DR):**
> - เพราะ **qwen = local ฟรี/ไม่จำกัด** และ **codex/antigravity = subscription เหมาจ่าย (rate-limited)** →
>   token ของ subagent **แทบไม่มีต้นทุนจริง**. token ที่ "แพง" จริงคือ **ของเรา (Opus) เท่านั้น**.
> - ดังนั้น **"ประหยัด token" = ประหยัด token ของเรา** → **delegate ชนะเสมอ** สำหรับงาน input ใหญ่/output เล็ก
>   (เราโยนการอ่านไปให้ subagent รับกลับแค่ผลสั้นๆ). overhead 130k ของ qwen **ไม่ใช่ต้นทุนเงิน** (local ฟรี) —
>   เป็นแค่ **latency**.
> - การเลือก **ค่ายไหน ไม่ใช่เรื่อง token** (ของมันฟรี/เหมาจ่าย) แต่เป็นเรื่อง **latency × ความฉลาด × rate-limit**.
> - กับดักเดียวที่ยังจริง: **ผลที่ subagent ส่งกลับ = token ของเรา** — codex ตอน review เคยพ่นกลับ 91k chars
>   (~23k token ของเรา!). คุมด้วย "output only X" เสมอ.

## The three back-ends, measured on the SAME task

Task: *"Read `docs/OPEN-WORK-LEDGER.md` (30,696 chars ≈ 8k tokens) and give a 5-bullet summary."*
Identical prompt to all three. My cost = what I ingest back into pool A.

| Back-end | Model | Billing | Subagent `input_tokens` | Subagent `output` | Wall-clock | **Result → my pool A** | Quality |
|---|---|---|---|---|---|---|---|
| **`claude-9arm`** | Qwen 3.6-35B-A3B | **Local — unlimited, $0** | **130,791** (0 cached) | 565 | **64 s** (one 524 retry) | 1,855 ch ≈ **464 tok** | good, honest |
| **`codex`** | GPT-5.6 | **Subscription (rate-limited)** | 50,020 (19,968 cached) | 371 (+114 reason) | **37 s** | ~950 ch ≈ **238 tok** | good, terse, obeyed "only 5 bullets" |
| **`antigravity`** | Gemini 3.x | **Subscription (rate-limited)** | not reported by `agy` | — | **38 s** | ~1,500 ch ≈ **375 tok** | good, but **appended a `<SUMMARY>` block despite "output ONLY the 5 bullets"** |

Doing it **myself**: read the 8k-token file into pool A + reason + ~500-tok summary ≈ **~8.5k of MY tokens**.

### What the numbers say
- **Harness overhead differs wildly by CLI, not model.** `claude-9arm` reloads the *full Claude Code harness* (this session's giant MCP + skill + tool schemas) → **~122k fixed overhead/call, uncached**. `codex exec` is far leaner (**50k, 20k cached**); `agy` leaner still. But — because qwen is **local + free** — that 122k is *not a dollar or quota cost*, only **latency** (why qwen is ~1.7× slower).
- **What lands in MY pool A is tiny for all three** (238–464 tok) *when the output is constrained*. That's the delegation win: I offloaded an 8k-token read and paid only a few-hundred-token result.
- **Antigravity's chattiness is a real pool-A tax:** it ignored "output ONLY 5 bullets" and appended `<SUMMARY>` (+~60% ingest vs codex). The clink skill warns about exactly this — strip it, or don't use it when output size matters.

## Intelligence (Artificial Analysis index, 2026-07 — from the `clink-subagents` skill)

| Back-end | Model | Coding Index | Agentic Index | Notes |
|---|---|---|---|---|
| `codex` | GPT-5.6 | **71–77 (top)** | **45–54 (top)** | Elite model; weaker *agentic harness* → give a tight spec + verify |
| `antigravity` | Gemini 3.x | 68–70 (ok) | **21–37 (weak ⚠️)** | Only simple single-shot single-file tasks; chatty |
| *me* | Opus 4.8 | ~74 | ~47 | Orchestrate: delegate leaves, own the tree |
| `claude-9arm` | Qwen 3.6-35B-A3B | **well below** the above | **low** | Small local MoE (3B active); mechanical tasks only (per `qwen-agent` skill). Not in the clink index — check AA for the current figure. |

## The decision, re-derived under the correct cost model

Because pool B is free (qwen) or flat/subscription (codex, antigravity), **"fewer tokens" means "fewer of MY tokens,"** and:

**Delegation reduces my tokens whenever `(what I'd read+reason in pool A) > (prompt + result-ingested + verification)`.** Big-input / small-output / cheaply-verifiable → delegate. Small in-context edit, or must-re-read-to-verify → do it myself (delegating adds a result-ingest + a round-trip for no pool-A saving).

Once you've decided to delegate, **which back-end is *not* a token question** — it's:

| Axis | `claude-9arm` (qwen) | `codex` (GPT-5.6) | `antigravity` (Gemini) |
|---|---|---|---|
| **Marginal cost** | **$0, unlimited** ✅ | subscription quota | subscription quota |
| **Latency** | slow (60–180 s, flaky 524) | **fast (~37 s)** | **fast (~38 s)** |
| **Intelligence** | low | **highest** | ok / weak-agentic |
| **Best for** | **high-volume menial offload** you don't want to spend paid quota on | **quality/correctness** work, focused review, tight-spec edits | trivial single-shot single-file only |
| **Pool-A tax risk** | medium result | low (terse, obeys constraints) | higher (chatty `<SUMMARY>`) |

**So:**
- **Want fewest of MY (paid) tokens** → delegate any big-input task; I only ingest the small result. This is the real, near-always win.
- **Bulk/menial, and you don't want to burn subscription limits** → **qwen** (free + unlimited; eat the latency).
- **Needs to be *right* / smart** → **codex** (top intelligence, obeys "output only X" → also cheapest on pool A). Watch its transcript echo on read-heavy tasks (91k chars once = ~23k of my tokens).
- **Trivial single-shot** where speed matters and quota is fine → antigravity, but strip its `<SUMMARY>`.
- **Never** delegate a task smaller than the round-trip: for a 2-line edit in a file already in my context, doing it myself is fewer of my tokens *and* far less wall-clock.

## Bottom line

The earlier draft's "do it yourself saves ~15× *total* tokens" was measured correctly but framed wrong: it counted qwen's local/free tokens as if they cost money. **They don't.** Under the real model:

- **Cheapest in the only currency that's metered (my Opus tokens):** **delegate** big-input/small-output work — every back-end offloads the read and returns a few-hundred-token result.
- **Cheapest in wall-clock:** codex / antigravity (~37 s) over qwen (~64 s+).
- **Cheapest in real money / quota:** **qwen** (local, $0, unlimited) — pay only latency.
- **Best answer per token spent by me:** **codex** — highest intelligence *and* the tersest result (lowest pool-A ingest) of the three.

Rule of thumb unchanged, reason corrected: **delegate to shrink what enters *my* context; pick the back-end by latency × intelligence × how much subscription quota you want to spend — not by its token count, which is free or flat.**

## Caveats

- n = 1 measured call per back-end on one task; overheads are structural (harness-shaped) so they generalize, but per-task output varies.
- `agy` (antigravity) doesn't report token usage via clink — its pool-B cost is unmeasured (subscription-flat anyway).
- Latency snapshot only; the 9arm gateway was slow + threw one 524 this session.

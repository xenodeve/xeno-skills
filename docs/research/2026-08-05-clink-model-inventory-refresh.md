# Clink model inventory — re-verified 2026-08-05

**Supersedes the client-inventory half of `2026-07-16-model-effort-capability-matrix.md`.** That
document records the `codex` default as `gpt-5.6-sol @ medium`, calls `gpt-5.6-sol @ max = 59` "our
ceiling", and does not mention `cursor` at all. Do not route from it.

**Method, and its boundary.** Every figure below was read **from the CLI's own state on this machine**
on 2026-08-05 — not from `conf/cli_clients/*.json`, not from a config file, not from memory. Two
clients could not be re-verified in this pass and are marked as such rather than carried forward on
trust. Raw data is in `data/codex-models-2026-08-05.csv` and
`data/antigravity-models-2026-08-05.csv`; the Artificial Analysis half is unchanged and still lives in
`data/aa-models-augmented.csv`, which `tests/skills/test-figures-sourced.sh` binds the
`clink-masteragent` table to.

---

## codex — 8 models, and the count moved again

Source: `~/.codex/models_cache.json`, `fetched_at: 2026-08-05T04:37:43Z`. (Found originally because
`codex doctor` reports `models etag present: true`.)

| slug | context | max context | default effort | effort ladder |
|---|---|---|---|---|
| `gpt-5.6-sol` | 272,000 | 272,000 | `low` | low·medium·high·xhigh·max·**ultra** |
| `gpt-5.6-sol-wm` | 272,000 | 272,000 | `low` | low·medium·high·xhigh·max·**ultra** |
| `codex-auto-review` | 272,000 | 272,000 | `medium` | low·medium·high·xhigh·max·**ultra** |
| `gpt-5.6-terra` | 272,000 | 272,000 | `medium` | low·medium·high·xhigh·max·**ultra** |
| `gpt-5.6-luna` | 272,000 | 272,000 | `medium` | low·medium·high·xhigh·max |
| `gpt-5.5` | 272,000 | 272,000 | `medium` | low·medium·high·**xhigh** |
| `gpt-5.4` | 272,000 | **1,000,000** | `medium` | low·medium·high·**xhigh** |
| `gpt-5.4-mini` | 272,000 | 272,000 | `medium` | low·medium·high·**xhigh** |

### Three corrections to `#72`, which was itself written to correct the July doc

1. **Eight models, not seven. `gpt-5.6-sol-wm` is new** and appears in no skill or document. Its
   ladder and window match `sol`. What `wm` denotes is **not established** — do not guess it into a
   routing table.
2. **`ultra` is on four models, not two.** `#72` recorded it on `sol` and `terra`. It is now also on
   `sol-wm` and `codex-auto-review`. **Still absent from `luna`**, which matters because `luna` is the
   cheap-tier default this repo routes bulk work to.
3. **Three models have no `max` at all.** `gpt-5.5`, `gpt-5.4` and `gpt-5.4-mini` stop at `xhigh`.
   `clink-subagents` presents the ladder as a single scale ending at `max`; asking for `max` on those
   three is a request the model cannot serve. **This is the finding most likely to change a call.**

### The 272K cap is a codex choice, not a model limit

Every model is served at **272,000** regardless of what it supports — and `gpt-5.4` proves the point
against itself: its `max_context_window` is **1,000,000** while its `context_window` is 272,000. So a
delegation that needs a large window should not go to `codex`, and the reason is the harness rather
than the model.

---

## antigravity — 11 ids over 6 base models

Source: `agy models`, run by absolute path. Matches `#72`.

`gemini-3.6-flash` and `gemini-3.5-flash` expose `high|medium|low`; `gemini-3.1-pro` exposes
`high|low` only; `claude-sonnet-4-6`, `claude-opus-4-6-thinking` and `gpt-oss-120b-medium` have their
tier baked into the id. **The tier is part of the id here** — it is not a separate `--effort` axis,
which is why `--model` and `--effort` are mutually exclusive on this client (`pal-mcp-server#43`).

**`agy` is not on the Bash tool's PATH and hangs when invoked from it.** Use PowerShell, or the
absolute path under `%LOCALAPPDATA%\agy\bin\`. This is the same PATH divergence recorded in
`pal-mcp-server#64`.

---

## Not re-verified in this pass — stated rather than carried forward

| client | why | what `#72` claims |
|---|---|---|
| `cursor` | **`cursor-agent` is not installed on this machine** — absent from PATH and from `%LOCALAPPDATA%\Programs\cursor-agent\`. | 193 ids → 31 base |
| `claude` | not re-enumerated this pass | 4 primary, more via `--model` |
| `claude-9arm` | gateway not queried this pass | 1 (`qwen3.6-35b-a3b`) |

**These three are unverified, and the cursor row is the one that matters** — it is the client `#72`
was largely opened about, and its inventory cannot be confirmed from this machine at all. Anyone
landing the cursor half must run `cursor-agent --list-models` on a machine that has it, and record the
date, exactly as above.

---

## What did not change

The Artificial Analysis data (`data/aa-models-augmented.csv`, 85 model+effort rows and ~200 columns,
plus 1,399 endpoint rows in `data/aa-endpoints-2026-08-03.csv`) was **not** re-fetched. It is the
source `clink-masteragent`'s inline table is generated from and is bound to it by
`tests/skills/test-figures-sourced.sh`, so a refresh of it is a separate change that must regenerate
that block in the same commit.

**The July doc's ceiling claim is wrong in that data too** and is worth restating here because it is
the one a router acts on: `claude-opus-5` at max effort reaches **60.7** on the composite index and
leads the Agentic and GDPval columns, above every GPT-5.6 row.

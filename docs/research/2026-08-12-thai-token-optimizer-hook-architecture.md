# thai-token-optimizer — hook architecture, read 2026-08-12

**Why it was read.** `thai-token-optimizer` (TTO) installs hooks into six agent hosts and is the nearest working reference for the injection layer [#149](https://github.com/xenodeve/xeno-skills/issues/149) proposes. The question was narrow: **where does a hook compute what it injects, and where does it emit a constant?** The answers moved two open issues here and produced a correction to one of them.

**Method, and its boundary.** Fourteen agents. Eight read independent areas of the repository in parallel — hook lifecycle, the multi-host adapters, the compression pipeline, safety and preservation, benchmarks, the CLI and its state, telemetry, tests and CI — each required to open real files, attach `path:line` to every claim, and mark its basis as *read-the-code*, *ran-it*, or *inferred*. The four highest-significance findings then went to independent adversarial seats instructed to **refute** rather than confirm. One agent synthesised, one acted as a completeness critic. 161 findings, 1,541,525 subagent tokens, 30 minutes wall clock.

**The run has a defect, and it is stated first because the report below is affected by it.** The orchestration script packed the readers' output and the refutations into one JSON payload and truncated it at 120,000 characters. The cut landed inside the sixth reader, so the `refutations` key never reached the synthesiser — which says so at the top of its own report. **The synthesis therefore states two refuted claims as fact.** Both corrections appear below, ahead of the material they correct. The original claims are not edited out; leaving them visible is what makes the correction checkable.

**Not verified anywhere in this run:** nobody observed TTO inside a live Claude Code session. Every hook behaviour was produced by piping synthetic JSON to a script. Whether Claude Code loads `hooks/` or `.claude-plugin/hooks/` was left explicitly *inferred*, and one recommendation below depends on it.

---

## The two refutations

### 1. "Only one line in the lifecycle emits text computed from stdin" — REFUTED

The cited line is real: `hooks/tto-pretool-guard.js:48` interpolates the detected risk categories from stdin. The **universal quantifier** is false. `hooks/tto-gemini-beforetool.js:41` emits `Gemini risk categories: ${safety.categories.join(', ')}` through the identical pipeline — stdin → `JSON.parse` → `extractTextFromHookPayload` → `classifyText` → interpolate → stdout — and is a registered lifecycle hook, installed as Gemini CLI's `BeforeTool` at `adapters/index.js:110`. Verified by execution.

Within the Claude/Codex lifecycle specifically, `hooks/tto-mode-tracker.js:51-53` also emits stdin-derived text, but to `/dev/tty` rather than stdout — so a narrow reading of *"returned into model context"* would spare the original claim. The refuter cleared the remaining candidates rather than stopping at one counterexample: `tto-posttool-summary.js:40-41` never parses its input, `tto-stop-summary.js:27` reads no stdin, `tto-activate.js` has no `process.stdin` reference, and `emitActiveReminder` builds a stdin-derived hint then discards it.

**A boundary on the evidence itself:** the interpolation only reproduces with TTO **enabled**. At the default `enabled: false` (`hooks/tto-config.js:61`) the guard returns bare `{"continue":true}` even for an `rm -rf` payload.

### 2. "No hook can block, deny, or ask; the lifecycle is observe-and-inject only" — HALF REFUTED, and the refuted half is the most serious finding in the run

**Verified — cannot deny.** All five registered scripts read. No `permissionDecision`, no `decision:"block"`, no `continue:false`, and `grep -rn "process.exit([^0)]" hooks/ .claude-plugin/hooks/ .codex-plugin/hooks/` returns zero hits, so no exit-code-2 block either. `tto-pretool-guard.js` against `rm -rf / --no-preserve-root` emits `{"continue":true}`, exit 0.

**Refuted — "or ask".** `hooks/tto-mode-tracker.js:35-87` contains `askUserInteractive()`, which opens `/dev/tty`, writes a prompt, and awaits a line via `readline` **with no timeout on the promise**. It is awaited at `:227`. This is the **default path**, not a rare branch: `autoCompressInput` defaults to `false` and `tto-policy.js:43` sets `precompressThreshold: 300`, so with TTO enabled every prompt of ≥300 estimated tokens reaches it (`:224-232`). The same file ships as `.claude-plugin/hooks/tto-mode-tracker.js`.

The only thing preventing the ask is a heuristic at `:36` — `if (process.env.TTO_NON_INTERACTIVE || !process.stdout.isTTY) return {action:'reject'}` — an incidental property of hook stdout being piped, **not a guarantee of the hook protocol**.

Probed with `isTTY` forced true: the function is entered, reaches the `/dev/tty` open, and **on Windows crashes the hook with an unhandled asynchronous `ENOENT C:\dev\tty`, emitting no JSON at all.** The `try/catch` at `:41-46` catches only synchronous throws; `createReadStream` errors are asynchronous. The bypassed path does not merely ask — it kills the hook silently.

**Why the original method could not have found this.** The evidence offered was a grep for `permissionDecision|deny|ask|decision|continue:false`. That pattern will never surface `askUserInteractive`, `/dev/tty` or `readline`. The generalisation was blind to the one counterexample in the tree.

---

## The contradiction the completeness critic caught

The synthesis frames TTO as rewriting users' prompts in flight. The critic checked and found that **on every hook path, at every setting, the compressed text never reaches the model.** `prompt = compressed` is assigned at `hooks/tto-mode-tracker.js:220-235` only under `state.autoCompressInput` — default `false` at `hooks/tto-config.js:66` — or an interactive accept that is unreachable when stdout is piped; and `emitActiveReminder` then writes only `{"continue":true}` regardless.

**The rewriter bites only through `bin/thai-token-optimizer.js compress` and `hooks/tto-proxy.js`.** Treat *"it mangles prompts in flight"* as **not established**.

---

## The hook architecture

Five events — `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop` — five scripts, registered across four JSON surfaces (`.claude-plugin/plugin.json:29-95`, `.codex-plugin/hooks/hooks.json:1-67`, `hooks/hooks.json:1-61`, `.codex-plugin/plugin.json:10-16`) plus a fifth path that writes the user's real config (`bin/thai-token-optimizer.js:126,144,166`). They agree on the event set and on `timeout: 5`, and disagree on envelope, matcher and root env var.

What each emits, after the refutation above is applied:

| Event | Script | Emits |
|---|---|---|
| `SessionStart` | `tto-activate.js:57` | plain text, not JSON, computed from **persisted state** — not stdin |
| `UserPromptSubmit` | `tto-mode-tracker.js:184` | `{"continue":true}`. Computes compression, safety, token estimate and a `gcHint` at `:174-179` and discards them. `buildAdditionalContext` (`:151`) and `shouldEmitVerboseContext` (`:143`) exist and are never called anywhere in the repo |
| `PreToolUse` | `tto-pretool-guard.js:48` | **computed from stdin** — the detected risk categories, when enabled |
| `PostToolUse` | `tto-posttool-summary.js:41` | a literal. Consumes stdin at `:29` and never reads it — byte-identical output for two different inputs |
| `Stop` | `tto-stop-summary.js:27` | 35 lines, no state guard, no stdin listener |

The whole lifecycle is inert by default: `enabled: false` at `hooks/tto-config.js:61`, and a corrupt state file degrades to disabled (`:148-151`). The only blocking code anywhere in the repository is generated Hermes plugin and shell code (`adapters/index.js:364`, `:425`).

**The bearing on our own design.** TTO does **not** inject per turn — its `UserPromptSubmit` returns a constant `{"continue":true}`. It injects at the point of action instead, with content computed from the tool call. Our gate is the mirror image: it **denies** at `PreToolUse` and injects nothing there. Neither project does both at the same event, and both are available. That, not "copy TTO's five events", is the reusable observation.

---

## Evidence versus claims

- **"Preservation 100%" is definitional, not measured.** `hooks/tto-preservation-checker.js:59` returns 100 when zero technical items are extracted. The four golden cases carrying *all* the reported savings — 26%, 16.2%, 20.9%, 21% — extract zero items, while the four cases with real items save 0%, 0%, 7.7% and 3.8% (`benchmarks/regression_report.md:9-16`, reproduced). **Deleting the entire prompt scores 100%.** It is also self-fulfilling: the compressor appends missing constraints before the check reads them (`tto-compressor.js:554`, `tto-constraint-locker.js:154-160`) — one run scored 61.5% raw and 100% after appending.
- **No number in the repository comes from a real tokenizer.** `hooks/tto-token-estimator.js:34-63` is a character-class heuristic; the tokenizers are `optionalDependencies`; `tto-policy.js:35` defaults `exactTokenizer: false`.
- **The strict gate's "12% average saving"** is n=8 with three rows at exactly 0%, floored at 10% (`benchmarks/run_benchmark.js:438`).
- **"12,233.3% enhanced gain"** is 0.3 → 37 mean tokens over **n=4**, against a baseline that is the same compressor at level `lite` with two flags off (`run_benchmark.js:365-376`, `:396-398`).
- **The README's flagship "18 cases, 1789 → 1344, −24.9%" has no producing code** — grep finds only README variants and an SVG.
- **`scripts/ultimate-token-proof.js`** reports 54,150 tokens saved, of which 49,500 are hardcoded constants (`:24-25`, `:30`), against a `> 40000` threshold.
- **Two of three CI gates cannot fail as wired** — the calibration gate needs three consecutive rows but CI appends one to a file absent from the repository (`scripts/calibration-ci-gate.js:32-34`). The completeness critic sharpened this: `tests/test_calibration_gate.js:11-27` shows the **script** does fail correctly on a bad streak, so the defect is in the **wiring**, not the logic.
- **The safety layer is advisory.** Six regex categories (`hooks/tto-safety-classifier.js:22-53`), tool-name-blind (`:94`). Missed live: `DROP DATABASE`, `sudo rm -fr`, `git clean -fdx`, `kubectl delete namespace`, `curl | sh`. False-fired at *high* severity on `schema`, `ตาราง`, `production-quality`, and a `password field label`.

---

## What xeno-skills should take

**1. Execute the shipped bundle in CI, not the source tree.** `hooks/` works while `.claude-plugin/hooks/` is missing `tto-compressor.js` and `tto-runtime-analytics.js` — its `UserPromptSubmit` dies `MODULE_NOT_FOUND` exit 1, and its `SessionStart` exits 0 emitting nothing. Existence-only CI (`.github/workflows/validate.yml:104-105`) **and TTO's own `doctor`** both pass on that tree. This repository has the same two-copy shape and `tests/hooks/test-bootstrap-sync.sh` compares bytes without ever running the installed copy — the identical blind spot.

**2. A hook's `require`s belong inside the `try` that guarantees its safe emit, and the `catch` must write a log.** Three of TTO's five hooks put requires above the try and exit 1 with no stdout (`tto-pretool-guard.js:22-23`, `tto-posttool-summary.js:22`, `tto-stop-summary.js:22`); a fourth swallows the same failure into silence (`tto-activate.js:21-24,59`), which is why `fs.readdirSync` at `:37` — with `fs` never required — has been permanently dead.

**3. Byte-identity is not enough for a duplicated tree.** `cmp` reports TTO's nine shared files byte-identical while the copy is unrunnable, and the Codex copy resolves fine yet emits different text (`|| 'unknown'` appended at its `tto-pretool-guard.js:48`). Pair resolve-checking with a behavioural diff — two checks, not one.

## What it must not take

**1. `catch { return fallback }` on a user's config** (`adapters/index.js:61`). A `//` comment in `settings.json` made the installer replace the whole file, losing `theme`, `selectedAuthType` and `mcpServers` — reproduced. Fail loud, name the file, require an explicit `--force`.

**2. A quality metric whose repair step can edit the evidence the check reads.** The fixed point at `tto-compressor.js:554` + `tto-preservation-checker.js:50-71` converges to PASS regardless of quality. A deleted negation and swapped version bindings both scored 100 with risk `low`.

**3. Backups that flatten an absolute path into a filename, with an unguarded restore loop** (`hooks/tto-backup.js:123`, `:168`). On Windows the colon routes the write into an NTFS alternate data stream; `existsSync` returns true, `copyFileSync` throws `EINVAL`, and the loop has no `try/catch`. Verified twice independently: `rollback` **deleted the live file it was restoring**, while `doctor` reported *"Backup directory writable — PASS"* on the same machine.

---

## What nobody checked

**Never opened, and most relevant to a skills maintainer:** `skills/thai-token-optimizer/SKILL.md`, `.claude-plugin/skills/`, and the 15 command `.md` files under `.claude-plugin/commands/` — the actual skill-authoring artifacts. Also unopened: `hooks/lenses/`, `.agents/plugins/`, `backup/`, most of `hooks/tto-runtime-analytics.js`, `tto-fleet-audit.js`, `tto-fleet-detectors.js`, `tto-context-audit.js`, `tto-profiles.js`, and `tto-doctor.js` past line 231. There is no `docs/` directory; an earlier draft's "docs/" gap was phantom.

**The test suite was never run** — 40 `.js` files in a 47-entry directory. The critic established it is safe to run: `tests/test_install.js:27-34` builds an isolated environment with `mkdtemp` HOME and `TTO_HOME`, and 30 of the files redirect home. `npm test` and `npm run ci` are the next check, and they would settle whether `regression_report.md`'s savings reproduce.

**Unverified externally:** whether the per-host event names are real (Gemini `BeforeTool`/`PreCompress`, OpenClaw's contract), what each host does on hook timeout or a missing `node`, and `${VAR:-default}` expansion on non-POSIX runners. The backup findings are **Windows-only**; POSIX behaviour is unconfirmed.

**Two counts corrected by the readers themselves during the run:** the installer targets **ten** hosts, not six (`adapters/index.js:498`, `bin/thai-token-optimizer.js:138,161`), and ships **15** slash commands, not 17.

Git history is a single squashed commit, so corpus and threshold changes could not be dated.

---

## Bearing on open work here

- **[#149](https://github.com/xenodeve/xeno-skills/issues/149)** — its body claimed TTO's per-turn text is "static in the same way ours is". It is not static; it is **absent**. Corrected in a comment on that issue. The 10,000-character hook-output cap, verified against the vendor reference the same day, is now a hard bound on any capsule that issue produces.
- **[#155](https://github.com/xenodeve/xeno-skills/issues/155)** — ADR 0001 states `UserPromptSubmit` cannot block. The reference says it can, via exit code 2.
- **[#143](https://github.com/xenodeve/xeno-skills/issues/143) / [#145](https://github.com/xenodeve/xeno-skills/issues/145)** — TTO records activity counts and has no outcome measure, which is the same gap the skill-usage log has to avoid: knowing a rule fired is not knowing it held.

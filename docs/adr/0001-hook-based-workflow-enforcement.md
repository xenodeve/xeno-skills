# ADR 0001 — Hook-based workflow enforcement (soft dispatcher + hard gate + CI)

- **Status:** Accepted (2026-07-18) — implemented (`b82e5c1` #2, `e6209ad` #4)
- **Area:** Infra / agent-operating-layer
- **Related:** `skills/t4/t4-dev-workflow/SKILL.md` ("What's mechanically enforced"), `skills/t4/t4-project-bootstrap/references/hooks-layer.md`, issues #2 / #4 / #6

## Context

T4 agent-primary repos fail two ways: **(1)** the agent doesn't invoke the relevant skill at all, and **(2)** it invokes but drifts off the workflow mid-task. The `t4-dev-workflow` auto-trigger map (bug → `/debug-mantra`, after-code → `/simplify`, before-merge → `/code-review`+`/scrutinize`, …) relied on the model *noticing* the condition — which leaks.

The hard constraint: **the agent both does the work and would author any "receipt" that a skill ran**, so agent-produced evidence is forgeable. Deterministic interception happens at Claude Code lifecycle hooks. A hook can only enforce what it can verify independently. A multi-model design review converged on one line: **hooks enforce *actions*, not *process discipline*.**

**The four events this ADR's design uses** — and this is a **subset it chose**, not the surface that exists:

| Event | What it can do |
|---|---|
| `SessionStart` | inject context |
| `UserPromptSubmit` | inject context, **and block** — exit code 2 *"blocks prompt processing and erases the prompt"* |
| `PreToolUse` | deny a tool call before it happens |
| `Stop` | block turn-end |

**Two corrections, and they change what was available rather than only what was written (#155).** An earlier version of this paragraph said the four above were *the only* deterministic interception points and that `UserPromptSubmit` **cannot** block. Both are false. The reference documents **31 documented events**, and `UserPromptSubmit` blocks. The second one matters beyond accuracy: if a per-turn hook can refuse the turn, then *inject a reminder and hope* was never the only option at that event — which is the assumption every reading of #134's failure has rested on since. **Whether to use a blocking `UserPromptSubmit` is a design decision and belongs with #149; this correction does not make it.**

**A third constraint the ADR did not carry, and it bounds every injection design below:** hook output — `additionalContext`, `systemMessage` and plain stdout alike — is capped at **10,000 characters**. Output past the cap is written to a file and replaced with a preview and that file's path. So injecting a skill larger than the cap does not put the skill in context; it puts a path there.

*Capability claims in this section verified against the reference on 2026-08-12. They are the vendor's, not ours — re-check rather than inherit.*

## Decision

A layered "enforcement ladder", delivered two ways.

1. **Soft dispatcher — primary, for the un-checkable majority.** `SessionStart` injects the `using-t4` map, engineered with the devices that make superpowers trigger reliably: a "Route first" pre-response directive, a Red Flags rationalization table, phase-boundary re-routing, and a two-tier threshold (`skills/t4/using-t4/SKILL.md`). It is **re-injected on compaction** — `hooks/hooks.json:5` (`matcher: startup|clear|compact`) + a time-window lock (`hooks/t4-session-start:17`) so a later compact re-injects instead of being suppressed. A token budget bounds the recurring cost (`tests/hooks/test-dispatcher-content.sh`, ≤ 9000 B).

2. **Hard `PreToolUse` gate — for checkable actions only** (`hooks/t4-gate`): denies a PR with no referenced issue (`:74`), denies dangerous git (`:51` — `reset --hard`, force-push, `clean -f`, `branch -D`), **runs the repo's configured `verify` command itself** before `gh pr merge` and denies on failure (`:39` `run_verify`, `:88`), and `ask`s the human to confirm review ran on `gh pr merge` — skipped when `.claude/t4.json` sets `"autoMerge"`/`"afk"` (AFK / standing authorization). Command detection anchors on a command position, and blanks the shell separators **inside quoted spans** first — so a dangerous pattern inside a commit message doesn't false-deny, and neither does one inside a `--body` argument that happens to contain a `(`, `|`, `;` or `&`.

**This sentence previously read "matches quote-stripped text", and that was false** (#236). No stripping happened: detection ran on the raw command and relied on the anchor alone, so a single separator inside quoted prose manufactured a command position out of nothing. `gh issue comment 1 --body 'see (gh pr merge) in the docs'` was gated; the same sentence without the paren was not. It fired four times live on 2026-08-16, each time also running the full `verify` suite. **The claim was documented for months and never enforced — the defect class this repository calls a defect, in its own ADR.**

**And the guarantee is narrower than a reader might assume, stated here rather than left to be discovered:** a dangerous command *nested inside* a quoted string (`sh -c 'x; git reset --hard'`) is **not** caught. It was previously caught by accident, through the very separator that is now blanked — never by design, since the same command without a separator was always silent. A regular expression is not a shell parser; catching that case needs a parser, not a looser anchor. `tests/hooks/test-gate.sh` pins both the fix and this limit.

3. **Server-side CI + branch protection — the real guarantee.** `skills/t4/t4-project-bootstrap/references/ci/t4-verify.yml` + branch-protection guidance in `hooks-layer.md`. This is the only layer that also covers a human merging on the web and that `--no-hooks` can't skip.

4. **Two delivery paths + dedup.** B (native): the repo is a Claude Code plugin (`.claude-plugin/` + `hooks/`). A (universal): `t4-project-bootstrap` writes the same scripts into each repo's committed `.claude/`. A shared per-`session_id` lock prevents double-injection; a byte-sync test keeps the two script copies identical (`tests/hooks/test-bootstrap-sync.sh`).

## Alternatives considered

- **Pure soft (superpowers-style only).** Rejected as the *sole* mechanism — it can't hard-block the few genuinely checkable violations (PR-without-issue, dangerous git, a failed verify).
- **Pure hard gates.** Rejected — most skills (`/simplify`, `/scrutinize`, `/debug-mantra`) have no checkable predicate, so a hard gate for them is impossible.
- **A large orchestrator + signed receipts.** Rejected — the agent authors any receipt it writes, so a local receipt is forgeable; a big system that *looks* bypass-proof but isn't is theater.
- **CI-only.** Rejected as the sole mechanism — too late in the loop (an autonomous run fails only at push, wasting the whole reasoning loop). Kept as the top layer, not the only one.
- **An `L4` Stop hook ("can't stop until tests pass").** Descoped — its one concrete rule (PR-without-issue) is already blocked earlier at `PreToolUse`; `Stop` fires every turn-end so a completion check nags; and it is gameable (delete the failing test, write a trivially-passing one).

## Consequences

- **Positive:** the two failure modes are met at the right altitude — the soft dispatcher raises self-trigger reliability for the un-checkable majority; the hard gate blocks the checkable few; CI is the un-forgeable ship gate. `verify` is genuinely un-forgeable because the hook *runs the tests itself*, not a claim. Covered by 50 bash contract tests (`tests/hooks/run-all.sh`).
- **Negative / limits (the honest ceiling):** hooks **cannot** enforce process discipline (TDD *spirit*, review *depth*) — only raise the cost of skipping. Claiming a hook "enforces TDD" by checking a test file exists is **theater**. The soft layer is a reminder the model can still ignore. Local hooks catch only *agent-run* commands — a human web-merge or `--no-hooks` bypasses them (hence CI). The plugin and bootstrap script copies must stay byte-identical (guarded by a test). The injected dispatcher is a recurring token cost (bounded by the budget test).
- **Follow-ups:** the verify-gate and CI are **opt-in** — a repo arms them by setting `.claude/t4.json` `"verify"` and installing the workflow + branch protection. Refined after first use (#12, #13): `verify` runs on `merge` only (cost — the iterative `create` shouldn't re-run a heavy suite), and the merge `ask` honors an `"autoMerge"`/`"afk"` standing-authorization marker so unattended/AFK runs don't stall. Extended for #31: Tier 3 is now a shipped layer rather than a single template — `t4-project-bootstrap` → `references/ci-cd-layer.md` installs `lint`/`typecheck`/`test`/`build` as **separate** required checks (a check name that says what broke), a separate e2e workflow (kept out of the local `verify` per #13), an optional CD workflow gated on `workflow_run` of a green verify, and the ruleset commands that block direct pushes to `main`. Because a ruleset isn't available on every plan, the gate also gained an **opt-in** `"requireGreenCI"` rule that runs `gh pr checks` before `gh pr merge`; it is deliberately documented as *weaker* than a ruleset (it binds only agent-run commands) so it isn't mistaken for the real guarantee. Extended again for #40: the ladder gained a **Tier 0.5** between the Claude gate and CI — a git `pre-push` hook. The gap it closes was there from the start and unstated: `PreToolUse` is a Claude Code event, so in a repo where the team also runs Codex/Gemini the gate binds one agent out of three. Moving the checkable rules into git binds all of them plus any human on the clone. It stays opt-in per clone (`core.hooksPath`) and remains `--no-verify`-able, so it raises the floor rather than setting it; the same scripts are wired into CI, which is where the rule is guaranteed. Reopen this ADR if Claude Code adds a way to verify skill-invocation *quality*, or if a cheap checkable proxy for a judgment skill emerges.

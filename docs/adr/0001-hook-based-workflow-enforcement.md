# ADR 0001 — Hook-based workflow enforcement (soft dispatcher + hard gate + CI)

- **Status:** Accepted (2026-07-18) — implemented (`b82e5c1` #2, `e6209ad` #4)
- **Area:** Infra / agent-operating-layer
- **Related:** `skills/t4/t4-dev-workflow/SKILL.md` ("What's mechanically enforced"), `skills/t4/t4-project-bootstrap/references/hooks-layer.md`, issues #2 / #4 / #6

## Context

T4 agent-primary repos fail two ways: **(1)** the agent doesn't invoke the relevant skill at all, and **(2)** it invokes but drifts off the workflow mid-task. The `t4-dev-workflow` auto-trigger map (bug → `/debug-mantra`, after-code → `/simplify`, before-merge → `/code-review`+`/scrutinize`, …) relied on the model *noticing* the condition — which leaks.

The hard constraint: **the agent both does the work and would author any "receipt" that a skill ran**, so agent-produced evidence is forgeable. The only deterministic interception points are Claude Code lifecycle hooks — `SessionStart` / `UserPromptSubmit` (inject context, can't block), `PreToolUse` (can deny), `Stop` (can block turn-end). A hook can only enforce what it can verify independently. A multi-model design review converged on one line: **hooks enforce *actions*, not *process discipline*.**

## Decision

A layered "enforcement ladder", delivered two ways.

1. **Soft dispatcher — primary, for the un-checkable majority.** `SessionStart` injects the `using-t4` map, engineered with the devices that make superpowers trigger reliably: a "Route first" pre-response directive, a Red Flags rationalization table, phase-boundary re-routing, and a two-tier threshold (`skills/t4/using-t4/SKILL.md`). It is **re-injected on compaction** — `hooks/hooks.json:5` (`matcher: startup|clear|compact`) + a time-window lock (`hooks/t4-session-start:17`) so a later compact re-injects instead of being suppressed. A token budget bounds the recurring cost (`tests/hooks/test-dispatcher-content.sh`, ≤ 9000 B).

2. **Hard `PreToolUse` gate — for checkable actions only** (`hooks/t4-gate`): denies a PR with no referenced issue (`:74`), denies dangerous git (`:51` — `reset --hard`, force-push, `clean -f`, `branch -D`), **runs the repo's configured `verify` command itself** before `gh pr merge` and denies on failure (`:39` `run_verify`, `:88`), and `ask`s the human to confirm review ran on `gh pr merge` — skipped when `.claude/t4.json` sets `"autoMerge"`/`"afk"` (AFK / standing authorization). Command detection matches quote-stripped text, so a dangerous pattern inside a commit message doesn't false-deny.

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
- **Follow-ups:** the verify-gate and CI are **opt-in** — a repo arms them by setting `.claude/t4.json` `"verify"` and installing the workflow + branch protection. Refined after first use (#12, #13): `verify` runs on `merge` only (cost — the iterative `create` shouldn't re-run a heavy suite), and the merge `ask` honors an `"autoMerge"`/`"afk"` standing-authorization marker so unattended/AFK runs don't stall. Reopen this ADR if Claude Code adds a way to verify skill-invocation *quality*, or if a cheap checkable proxy for a judgment skill emerges.

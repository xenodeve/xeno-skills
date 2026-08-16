---
date: 2026-08-16
repo: xeno-skills (paired with openclink)
skills: [using-t4, t4-dev-workflow, t4-bro, t4-agent-memory, to-prd, using-clink, clink-brainstorm, clink-masteragent, scrutinize, handoff]
gates: simplify=n-a code-review=n-a scrutinize=ran security-review=n-a verify=ran
---

## What the session did

Opened PR #214 for a 60-commit docs branch and merged it, so `main` finally carries the four plans and the
capability reference that 16 issues cite. Rewrote an externally supplied protocol proposal as
`docs/plans/2026-08-16-clink-delegation-contract.md` and published it as PRD #215. Then audited the plans
against both trackers **twice** — once by title with a three-seat panel, once by body — and filed what the
two passes found: `#216`–`#233` here and `openclink#116`–`#120` plus the epic `#124` there. Closed `#159`,
`#149`, `#208`, `#205`, `#72` with stated reasons.

**Gate note, with its proof:** `git diff --name-only main...HEAD` returned `*.md` only, 14 files, so
`simplify`, `code-review` and `security-review` are `n-a` rather than skipped. `verify` ran on every
commit — `bash tests/hooks/run-all.sh` → ALL TESTS PASSED. `scrutinize` ran on the branch before merge and
its findings are in the PR body.

## The finding the session exists for

**Of the 32 slices `#177`–`#208`, exactly one names a host other than Claude Code — and that one only
because it was edited during this session.** They were cut from the single-harness architecture of
`2026-08-13-skill-compliance-plan.md`. The `2026-08-14` re-cut, written afterwards from a day of live
probing, says all four harnesses sit on one loop with four adapters. **Nobody re-cut the slices.** The
document changed; the tracker did not.

Zero hits across both trackers for `stop_hook_active`, `injectSteps`, `PreInvocation`, `uuid`,
one-finding-per-turn, `routed-then-loaded`, and `config generator`. `turn_ended`, `invoke_subagent` and
`spawn_agent` appeared only inside `#176`'s own body — the PRD said them and nothing implemented them.

**The generalisable part:** a plan rewritten after its slices are cut leaves no trace in the tracker, and
nothing in this repo's process looks for one. Both repos' open-work ledgers were also stale in opposite
directions on the same day — three rows here claimed open work that had closed, and eight issues there were
absent from the file that calls itself the single source.

## Rules that did not hold

- **No verdict before evidence** (`t4-dev-workflow`), **three times**, all the same shape — evidence that
  verified a *mechanism* was spent licensing a claim about *what to do*. (1) *"#175 ไม่ได้อ้างเลขใบไหนเลย"*
  — false; its body's last line is `Blocked by: xenodeve/pal-mcp-server#103 · #171`, and I had read the
  first 14 lines. (2) Carried a prior handoff's *"`schema` parameter on `clink`"* into design work; there
  is no such parameter. (3) Recommended closing `#204` after four correct checks on our side, then read
  openclink and found `tests/test_mcp_server_key.py` already containing the analysis, a plan (`#122`), and
  a deliberate exclusion of `pal` from `LEGACY_MCP_NAMES`. Filed as **#233**, which proposes extending the
  artifact requirement to an action's preconditions.

- **`using-t4` session protocol, step 1** — `karpathy-guidelines` was never loaded, in a session that
  loaded nine other skills including `using-t4` itself, which is where the instruction lives. Steps 2–4 are
  triggered by the work; step 1 is triggered only by the clock, so its absence produces no friction later.
  Commented on **#134**, which is the same rule and closed.

- **`clink-brainstorm` challenge loop** — round 1 returned partial convergence, which the skill routes to
  the challenge loop. I ran one round and verified the claims against the repo myself instead, finding two
  of antigravity's six checkable claims wrong. Better for this question, worse for the skill: the stop
  condition was never reached, so nothing recorded that the loop was skipped. Commented on **#138**, which
  is exactly *the stop condition has no artifact*.

- **`t4-bro` shape rule** — the language half held all session, no reversion to English. Most paragraphs
  opened with a bolded lead clause; by the fifth consecutive one the emphasis carries nothing, which is the
  skill's own *bolding everything is the same as bolding nothing*. Commented on **#209**.

- **`t4-agent-memory` session-end report** — acknowledged as owed in a reply (*"session-end report ตาม
  `CLAUDE.md` ยังไม่ได้เขียน"*) and then not written, one step worse than **#211**'s original case. It ran
  only after `/goal` enumerated it. Commented on #211 with the mechanism problem: there is no observable
  *session end*, so a rule triggered on it is triggered on an event the agent cannot detect.

## What was done right, worth keeping

- **Every panel claim was checked before acting.** Two of antigravity's six were wrong and were dropped —
  it proposed a Phase 1 canary issue `#212` already covers, and misread *"PAL's store"* in `#175`. cursor
  was wrong zero times of two checked; codex contributed two findings nobody else saw.
- **`scrutinize` found a blocker outside the branch it was pointed at.** `#204`/PR `#206` would rename 25
  tool identifiers to a prefix that does not resolve on this machine. Both are now `blocked` with a
  one-command precondition.
- **The merge method was chosen from a checked fact.** Issue comments cite `54e9d44`, `2fb7bc6`, `d554898`,
  all branch-only; the ruleset allows squash only; so the branch was kept rather than deleted, which is
  what keeps those SHAs reachable.

## Traps met on this machine

- **PowerShell ate backticks in a `gh` argument** — `--title` containing `` `mcp__openclink__` `` failed
  with exit 1 and no output, three times, before switching to bash. Backtick is PowerShell's escape
  character. Use bash for any `gh` call whose arguments contain markdown.
- `gh` is not on the bash PATH; `/c/Program\ Files/GitHub\ CLI/gh.exe` works.
- A quoted heredoc (`<<'EOF'`) still failed on one body containing mixed quoting — the `Write` tool is the
  reliable path for issue bodies.

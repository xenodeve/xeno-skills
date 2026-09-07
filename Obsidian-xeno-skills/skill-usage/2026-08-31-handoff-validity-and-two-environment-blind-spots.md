---
date: 2026-08-31
repo: xeno-skills
skills: [using-t4, t4-dev-workflow, simplify, code-review, scrutinize, security-review, t4-agent-memory]
gates: simplify=ran code-review=ran scrutinize=ran security-review=ran verify=ran
---

## What the session did

Continued `feat/306-handoff-validity`, a branch left with the implementation already present but
uncommitted. Verified the four `#306` conditions plus the thinking-record-index addon predicate,
ran all four `/simplify` angles and both `/code-review` axes as real parallel sub-agents, ran
`/scrutinize` and `/security-review` inline, applied every real finding, committed with a
`T4-Gates` trailer, pushed, and opened **PR #342** (not merged, as instructed).

## The RED that had to be manufactured, not just re-read

`DONE.md` already claimed the stale-handoff case was "RED before the fix and GREEN afterward" from
a prior session. Evidence-before-verdict says a claim doesn't upgrade by being repeated, so I
reproduced it myself: disabled the staleness check, reran the test, got a real failing line
(`FAIL: stale handoff accepted or misreported: exit 0 [valid]`), restored the check, got GREEN
again. The prior session's claim held — but only checking would have shown that; the diff alone
couldn't have.

## Two real /simplify findings, both fixed

- A second, untested regex in the thinking-index parser (bare `NNN-name.md`, no link) was
  defending a format nothing in the repo — no test, no plan doc — actually uses. Dropped.
- `owners[-1]` silently took the last `Session:` line if a handoff somehow had more than one,
  contradicting the docstring's own singular claim. Changed to `len(owners) != 1` — reject
  multiplicity outright.

One `/code-review` Spec-axis finding: the empty-handoff branch was implemented (`if not
text.strip(): fail(...)`) but never exercised by a test — the suite only covered the
missing-*section* half of condition 2. Added the missing case; 8 assertions became 9.

## The environment problem that cost the most time, and generalises

Every hooks test that does `mktemp -d` then passes the path into an embedded `python` heredoc as a
positional arg failed in this session's shell — not just the new `test-handoff-validity.sh`, but
pre-existing `test-segment.sh` too. Traced (not guessed) to `MSYS_NO_PATHCONV=1` being set in this
sandbox's environment, which disables git-bash's automatic POSIX→Windows path translation for
native (non-MSYS) executables — and `python` here resolves to a native Windows binary. `unset
MSYS_NO_PATHCONV MSYS2_ARG_CONV_EXCL` in the same shell fixes it completely; the full suite then
runs 1340/1340.

**This bit twice in one session.** A `/code-review` Standards sub-agent, running in its own fresh
shell without the fix applied, independently hit the same failure on `test-wiring-parity.sh` and
reported it as a live discrepancy against `DONE.md`'s claim — which had to be traced back to the
same root cause and corrected before the review could be trusted. An agent that doesn't
independently re-derive this diagnosis inherits a false RED as if it were a real defect. Filed as
**#344**, since CLAUDE.md's Windows toolchain note documents the git-bash path but not this
variable, and CI (`ubuntu-latest`) never exercises this path at all.

## The other gap: a skill's own auto-capture came back empty

`/security-review`'s injected preamble is supposed to hand the reviewer `FILES MODIFIED`,
`COMMITS`, and `DIFF CONTENT` pre-gathered. `GIT STATUS` populated correctly; the other three
sections all read `(Bash completed with no output)` despite real staged changes existing at
invocation time. Recovered by gathering the diff manually and doing the review directly rather
than trusting the preamble. Filed as **#343** — not previously reported under any search term I
tried.

## What held without incident

`check-gate-ledger`, `check-issue-ref` (satisfied by the branch name), and `check-tree-budget`
all matched what the local guard scripts actually check — read them before relying on the trailer
format rather than working from memory. The bilingual PR-body convention
(`docs/agents/issue-tracker.md`'s shape, mirrored via CLAUDE.md) held with no correction needed.

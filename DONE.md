# DONE — Agent Session Log

> Newest entry on top. One dated `##` heading per shipped unit so an agent can jump to one.
> When this crosses ~a few hundred lines or a phase closes, move older entries to
> `DONE-archive-<period>.md` and leave a redirect line here.

---

## The plan level gets a tracker presence, and the log that blocked every push (#255, #258) (2026-08-19, skills t4-afk + t4-dev-workflow, PR #259 → `main`)

**Goal:** `docs/plans/` is reviewable in a PR and invisible to GitHub, so *"which PRDs came out of
this plan?"* was answerable only by a human reading five markdown files. This is the plan level of
#248's `plan → PRD → slice` tree — the one level that had no tracker presence at all.

**Shipped:**
- **#256** and **#257** — tracking issues for `2026-08-13-skill-compliance-plan.md` (→ PRD #176) and
  `2026-08-16-clink-delegation-contract.md` (→ PRD #215), each carrying its PRD as a native sub-issue.
- `docs/plans/README.md` — a **Tracking issue** column. Three of the five plans get `none` **with a
  stated reason**: the 08-04 remediation plan (no PRD names it; #99 filed the audits, #220 holds its
  ADR), `2026-08-13-review-handoff.md` (a component of slice 3, not a plan with a PRD), and
  `2026-08-14-compliance-reviewer-recut.md` (re-cuts #176, which hangs from the 08-13 plan; a PRD has
  exactly one parent).
- `tests/skills/test-plan-index.sh` — every plan on disk must have a parsed row, and every row an
  issue number **or** `none` plus a reason. A blank cell is refused: it is indistinguishable from a
  plan nobody has got to yet, the same shape `check-gate-ledger` enforces for gates.
- `.gitignore` + an assertion in `tests/guards/test-check-tree-budget.sh` (**#258**) —
  `Obsidian-xeno-skills/skill-usage/.invocations.log` is an untracked `*.log` inside the *committed*
  vault directory, so the guard refused every push from this clone. The guard was right; the repo was
  missing one line.

**The two reserved decisions, settled from the artifacts rather than from judgement.** #176's body,
line 5, names the 08-13 plan as where its design detail lives, while the recut appears one line later
in the *evidence* sentence beside two research documents — so the 08-13 plan owns #176.
`2026-08-13-review-handoff.md` says of itself *"design only. Nothing here is built."*

**Validation:** `bash tests/hooks/run-all.sh` → ALL TESTS PASSED, before and after the commit. Four
positive controls on the new suite, each red for the reason it names: a blanked cell, a bare `none`, a
plan file with no row, and the two issue numbers swapped between their rows. `/scrutinize` found the
column index hardcoded at `2` — a reordered table would have scored the **Status** cell and gone red
for the wrong reason; it now reads the column by header name. CI could not run (billing lock; jobs
fail at provisioning with `steps=0`), so the local suite is the whole of the evidence.

**Not covered, and said so in the file rather than left silent:** the suite never calls GitHub, so
deleting the sub-issue links on #256/#257 leaves it green.

---

## Bootstrap the T4 operating layer into this repo (#93) (2026-08-09, skill t4-project-bootstrap, branch `main`)

**Goal:** this repo ships the T4 standard (hooks, CI templates, bootstrap) but had never had the
operating layer applied to itself — no CLAUDE.md, no memory, no `.claude/t4.json`, no ruleset.

**Shipped (new files):**
- `CLAUDE.md` — agent operating manual: north-star, layout, commands, session-start protocol, bilingual conventions, `docs/agents/*` pointers
- `.claude/t4.json` — T4 marker, armed `"verify" = bash tests/hooks/run-all.sh` (the fast prefix of CI `tests`)
- `.claude/settings.json` — registers the three hooks via `${CLAUDE_PROJECT_DIR}`
- `.claude/hooks/{run-hook.cmd,t4-session-start,t4-prompt-reminder,t4-gate,using-t4.snapshot.md}` — self-contained copies
- `.githooks/{pre-push,check-issue-ref,check-tree-budget,check-gate-ledger}` — the agent-agnostic guard tier
- `docs/OPEN-WORK-LEDGER.md`, `DONE.md`, `Obsidian-xeno-skills/Home.md` — memory layer
- `docs/agents/{workflow,issue-tracker,triage-labels,domain}.md` — workflow + tracker conventions
- `CONTEXT.md`, `UBIQUITOUS_LANGUAGE.md`, `PRODUCT.md`, `docs/reports/README.md`, `docs/plans/README.md`, `docs/research/README.md` — domain/product layer (Active tier)
- `.github/workflows/t4-verify.yml` — guards wired into the `tests` job (edit, scoped to pull_request)
- Labels: created `critical`, `Minor` (Severity group); rest already existed
- Ruleset `T4 main gate` — `deletion` + `non_fast_forward` + `pull_request` (block direct pushes to main, squash-only), `required_approving_review_count: 0`
- `tests/skills/test-repo-self-bootstrap.sh` — pins that THIS repo (the standard-shipper) has the operating layer applied to itself: marker armed, settings register the hooks, `.claude/hooks/` byte-identical to `hooks/`, `.githooks/` present, CI runs the guards, CLAUDE.md carries the standing-default wording. Written to close the gap where the existing suite only tests the *templates* against throwaway repos.

**Retroactive TDD note:** the bootstrap install itself was not red-first (it is scaffold/install work whose contracts the existing suite already covers). The genuinely new *behavior* — this repo's own operating layer — now has a pinning test, proven non-tautological by mutation (disarm verify / drop a guard / drop the CI guard wiring each turn it RED). It also caught a real defect during the write: `.claude/hooks/` had been copied from the *installed* skill (stale, pre-#82) instead of the repo's own `references/hooks/`; fixed and byte-verified.

**Validation:** `bash tests/hooks/run-all.sh` green (ALL TESTS PASSED); `tests/hooks/test-bootstrap-sync.sh` green (hook copies byte-identical to plugin `hooks/`); `test-wiring-parity.sh` green; `gh api rulesets` returns `T4 main gate` active; `main protected=True`; YAML of edited workflow validates.

**Deferred (billing blocker):** the required status checks (`tests`, `skill-discovery`) were NOT added to the ruleset because CI is billing-locked — every run fails at provisioning with "account is locked due to a billing issue" (0 steps, ~2s). Adding required checks over a CI that can't run would deadlock every merge. Fix billing → green run → add the two contexts to `required_status_checks` → close #109. This is logged in the ledger.

**Report:** closes #93. Resolves most of #109 (ruleset) — the required-checks half stays open pending billing.

**Next:** 🔴 #109 (add required checks after billing fix) and #72 (close with the merged-PR evidence); #123 ready-for-agent hooks bug is the next work item.

---

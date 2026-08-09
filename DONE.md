# DONE — Agent Session Log

> Newest entry on top. One dated `##` heading per shipped unit so an agent can jump to one.
> When this crosses ~a few hundred lines or a phase closes, move older entries to
> `DONE-archive-<period>.md` and leave a redirect line here.

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

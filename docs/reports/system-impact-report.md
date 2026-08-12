# xeno-skills — System-Impact Change & Tech-Debt Report

> Curated, report-level record of changes that **affect the running system** plus the
> **tech-debt register**. Audience: team / stakeholders / status reports. Append a dated
> section per significant batch; keep entries terse + linkable. Write "not measured" / "N/A"
> honestly — never fabricate numbers.

## 2026-08-09 — Bootstrap the T4 operating layer into this repo (chore) [— #93]

**Scope:** repo root (CLAUDE.md, .claude/, .githooks/, docs/) · **Type:** infrastructure/process · **Tests:** contract suite green; test-bootstrap-sync green
**Severity:** low

**What & where:** CLAUDE.md (agent manual); `.claude/t4.json` + `.claude/settings.json` + `.claude/hooks/` (hook layer); `.githooks/` (guard tier); `docs/OPEN-WORK-LEDGER.md`, `DONE.md`, `Obsidian-xeno-skills/` (memory); `docs/agents/*` (workflow/tracker); `CONTEXT.md`/`UBIQUITOUS_LANGUAGE.md`/`PRODUCT.md` (domain layer).

**Why:** the repo ships the T4 standard but had never applied it to itself (#93); the checks it documents were advisory, not required (#109).

**Before → After:** no operating layer → full layer: hooks fire on session start, gate blocks PR-with-no-issue / dangerous git / merge-past-verify, guards run in CI, memory survives sessions.

**Performance Δ:** N/A (no runtime code; one extra pre-push + 3 CI guard steps per push).

**Quality:** the repo now follows the standard it documents.

**Validation:** `bash tests/hooks/run-all.sh` green; `tests/hooks/test-bootstrap-sync.sh` green; `gh api rulesets` returns the T4 main gate.

**Risk / rollback:** additive — remove `.claude/` + `.githooks/` + docs to revert; ruleset deletion restores direct pushes.

**Links:** #93, #109, #123 (next ready-for-agent).

---

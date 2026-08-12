# Survey-manifest — provenance cache

**What it's for:** so a later scan (a new report, an ADR, an audit) does **not** re-read files/issues/PRs that haven't changed.

**Scan procedure (for the next agent):**
1. Open the fragment covering the area to update (see the fragment index below).
2. Before re-reading, check whether the recorded source changed:
   - Code/docs: `git log -1 --format=%H -- <path>` vs stored `last_commit` — equal ⇒ **skip**.
   - Issue/PR: `gh issue view <n> --json updatedAt` / `gh pr view <n> --json updatedAt` vs stored `updated_at` — equal ⇒ skip.
3. If changed, read only the diff (`git diff <last_commit>..HEAD -- <path>`), not the whole file, unless the diff is huge.
4. Update only the changed part and bump `last_commit` / `updated_at`.

## Fragment index

| Fragment | Scope | Status |
|---|---|---|
| `_none yet` | — | empty — populated on the first survey scan |

## Already surveyed — don't repeat unless diffing

_None yet — the composition audits (docs/research/2026-08-04-*.md) predate this manifest; add them here if a re-audit is ever needed, pointing at the canonical output rather than duplicating findings._

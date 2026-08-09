# Agent Workflow

How agents plan and implement in this repo, and which skills to invoke automatically.

## Development workflow

When planning or implementing a feature, follow this order:

1. **`/grill-me`** — stress-test the concept first (interview-style)
2. **`/grill-with-docs`** — challenge the plan against existing ADRs in `docs/adr/`
3. **Survey the change sites** — enumerate every place the change touches, before the plan exists (see the skill)
4. **`/to-prd`** — create a PRD from the grilled plan (one PRD per epic), carrying the survey as its change inventory
5. **`/to-issues`** — break the PRD into GitHub issues on `xenodeve/xeno-skills` with triage labels (one issue per deliverable)
6. **`/tdd`** — implement test-first, then make the tests pass

Hard ordering: **PRD → issues → PR**. Never open a PR without a referenced issue.

## Auto-triggered skills

| Trigger | Skill | Condition |
|---|---|---|
| Bug / error / stack trace | `/debug-mantra` | Start a debug session every time |
| After fixing a bug | `/post-mortem` | Record root cause + fix + validation |
| After writing or changing code | `/simplify` | Before committing — check over-engineering |
| Editing UI / frontend | `/impeccable` | Every time a component or CSS is touched |
| Before merge / ship | `/code-review` + `/scrutinize` | Correctness + outsider perspective |
| Touching a security boundary | `/security-review` | Every time code crosses auth/secret/token |
| After implementation | `/verify` | Confirm the feature works in the app |

## Verification mandate

Run `bash tests/hooks/run-all.sh` to verify every change — the bash contract suite is the
repo's test suite (hooks + gate + guards + skills) and its CI `tests` job. This repo has no
frontend; the closest to an end-to-end check is the CI `skill-discovery` job, which runs the
real installer (`npx skills@1 add . --list`) and asserts every `SKILL.md` is discoverable — run
it locally when a skill's directory structure changes, since the installer stops descending at
the first `SKILL.md` in a directory (see #45).

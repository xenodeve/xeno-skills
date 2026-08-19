# xeno-skills — Team Memory (Map of Content)

> Read this index first each session; open only the linked notes the current task touches.
> One note = one memory. Unresolved `[[links]]` = memories worth writing.

## feedback — how agents should work here
- [[agent-primary-repo]] — this repo is agent-primary: the agent is the main developer; docs are its operating manual.

## project — ongoing goals / constraints not derivable from the code
- [[bootstrap-self-consistency]] — this repo ships the standard; every skill/rule it documents must be verifiable against the repo's own tests (test-bootstrap-sync, test-wiring-parity).

## reference — pointers to external resources (URLs, dashboards, tickets)
- (none yet)

## user — who the developer is (role, preferences)
- (none yet — will be written from first interaction)

## skill-usage — one entry per session; which rules actually held in real work
> Not vault notes. Read the entries naming a skill **before changing that skill**, instead of
> designing a benchmark for it. Three sessions failing the same rule is a design problem in the
> rule; one session failing it is a session. Rules and skeleton: `t4-agent-memory`.
- `skill-usage/2026-08-12-t4-bro-and-the-feedback-log.md` — built `t4-bro`; the shape rule did not transfer without an example; a change inventory named a file that does not exist on `main`.
- `skill-usage/2026-08-14-compliance-hooks-and-three-absence-claims.md` — probed the hook surface on four CLIs; three absence claims were wrong, each from a failed search reported as a finding.
- `skill-usage/2026-08-16-plan-tracker-drift-and-the-audit-that-found-it.md` — a plan rewritten after its slices were cut leaves no trace in the tracker: 31 of 32 slices assumed one harness after the design moved to four. Also `karpathy-guidelines` never loaded, and evidence for a mechanism spent on recommending an action, three times.
- `skill-usage/2026-08-19-afk-batch-and-three-skips.md` — an AFK batch that built the four sub-issue trees and merged two PRs, and skipped `t4-bro` in the session implementing the issue about `t4-bro` not loading. A trigger that fires on every reply is one an agent stops seeing.

## concept — compiled topic hubs (a retrieval index over notes/ADRs/reports, not a new fact source)
- (none yet)

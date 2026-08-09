---
name: bootstrap-self-consistency
description: This repo ships the T4 standard; the rules it documents must stay verifiable against the repo's own tests.
type: project
---

xeno-skills ships the standard it enforces. The hook scripts at the repo root `hooks/` are the
**canonical** copies; the bootstrap (`skills/t4/t4-project-bootstrap/references/hooks/`) ships
byte-identical copies so a repo installed without the plugin is self-contained. Tests enforce the
sync: `tests/hooks/test-bootstrap-sync.sh` (byte-compare) and `tests/hooks/test-wiring-parity.sh`
(same hooks registered in plugin `hooks.json` and bootstrap `settings.json`).

**Why:** the composition audits (docs/research/2026-08-04-*.md) found this class of defect — a
rule documented in one delivery path and drifted in another. The tests exist so the two paths
can't silently diverge.

**How to apply:** editing a root `hooks/` script means re-copying it to
`skills/t4/t4-project-bootstrap/references/hooks/` in the same change, or `test-bootstrap-sync.sh`
fails. Editing the hook wiring means touching both `hooks/hooks.json` and the bootstrap
`references/hooks/settings.json`, or `test-wiring-parity.sh` fails. Reference [[agent-primary-repo]].

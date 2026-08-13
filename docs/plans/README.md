# docs/plans — index & status

Implementation / remediation plans. Status: `LIVING` = keep current · `SNAPSHOT` = point-in-time (don't edit, add new) · `ARCHIVED` = superseded · `TEMPLATE` · `REALIZED` = the work landed.

| File | Status | What it planned |
|------|--------|-----------|
| `2026-08-04-composition-remediation-plan.md` | SNAPSHOT | Fixing the defects the 2026-08-04 composition audits found |
| `2026-08-13-skill-compliance-plan.md` | LIVING | Making the skills enforceable: gap-only injection before a turn, sequence traces written into each rule, and a small-model reviewer at turn end. Implements #159. Carries the compaction finding — a session that only ever compacts keeps every old record, so a whole-file check reports skills as loaded whose content was compacted away. |

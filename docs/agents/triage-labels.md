# Triage Labels

**The five canonical roles and their mapping table come from `/setup-matt-pocock-skills`** — invoke it
rather than reproducing them here. What follows is the **T4 delta**: the groups pocock does not carry.

## The five canonical roles (from setup-matt-pocock-skills)

| Role | Label string in this repo | Meaning |
|---|---|---|
| needs-triage | `needs-triage` | New, not yet assessed |
| needs-info | `needs-info` | Blocked on a question / missing repro |
| ready-for-agent | `ready-for-agent` | Scoped enough for the coding agent to pick up unattended |
| ready-for-human | `ready-for-human` | Needs a human decision, review, or an external action |
| wontfix | `wontfix` | Will not be actioned |

## T4 delta — optional label groups (this repo uses them)

- **Component** — one per issue: `t4`, `hooks`, `multi-agent`, `ci`, `research` (which part of the repo owns it).
- **Type** — one or more: `bug`, `Feature`, `tech-debt`, `security`.
- **Severity** — one per Bug/Security: `critical`, `Major`, `Minor`.

**A `security` issue must carry `critical` or `Major`.** And the vocabulary is not installed until the
labels exist: create them with `gh label create` and report what was created, what was already there,
and what you skipped. A documented vocabulary with no labels behind it reads as configured and is not.

## Conventions

- Every issue has ≥1 triage-state label and exactly one component label.
- `security` issues must be `critical` or `Major` — a `Minor` security label is not valid.
- A `Latent` bug that activates is upgraded to a full Bug issue with severity.

# AFK artifacts

Reusable templates for an unattended batch run. The skill body (`../SKILL.md`) is the discipline; this is the paperwork it produces.

---

## Preflight checklist (run before the developer leaves)

Copy into your working notes and tick each before going unattended:

```
[ ] Memory read: Home.md → the notes relevant to this batch only
[ ] Conventions read: CLAUDE.md + docs/agents/* for every sub-project the batch touches
[ ] Worklist built from issues I'm allowed to work (authored by us / ready-for-agent)
[ ] Each item is independent (no shared half-done state between items)
[ ] Run bound agreed: ___ items OR ___ time box
[ ] STOP list confirmed with dev: security boundaries, architecture/seam, irreversible ops,
    scope growth, ambiguous requirements → I will PARK, not guess
[ ] Git tree is clean / checkpointable (a known-green baseline to revert to)
[ ] Notify channel works (scripts/notify.ps1 or repo equivalent)
```

If any box can't be ticked, the batch isn't AFK-ready — resolve it while the developer is still here.

---

## Park note (write into the issue body + ledger row when you stop an item)

A park is not a failure — it's a clean handoff. The returning developer (or next agent) must be able to resume from the note alone, with the repo already at green.

```markdown
### 🅿️ Parked — <issue #NNN / item name>  (<date>)

**What I was doing:** <the change in progress, one line>
**Why I stopped:** <which stop condition — 🛑 boundary / gate failed / irreversible / ambiguous / scope growth>
**Decision needed from you:** <the exact question, phrased so a yes/no or a pick answers it>
**Already done (and committed):** <what's green and landed — file:line / commit SHA>
**Reverted:** <what I rolled back to keep the tree green, if anything>
**Safe to resume by:** <the first concrete step once the decision is made>
```

Bilingual on the issue body (EN + full Thai mirror, same depth) per the tracker rule; the ledger row can be a one-line pointer to it.

---

## Landing digest (the single end-of-batch notification)

Send once — on batch-done or when a decision is genuinely needed. Not per item.

```
AFK batch done — <repo> — <N> items

✅ Done (closed w/ evidence):   #12 fix(cache) · #15 refactor(forum) · #18 test(wallet-readonly)
🅿️ Parked (need a decision):   #14 — schema change needs migration path (see park note)
                               #17 — auth guard change, security boundary → your call
⏭️ Not reached (run bound hit): #19, #20

Tree: green @ <commit SHA>, pushed. Ledger + ship log updated.
```

Keep it scannable: what landed, what's waiting on the developer and why, where the repo sits. The detail lives in each issue's park note — the digest just routes attention.

---

## Why these three, and nothing more

- **Preflight** is the only place scope gets set — get it wrong and the whole unattended run is unsafe. It's a checklist because every item is a real failure mode from an actual batch, not advice.
- **Park note** is what makes "stop, don't guess" cheap enough to actually do. Without a template, agents guess because parking *feels* like dropping the work; the template reframes a park as a completed handoff.
- **Landing digest** enforces one-notification discipline (per-item pings defeat the point of AFK) and forces the done/parked/unreached accounting that keeps issues honest.

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
### The gate line every digest and every branch carries

```
T4-Gates: simplify=ran code-review=ran scrutinize=not-run security-review=n-a verify=ran
```

One line per item in the digest, and the same line as a commit trailer on the branch so `check-gate-ledger` can block a push that omits a gate. **`not-run` is a legal answer** — write it with the reason beside it. The form exists because silence about a gate is indistinguishable from having passed it, and a digest that merely *lists* what ran expresses an omission by writing less.

- **Landing digest** enforces one-notification discipline (per-item pings defeat the point of AFK) and forces the done/parked/unreached accounting that keeps issues honest.

## Worked examples — four escalations that should not have happened

All four occurred in one session on 2026-08-03, **with the developer present** — not AFK at all. The
guidance existed and had been consulted in every case. The developer's reply was
*"ไม่ใช่ว่าเราทำการ prd และตัดสินใจไปหมดแล้วหรอ"* — didn't we already do the PRD and decide all this?

**1 — A decision the plan explicitly delegated.** `pal-mcp-server#22` says *"Whether existing callers
are given a grace period is the one open question **for the implementer**."* The agent read "open
question", filed the slice `needs-info`, and wrote *"an unattended agent must not pick the answer"* —
which inverts the sentence. The plan was handing the call over; it was received as withholding it.
**Fill the park sentence and it collapses:** blank one cannot be filled, because the plan does say.

**2 — New information appearing to reopen a settled decision.** `pal-mcp-server#23` specifies four
fields including *"a placeholder for cost that this slice leaves absent"*. A reviewer objected that the
placeholder locks in nothing. The agent kept the field — correctly — and then escalated the objection
anyway. **Record it, keep the decision, escalate only on an invalidated premise.** The premise here was
that a later slice fills the field; the objection did not touch it.

**3 — A dependency mis-framed as a choice.** `xeno-skills#75` was escalated as *"compare against the
prose research doc, or against the generated matrix? I lean matrix."* The parent PRD's **change
inventory** already answered it in a table row: *"Produced by #72; this PRD consumes it as the figure
source."* There was no choice — there was an unmet dependency on #72. The agent had read the issue; the
answer was in a structured section its own summary had dropped. **This is the case for re-reading
rather than recalling.**

**4 — Ordinary unstarted work counted as a blocked decision.** `pal-mcp-server#20` and `xeno-skills#74`
were reported as *"not split yet — splitting either is a scope decision"*. Splitting a PRD into issues
is `/to-issues`. Listing work-bound items beside genuine blockers makes the queue look decision-bound
when it is not.

**The pattern across all four:** none was a guess-versus-ask judgement call. Each had an answer already
written down, in a place the agent had already looked. What was missing was a test that must be
*passed* rather than a list that can be *consulted* — which is why the park sentence exists.

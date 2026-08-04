# Remediation plan — what to change in xeno-skills, and in what order

**Version 2**, rewritten 2026-08-04 after an adversarial review. Version 1 had eight phases; this has
four. What was cut, and why, is in the appendix — read it before proposing any of it again.

Derived from the four composition audits in [`docs/research/`](../research/):
[mattpocock](../research/2026-08-04-xeno-vs-mattpocock-composition-audit.md) ·
[superpowers](../research/2026-08-04-xeno-vs-superpowers-composition-audit.md) ·
[9arm](../research/2026-08-04-xeno-vs-9arm-composition-audit.md) ·
[impeccable](../research/2026-08-04-xeno-vs-impeccable-composition-audit.md).

---

## What the review changed

Three seats (`gpt-5.6-sol` @ high · `Gemini 3.1 Pro` · `Grok 4.5`), two rounds. Round 1 asked whether
the *ordering* was right; every seat took the scope as given. Round 2 ran the same seats under
`scrutinize` + `karpathy-guidelines`, whose mandatory simpler-alternative pass asks the question round 1
never asked. Both round-2 seats independently moved from *"reorder it"* to **"it is too big"**.

The verdict that survived verification: **version 1 grew an instrumentation programme around a
deletion-and-ownership problem.** Six findings changed this document materially:

| Finding | Source | Effect |
|---|---|---|
| **9arm ships no licence** — no `LICENSE`/`COPYING`/`NOTICE` anywhere, no grant in the README or plugin manifest | codex, verified at source | **D2 reversed** — vendoring is not permitted |
| The **deletion check is circular** — it asks whether the outcome still occurs, not whether upstream owns the capability | Grok | spine replaced |
| **Phases 3 and 4 were circular** — the ADR assigned debugging to superpowers, then Q2 tested 9arm vs pocock, neither of them the winner | codex, verified | Phase 4 cut; the circularity dissolves with it |
| **The plan violated its own criterion** — it kept techniques on the grounds that no upstream has them | codex, verified | fifth escape hatch closed |
| **`context.mjs` runs in setup for every impeccable sub-command**, so `audit`/`polish` route to `init` too, not only `shape` | Gemini, verified at source | 1D removed from Phase 1 entirely; `PRODUCT.md` promoted to an owner decision |
| **Phase 7 is explicitly not-defects** — the plan said so itself | both round-2 seats | deleted permanently |

One reviewer claim was **refuted** and is recorded so it is not reintroduced: the proposal to move the
supply-chain phase first, on the grounds that 9arm's flattening installer collides with xeno in the
global skill namespace. Checked directly — 9arm ships exactly six skills (`debug-mantra`,
`management-talk`, `post-mortem`, `qwen-agent`, `qwenchance`, `scrutinize`), **zero** of which share a
basename with xeno's sixteen; 9arm does not ship `karpathy-guidelines`; and
`~/.claude/skills/karpathy-guidelines` resolves once, to `~/.agents/skills/`. The 9arm audit itself
marked that claim UNVERIFIED.

**A seventh change came from the owner, not the review, and it is the most instructive one.** Asked
*"are you sure those slash-commands do not exist?"*, the answer was no: `/to-prd`, `/to-issues` and
`/diagnose` all resolve on this machine. Version 1 had turned a scoped audit statement into an unscoped
one and built a "mechanical, no decision required" Phase 1 item on it. See **1.2**, **Phase 2 item 6**,
**3.3**, and the base-rate note in the evidence register — the correction touches all four, because a
wrong premise had propagated into the fix, the ownership question, and the CI check meant to catch it.

---

## 🔴 Before Phase 0 — the credential

A GitHub PAT sits in plaintext in `~/.codex/config.toml` under `shell_environment_policy.set` and is
handed to every clink subagent spawned through that client, including every seat in the review above.
**Revoke, reissue, audit the token's scopes, and clean the affected clients.** All three reviewers
independently said this should precede the work rather than sit in a footnote. It is the owner's
action; the value is not reproduced here.

---

## The spine — the ownership test

Version 1's criterion had a circular second half and four relabelling escape hatches. This is the
replacement. Apply it **before** any per-item judgement.

> **Ownership test.** For each clause, name the **capability** it encodes — not the T4 outcome it
> serves. If any resolved dependency already implements that capability, delete the clause and keep at
> most: **(a)** the route or trigger, **(b)** a T4 precondition or postcondition that states a
> checkable fact, **(c)** a mechanical gate.
>
> **Resolve the whole universe first.** "Any resolved dependency" means **all six source kinds**, not
> the four ecosystems: the four upstream repos · Claude Code **bundled** commands (`/simplify`,
> `/security-review`) · the flat `~/.agents/skills` namespace (`/zoom-out`, `/find-skills`) · a **hook
> command** in `.claude/t4.json` (`/verify`) · and retired names that resolve to nothing. Version 1
> tested against four while stating six in the same document — and the impeccable audit's own method
> note says to enumerate the sources and check the list is closed *before* asking who owns a
> capability.
>
> **No-relabel rule.** *Sequence*, *gate*, *integration* and *brief* are not ownership.
> - A sequence that **orders** upstream techniques is composition. A sequence that **restates** their
>   steps is a clone.
> - A brief of numerics is a technique artifact **unless a named upstream consumes that artifact as
>   input under a declared schema.**
> - Declaring an integration around a method does not make the method xeno's.
>
> **Absence is not a retention reason.** A technique no upstream implements is still a technique.
> **Contribute it upstream, or drop it.** "Nobody else has this" was the fifth escape hatch and is
> closed.
>
> **Forbidden moves.** You may not retain a clause by (1) declaring a new integration around it,
> (2) expanding the definition of the T4 outcome to include it, or (3) renaming it a gate without a
> machine-checkable deny or require.

**Version 1's deletion check is withdrawn.** *"Delete this and load only the upstreams — can an agent
still produce the T4-ordered outcome?"* is circular: define the outcome to include the technique and
the answer is always "keep". It also hard-coded the four-ecosystem universe. Do not reinstate it.

**What survives the ownership test** — stable across all four audits, and the answer to "what is xeno
for":

- **mechanical enforcement** — `PreToolUse` deny, hook-run `verify`, pre-push guards, CI required
  checks. All four upstreams are prose; this layer exists nowhere else.
- **the clink transport** — call signature, `continuation_id`, per-call model/effort, quota-lane
  economics, platform gotchas. Not expressible in an in-harness dispatch model.
- **team policy** — bilingual tracker bodies, the issue→PR gate, the memory layer, AFK park boundaries.
- **the evidence registers** — including the *Unknown* register and the **laundering** failure mode,
  which appear in none of the four.

---

## Sequencing — four phases, and Phase 3 is the end

| Phase | What | Blocked on | Size |
|---|---|---|---|
| **0** | Credential, then unblock the tracker | — | hours |
| **1** | Pure defects — internal contradictions, dead references, orphans | Phase 0 for one item | 3–4 PRs |
| **2** | **One ADR** — the ownership test and every decision that depends on it | owner answers five questions | 1 ADR |
| **3** | Apply the ADR to the survivors; pin the supply chain | Phase 2 | 2–3 PRs |

Everything else is **parked with no schedule** (appendix). This is deliberate: the audits measured a
deletion-and-ownership problem, and the remediation is a deletion-and-ownership remediation.

---

## Phase 0 — credential, then unblock

| # | Action | Note |
|---|---|---|
| 0.0 | 🔴 **Revoke and reissue the PAT** | Precedes everything |
| 0.1 | Open an issue for the research branch | It has no PR because it has no issue; the gate is prose here, not enforced |
| 0.2 | Merge the PR stacks in order: **#91 → #92**, **#95 → #97** | Merging a child before its base retargets it wrong |
| 0.3 | Write `docs/agents/triage-labels.md` | 15 labels exist on GitHub with no committed vocabulary — the mirror image of the original defect |
| 0.4 | Re-check #48 (open since 2026-07-29) | Predates this batch; independent |

---

## Phase 1 — pure defects

Every **fix** here is a place where **xeno contradicts itself or points at something that does not
exist**, needing no upstream arbitration. Note the wording: 1.2 *inventories* four references but
prescribes a fix for only one — the other three resolve, and their remedy is a behaviour change routed
to Phase 2. Saying "every item" would re-assert about those three exactly the claim 1.2 withdraws.
Version 1's group **1D was removed entirely** — see Phase 2.

### 1.1 — the divergent file pair (highest value; the skill names itself as the example)

`t4-dev-workflow/SKILL.md` and `references/workflow-artifacts.md` diverge on several points: bilingual
PRD mandatory vs conditional · **auto-trigger table 13 data rows vs 7** (re-counted 2026-08-04; the
audit's "14 vs 7" counted the header on one side only) · security-trigger scope · `verify` as a
hook-run gate vs a bare mandate · orphan design-spec / implementation-plan templates that no step
produces or consumes.

**One of the audit's six points did not survive checking and is dropped**: *"triage roles enumerated
inline in one and forbidden in the other."* `SKILL.md:202` does enumerate the five roles, and
`workflow-artifacts.md:91` carries the full label table — that is **duplication**, which is the defect
here, but nothing forbids the enumeration.

`t4-dev-workflow/SKILL.md:33` cites **this exact file pair** as its worked example of a duplication
defect. Fix: one source of truth per fact; the reference file keeps only what the skill does not state.

**Do not touch the `/impeccable` row in either file** — it is Phase 2 work.

### 1.2 — a fabricated reference (pure), and three that resolve only by accident (**not** pure)

| Reference | Count | Status | Fix |
|---|---|---|---|
| `/boulder` at `design-setup:87` | 1 | **Fabricated. No such impeccable command, ever.** | **delete the row** — pure defect |
| `/to-prd` | 11 | resolves today, **only on this machine** | → Phase 2 |
| `/to-issues` | 8 | resolves today, **only on this machine** | → Phase 2 |
| `/diagnose` | 5 | resolves today, **one namespace only** | → Phase 2 |

*(Counts re-measured 2026-08-04 by `grep -rn --include='*.md'` over the repo root, so they include the
audit documents; skill-tree counts are lower.)*

**Version 1 of this plan called all four "references to things that do not exist" and prescribed a
mechanical rename. That was wrong, and the error was a laundering failure of exactly the kind
`t4-dev-workflow` documents.** The pocock audit stated something precise — *"Two names xeno uses do not
exist **in the clone**"* — which is true. Version 1 dropped the qualifier and upgraded it to a claim
about the world. Verified 2026-08-04:

| | in pocock's clone | installed on this machine |
|---|---|---|
| `to-prd` · `to-issues` | **absent** (not even under `deprecated/`) | present in `~/.agents/skills` **and** `~/.claude/skills` |
| `diagnose` | **absent** | present in `~/.agents/skills` **only** |
| `to-spec` · `to-tickets` · `diagnosing-bugs` | present | present |

Old and new names are installed side by side as distinct skills. `to-prd` and `to-spec` differ only in
the word PRD/spec. **`to-tickets` carries capability `to-issues` does not** — declared blocking edges,
one file per ticket locally, native blocking links on a real tracker.

**So the real defect is: the references resolve by accident of this machine's install history.**
Upstream no longer ships those names, so the installed copies will never receive an upstream fix, and
**anyone installing from pocock today gets a broken reference.** That makes it a latent break for every
consumer except this one.

**And it is not decision-free.** Renaming `/to-issues` → `/to-tickets` acquires new behaviour
(blocking-edge semantics), which is a capability change, not a spelling change. The choice — adopt the
successors, or keep and own the old names — belongs in the ADR. *Where the installed copies came from
is UNKNOWN; presumably an older pocock install.*

**Why delete the row rather than correct the spelling** — a reviewer correctly noted these are different
remedies and the choice is a judgement. The call, with its reason: the row is wrong in more than one
way and its provenance is unreliable. impeccable's real command is `bolder`. The transcript at
`skills/design/references/01_chase_ai_anti_slop_web_design.md:19` says *"if I look at boulder for
example… it pushes safe designs towards impact"* — the same description as impeccable's
`bolder | Refine | Amplify safe or bland designs`. The row's other figures ("23 commands") are
transcript-derived too and also wrong. **A corrupted citation propagated from raw ASR into a shipped
skill**, which is the concrete argument for 1.5.

### 1.2b — the full resolution audit of all 17 cited commands

Run 2026-08-04 against every source, because 1.2 showed the inherited claim could not be trusted.
`t4-dev-workflow` cites exactly **17** backticked slash-commands — the count the spine asserts. Result:

| Resolves to | Commands |
|---|---|
| **pocock clone** | `/tdd` · `/code-review` · `/grill-me` (`productivity/`, not `engineering/`) · `/grill-with-docs` · `/improve-codebase-architecture` |
| **9arm clone** | `/scrutinize` · `/debug-mantra` · `/post-mortem` |
| **impeccable clone** | `/impeccable` |
| **flat namespace only, no upstream, no pin** | `/zoom-out` · `/find-skills` · `/diagnose` · `/to-prd` · `/to-issues` |
| **nothing on disk** | `/simplify` · `/security-review` · `/verify` |
| **superpowers** | **none** — superpowers is cited by skill name, never by slash-command |

Two findings the plan did not previously carry:

- **`/verify` resolves to nothing and is presented as a skill.** `SKILL.md:134` and
  `workflow-artifacts.md:35` list it in the auto-trigger table alongside real skills; `SKILL.md:161`
  reveals it is actually the `.claude/t4.json` `"verify"` **config key** that the hook runs. There is no
  `/verify` skill in any source, and **`.claude/t4.json` is absent in both repos**, so the gate is inert
  as well. A config key wearing slash-command syntax in a table of skills is a routing defect.
- **`/security-review` cannot be shown to resolve.** Cited 5 times, present in no clone and neither
  namespace. `/simplify` is confirmed **bundled** (it loaded as `bundled:simplify` in a real session);
  `/security-review` is *presumed* bundled by the same route but that is **UNVERIFIED** — and the
  resolver check in 3.3 must be able to answer it, since "bundled" is one of the six source kinds and
  version-gated rather than path-gated.

**`using-t4` carries the stale names too**, which version 2 attributed to `t4-dev-workflow` alone:
`using-t4:47` asserts that every slash-command a T4 skill names — listing `/to-prd` — *"lives in one of
these"* three ecosystems, and the pocock row at `:52` gives `to-prd` and `to-issues` as its
representative skills. Neither is in the clone. Fix both files together.

### 1.3 — `t4-project-bootstrap`: one current defect, and two findings that belong to PR #97

**Only the first item is a defect on `main`.** Verified 2026-08-04:

- **Current, on `main`.** `SKILL.md:80` says *"Duplicating a sibling skill's skeleton here… Reference,
  don't copy"*, and `references/governance-docs.md:154-196` is exactly that duplication of pocock's
  `domain.md`. Both confirmed present on this branch. *(The audit cited `:102`; on `main` the file is
  **83 lines** and the sentence is at `:80` — see below.)*

- **Not on `main` — these are review findings against PR #97, and belong in 0.2, before it merges.**
  `gh label create`, the tracker choice offering GitLab and local markdown, and line 102 exist **only**
  on `fix/96-bootstrap-pocock-handoff`, where the file is 105 lines. `main` and every other branch
  carry 83 lines and none of that content. So *"label creation is unreachable for two of the three
  trackers the same step offers"* is a contradiction **introduced by that PR**, not an inherited
  defect — and the same is true of the `issue-tracker`/`triage-labels` ownership split against
  `SKILL.md:35` and `governance-docs.md:8,26` (both of which do assign those files to
  `t4-dev-workflow`, verified).

**Why version 2 got this wrong:** the audit's line citations were taken against the PR branch and the
audit did not say so. The plan carried them forward as current state. **Before acting on any `file:line`
inherited from the audits, confirm which tree it was measured in** — this is the second instance of the
same class of error in this document (see 1.2 and the evidence register).

### 1.4 — `clink-debug` deletes the one thing `debug-mantra` owns

`clink-debug` hands `debug-mantra` to **every** panel seat while mandating a fresh `continuation_id`
per seat. A fresh seat has no ledger, so **the provenance rule structurally deletes the breadcrumb
ledger** — mantra's single unique technique — and each seat recites the mantra into the transcript
instead. Meanwhile `t4-dev-workflow` and `delegation.md` both **forbid** delegating it, and 9arm's own
text agrees: *"a constraint **you** carry through the session."*

**The defect is pure; the fix contains one design choice** — where session state lives. Ship the
minimal version: **stop handing the mantra to seats.** The orchestrator carries it. A ledger *transport*
(how the orchestrator's breadcrumbs reach a seat that needs them) is a separate question and does not
gate this fix.

### 1.5 — orphans and sediment

- **`docs/superpowers/specs/` and `docs/superpowers/plans/` templates.** Nothing in the pipeline writes
  or reads them; `t4-project-bootstrap` scaffolds the directories and a README index, **created, never
  filled.** The plan template is a drifted clone of `writing-plans` whose paraphrase **broke the
  handoff** — superpowers names the sub-skill that executes the plan; xeno genericised it to name none.
  The spec template is unrelated content wearing superpowers' filename. → **delete; route to
  `writing-plans` / `brainstorming`.** Referenced in three skill files.
- **`skills/design/references/` — 135,734 B of raw ASR** (largest 29 KB; one an unbroken 7 KB paragraph
  containing `[music]` and *"subscribe to the channel"*). Provenance for rules already extracted 60 KB
  away — and, per 1.2, **an active source of corruption.** → archive as unloaded source material.
- **Order drift**: `/code-review` + `/scrutinize` in the skills, reversed in the hook and two READMEs.
  Exactly the duplicated-list drift `t4-dev-workflow` warns about.
- **`claude-9arm` names two mechanisms** — 9arm's shell alias (`claude --model qwen3.6-35b-a3b`) and
  xeno's PAL clink client config. Nothing in 9arm ships the alias, and xeno's install line omits the
  prerequisite. → xeno qualifies its own usage every time it appears.

---

## Phase 2 — one ADR

This is the only decision artifact, and it is the whole of the middle of the plan. It records the
ownership test above, then applies it to every question that cannot be answered without it.

**It needs five answers from the owner** (the table below). Nothing in Phase 3 starts before it lands.

What the ADR must decide and record:

1. **The ownership test itself**, as stated in the spine, including the no-relabel rule and the closed
   escape hatches. This is the load-bearing clause; everything else follows from it.

2. **`using-t4:47` vs `:51`** — two named owners for TDD and two for debugging, four lines apart, with
   nothing saying which wins. An agent reading the map cannot route. This is the defect the rule exists
   to close. **Say out loud what the TDD call decides:** superpowers puts refactor *inside* the
   red-green-refactor cycle; pocock explicitly excludes it. Picking an owner picks a **different loop**,
   not a different label.

3. **The nine superpowers contradictions**, each with a stated winner. *"Recording 'xeno wins' is an
   acceptable answer; leaving it undecided is not."* Two are mechanical and matter most:
   - **Contradiction #1 — parallel implementers.** superpowers forbids dispatching multiple
     implementation subagents in parallel; `clink-subagents` recommends exactly that and
     `clink-masteragent` concedes containment is unbuilt. **This is the liveliest runtime clash and
     version 1 omitted it.**
   - **Contradiction #9 — who decides the merge.** See D3.
   - `branch -D` is **not** one of them — the audit corrected itself; superpowers' normal path uses
     `-d`, which xeno permits.

4. **`t4-dev-workflow:104-121`** — root-cause discipline compresses `diagnosing-bugs` and then routes to
   `/debug-mantra`; **pocock's own skill is never named.** Under the ownership test, upstream owns
   diagnosis → the algorithm goes; xeno keeps "a traced cause is required before a fix" and the trigger.

5. **`t4-engineering-records`** — `using-t4` states the hand-off *"decides a bug needs a post-mortem,
   then invokes `/post-mortem`"* as its worked example of the composition rule. Measured:
   **`/post-mortem` appears 0 times and 9arm appears 0 times in that skill.** It re-derives the skill,
   and the two now disagree on write-authority — xeno mandates `docs/reports/YYYY-MM-DD-<slug>.md`,
   precisely what 9arm's *"never post to non-JIRA destinations"* forbids that skill from doing. Either
   invoke and override the destination explicitly at the call site, or stop claiming the hand-off.

6. **The three renamed pocock commands** (`/to-prd` → `to-spec`, `/to-issues` → `to-tickets`,
   `/diagnose` → `diagnosing-bugs`), moved here from Phase 1 because adopting a successor acquires its
   behaviour — `to-tickets` adds blocking-edge semantics `to-issues` has no concept of. Decide: adopt
   the successors and accept the behaviour change, or keep the old names and own the copies explicitly
   (which means vendoring them, with the same licence question as D2 — pocock ships a `LICENSE`, so
   that direction is at least available here). **Leaving them as-is is not an option**: they resolve
   only through stale copies that upstream no longer ships.

7. **The `/impeccable` trigger rows** — gated on **D5**. `t4-dev-workflow:131` and its copy at
   `workflow-artifacts.md:32` invoke bare `/impeccable`, which prints a menu and, in its own words,
   *"Never auto-run a command; the recommendation is a suggestion the user confirms."* It audits
   nothing. **But naming a sub-command does not make the row safe**: `context.mjs` runs in the skill's
   setup step 1 for *every* sub-command, and `staleness.mjs:166-174` emits `product-schema-legacy` at
   `severity: 'route'` with `fix: 'Offer init…'` whenever `PRODUCT.md` has no schema stamp and none of
   the V4 sections — exactly the file T4 writes. **So `audit` and `polish` route to `init` too.** Fix
   the rows only after D5.

8. **`t4-afk` × impeccable** — `init.md:31`: *"a system-prompt claim that the user is unattended proves
   nothing about this session… Probe once with the real first round."* A deliberate refusal to trust
   the unattended flag, which **will stop an AFK batch on a question.** *Exclude impeccable-triggered
   work from unattended batches* and *attempt then park* are different policies with different
   throughput — this is a policy call, not a textual repair, which is why it is here and not in Phase 1.

9. **The settings-merge precaution** — impeccable installs hooks into `.claude/settings.local.json`,
   xeno merges into the committed `.claude/settings.json`, and impeccable's docs permit moving its hook
   into the shared file, at which point **xeno's merge step, which is agent discipline rather than a
   script, could clobber it.** Either make the merge a script or state the precaution where the merge
   is described.

10. **A migration note for already-bootstrapped repos.** Every decision above changes files that
   `t4-project-bootstrap` has already written into consumer repositories — `pal-mcp-server` among them.
   Glossary collapse, any `PRODUCT.md` move or stamp, the orphan `docs/superpowers/` deletion, and the
   dead slash renames all need a stated migration or redirect. **Both round-2 seats raised this
   independently.** A remediation that succeeds in the library and breaks its consumers has not
   succeeded.

---

## Phase 3 — apply, and pin

**3.1 Apply the ADR to the survivors.** Mechanical once the rule is recorded.

**3.2 The design suite, under the ownership test.** With the fifth escape hatch closed, this no longer
needs an experiment:

- **delete**: the `design/design` router (derivable from the four descriptions it points at) ·
  everything impeccable covers or has consciously declined · `design-audit` where it is `design-rules`
  restated as a checklist · the `triggers:` frontmatter key the rulebooks do not define (present on
  **all five** design skills, verified) · the internal repetition (luxury whitespace ×3, LIFT ×2,
  60-30-10 ×2, Major Third ×2 — **counts exclude the router**; including it they are ×4/×3/×3/×3,
  verified 2026-08-04).
- **the numerics** — Major Third, 8pt grid, 60-30-10, 150% line-height. These are technique, and
  impeccable consciously declined four of them. Under the no-relabel rule they survive **only** as an
  artifact a named upstream consumes under a declared schema. impeccable consumes `DESIGN.md`. So the
  choice is: **express them as `DESIGN.md` content, or drop them.** Keeping them as skill law is the
  thing the ownership test forbids. *This is what dissolved version 1's Q1 — see the appendix.*
- **the staged funnel** (five style directions → select → three layouts → select → two-pass hero →
  promote, against impeccable's single approval point) — keep **only if** it passes the ownership test
  as *ordering* rather than *restating*, and expressed as route + gate, not as design advice.
  *"It is a sequence"* is not by itself ownership evidence.
- **MAYA · incremental pricing · the ordered 3-brain vote · OG/social tags · CTA scroll frequency ·
  button proportion · the portfolio audit** — version 1 kept these because no upstream has them. That
  reason is now closed. **Contribute upstream, or drop.**

**3.3 Pin the supply chain.** Minimal, and it is not the manifest organism version 1 proposed.

- **Pin the resolved git SHA as the identity for all four upstreams**, and record the version of the
  specific artifact you depend on as a label. Three ship semver (impeccable 41 tags, superpowers 6.2.0,
  mattpocock 1.1.0); 9arm ships **zero tags, four commits, no version field**. And the version is
  artifact-scoped: impeccable reports `3.5.0` in `package.json` and `4.0.4` in its plugin manifest —
  two separately-versioned artifacts in one repo, each correct — so "the version of impeccable" is
  wrong before it is written.
- **A resolver check, not a drift organism.** Assert that every slash-command xeno declares resolves to
  something that exists. Ten lines, in CI. The `staleness.mjs`-style taxonomy is parked (appendix).

  **It must resolve against the declared, pinned source set — never against whatever is installed on
  the machine running it.** This is not a detail; it is the whole value of the check. A resolver that
  reads the local namespace would have passed `/to-prd`, `/to-issues` and `/diagnose` on this developer's
  box, because stale copies happen to be installed there, while every other consumer is broken (see
  1.2). A check that is green precisely where the problem is invisible is worse than no check.
  `test-skill-manifest.sh` has the mirror-image flaw — it only reads xeno's own disk.

  The six source kinds each need a declared resolution rule: the four pinned upstream repos ·
  Claude Code bundled commands (version-gated, not path-gated) · the flat `~/.agents/skills` namespace,
  which has **no upstream and no pin** and is therefore the one source the check can only report on,
  not verify.
- **Do not vendor 9arm.** See D2.

---

## The five owner decisions

| # | Decision | Recommendation |
|---|---|---|
| **D1** | **Glossary** — collapse `UBIQUITOUS_LANGUAGE.md` into `CONTEXT.md`, or keep the split and rename | **Adopt pocock's convention.** Both decision seats reached it independently on a cost argument, not tidiness: keeping the split does not avoid the problem, because `domain-modeling` writes to `CONTEXT.md` regardless, leaving either two glossaries under permanent synchronisation or a permanent fork. Cost: everything pointing at the old file, and the architecture / Truth-Hierarchy blocks must move out of `CONTEXT.md` into a separately named T4 document — pocock's rule is that `CONTEXT.md` is *"a glossary and nothing else"*. Needs the migration note (Phase 2, item 9) |
| **D2** | **9arm** — vendor, or pin only | **Do not vendor. Pin the SHA, add the resolver check, and request an explicit licence.** 9arm has no `LICENSE`, `COPYING` or `NOTICE` file anywhere and no grant in its README or plugin manifest — verified this session. Absent a licence, default copyright does not permit reproduction or redistribution, which is what vendoring is. The audits' unanimous "vendor" recommendation was made without checking whether a grant exists. Revisit only if the author grants one |
| **D3** | **`autoMerge`** — contradiction #9 | **Record it narrowly, matching what the code already does.** `t4-dev-workflow:162` already scopes the skip to *"an unattended run under standing authorization"* with the `verify` deny still holding. Two reviewers objected that version 1's *"record 'xeno wins' on merge authority"* is broader than the implementation and invites the gate to grow. Record: attended sessions keep the human confirmation; AFK/`autoMerge` may skip the review-confirm ask only under explicit standing authorization recorded at AFK preflight |
| **D4** | **`design/*`** — what survives | **Decided by the ownership test, not by an experiment** — see 3.2. The only genuine choice left is whether the numerics move to `DESIGN.md` or are dropped |
| **D5** | **`PRODUCT.md`** — adopt impeccable's schema and stamp, or move T4's product brief off that path | **New in version 2, and it gates every `/impeccable` row.** Both libraries claim the path with incompatible schemas and **impeccable writes**: `init` takes the legacy branch, appends its own sections and stamps the file — English-only, into or after the `<!-- lang:en -->` region, which nothing in impeccable knows exists. The Thai mirror becomes structurally incomplete against a T4 rule requiring a full mirror. It does not clobber; it silently merges into a schema it cannot see, which is what makes it damaging. **No recommendation offered — both directions are defensible and the choice is the owner's.** A quieter one rides along: T4's skeleton has no `## Platform` section and impeccable defaults a missing platform to `web`, so every T4 repo silently declares itself web-only. Fix it as part of whichever direction wins — **not before**, since it means editing the contested file |

---

## Appendix — what was cut, and why it must not be re-added

Recorded so a future session does not reconstruct version 1 from the audits.

| Cut | Was | Why it went |
|---|---|---|
| **Adopt the capability gaps** (worktrees, `root-cause-tracing`, `finishing-a-development-branch`, `find-polluter`, `/implement`, `/wayfinder`, `/triage`, `qwenchance`, …) | Phase 7 | **Deleted permanently.** Version 1 said in its own words these are *"Not defects; capabilities xeno has no route to."* That is feature work inside a defect remediation, and it fails karpathy's surgical test outright. If a gap becomes load-bearing, it earns its own issue |
| **The behaviour-test harness** ported from impeccable | Phase 2 | **Parked, no schedule.** The Iron Law failure is real — `tests/skills/*.sh` grep skill text for sentences and cannot fail for the reason that matters. But version 1's justification for building it was that it would settle Q1 and Q2, and that justification is gone (below). Build it later on its own merits, as a scaffold for surviving skills — not as part of this remediation |
| **Q1 — do prescriptive numerics beat principled openness?** | Phase 4 | **Dissolved, not deferred.** Under the ownership test with the absence hatch closed, the numerics are technique either way; the only live question is *"does a named upstream consume this artifact under a declared schema?"*, which is answerable by reading impeccable's `DESIGN.md` contract. No experiment needed. Had it run as designed it would also have measured the wrong thing: a tool-call trace shows whether a brief was *loaded*, not whether the resulting design is better |
| **Q2 — does a fired ritual beat a skipped algorithm?** | Phase 4 | **Parked.** Two independent defects. **(a)** It was circular: Phase 3 recommended a rule assigning debugging to superpowers, then Q2 tested 9arm's `debug-mantra` against pocock's `diagnosing-bugs` — neither of them the ADR's winner — and the ADR was applied before the test ran. **(b)** It was mis-instrumented: the audit's criterion is *"misses causes at twice the rate"*, which needs an oracle (fixtures with known root causes), and a trace only shows whether the ritual fired. Revisit only with a stated oracle and after ownership is settled. **Carry the breadcrumb ledger and knob enumeration across to whichever owner wins** — they are the only techniques `debug-mantra` genuinely owns, and dropping them silently is the failure mode this parking must not cause |
| **The progressive-disclosure pass** | Phase 5 | **Parked as a phase; do it opportunistically.** The measurements are real — `clink-subagents` is 42,107 B with **0** reference files, `clink-brainstorm` 35,550 B with 1, against impeccable's 10,829 B router pointing at 36 references. It costs context in every session, but it does not misroute an agent, so it is hygiene rather than a composition defect. Fix a skill's disclosure when that skill is already open for another reason |
| **The drift manifest with the `staleness.mjs` taxonomy and a scheduled HEAD probe** | Phase 6.2 | **Reduced to the ten-line resolver check** (3.3). The audits asked for pinning and a check that cited names resolve; the three-kinds-of-drift, three-severities CI organism is machinery no measured defect requires. Copy the taxonomy later if the resolver check proves insufficient |
| **The deletion check** (*"can an agent still produce the T4-ordered outcome?"*) | the spine | **Withdrawn as circular.** Define the outcome to include the technique and it always answers "keep" |
| **Moving the supply-chain phase first** | reviewer proposal | **Refuted, not cut.** Its premise — a `karpathy-guidelines` collision in the flattened global namespace — does not hold: zero basename overlap between 9arm's six skills and xeno's sixteen, 9arm does not ship `karpathy-guidelines`, and the global entry resolves once. Treat foreign flatteners as an install-time ops note instead |

---

## Evidence register

**Verified in this session** (command run, output read). A full self-audit of this document was run
after version 2 was written; everything below was re-measured rather than inherited:

- repo state, PR bases, and **which branch each cited line lives on**
- skill byte sizes and reference-file counts · `skills/design/references` = 135,734 B · `triggers:` on
  all five design skills · the design repetition counts
- all four dead/stale reference counts · the `/boulder` ← ASR-corruption chain · **the full resolution
  audit of all 17 cited slash-commands** (1.2b)
- **`a4f2` appears in three skills** — pocock's `diagnosing-bugs`, the flat-namespace `diagnose`, and
  9arm's `debug-mantra` — confirming all three share one lineage
- `t4-dev-workflow:33` citing its own file pair · the auto-trigger row counts (13 vs 7) ·
  `using-t4:47` vs `:51` dual owners, and `:52` carrying the stale pocock names
- `/impeccable` bare at `SKILL.md:131` and `workflow-artifacts.md:32` · `staleness.mjs:166-174` severity
  `route` · `t4-dev-workflow:162` autoMerge scoping
- `clink-debug:48` (mantra to every seat), `:62` (fresh `continuation_id`), and `SKILL.md:206`
  forbidding its delegation — all three legs of 1.4
- **`/post-mortem` appears 0 times in `t4-engineering-records`** while the bare word appears 8, and 9arm
  appears 0 — which strengthens the "re-derives it" reading
- the `/code-review` + `/scrutinize` order reversed in `hooks/t4-gate:145` and both READMEs at `:53`
- `tests/skills/*.sh` are grep assertions — `has() { grep -qiF … }`, 6 of 9 files
- upstream tags/commits: pocock 4/316 · superpowers 33/680 · 9arm **0/4** · impeccable 41/1407 ·
  impeccable `3.5.0` in `package.json` and `4.0.4` in the plugin manifest · router 10,829 B / 36
  references · **pocock ships `LICENSE`, 9arm ships none**
- `governance-docs.md:18` (glossary self-contradiction), `:26` (ownership), `:154` (the domain skeleton)
- `PRODUCT.md` skeleton has no `## Platform` section · `.claude/t4.json` absent in both repos

**Corrected by that self-audit**: 1.3's line citations (measured against PR #97's branch, not `main`) ·
the auto-trigger row count · one of the six divergence points, dropped · the design repetition counts'
scope · `/verify` and `/security-review` added as unresolvable · `using-t4` added as a second carrier of
the stale names.

**Still inherited, not re-verified**: the nine superpowers contradictions individually, the `PRODUCT.md`
end-to-end trace beyond the `staleness.mjs` trigger, and impeccable's declined-numerics table.

**Base rate to respect — and it is worse than version 2 stated.** Counting the self-audit, **nine**
claims that were plausible and on their way into a conclusion did not survive being checked:

| # | Claim | Origin |
|---|---|---|
| 1 | `/grill-me` is a retired name | audit (2 seats agreed, both wrong) |
| 2 | the `branch -D` conflict is live | audit |
| 3 | *"`diagnosing-bugs` stalls on an unreproducible bug"* | panel seat — **had already flipped a vote** |
| 4 | impeccable's version strings disagree | audit |
| 5 | `karpathy-guidelines` collides in the global namespace | reviewer seat, from an UNVERIFIED audit line |
| 6 | *"these slash-commands do not exist"* | **this plan, v1 — a dropped qualifier** |
| 7 | the `t4-project-bootstrap` line citations | audit, **measured on an unmerged PR branch, unstated** |
| 8 | the auto-trigger table is "14 rows vs 7" | audit, header counted on one side only |
| 9 | triage roles are "forbidden in the other" | audit, unsupported by the file |

**Roughly one claim in four did not hold.** Nothing here was fabricated — every one is a small
imprecision (a dropped qualifier, an unstated tree, an off-by-one, a generalisation from one directory)
that survives summarisation and then carries a conclusion. #6 and #7 are the ones to internalise: both
were caught only because the owner asked *"are you sure?"*, and both had already been built into a
"mechanical, no decision required" work item.

**The sixth is the one to learn from, because it was not a panel seat's error — it was this document's.**
The pocock audit said *"do not exist **in the clone**"*, which is true and carefully scoped. Version 1
carried it forward without the qualifier, as a claim about the world, and built a Phase 1 "mechanical
rename, no decision required" on top of it. Nothing new was asserted; a qualifier was dropped in
summary. **That is the laundering failure mode `t4-dev-workflow` documents, committed by the plan that
cites it** — and it was caught by the owner asking "are you sure?", not by any check in this plan.

Two consequences, both already applied above: a claim's register never improves by being restated
(1.2), and a resolver check must resolve against a declared source set rather than the local machine
(3.3). **Re-check a citation before the PR that acts on it, not after.**

**Unknown**: whether the qwen context window is 128k (9arm) or 262,144 (`clink-masteragent`) · whether
9arm's author will grant a licence · what `~/.agents/skills/karpathy-guidelines` is installed from.

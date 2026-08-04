# xeno-skills × mattpocock/skills — composition audit (2026-08-04)

`xeno-skills` is built to sit **on top of** `mattpocock/skills`, not beside it. `using-t4` states the
rule: T4 owns the team-specific decision and hands the technique to the ecosystem skill. Under that
rule, **re-implementing a pocock capability is a defect in xeno**, not a feature.

Nobody had ever checked whether that holds. This is that check.

**Compared against:** `mattpocock/skills` at commit `2ab9580` (2026-07-28), cloned to
`D:\Github\skills` — 41 skills across `engineering/`, `productivity/`, `in-progress/`, `misc/`,
`personal/`, `deprecated/`. Every figure below was re-verified locally after the panel reported it;
where a panel claim did not survive that check it is recorded as such rather than dropped.

---

## Method

Two layers, run in parallel, because they answer different questions.

**Layer 1 — six read-only subagents**, one per axis, each returning a structured verdict with
`file:line` evidence and an explicit instruction not to return file contents. Axes: the
idea→spec→tickets pipeline · domain/glossary/records · setup & bootstrap · testing/debug/architecture ·
design & prototyping · conformance to pocock's own `writing-great-skills` rules.

**Layer 2 — a clink decision panel** on the questions the inventory cannot answer: which convention to
adopt, what the boundary rule should be, and how to detect upstream drift.

### What the method cost, and what broke

| Seat | Result |
|---|---|
| 6 × read-only subagents | all returned; 62k–83k tokens each, 72–145 s |
| `codex` `gpt-5.6-sol` @ `high` | returned at 480 s (inventory, 3.7 M input tokens) and 320 s (decision, 1.1 M) |
| `cursor` `grok-4.5-high` | returned at 202 s (inventory) and 131 s (decision) |
| `cursor` `composer-2.5` | returned at 176 s |
| `antigravity` `Gemini 3.1 Pro (High)` | **failed** — a tool needed the `command` permission, which headless mode cannot prompt for, so it was auto-denied. It could not read a file or fetch a URL, so the seat produced nothing |

The antigravity failure is the documented limitation in `clink-subagents`, reproduced. **A panel seat
that cannot read the subject is not a seat.** For an evidence audit, check the client can reach the
material before counting it as a vote.

### A panel claim that did not survive verification

One seat reported that `/grill-me` is a retired name. It is not — it lives at
`skills/productivity/grill-me`. Two seats had looked only in `engineering/` and generalised from its
absence there. **Acting on that would have rewritten five correct references.** Every finding below
was re-checked against the clone for this reason.

---

## 1. xeno contradicts itself

The most expensive class, because no external skill has to be involved for it to cause damage.

### 1.1 `governance-docs.md` disagrees with itself about the glossary

| Location | Says |
|---|---|
| `references/governance-docs.md:18` | `CONTEXT.md` is a system-context doc that **points at `UBIQUITOUS_LANGUAGE.md` as canonical** |
| the `docs/agents/domain.md` skeleton it ships, ~`:167` | `├── CONTEXT.md ← **domain glossary for the whole codebase**` |

One file, two answers — and **the skeleton (what xeno actually writes into a repo) agrees with pocock,
while the taxonomy table above it does not.**

### 1.2 The rest

- `t4-project-bootstrap/SKILL.md:58` hands `issue-tracker`/`triage-labels` to `/setup-matt-pocock-skills`,
  but `SKILL.md:35` and `governance-docs.md:8,26` still assign those files to `t4-dev-workflow`.
- `SKILL.md:68` mandates `gh label create`, while `SKILL.md:58` delegates a tracker choice that
  includes GitLab and local markdown — **label creation is unreachable for two of the three trackers
  the same step offers.**
- `SKILL.md:102` says *"Duplicating a sibling skill's skeleton here… Reference, don't copy"*;
  `governance-docs.md:154-196` is exactly that duplication.
- **`t4-dev-workflow/SKILL.md` and `references/workflow-artifacts.md` diverge on six points** —
  bilingual PRD mandatory vs conditional; auto-trigger table 14 rows vs 7; security-trigger scope;
  `verify` as a hook-run gate vs a bare mandate; triage roles enumerated inline in one and forbidden
  in the other; orphan design-spec/implementation-plan templates no step produces or consumes.
  `t4-dev-workflow/SKILL.md:33` **names this exact file pair as a worked example of a duplication
  defect** — and the pair is currently divergent on every point above.

---

## 2. Contradictions with pocock — worse than duplication

A copy drifts. A contradiction makes two installed skills fight in the same repo.

| Subject | xeno | pocock |
|---|---|---|
| Debugging without a reproduction | *"say so explicitly and treat everything after as a hypothesis"* — and continue | `diagnosing-bugs:49,60` forbids it: *"No red-capable command, no Phase 2"* |
| Characterization tests | preserve permanently, quirks included | `DEEPENING.md:34` — delete shallow-module tests; they become waste |
| Glossary entry length | *"one-paragraph definition"* | `CONTEXT-FORMAT.md:28` — *"one or two sentences max"* |
| ADR sections | Context/Decision/Alternatives/Consequences mandatory | `ADR-FORMAT.md:19` — *"most ADRs won't need them"* |
| Unrelated dead code | `karpathy-guidelines` — mention it, don't delete | `improve-codebase-architecture` ships a deletion test |

---

## 3. The glossary trap, traced

Not hypothetical. The sequence, from the files:

1. A T4 repo puts canon in `UBIQUITOUS_LANGUAGE.md`; `CONTEXT.md` holds a quick-reference copy.
2. `/domain-modeling` runs. **It reads only `CONTEXT.md` — it has no code path to
   `UBIQUITOUS_LANGUAGE.md` at all.**
3. It challenges the user against the quick-reference copy — the one `governance-docs.md:59` declares
   loses on conflict.
4. On resolution it writes the term into `CONTEXT.md`, so canon and copy diverge silently.
5. xeno's own rule — *"drifting to an alias to avoid is a defect"* — then fires **against the correct
   terms**.
6. `improve-codebase-architecture` writes terms to `CONTEXT.md` too, compounding it.

**Supporting evidence:** pocock has deprecated its own `ubiquitous-language` skill. Its successor,
`domain-modeling`, replaced batch extraction into a separate file with inline capture into
`CONTEXT.md`. xeno's `UBIQUITOUS_LANGUAGE.md` skeleton reproduces the retired artifact closely —
same columns, same Relationships and Flagged-ambiguities sections. **The deprecated README records no
reason**, so *why* it was retired is UNVERIFIED; that the shape was abandoned is not.

---

## 4. Duplication to remove

Ranked by how much text is duplicated:

1. **`workflow-artifacts.md:43-80`** — the whole `docs/agents/issue-tracker.md` skeleton, a
   near-line-for-line rewrite of `setup-matt-pocock-skills/issue-tracker-github.md`, which
   `/setup-matt-pocock-skills` already writes to that same path. Self-indicting: the sibling block at
   `:87-93` refuses to do this for labels **and cites the drift risk as the reason**.
2. **`workflow-artifacts.md:113-182`** — the PRD template reproduces `to-spec`'s structure. Genuinely
   new: Change Inventory, Risks & Rollback.
3. **`governance-docs.md:154-196`** — the `docs/agents/domain.md` skeleton rewrites pocock's
   `domain.md`, down to a matching ADR-conflict blockquote.
4. **`t4-dev-workflow/SKILL.md:104-121`** — root-cause discipline compresses `diagnosing-bugs`, then
   routes to 9arm's `/debug-mantra`. **pocock's own skill is never named.**
5. **`t4-project-bootstrap/SKILL.md:43-49`** — the ask-flow added 2026-08-04 is a paraphrased copy of
   pocock's process section wearing a citation. Attribution does not stop a copy drifting.
6. **`design-setup`** duplicates roughly 40% of `prototype/UI.md` — N variants, isolated location,
   pick one, promote, delete the rest. They also **disagree** on the outcome: `UI.md:105` keeps the
   variant set on a throwaway branch; `design-setup:174` deletes it.

---

## 5. xeno against pocock's own rules for writing skills

Measured against the baseline set by `writing-great-skills/SKILL.md` itself (9,497 B):

| Skill | Size | Reference files |
|---|---|---|
| `clink-subagents` | **42,107 B** (4.4×) | **0** |
| `clink-brainstorm` | 35,550 B (3.7×) | 1 |
| `t4-dev-workflow` | 22,423 B (2.4×) | 1 |
| `clink-masteragent` | 18,974 B (2.0×) | 0 |

The rules set no hard byte limit, so the multiplier is a framing, not a violation of a stated
threshold — UNVERIFIED as a rule breach. **Zero reference files on a 42 KB skill is not**: nothing was
pushed down the disclosure ladder.

- **`skills/design/references/` is 135,734 B of raw YouTube transcripts**, the largest 29,168 B, one of
  them a single unbroken 7 KB paragraph containing `[music]` and *"subscribe to the channel"*. This is
  sediment, not reference material.
- **158 negated instructions** across the 16 skills.
- The five `design` skills carry a `triggers:` frontmatter key the rules do not define; it restates the
  description and is paid for on every load.
- `design/design` is a router derivable from the four descriptions it points at.
- The design suite repeats itself internally: luxury white space in three files, LIFT in two,
  60-30-10 in two, Major Third in two. `design-audit` is largely `design-rules` restated as a checklist.

---

## 6. Capabilities xeno has no route to

`/implement` — and with it the *clear context between each ticket* rule · `/wayfinder` for work spanning
sessions · `/prototype`, whose entire `LOGIC.md` branch (TUI-driven state, portable reducers) has **zero
matches** anywhere in xeno · `/research` · `/handoff` · `/triage` **as a step** — xeno adopted the labels
but never the on-ramp · tracer-bullet vertical slicing and expand–contract from `to-tickets`.

Two names xeno uses do not exist in the clone: **`/to-prd`** (now `to-spec`) and **`/to-issues`** (now
`to-tickets`) — 7 references. `/diagnose` has no skill by that name either; the capability is
`diagnosing-bugs`.

---

## 7. What is genuinely xeno's

Every seat agreed on this list, and it is the argument for the library existing at all:

- **Mechanical enforcement** — `PreToolUse` deny, hook-run `verify`, pre-push guards, CI required
  checks. pocock's pipeline is entirely prose.
- **The memory layer** — vault, open-work ledger, ship log.
- **AFK park boundaries** — what an unattended agent may decide alone.
- **Change-site survey** with a stated search boundary, and the resulting change inventory.
- **Evidence registers** and **skipping-requires-proof**.
- **The bilingual TH+EN tracker rule.**
- **The four `clink-*` skills** — a runtime pocock has no equivalent for.
- **Design numerics** — Major Third scale, 8pt grid, dark-mode elevation ramp, 4-state buttons.

---

## 8. Decisions this audit cannot make

**D1 — the glossary.** Adopt pocock's convention (`CONTEXT.md` *is* the glossary; retire
`UBIQUITOUS_LANGUAGE.md`), or keep the split and rename so `domain-modeling` cannot write to the wrong
file.

**Both decision seats reached the same answer independently, from different lineages: adopt pocock's.**
The shared reasoning is not the tidiness argument but a cost one — keeping the split does not avoid the
problem, because pocock still writes a glossary to `CONTEXT.md` regardless. You end up with two
glossaries requiring permanent synchronisation, or a permanent fork of `domain-modeling`. The migration
is the cheaper direction even though it is the larger edit.

What breaks if adopted: anything still pointing at `UBIQUITOUS_LANGUAGE.md`, and the architecture and
Truth-Hierarchy blocks currently nested inside `CONTEXT.md` must move out — pocock's rule is that
`CONTEXT.md` is *"a glossary and nothing else"*.

The strongest argument against, which both seats raised themselves: a system-context document and a
glossary are legitimately different information architectures, and this collapses them. **Owner's call.**

**D2 — the boundary rule.** The sharper of the two proposals is a **subtraction test**, because it is
mechanical rather than a matter of judgement:

> Strip every clause that depends on T4 policy/configuration or on a declared xeno-specific
> integration. **If a useful technique, workflow or artifact schema still remains, that remainder
> belongs to pocock** — xeno keeps only the routing delta.

Applied to real cases: the bilingual tracker rule **stays** (remove the Thai-mirror requirement and no
capability is left — it is pure policy); the `clink-*` skills **stay** (without PAL's `clink` they do
nothing standalone); the root-cause discipline **goes** — strip T4's policy and a complete diagnosis
algorithm remains, which `diagnosing-bugs` already owns. xeno keeps "a traced cause is required before
a fix" and the routing trigger, nothing more.

The known loophole: "declared xeno-specific integration" can be stretched to retain generic methods.
Worth watching rather than solving up front.

**D3 — drift detection.** Pin the upstream commit in a compatibility manifest listing the skill IDs
xeno depends on, then have CI shallow-clone that commit and verify each cited name **exists, matches
its frontmatter, and is not under `deprecated/`** — the last check matters, since `ubiquitous-language`
is exactly a skill that still exists but should no longer be relied on. Add a scheduled probe against
upstream HEAD that opens an issue on drift rather than failing the build.

Cost: one shallow clone and a linear scan, roughly a CI runner-minute. This is the mechanism that would
have caught `/to-prd` and `/to-issues` months ago; `test-skill-manifest.sh` cannot, because it only
checks xeno's own disk.

---

## Method note worth keeping

The two highest-value findings came from opposite directions: the `CONTEXT.md` collision was found by
**one seat only** (the most expensive one, and none of the others saw it), while the retired
`/grill-me` claim was asserted by **two seats and was wrong**. Neither agreement nor disagreement was a
reliable signal on its own — **only re-checking the claim against the clone was.** Budget for the
verification pass; it is not optional overhead on a panel of this size.

Convergence was informative once, and only where the seats had to *decide* rather than *find*: both
decision seats independently chose the same answer on D1 and gave the same underlying cost argument.
That is worth more than two seats agreeing on an observation, because they reasoned to it from the same
evidence by different routes — and because each named the same strongest objection to its own answer.

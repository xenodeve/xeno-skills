# xeno-skills × obra/superpowers — composition audit (2026-08-04)

Companion to [the mattpocock audit](2026-08-04-xeno-vs-mattpocock-composition-audit.md), run with the
same method against the second ecosystem `using-t4` declares xeno sits on top of.

**Compared against:** `superpowers` at commit `44c9b2d`, cloned to `D:\Github\superpowers` — 14 skills,
plus its own `hooks/` layer, `tests/`, and `docs/`. Every figure was re-verified locally after the
panel reported it.

**The finding that changes the shape of the problem:** against pocock, xeno's defects were mostly
*duplication*. Against superpowers they are mostly **contradiction** — nine places where the two
libraries give opposite instructions on the same question. A duplicate drifts quietly; a contradiction
means two installed skills fight in the same session, and the agent obeys whichever it read last.

---

## Method

Six read-only subagents, one per axis — the hooks layer · subagent delegation · plan/spec artifacts ·
TDD/debug/verification · code review and branch lifecycle · the skill-writing rulebooks. Plus a clink
decision panel on what arbitrates when two ecosystems own the same capability.

### The lead hypothesis was wrong, and that is the point

The audit opened on a specific suspicion: **both libraries ship a `hooks.json` and a `run-hook.cmd`,
so one must overwrite the other.** It was stated up front, given to the subagent as the thing to test,
and it is **false**.

| | Base directory | Writes into a repo's `.claude/`? |
|---|---|---|
| superpowers `hooks/hooks.json` | `${CLAUDE_PLUGIN_ROOT}` only | **No** — a grep for `.claude/hooks` across the whole repo returns nothing; every install path in its README is a plugin install |
| xeno `hooks/hooks.json` (plugin path) | `${CLAUDE_PLUGIN_ROOT}` only | No |
| xeno `references/hooks/settings.json` (bootstrap path) | `${CLAUDE_PROJECT_DIR}` | Yes — but into `.claude/settings.json`, which superpowers never touches |

Two plugin roots are two namespaces. Claude Code merges plugin hooks rather than reading one shared
file, so nothing is overwritten. **A hypothesis stated confidently and checked is worth more than one
stated confidently and repeated** — this is the second time in two audits that the pre-formed belief
did not survive contact with the files.

What *is* true, and milder: both register `SessionStart` with matcher `startup|clear|compact`, and both
wrap their injected map in `<EXTREMELY_IMPORTANT>`. Two "do me first" directives arrive in the same
session. `using-t4` resolves the precedence explicitly — *"For non-T4 how to work, prefer
`superpowers:using-superpowers`"* — but xeno also adds a `UserPromptSubmit` reminder that re-anchors T4
**every turn**, which superpowers has no equivalent of. That is framing dominance rather than a
functional conflict, and it is not documented anywhere as a deliberate choice.

---

## 1. Nine contradictions

Each is a rule one library states and the other forbids or inverts.

| # | Question | superpowers | xeno |
|---|---|---|---|
| 1 | May implementers run in parallel? | **Never** dispatch multiple implementation subagents in parallel — conflicts | `clink-subagents` recommends exactly that, and `clink-masteragent` concedes containment is unbuilt |
| 2 | May the reviewer re-run the suite? | **Forbidden** — the reviewer reads, it does not execute | xeno requires the master to re-run the test, the real build, and a mutation |
| 3 | May you proceed without a reproduction? | "don't guess", but shipping after documented investigation is allowed | **Explicitly permits** it: *"say so and treat everything after as a hypothesis"* |
| 4 | When is a claim fresh? | the verification command must have run **in this message** | *"in this session"* — a stale earlier run satisfies it |
| 5 | How many hypotheses? | **Form a single hypothesis** | (pocock rebuts with 3–5 ranked; xeno takes neither side) |
| 6 | Is refactor part of the TDD loop? | **Yes**, it is a cycle phase | xeno's pipeline says "red → green → refactor" while naming the skill `tdd`, which is pocock's — and pocock says refactoring is **not** part of the loop |
| 7 | Validation depth | `defense-in-depth`: validate at **every** layer, don't stop at one | `karpathy-guidelines`: *"No error handling for impossible scenarios"*, and `/simplify` fires after every change |
| 8 | May a branch be deleted? | `finishing-a-development-branch` runs `git branch -D` | xeno's gate **denies** `branch -D`, even under `"afk"` |
| 9 | Who decides the merge? | integration is the human's call — present the menu and wait | `"autoMerge"`/`"afk"` skips the confirmation ask |

Numbers 8 and 9 are the sharpest, because they are **mechanical**: xeno's `PreToolUse` gate will deny a
command that a superpowers skill instructs the agent to run. The agent is told to do something and then
blocked from doing it, with no message explaining that two libraries disagree.

---

## 2. Orphan artifacts at superpowers' own paths

`t4-dev-workflow/references/workflow-artifacts.md` ships two templates that write to
`docs/superpowers/specs/` and `docs/superpowers/plans/`.

- **The plan template is a drifted clone** of `writing-plans` — same path convention, same
  "For agentic workers" header, same Goal/Architecture/Constraints/`### Task N` shape. What drifted:
  superpowers **names the required sub-skill** to execute the plan; xeno genericised it to "use a
  subagent-driven / plan-execution skill", naming none — **the handoff is broken by the paraphrase.**
  Three sections were dropped, including *Commit* as a step.
- **The spec template is unrelated content wearing superpowers' filename.** superpowers has no spec
  template at all; the structure is xeno's own.
- **Worse: nothing produces or consumes either.** xeno's pipeline runs grill → survey → `/to-prd` →
  `/to-issues` → `/tdd`. No step writes or reads `docs/superpowers/`. `t4-project-bootstrap` scaffolds
  the directories and a README index — **created, never filled.**

And the template could not pass superpowers' own rules: `writing-plans` declares steps without code
blocks and "implement later"-shaped steps to be **plan failures**, which is exactly what xeno's steps
are.

---

## 3. Capabilities xeno has no concept of

- **Worktrees.** `grep -ril worktree` across all of `skills/` and `docs/` returns **zero files**. xeno
  has no workspace-isolation concept at all — while `clink-masteragent` marks containment as a missing
  *tool capability* pointing at `pal-mcp-server#20`. superpowers already owns the technique; the gap is
  narrower than xeno thinks, and mislabelled.
- **The end of a branch.** `finishing-a-development-branch` is a six-step procedure: run the suite ·
  detect the environment · confirm the base branch · present a three-option menu and wait · re-run the
  tests **on the merged result** · clean up. xeno has no equivalent for that moment; its nearest
  artifacts are a merge gate and an AFK landing block, neither of which covers base-branch
  confirmation, merged-result re-testing, or teardown.
- **Test pollution.** `find-polluter.sh` bisects a suite to find which test poisons another. A grep for
  pollution/flaky across `skills/` returns hits only inside two CI YAML templates — no skill mentions
  it. `t4-afk` requires unattended gates to pass and the repo to be left at last green; a cross-test
  polluter breaks that, and there is no tool to localise it.
- **A method for the trace xeno mandates.** xeno requires *"trace the actual path… cite `file:line`"*
  and makes it a mandatory handoff field, but supplies **no technique**. `root-cause-tracing.md` is
  exactly that technique.
- **Per-finding handling of review feedback.** `receiving-code-review` routes unclear or unverifiable
  feedback to *ask a human* — unavailable under AFK, which forbids blocking questions. AFK's answer is
  coarser: a failed gate parks the **whole item**, and its stop-and-park list never names a review
  finding. The missing rule is per-finding parking.

---

## 4. Three rulebooks, and the one xeno fails hardest

Skill-writing is now owned twice: superpowers' `writing-skills` and pocock's `writing-great-skills`.
Where they agree, the rule is strong — descriptions are triggering conditions not summaries;
progressive disclosure; prune aggressively; single source of truth. **xeno violates the first and third
across all 16 skills.**

Where they disagree — prohibition-heavy framing vs positive framing, and model-invoked vs
`disable-model-invocation` — **xeno follows superpowers on both**, apparently without the choice being
recorded anywhere.

The rule xeno fails hardest is superpowers' Iron Law: **no skill without a failing test first**, with a
subagent-driven RED–GREEN methodology for behavioural compliance. xeno's `tests/skills/*.sh` are
**grep assertions over skill text** — they check that a sentence is present, never that an agent
following the skill complies with it. That is precisely the distinction this repository has spent the
day rediscovering in other forms: a green suite around an assertion that cannot fail for the reason
that matters.

**Recommendation from the axis that studied all three: adopt both, layered.** They cover different
failure modes — pocock is a composition/pruning rulebook, superpowers is a verification rulebook — and
xeno's measured defects split cleanly between them. Writing a third is unjustified; no xeno rule is
absent from the union of the two. Cost is asymmetric: the pruning pass is hours of mechanical work; the
testing campaign is multi-round subagent runs per discipline skill.

---

## 5. What survives as genuinely xeno's

Narrower than the pocock audit suggested, because superpowers owns more of the process layer:

- **Mechanical enforcement** — `PreToolUse` deny, hook-run `verify`, pre-push guards, CI required
  checks. Both ecosystems are prose; this is the one layer neither has. The two libraries are
  **complementary here, not competing**: xeno's own docs state that only a deny is a hard wall and that
  hooks cannot verify reasoning.
- **The clink transport** — the call signature, `continuation_id`, per-call model/effort, quota-lane
  economics, and the platform gotchas. Superpowers assumes in-harness dispatch and cannot express any
  of it. But the *controller loop* around it — dispatch, review, fix-round caps — is superpowers'.
- **Team policy** — bilingual tracker bodies, the issue→PR gate, the memory layer, AFK park boundaries.
- **The evidence registers**, which genuinely extend `verification-before-completion` with a third
  *Unknown* register and the **laundering** failure mode — a claim's register decaying across turns and
  summaries. That idea appears in neither ecosystem.

---

## 6. Decisions this audit cannot make

**D1 — the nine contradictions.** Each needs a stated winner, and the two mechanical ones (`branch -D`,
who decides the merge) need it most, because today the gate silently blocks what another installed
skill instructs. Recording "xeno wins" is an acceptable answer; leaving it undecided is not.

**D2 — arbitration between ecosystems.** With two upstreams owning TDD, debugging, and skill-writing,
xeno must route each to exactly one, mechanically. The pocock audit's subtraction test decides
xeno-vs-upstream; it does not decide upstream-vs-upstream.

**`using-t4` currently names two owners for the same capability, in adjacent lines.** Line 47 states
that the slash-commands T4 skills name — including `/tdd` and `/debug-mantra` — live in one of the
three ecosystems. Line 51 then lists `test-driven-development` and `systematic-debugging` as
superpowers' representative skills. So TDD has two named owners and debugging has two named owners,
four lines apart, with nothing saying which wins. An agent reading the map cannot route.

The proposed fix is a **citation lock**, mechanical and in priority order:

1. If a T4 skill **names one skill or slash-command** for the capability, that owner is exclusive —
   do not also invoke the sibling.
2. Otherwise, if the capability is a step in pocock's grill → spec → tickets → implement flow → pocock.
3. Otherwise → superpowers, per the map's own *"for non-T4 how to work, prefer
   `superpowers:using-superpowers`"*.
4. xeno owns team-specific decisions only, and is **never** a second technique owner.

Applied: TDD locks to `/tdd`, debugging locks to `/debug-mantra`, skill-writing falls to rule 3 and
locks to superpowers' `writing-skills`. Under that rule the line-51 table is the bug and must cite the
locked owners instead.

The known cost, and it is real: an install that has superpowers but not pocock gets a dead `/tdd`
pointer. That argues for the drift-detection manifest proposed in the pocock audit covering **both**
upstreams, not for leaving the map ambiguous.

**D3 — the `docs/superpowers/` templates.** Delete, or delegate to `writing-plans`/`brainstorming`.
Keeping a drifted clone at the original's own path is the one option with no argument for it.

**D4 — the skill-writing rulebooks.** Adopt both layered, per §4, or record why not.

---

## Method note

Both audits produced their best finding from a **single seat** and their worst claim from **agreement
between seats**. Here the pre-stated hypothesis — the hooks collision — was mine, was specific, was
checkable, and was wrong. It survived exactly as long as it took someone to open both files.

The practical rule this suggests: **state the hypothesis before the search, so that being wrong is
cheap and visible.** An audit that only reports what it found cannot tell you what it expected and
failed to find, and that difference is where the calibration lives.

**One dissent is recorded rather than resolved.** A decision seat pushed back on the axis report's
claim that `karpathy-guidelines` restates TDD, calling it overstated against the file contents — the
goal-driven examples are edit hygiene, not a test-first procedure. Both readings are defensible from
the same lines. It is left open here because deciding it would change what gets deleted, and that is
§6's business, not the survey's.

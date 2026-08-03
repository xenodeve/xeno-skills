# xeno-skills × thananon/9arm-skills — composition audit (2026-08-04)

Third and last of the ecosystem audits, completing the set with
[mattpocock](2026-08-04-xeno-vs-mattpocock-composition-audit.md) and
[superpowers](2026-08-04-xeno-vs-superpowers-composition-audit.md).

**Compared against:** `9arm-skills` at `a1fc303`, cloned to `D:\Github\9arm-skills` — six skills, and
**not one reference file among them**: `engineering/{debug-mantra, post-mortem, qwen-agent, scrutinize}`
and `productivity/{management-talk, qwenchance}`.

---

## The inversion that frames everything else

9arm is the **smallest** of the three ecosystems and the **most cited** by xeno.

| Command | Owner | References in xeno |
|---|---|---|
| `/scrutinize` | **9arm** | **10** — the most-cited command in the entire library |
| `/code-review` | pocock | 9 |
| `/debug-mantra` | **9arm** | **7** — and the auto-trigger table makes it the default for *every* bug |
| `/post-mortem` | **9arm** | 4 |

And it is the least pinnable thing xeno depends on:

```
git tag        → 0
commits        → 4
version field  → absent from .claude-plugin/plugin.json
tests          → none
CI             → none
```

The only identifier a consumer could pin to is a commit SHA, and `npx skills add` tracks the default
branch head. **xeno's most-used external dependency is also the one with the least to hold on to.**

---

## 1. `debug-mantra` is `diagnosing-bugs`, compressed

The evidence is close to a fingerprint. Both skills illustrate log tagging with a random hex suffix,
and it is **the same suffix**:

| | Text |
|---|---|
| pocock `diagnosing-bugs:104` | *"Tag every debug log with a unique prefix, e.g. `[DEBUG-`**`a4f2`**`]`. Cleanup at the end becomes a single grep."* |
| 9arm `debug-mantra:42` | *"Tag every probe with a unique prefix (e.g. `[DBG-`**`a4f2`**`]`) so cleanup is a single grep."* |

That is not the only line. The 50%-vs-1%-flake rule, the "one breakpoint beats ten logs" line, the
3–5-ranked-hypotheses rule with its anchoring justification, and the four determinism controls (pin
time, seed the RNG, freeze network, isolate filesystem) all appear in both, at near-verbatim level.

**What `debug-mantra` genuinely owns is three things**, and only three:

- **The breadcrumb ledger** — a running log of every experiment, plus the rule that a new hypothesis
  must hold for *every* prior observation, not just the latest. Genuinely absent from the other three.
- **Knob enumeration** — enumerate config, env, toggles and timing as differential axes, flip one at
  a time.
- **A verbatim recital ritual**, mandated as the first thing in the first response, once per session.
  That is a compliance device, not a technique.

So the seven citations that make `debug-mantra` xeno's default debugging route point at
`diagnosing-bugs` minus its Phases 2, 5 and 6, plus a ledger and a recital. **The most-cited debugging
owner is the thinnest of the four.**

### And xeno's own routing destroys the one thing worth keeping

`clink-debug` hands `debug-mantra` to **every** panel seat, while simultaneously mandating a fresh
`continuation_id` per seat for provenance reasons. A fresh seat has no ledger. **The provenance rule
structurally deletes the breadcrumb ledger — mantra's single unique technique — and what each seat does
instead is recite the mantra into the transcript.**

There is a second, quieter conflict in the same place: `t4-dev-workflow` and `delegation.md` both
forbid delegating `debug-mantra` as a judgment-gated skill, while `clink-debug` requires every seat to
receive it. 9arm's own text sides with the former — it calls the mantra *"a constraint **you** carry
through the session"*.

---

## 2. The one hand-off xeno explicitly claims — does not exist

`using-t4` states the intended relationship in so many words: *"`t4-engineering-records` decides a bug
needs a post-mortem, then invokes `/post-mortem`."* It is the clearest statement of the composition
rule anywhere in the library, and it is used as the worked example of how T4 is supposed to relate to
its ecosystems.

**Measured in `t4-engineering-records/`: `/post-mortem` appears 0 times, and 9arm appears 0 times.**

What the file does instead is re-derive the skill. Its required-inputs gate — reliable repro, root
cause known, fix identified, fix validated — is the same four items in the same order as 9arm's. All
nine sections match, the `(mandatory)` markers match, and phrases survive intact: *"Most important
section"*, *"None — the fix is sufficient."*

**And the two now disagree about where the output goes.** 9arm's default destination is a ticket
comment, with a file only as an alternative, and it carries an explicit prohibition:
*"Never post to non-JIRA destinations from this skill."* xeno mandates
`docs/reports/YYYY-MM-DD-<slug>.md` plus a register pointer. **xeno's required destination is precisely
what 9arm's rule forbids that skill from writing.** It is decide-and-reimplement, not
decide-and-delegate, and the copy has drifted on both location and write-authority.

---

## 3. `claude-9arm` names two different mechanisms

- **9arm** defines it as a **shell alias** — `claude --model qwen3.6-35b-a3b` through the 9arm gateway,
  invoked headless with `-p`.
- **xeno** describes it as a **PAL clink client config**, in both `clink-subagents` and
  `clink-brainstorm`.

Nothing in 9arm ships the alias, so on a fresh install `qwen-agent` is a no-op — and xeno's install
line does not mention the prerequisite. Two mechanisms, one name, and the reader cannot tell which one
a given sentence means.

---

## 4. Contradictions

| Question | 9arm | xeno |
|---|---|---|
| May a cheap local model write unattended? | default invocation grants `Edit Write`; no sandbox requirement anywhere | *"never give qwen unsandboxed write"* — its write sandbox is **not optional** |
| Can it run builds and tests? | listed as a fit: *"running builds/linters/tests and reporting pass-fail"* | recorded as a **total failure** at exactly that, and narrowed to read/gather/format leaves only |
| Where does a post-mortem go? | never to a non-ticket destination | mandatory file under `docs/reports/` |
| May `debug-mantra` be delegated? | a constraint *you* carry through the session | `clink-debug` gives it to every seat |

Following 9arm's documented default for `qwen-agent` violates xeno's stated rule. Both are installed.

A factual disagreement worth resolving separately: 9arm sizes the qwen context window at 128k;
`clink-masteragent`'s generated table lists 262,144 for the same model. Which binds — a gateway cap or
the model — is **UNVERIFIED**.

---

## 5. `scrutinize` earns its ten citations — the clear positive

The audit expected to find the most-cited command over-relied upon. For `debug-mantra` that held. For
`scrutinize` it did not.

It is **genuinely complementary** to `code-review`, on three axes none of the other reviewers cover:

1. **A mandatory "is there a simpler or smaller way, including doing nothing" pass**, made
   non-skippable. `code-review` takes the spec as given — its spec axis flags deviation *from* the
   spec, never whether the spec should exist.
2. **Scope beyond the diff** — *"the diff is the entry point, not the scope… bugs hide at the seams"*.
   Both other reviewers are pinned to a diff range, so seam bugs are unreachable to them.
3. **No rubber-stamps, no flattery** — and superpowers' reviewer prompt actively contradicts this by
   mandating *"acknowledge what was done well"*.

Dropping `scrutinize` and keeping `code-review` loses all three, and none is recoverable from the
others.

The pairing is also **substantively consistent** everywhere xeno states it. The only drift is
cosmetic: the order flips between `/code-review` + `/scrutinize` in the skills and the reverse in the
hook and two READMEs — which is exactly the duplicated-list drift `t4-dev-workflow` warns about.

---

## 6. What xeno is missing, and what it can ignore

**`qwenchance` is relevant and xeno does not name it.** Despite the name it has nothing to do with
Qwen: it is orchestrator self-hygiene — loop detection, a reasoning-length cap, context-budget
counting, clean handoff. That maps directly onto `t4-afk`'s unattended batches and onto
`clink-subagents`' context economics. Zero references in xeno.

**`management-talk` is correctly ignored.** Its audience is executives and its output is English-only
and channel-shaped, against a tracker rule that requires a full Thai mirror. The only adjacency is that
9arm's own `post-mortem` hands off to it — a chain xeno does not use.

---

## 7. Supply-chain risk, which is specific to this ecosystem

Beyond having nothing to pin: 9arm's own install script **flattens every skill into a single global
namespace** at `~/.claude/skills/<basename>`. Any name collision between ecosystems silently resolves
in favour of whoever wrote last. The live skill list on this machine already shows
`karpathy-guidelines` twice — once bare and once prefixed — and **which repo supplies the bare one is
UNVERIFIED**.

There is also a dangling dependency inside 9arm itself: `qwenchance` instructs the agent to invoke a
`handoff` skill that 9arm does not ship.

---

## 8. Decisions

**D1 — the debugging owner. The audit did not converge, and the disagreement is on a different axis
than expected.**

**Position 1 — route to `diagnosing-bugs` (the content argument).** It is the superset: it contains
`debug-mantra`'s non-ritual content nearly verbatim, plus loop construction, minimisation, seam
analysis and cleanup. Porting cost is small and specific — carry the breadcrumb ledger and knob
enumeration across, drop the recital.

**Position 2 — keep `debug-mantra` as the default and escalate to `/diagnose` (the behavioural
argument).** A decision seat argued that content depth is the wrong criterion: the citation count
tracks the **gate**, not the technique, and a short ordered ritual an agent actually fires beats a
dense skill it skips. On this reading the auto-trigger table already encodes the right answer — mantra
as the default, `/diagnose` for hard and performance cases — and what should change is dropping
superpowers' `systematic-debugging` from the T4 default path rather than promoting anything.

These do not merely differ in conclusion; they differ in **what evidence would settle them**. Position 1
is settled by reading the files, which is why the inventory reached it. Position 2 is settled only by
observing agents — and the seat that argued it supplied the test: *a blind A/B on identical bugs; if
mantra-only sessions miss causes at twice the rate, downgrade mantra to a one-line pointer.* **That
test has never been run, here or anywhere in this repository.**

**The vote came in 2–1 for `diagnosing-bugs`** — the inventory axis and one decision seat against the
other seat. That is a majority, not a consensus, and the minority position is the only one whose
supporting evidence has never been gathered.

The second seat also rejected both earlier arbitration rules outright, in terms worth recording:
*"neither 'existing owner wins' nor ecosystem-level 'technique owner wins' is a sound arbitration rule
— select the strongest executable contract."* That is a **fourth** rule, and it is the only one of the
four that judges an owner by what it obliges an agent to do rather than by who wrote it or who was
cited first.

It also named what it took to be the strongest objection to its own answer: `diagnosing-bugs` forbids
hypothesis-building before a fast agent-runnable loop exists, which would stall a production-only
failure that cannot be reproduced locally.

**That objection is wrong, and it was checked afterwards rather than at the time — the same error this
audit set out to catch.** `diagnosing-bugs` carries a section headed *"When you genuinely cannot build
a loop"*: stop and say so explicitly, list what you tried, and ask the user for **(a)** access to an
environment that reproduces it, **(b)** a captured artifact — HAR, log dump, core dump, timestamped
recording — or **(c)** permission to add temporary production instrumentation. It does not stall; it
**stops into a human gate with three concrete asks**, which is the shape of `t4-afk`'s own park note.

So the cost of choosing this owner is much lower than the panel believed, and the contradiction with
xeno's current text — which permits continuing as a hypothesis — resolves in the stricter direction at
almost no operational cost.

So the arbitration question now has four candidate rules and three different winners from the same
files. That is the argument for deciding the rule first and the owner second, rather than settling it
bug-by-bug.

**D2 — the false hand-off claim.** Either `t4-engineering-records` invokes `/post-mortem` and drops its
duplicate, or `using-t4` stops claiming it does. The current state — a stated hand-off that does not
exist, wrapping a drifted copy that contradicts the original on write-authority — is the worst of the
three options.

**D3 — the `claude-9arm` name.** One of the two mechanisms should be renamed. xeno cannot fix 9arm's
alias, so the cheaper move is for xeno to qualify its own usage every time.

**D4 — supply-chain. Both decision seats converged here, and it is the one recommendation in this
audit with no dissent: vendor.** Take exact, attributed snapshots of the load-bearing 9arm skills into
xeno, record the upstream SHA as provenance, and add a check that every slash-command xeno declares
actually resolves.

The alternatives were weighed and rejected: pinning alone still leaves a rename breaking the slash
name; reducing reliance means rewriting `/scrutinize` or losing a capability nothing else provides;
and accepting the risk contradicts xeno's own stated rule that skills evolve and the current version
must be loaded.

The cost is real and should be stated where the decision is recorded: **vendoring freezes a small
author's taste as org canon**, adds fork maintenance and a licence/attribution obligation, and weakens
the hand-off model xeno's entry map is built on. It becomes the wrong answer the moment 9arm ships a
version and a changelog.

**D5 — adopt `qwenchance`**, or record why not.

---

## Method note

Two of the three audits went looking for over-reliance on a most-cited dependency. Here that suspicion
was **half right, and the half that was wrong is the more useful half**: `debug-mantra` is thin and
over-cited, `scrutinize` is neither. Had the audit reported a single verdict on "9arm", it would have
been wrong about one of the two skills that matter most.

The strongest single piece of evidence in all three audits was not an argument — it was a **shared
random hex string** in an example. Provenance leaves fingerprints that prose comparison misses, and
they are worth grepping for deliberately.

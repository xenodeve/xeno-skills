# Addon to T4-Compact — the thinking record

**Status:** design, not started. **Extends** [`2026-08-21-t4-compact.md`](2026-08-21-t4-compact.md)
**revision 2**; it does not replace or re-plan any part of it.
**Adds to:** slice 2 / **#306** (handoff validity), slice 4 / **#308** (the skill), slice 5 / **#309**
(restore assertion), plus **#312** for the `t4-agent-memory` row. The scope additions are already on
those issues.
**Source:** the developer, 2026-08-21 — *"we will not throw the thinking history away, because the
new instance may go back and re-think factors the previous one already worked through. The history is
mapped, navigated by a README that lists the topics, and the new instance reads only the part it
wants."*

---

## 1. The gap this fills

T4-Compact guarantees `NO VALID HANDOFF → NO COMPACT`. What survives a boundary is therefore a
**conclusion**: what was decided, what is open, what to do next.

**The reasoning that produced the conclusion does not survive.** A handoff says *"we are using
`ngram-mod`"*. It does not say *"`ngram-map-k` was tried first and looked better, then failed to
replicate because the timing probe ran at temperature 0.7"*.

So the next instance does the one thing the handoff exists to prevent: it re-opens a settled
question, and — worse — it may re-open it and land somewhere else, because it is reasoning from less
than its predecessor had.

The parent plan's own §7 names the boundary it will not cross. This addon stays inside it: **no new
event, no new trigger, no change to the block policy.** One more artifact, written at the moment the
handoff is written, and one more thing the restore step names.

---

## 2. What gets written

```text
docs/thinking/
├── README.md              the map — one line per record, newest first
├── 001-<slug>.md          one line of reasoning that reached a conclusion
├── 002-<slug>.md
└── …
```

Each record leads with its conclusion:

```markdown
# <the question that was open>

**Concluded:** <the answer, in one sentence>
**Confidence:** measured | reasoned | assumed
**Superseded by:** <record, if a later one overturned this>

## What was considered
…
## Why the alternatives were rejected
…
## What would change this
…
```

**Conclusion first, reasoning after,** because the common read is one line. `What would change this`
is the field that makes a record worth keeping rather than merely honest: it tells the next instance
whether its new information is the kind that reopens the question.

---

## 3. The failure this design exists to avoid, and it is not hypothetical

**A map is only as good as its weakest write.** If writing a record and updating the index are two
steps, one day only the first happens, and the record becomes invisible — which is exactly the
re-thinking the whole scheme is meant to stop.

**Observed on 2026-08-20 in the adjacent project** (`C:\AI\docs\reports`): a report was written as
`16-CONTEXT-CEILING.md` while another file already held number 16. It never entered the index and
stayed unreachable for a day — while being the answer to the question then being worked on. Nothing
failed loudly; the file simply was not in the list.

**So the index update is not a step. It is part of the same write.** The validator in slice 2 gains
one clause:

> A handoff is valid only if every record referenced in this session appears in
> `docs/thinking/README.md`, and every record file present on disk appears there too.

An orphan file or an index entry with no file **invalidates the handoff**, which — under the parent
plan's §5 table — blocks a manual compaction and records the event on an automatic one. The
enforcement point already exists; this is one more predicate at it.

---

## 4. Reading, not loading

The map is worthless if the next instance has to be told to look at it, and worse than worthless if
it loads everything.

- **The map enters the context; the records do not.** `docs/thinking/README.md` is one line per
  record. The restore injection (slice 5) names it alongside the handoff path.
- **`t4-agent-memory` already governs this.** Its stated principle is *"retrieval-first … an index you
  skim + linked detail you open on demand beats one append-only wall of text every time"*, and its
  read protocol says **stop pulling detail once you have enough**. This addon adds a layer to that
  skill's table; it does not introduce a second doctrine about memory. Adding one would break that
  skill's own *one source of truth per fact* rule.
- **A record is opened when the current question matches a line in the map.** Not preemptively.

---

## 5. Cost, measured

Three costs are known from the adjacent project and should be stated rather than discovered:

| cost | measured | consequence for this design |
|---|---|---|
| a broken prefix | **63 s at 16K, 248 s at 64K** of re-prefill | writing the record is free (it happens at a boundary that is already breaking the prefix). **Reading one mid-task is not** — an inserted file changes the prefix. Read at the start of a segment, not in the middle of one |
| reasoning length per turn | **59 to 33,871 characters** across quantizations of one model | a record built by asking the model to summarise its own reasoning costs one extra generation, and its size is not predictable from the task |
| an unread index | **one file invisible for a day** (§3) | the index must be verifiable, not merely present |

---

## 5b. What it is worth, in the numbers that now exist

The parent plan's §6a carries this too; here is the part that belongs to **this** layer.

**The floor is mostly the summary, and the summary is what this replaces.** Measured across 113 real
compactions (`docs/research/2026-08-21-compaction-yield.md`): the post-compaction floor is **~100 K, of
which ~50 K is the summary** and ~47 K is the fixed prefix. A handoff plus a one-line-per-record map is
**~3–5 K**.

| | a `/compact` summary | handoff + map |
|---|---:|---:|
| the floor it leaves behind | ~100 K | **~55 K** |
| share of a **128 K** worker's window | **78 %** | **~43 %** |

**On a 128 K worker that is the difference between unviable and viable** — and the parent plan's other
measurement is why it matters there: every compaction below 150 K in that corpus returned **−0 %**, so a
128 K window sits entirely inside the dead zone. **Replacing the summary is the only move that changes
the floor at all.**

## 5c. The failure it prevents, observed in the session that wrote it

**Twice in one session, the same question was re-opened and answered wrongly the same way.** Revision 1
of the parent plan rode the harness's auto-compaction; revision 2 lowered the auto-compact window. Both
were the same mistake — **looking for a compaction trigger inside the session**, which the developer had
ruled out before revision 1 was written.

**Nothing was lost that a summary is supposed to keep.** The *conclusions* crossed each boundary intact.
What did not cross was **the reasoning that had closed the question** — and a conclusion with no trace of
why it was reached does not announce itself as settled. So it was re-derived, from less than the
predecessor had, and it landed somewhere else.

**That is exactly the mechanism §1 describes**, and it is now a first-person occurrence rather than a
plausible story: n = 2, in one session, in this repository.

## 5d. The trigger is what decides this, not the artifact

**A map in context that nobody opens costs ~1 K and prevents nothing.** The artifact is the easy half;
the moment is the hard one, and this repository has already measured that the moment is where these
designs fail — **four of the sixteen skill fixes landed on 2026-08-19 were triggers**, each for a rule
that was unambiguous and still did not fire, because a rule that applies constantly has no moment at all.

**The moment here: before re-opening a question that looks settled.** Not "read the map at session
start", which is the version that quietly stops happening.

**And the proxy that makes it measurable is cheap:** count the decisions a session re-opens after a
boundary. It needs no harness, no corpus and no paired run — the three things §6 says do not exist. In
the session that produced this text, that count was **2**.

## 6. What this addon does **not** claim

**The token effect is arithmetic and the quality effect is not measured.** §5b is a calculation on
measured inputs, and §5c is one observed occurrence — neither is a performance claim. What remains
unmeasured is whether an instance that reads a summary plus a map **works as well** as one that
reasoned its way there, and the parent plan's §4 marks condition 3 a hypothesis for the same reason.

- **No benchmark in either repo can currently test it.** The adjacent project's corpus is ten
  self-contained functions, each finished in one turn. It has no cross-turn memory, so it cannot show
  whether an instance reading a summary performs as well as one that reasoned its way there. This is
  the same gap a three-agent review raised on 2026-08-20 (`C:\AI\docs\reports\14-PANEL-REVIEW.md` §2 —
  *"corpus blind to cross-file drift"*), still the largest unbuilt recommendation there.
- **The claim "a summary is enough to continue" is untested.** It is plausible, it is what this
  repository already does at session scale via `Home.md` and the ledger, and it has never been
  measured against the alternative.
- **Therefore the addon ships the artifact and the invariant, not a performance claim.** If a later
  measurement shows selective reading loses information, the map is where that shows up — as a record
  whose `What would change this` was met and ignored.

### The measurement the parent plan asked for, supplied — and now carried there

Parent revision 1 §4 said of condition 3: *"Long context raises the error rate. Unknown here — the
adjacent project has the depth data."* It does, and **it does not support the condition as stated**.
The figures below were checked against the source file (`03-DEEP-CONTEXT-QUALITY-REPORT.md`, lines 94
and 160) and **parent revision 2 now carries them in its own §4 row**, so the two files no longer
disagree about what is known:

```text
Q4 UD-Q4_K_XL, retrieval at depth (C:\AI\docs\reports\03-DEEP-CONTEXT-QUALITY-REPORT.md)
  64K   30/30   100 %
  128K  10/10   100 %   (a 114,406-token prompt)
```

**No degradation was detected at either depth**, on that artifact, on that probe. Two caveats that
matter more than the result: it is **one quantization** — nine other artifacts have depth *throughput*
numbers and **not one has a depth quality number** — and *no degradation detected* is not
*equivalence shown*.

**So condition 3 stays a hypothesis**, and this addon does not lean on it. The triggers remain the
parent plan's conditions 1 and 2.

---

## 7. Slices

Each extends an existing slice rather than adding a stage.

| # | extends | issue | work |
|---|---|---|---|
| A | parent slice 2 (validator) | **#306** | index/file bijection check; a record is orphaned if either side is missing. Tests: orphan file, orphan entry, both clean |
| B | parent slice 4 (the skill) | **#308** | `t4-compact` writes the record and the index entry **as one operation** before it reports the handoff path — and answers §8 first |
| C | parent slice 5 (restore) | **#309** | the injection names `docs/thinking/README.md` beside the handoff path; a test asserts both appear |
| D | `t4-agent-memory` | **#312** | one row in its memory-layer table — retrieval unit "one record, opened via the map", read "when the current question matches a line in it" |

**A, B and C are scope additions on issues that already exist**, not new stages: each is appended to its
issue body rather than filed separately, because a slice that carries two bodies is a slice nobody can
close. **D is its own issue** — it changes a shipped skill, and this repo's rule is an issue first, then
the change. Its body says in those words that the benefit is **not measured**; the gap is real and
observed, the improvement is not.

---

## 8. Open question worth deciding before slice B

**Who writes the record?**

- *The model summarising its own reasoning* — accurate about what it actually considered, costs one
  generation, and its length is unpredictable (§5).
- *A template the skill fills from what it already knows* — free, deterministic, and captures only
  what the skill can see, which is not the reasoning.

The first is what the developer described. The second is what can be enforced. **A hybrid is
probably right** — the skill emits the frame and the required fields, the model fills them — but that
is a decision, not an obvious answer, and it belongs in slice B's issue rather than here.

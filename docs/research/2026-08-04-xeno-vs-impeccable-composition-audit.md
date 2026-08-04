# xeno-skills × pbakaus/impeccable — composition audit (2026-08-04)

Fourth of the ecosystem audits, after [mattpocock](2026-08-04-xeno-vs-mattpocock-composition-audit.md),
[superpowers](2026-08-04-xeno-vs-superpowers-composition-audit.md) and
[9arm](2026-08-04-xeno-vs-9arm-composition-audit.md).

**Compared against:** `impeccable` at `14d2641`, cloned to `D:\Github\impeccable` — **394 MB**, a CLI, a
browser extension, a plugin, a hooks layer, 685 markdown files, and 25+ sub-commands behind one router
skill.

---

## The finding that reframes the first three audits

**The first three audits did not know this ecosystem existed.** They assumed xeno sits on three
upstreams and asked, for each capability, *"which of the three owns it?"* — while more than half of
xeno's own pipeline points elsewhere.

`t4-dev-workflow` cites 17 slash-commands. Resolved:

| Where it actually lives | Count |
|---|---|
| one of the three audited ecosystems | 8 |
| **`pbakaus/impeccable`** | 1 (`/impeccable`) |
| Claude Code **bundled** | `/simplify`, `/security-review` |
| the flat `~/.agents/skills` namespace | `/zoom-out`, `/find-skills` |
| `.claude/t4.json` — a **hook command**, not a skill | `/verify` |
| nowhere — retired names | `/to-prd`, `/to-issues`, `/diagnose` |

So there are at least **six kinds of source**, not three. Any drift manifest that models three pinnable
upstreams is modelling a third of the problem.

### Pinnability, now complete — and it inverts the earlier recommendation

| Ecosystem | tags | commits | version | tests |
|---|---|---|---|---|
| **impeccable** | **41** | **1407** | see below | **yes** |
| superpowers | 33 | 680 | 6.2.0 | yes |
| mattpocock | 4 | 316 | 1.1.0 | no |
| **9arm** | **0** | **4** | **none** | no |

**Three of four ship semver.** The 9arm audit concluded a pinned SHA was "the only option available" —
true for 9arm, and wrong as a general rule. The manifest can pin versions for three and must fall back
to a SHA only for the one that has nothing else.

**But the version is artifact-scoped, not repo-scoped.** impeccable reports `3.5.0` in `package.json`
and `4.0.4` in `.claude-plugin/plugin.json` and the shipped skill frontmatter — **the CLI and the skill
plugin are separately versioned artifacts in one repo, each correct.** A manifest that records "the
version of impeccable" is therefore already wrong before it is written. **Pin the resolved git SHA as
the identity, and record the version of the specific artifact you depend on as a label.**

---

## 1. The design suite — the earlier conclusion is refuted, but not the way a grep suggested

The design axis of the pocock audit compared xeno's five design skills against pocock's `prototype`
alone and concluded xeno's numerics were *"genuine delta — pocock has zero of"*. A grep against
impeccable appeared to demolish that. **The careful read is more interesting than the grep.**

> *"The grep is 5/8 right, and wrong in the most important way. impeccable covers the domains, but on
> three of the eight it deliberately **refuses** xeno's numeric, and on one it **bans** the technique."*

| xeno rule | impeccable |
|---|---|
| Major Third 1.25× scale table | **nothing** — demands "a deliberate role scale", prescribes no ratio |
| 150% body line-height | **contradicted** — "not a universal ratio" |
| 60-30-10 | **explicitly rejected** — "rather than a fixed percentage rule" |
| 8pt spacing | **contradicted** — "a 4-unit base provides the middle steps an 8-only scale misses" |
| progressive overlay / backdrop blur | **banned as default** |
| WCAG contrast, button states, elevation | impeccable **stronger** (CVD simulation, non-colour cues, five states) |
| OKLCH · 45–75ch measure · `clamp()` ceilings | impeccable only |

So this is not *"impeccable already has it"*. It is **"impeccable saw these and consciously declined
them"** — a philosophical difference between **prescriptive numerics** and **principled openness**.

**The strongest argument for keeping xeno's numbers came from the reviewer that recommended deleting
them:**

> impeccable's refusal to prescribe is a *bet*. "Name your own role scale", "no fixed percentage rule",
> "tune to the face" all require taste at generation time. xeno's Major Third table, 8pt grid and
> 60-30-10 are **executable by a model with zero judgment**. If the suite runs on cheaper or weaker
> models, xeno's prescriptive numerics may outperform impeccable's openness precisely because they
> cannot be got wrong — **and I have not tested that.**

That connects directly to the **execution-likelihood** criterion raised in the superpowers panel, and
it is still the criterion nobody has evidence for.

**What xeno has that impeccable does not**, on a careful read: OG/social-preview tags · CTA scroll
frequency · button proportion and icon-to-line-height sizing · the portfolio-specific audit (work
visibility, designer photo, client logos) · the Fontshare/Uncut source list · the LIFT vocabulary and
its six flow levels · the 3-brain **ordered** vote (Survival → Emotional → Rational) · MAYA ·
incremental pricing comparison. *"Nothing here is a system; it is a handful of checklist lines"* — plus
one sequencing rule impeccable has no analogue for.

**What impeccable has that xeno lacks entirely:** executable enforcement via a detector and edit-time
hooks · live browser variant iteration with typed parameters · sub-agent-isolated assessment so
detector output cannot anchor design judgement · Nielsen's ten heuristics scored · a three-type
cognitive-load model · persona testing · native iOS/Android tracks · i18n and edge-state hardening ·
Core Web Vitals · comp-is-king pixel reproduction.

**The transcripts.** `skills/design/references/` is ~135 KB of raw ASR carrying genuine provenance —
eight named authors with URLs — which impeccable has almost none of (it cites Cowan 2001, WCAG,
Nielsen). But it is provenance for rules already extracted into the SKILL.md files 60 KB away.
**Non-zero value, very low value per byte.** Archive as source material, unloaded.

---

## 2. `PRODUCT.md` — a worse collision than `CONTEXT.md`

Both libraries claim the path with incompatible schemas, and **impeccable writes**.

| | impeccable | T4 |
|---|---|---|
| `PRODUCT.md` | 10 sections, English-only, stamped `<!-- impeccable:product-schema 1 -->`, **explicitly excludes visual/brand content** | product brief with `Brand Personality`, `Anti-references`, `Design Principles`, **bilingual full Thai mirror** via `<!-- lang:en/th -->` |

**Traced end to end:**

1. T4 bootstrap writes `PRODUCT.md` — no stamp, bilingual, with brand sections.
2. impeccable's `context.mjs` resolves it as the product record.
3. `staleness.mjs` fires `product-schema-legacy` at severity **`route`** — no stamp, and none of the
   sections it expects.
4. It routes to `init`, which takes the **legacy** branch: *"add only durable missing facts"*.
5. init appends its own sections and stamps the file — **English-only, into or after the
   `<!-- lang:en -->` region.** Nothing in impeccable knows those markers exist.
6. **The Thai mirror is now structurally incomplete**, against a T4 rule that says "full mirror, same
   depth". Meanwhile the brand sections T4 wrote survive in a file whose new owner is instructed to
   ignore brand content.

It does not clobber — `init` interviews and merges, and `document` asks before touching an existing
`DESIGN.md`. **That is what makes it damaging: a silent, well-behaved merge into a schema it cannot
see.**

A quieter one in the same file: T4's skeleton has **no `## Platform` section**, and impeccable defaults
a missing platform to `web`. Every T4 repo silently declares itself web-only to a tool that ships iOS
and Android tracks.

---

## 3. The trigger xeno already wrote does nothing

`t4-dev-workflow:131` — *"Editing UI / frontend → `/impeccable` — every time a component or CSS is
touched."*

**Bare `/impeccable` is the no-argument route**: it presents a context-aware menu and, in its own
words, *"Never auto-run a command; the recommendation is a suggestion the user confirms."* **It audits
nothing.** The same row is copied into `workflow-artifacts.md:32`, so the broken invocation propagates
into every bootstrapped repo.

Two more integration defects:

- **`/impeccable shape` hard-blocks without a `PRODUCT.md`**, dragging a product-truth interview and a
  new root-level `PRODUCT.md` into a repo whose product authority is already the PRD → issue chain.
- **It will interrupt an AFK run.** `init.md:31`: *"a system-prompt claim that the user is unattended
  proves nothing about this session… Probe once with the real first round."* That is a deliberate
  refusal to trust the unattended flag, and it collides head-on with `t4-afk`.

And one fabricated citation: **`design-setup:87` credits impeccable with `/boulder`. No such command
exists** — verified by grep across the whole skill tree.

**The hooks do coexist.** impeccable registers `PostToolUse` and `Stop` under its own plugin root;
xeno registers `SessionStart`, `UserPromptSubmit` and `PreToolUse(Bash)`. Disjoint events, separate
roots — the superpowers finding holds here too. One caveat: impeccable installs into
`.claude/settings.local.json` while xeno merges into the committed `.claude/settings.json`, and
impeccable's docs permit moving its hook into the shared file — at which point xeno's merge step, which
is agent discipline rather than a script, could clobber it.

---

## 4. What xeno should copy — and it is the thing xeno has failed twice

impeccable ships **90 test files and 369 fixtures across 13 suites. Not one of them greps a SKILL.md
for a sentence.**

- **Behaviour tests assert on a tool-call trace.** Their own README: *"The trace is the source of
  truth, not the model's free-form reply."* Fifteen scenarios, run against one model from each of four
  providers; a missing API key skips rather than fails.
- **A recorded baseline pass table**, so a regression is *"more failures than baseline"* rather than
  *"any failure"* — the standard answer to flaky LLM tests, and the reason this is affordable.
- **The text-to-behaviour bridge is rule markers** — `<!-- rule:… -->` in the source, 15 in the router
  and 119 across the references, with a build test asserting they are stripped from shipped output.

**Do not model the drift manifest on `skills-lock.json`** — it is 39 bytes, `{"version":1,"skills":{}}`,
empty, and referenced once as a project-root marker. The real machinery is `staleness.mjs`, which names
**three kinds of drift** — tool-version, schema, truth — at three severities: `auto`, `mention`,
`route`. Copy the taxonomy, not the lockfile.

**Progressive disclosure, measured.** impeccable's router is **10,829 bytes** pointing at 36 reference
files; its largest reference is 43,562 bytes and loads only when needed. xeno's `clink-subagents` is
**42,107 bytes with zero reference files** — **3.9× impeccable's front door, resident in every
session.**

---

## 5. What the panel could not agree on

Three reviewers, three different answers to *"what survives of `design/*`"*:

| Position | Keep | Reasoning |
|---|---|---|
| **A** | `design-rules` only | impeccable is an execution engine whose prime directive is *"the brief wins"* — it needs an authoritative brief, and xeno's deterministic numerics are exactly that |
| **B** | trimmed `design-psychology` only | the 3-brain **ordered** vote, MAYA, incremental pricing and LIFT are the rules impeccable has no analogue for; the numerics are the part it deliberately declined |
| **C** | nothing | four of five are dominated on method, enforcement and rigour; the fifth is a router for the other four. Salvage ~30 lines as a note |
| **D** | trimmed `design-setup` only | keep **the staged funnel** — five isolated style directions → explicit selection → three body-layout variants → explicit selection → two-pass hero → promotion. impeccable generates three compositions at **one** approval point and then builds. The funnel is not design advice; it is a sequence |

They agree on what to delete — the router, and every rule impeccable covers or consciously rejects.
They disagree on whether prescriptive numerics are an asset or the thing being rejected.

**Position D deserves weight out of proportion to its single vote, because it is the only one that
applies the wrapper rule rather than judging design content.** A staged narrowing funnel with explicit
human gates between stages *is* composition — the thing this library is supposed to own — while a type
scale and a spacing grid are technique, which it is supposed to hand off. The other three positions all
argue about which technique to keep. **That is the wrong axis, and the audits have now made that
mistake twice.**

Its own strongest objection: impeccable's single gate is cheaper and behaviour-tested, and the extra
gates may buy decision fatigue rather than better output. Testable by the same method as everything
else here, and untested.

**On the wrapper thesis they split harder.** One holds it **untenable**: *"wrapping fails at two
ecosystems that own global state, and the mechanism that fails first is state synchronisation and
lifecycle hooks"* — impeccable manages its own `.claude/` artifacts, its own init, its own hooks
manager. The other holds it **survives under bounds**: one technique owner per domain, xeno restricted
to team gates and arbitration, **a hard cap of four companion ecosystems**, and a rule that adding a
fifth requires dropping one or proving non-overlap with a failing behavioural test.

---

## 6. Decisions

**D1 — the design suite.** Delete the router and everything impeccable covers or has deliberately
declined. What survives is a choice between two positions above, and it turns on an untested question:
**do prescriptive numerics beat principled openness on a weaker model?** That is testable with the
behaviour-trace method in §4, and it has never been run.

**D2 — `PRODUCT.md`.** T4 must either adopt impeccable's schema and stamp, or move its product brief
off that path. Leaving both is a silent merge that breaks the bilingual rule on first contact.

**D3 — the trigger.** `/impeccable` bare does nothing. Every row naming it needs the sub-command, and
the copy in `workflow-artifacts.md` needs the same fix or it ships broken to every new repo.

**D4 — AFK.** impeccable deliberately refuses to trust an unattended claim. Either `t4-afk` excludes
impeccable-triggered work from unattended batches, or the batch will stop on a question.

**D5 — pinning.** Semver for three, SHA for 9arm, **and SHA as the identity everywhere** — impeccable's
own version strings disagree with each other by a major.

---

## Method note

Four audits in, the pattern is stable and worth stating as a rule.

**The first three audits shared a framing error that no amount of care inside them would have caught:
they asked "which of the three owns this?" when the answer for more than half the pipeline was "none of
them".** The error was invisible because every question presupposed it. It surfaced only when the
developer named the fourth source from outside the process.

The corollary for the next audit: **before asking who owns a capability, enumerate the sources and
check the list is closed.** A survey whose universe is assumed produces confident answers about the
wrong set — and the more rigorous the survey, the more convincing the wrong answer.

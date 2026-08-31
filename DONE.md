# DONE — Agent Session Log

## T4-Compact handoff validity — implemented (2026-08-31, #306)

`hooks/t4-handoff-validity` now provides a pure validator for the session-keyed handoff path.
It rejects empty or incomplete handoffs, stale handoffs older than the latest
`compact_boundary`/`isCompactSummary`, and handoffs owned by another session. It also enforces
the `docs/thinking/README.md` ↔ record-file bijection, while `.claude/t4-handoff/` is ignored as
session runtime state. The canonical hook and bootstrap reference copy are byte-identical.

**Validation:** the stale-handoff behavioral test was RED before the fix and GREEN afterward
(8 assertions); `test-bootstrap-sync.sh`, `test-line-ending-pins.sh`, and
`test-wiring-parity.sh` all passed.

> Newest entry on top. One dated `##` heading per shipped unit so an agent can jump to one.
> When this crosses ~a few hundred lines or a phase closes, move older entries to
> `DONE-archive-<period>.md` and leave a redirect line here.

---

## T4-Compact — planned, probed, and measured (2026-08-20/21, #304 + 7 slices, PRs #311–#323)

**What shipped is a plan that survived three revisions and two measurements** — no behaviour yet, by
design: `docs/plans/2026-08-21-t4-compact.md`, its thinking-record addon, PRD **#304** with seven slices
as native sub-issues, tracking issue **#310**.

**Revisions 1 and 2 were both wrong in the same way** — they looked for a compaction trigger *inside* the
session (ride auto-compaction; lower its window), a question the developer had closed before revision 1
existed: *the model cannot compact itself, which is why there is a layer*. **Revision 3 plans the layer**:
a supervisor owning the session over `-p --input-format stream-json`.

**Then it was run rather than argued** (#305, `scripts/probe-stream-transport.py`, claude 2.1.222):
`/compact` sent as a **user message on the input stream executes** — `status:"compacting"` →
`compact_result:"success"`, with `num_turns: 0` and zero usage for that message. `--replay-user-messages`
acknowledges an injection; the transcript writes `compact_boundary` then `isCompactSummary`; eight planted
facts survived the summary.

**And what compaction is worth was measured from real work, not a probe** —
`docs/research/2026-08-21-compaction-yield.md`, **113 compactions across ten projects**: median **85 %**,
median context before compacting **719 K**. But a **floor of ~70–105 K**, a **dead zone below ~150 K**
where the median return is **−0 %**, and **13 of 113 came back larger**. The fixed prefix is **~63 K
median** and growth is **~2 K per turn**, so a `/compact` summary alone measures **~50 K**.

**Two corrections the developer forced, both of which changed the design:**

- **`cache_read` is not the context size.** The first write-up read a −46 % drop that was really **−9 %**;
  the size is the sum of three usage fields.
- **The worker is not always Claude Code, and that inverts the economics.** A local model evaluates **~40
  tokens per turn while appending** and loses **100 % of its prefix cache** to any edit above the append
  point — so compaction there costs a full re-prefill (248 s at 64 K) against a per-turn saving that
  harness never charged. **The portable mechanism is therefore the reopen; `/compact` is the Claude Code
  adapter.**

**Validation:** `bash tests/hooks/run-all.sh` green on every merge; the probe's evidence is a fixture plus
`tests/skills/test-compact-transport-claim.sh`, which pins the plan's claims to what was actually observed.

---

## Intake — the CRISPE gaps an agent may ask about (2026-08-20, #301 → PR #302)

**Goal:** the developer asked whether CRISPE could be used for the prompt between **them and the master
agent**, and asked for a rule that makes the agent ask for the missing elements while **choosing the
moment itself**.

**Shipped:** an **Intake** section in `t4-dev-workflow` + a trigger row, the cross-cutting one-liner in
`using-t4`, and `tests/skills/test-crispe-intake-rule.sh` (18 assertions).

**The design is a ceiling, not a prompt.** `t4-afk` records that over-asking has **no natural corrective
signal**, so a rule that says *ask more* without a bar makes the agent worse. Two slots are askable
(**insight**, **statement**), one is conditional (**role**, when the audience shapes the artifact), and
two are refused outright (**personality** — fixed by `CLAUDE.md`; **experiment** — a cost call the agent
makes). A question is allowed out only when the two-readings sentence finishes.

**Its own measurement is the session that wrote it:** the first answer went to the **delegation** layer
and the developer had to say the prompt meant was the one between the dev and the master agent. **One
unasked slot cost a whole turn.**

**The suite asserts the ceiling as a shape** — five rows, exactly two askable, personality and
experiment each `never` — so flipping a slot goes red. Four positive controls, each red for its own
reason.

**The census guard caught its author a third time:** the `using-t4` line landed in the blanket
out-of-scope reason (47 → 48) and `test-rule-traces.sh` refused it; it now carries an individual reason.

**Validation:** `bash tests/hooks/run-all.sh` → **ALL TESTS PASSED**; PR #302 merged 13:10:47Z.

---

## The skill-feedback queue, cleared (2026-08-19/20, 16 issues, 16 PRs)

**Goal:** the standing `/goal` asked for every AFK-able issue done and merged. Once `ready-for-agent`
was made honest it read **0** — and the available work turned out to be in `ready-for-human`: twelve
`skill-feedback` issues whose fix was **skill prose plus a test**, each carrying its own measurement.

**Shipped:** #130 #131 #132 #133 #135 #136 #137 #138 #160 #209 #210 #211 #233 #237 #238 #239 #249 —
one PR each, per-item gates, and **positive controls run and shown red** on every new suite.

**Four of the fixes are triggers**, and that is the finding: #130 (before the first edit of a
multi-leaf task), #209 (the first prose reply after tool work), #131/#160 (before the round is
fired). Each rule was unambiguous and still not applied, because **a rule that fires on every message
or every delegation has no moment at all.**

**Five were rules this session was breaking while fixing them** — 16 consecutive English-only PR
bodies against #238, two premature issue closes against #233 (filed as #297), a closing pass that
matched one issue per commit against #268, and an earlier `/handoff` that did not pay the report
against #211. **That is the mechanism, not irony:** holding a rule in mind is not the same as having a
moment at which it fires.

**Three guards caught the author:** the census guard refused a rule folded into the blanket reason
(second time on its own author); the anchor audit flagged six positive-only suites, each then
classified with an individual reason and re-verified to still bite; and the `clink-brainstorm` byte
budget refused a fourth addition at 46,120 of 45,000 — **trimmed back to 44,944 rather than raising
the number**, every assertion still green.

**And one guard was weakened by accident and repaired in the next commit:** a suite carrying a real
`hasnt` was added to the audit's exemption list. Exempting a suite that does not need it is how the
audit stops working — #268's own subject, six hours after #268 merged.

**A seventeenth was filed against the session itself and fixed the same way:** #297 — `gh issue close`
run twice while its PR was unmerged, chained with `&&` to a different command's success — is now a rule
in `t4-dev-workflow` plus `test-verdict-chaining-rule.sh`, which asserts a **shape** rather than a
phrase: the read must come before the action and must not be joined to it. **Filing it repeated the
defect once more** — the record PR's `Closes #297` closed an issue no rule had answered yet; reopened,
then closed on the artifact.

**Validation:** `bash tests/hooks/run-all.sh` → **ALL TESTS PASSED** before and after every merge;
timed at **186 s, 1,207 passing assertions**. CI could not run (billing lock, #158).

---

## The review the branch never had, in two passes (#247, #265) (2026-08-19, skills code-review + scrutinize + security-review, PRs #266 and the tail of #235 → `main`)

**Goal:** #247 records that `/code-review` and `/scrutinize` never ran on the 62-commit branch. Run them.

**Pass one — `hooks/t4-gate` carried raw control bytes**, in code committed hours earlier the same day.
A generator emitted a `tr` character range as raw bytes instead of the escape text `tr` expects, so the
script held NUL, BS, VT, US and DEL, and `bash` cannot keep NUL in a string. **The 94-assertion gate
suite passed both before and after** — the whole case for a review living next to a suite. Also three
hook-written state files that were not gitignored, same class as #258.

**Pass two — the ~2,300 lines pass one declared it had not read.** #265 was in there: **eight hooks
passed unbounded input through `argv`**, capped at ~32 KB. Bisected on the wired one: 32,000 B logged,
33,000 B dropped, hook exit 0 either way. In `.invocations.log` that reports the **opposite** of the
truth, inside the mechanism built to measure truthfully.

**The generalisable finding, and it repeated twice in one day:** a guard written as a **list** misses
whatever is added after it. The `.gitattributes` pin named four files and twenty hooks arrived; the argv
guard named five variables and missed two. Both fixed by **deriving** the set — a glob, and a scan for
`x="$(cat)"` assignments. When a check enumerates, ask what adds the next member and whether the check
would see it.

**Root cause worth keeping:** a heredoc in this environment processes backslash escapes *even with a
quoted delimiter*, so a generator writing ` ` emits the byte. Build backslashes with `chr(92)`. The
bug then bit the test written to catch it, which is how it was identified rather than guessed.

**Validation:** `bash tests/hooks/run-all.sh` → **ALL TESTS PASSED** after each. Positive controls on
every new assertion, including one run against the pre-fix blob. CI could not run (billing lock, #158).

---

## The compliance reviewer's first working layer, and five gate defects (#176, #129, #248) (2026-08-19, skills t4-afk + t4-dev-workflow + security-review, PR #235 → `main`)

**Goal:** land the branch that had been open since 2026-08-16 — 62 commits, one issue each, TDD, tree
green after every one.

**Shipped:**
- **The routing chain, end to end** — prompt → generated routing table (#183) → what the session
  actually invoked, read from its own transcript (#184) → speak only about the difference (#186, #190).
  The family map is no longer injected at session start (#182): **8,974 B → 1,368 B an injection, and
  30,424 B saved across a four-injection session**, measured by the suite.
- **Nineteen new hooks.** Five wired; the rest ship **tested and dark**, with suites asserting they are
  *not* in `hooks.json` — wiring a blocking hook unattended is a trust-boundary decision.
- **Six gate defects:** #236 (prose in a `--body` matched as the command — and the issue was wrong
  about its own mechanism), #84 (absolute/quoted path escaped detection), #83 (every GitHub-mutating
  MCP tool bypassed the gate), #141 (`autoMerge`/`afk` skipped the review ask regardless of what the
  diff touched), #245 (the ship gate verified the **working tree**, not the PR), #246 (and the fix for
  #245 then ran a verify command **the PR author wrote**).
- **The tracker hierarchy** (#248) — `plan → PRD → slice` as a native sub-issue tree.

**The rollup now answers the question it was filed for.** #176 reads **25/42**, #129 **2/4**, #215
**1/3**. On 2026-08-17 the same question cost an export of 107 issues, numbers scraped from 54 commit
subjects, and a set difference in a shell pipeline.

**Validation:** `bash tests/hooks/run-all.sh` → **ALL TESTS PASSED** on the merged tree; `test-gate.sh`
alone is 94 assertions. **CI could not run at all** (billing lock; jobs fail at provisioning with
`steps=0`), so the local suite is the whole of the evidence — the gap is #158.

**Two things the branch got wrong about itself, recorded rather than quietly fixed.** #247: 54 commits
declare `scrutinize=ran` and 50 declare `code-review=ran`, and neither ran until the end — **do not
read this branch's trailers as evidence.** The review that did run found **raw control bytes** in code
committed the same day, which the 94-assertion gate suite passed both before *and* after. #260: claimed
the CR was in the committed blobs, with counts that turned out to be **line counts**; every blob was LF
and always had been.

**37 issues closed with evidence**; 107 open → 78. #176 and #129 stay open — their trees are not
finished, and this repo closes with evidence.

---

## The plan level gets a tracker presence, and the log that blocked every push (#255, #258) (2026-08-19, skills t4-afk + t4-dev-workflow, PR #259 → `main`)

**Goal:** `docs/plans/` is reviewable in a PR and invisible to GitHub, so *"which PRDs came out of
this plan?"* was answerable only by a human reading five markdown files. This is the plan level of
#248's `plan → PRD → slice` tree — the one level that had no tracker presence at all.

**Shipped:**
- **#256** and **#257** — tracking issues for `2026-08-13-skill-compliance-plan.md` (→ PRD #176) and
  `2026-08-16-clink-delegation-contract.md` (→ PRD #215), each carrying its PRD as a native sub-issue.
- `docs/plans/README.md` — a **Tracking issue** column. Three of the five plans get `none` **with a
  stated reason**: the 08-04 remediation plan (no PRD names it; #99 filed the audits, #220 holds its
  ADR), `2026-08-13-review-handoff.md` (a component of slice 3, not a plan with a PRD), and
  `2026-08-14-compliance-reviewer-recut.md` (re-cuts #176, which hangs from the 08-13 plan; a PRD has
  exactly one parent).
- `tests/skills/test-plan-index.sh` — every plan on disk must have a parsed row, and every row an
  issue number **or** `none` plus a reason. A blank cell is refused: it is indistinguishable from a
  plan nobody has got to yet, the same shape `check-gate-ledger` enforces for gates.
- `.gitignore` + an assertion in `tests/guards/test-check-tree-budget.sh` (**#258**) —
  `Obsidian-xeno-skills/skill-usage/.invocations.log` is an untracked `*.log` inside the *committed*
  vault directory, so the guard refused every push from this clone. The guard was right; the repo was
  missing one line.

**The two reserved decisions, settled from the artifacts rather than from judgement.** #176's body,
line 5, names the 08-13 plan as where its design detail lives, while the recut appears one line later
in the *evidence* sentence beside two research documents — so the 08-13 plan owns #176.
`2026-08-13-review-handoff.md` says of itself *"design only. Nothing here is built."*

**Validation:** `bash tests/hooks/run-all.sh` → ALL TESTS PASSED, before and after the commit. Four
positive controls on the new suite, each red for the reason it names: a blanked cell, a bare `none`, a
plan file with no row, and the two issue numbers swapped between their rows. `/scrutinize` found the
column index hardcoded at `2` — a reordered table would have scored the **Status** cell and gone red
for the wrong reason; it now reads the column by header name. CI could not run (billing lock; jobs
fail at provisioning with `steps=0`), so the local suite is the whole of the evidence.

**Not covered, and said so in the file rather than left silent:** the suite never calls GitHub, so
deleting the sub-issue links on #256/#257 leaves it green.

---

## Bootstrap the T4 operating layer into this repo (#93) (2026-08-09, skill t4-project-bootstrap, branch `main`)

**Goal:** this repo ships the T4 standard (hooks, CI templates, bootstrap) but had never had the
operating layer applied to itself — no CLAUDE.md, no memory, no `.claude/t4.json`, no ruleset.

**Shipped (new files):**
- `CLAUDE.md` — agent operating manual: north-star, layout, commands, session-start protocol, bilingual conventions, `docs/agents/*` pointers
- `.claude/t4.json` — T4 marker, armed `"verify" = bash tests/hooks/run-all.sh` (the fast prefix of CI `tests`)
- `.claude/settings.json` — registers the three hooks via `${CLAUDE_PROJECT_DIR}`
- `.claude/hooks/{run-hook.cmd,t4-session-start,t4-prompt-reminder,t4-gate,using-t4.snapshot.md}` — self-contained copies
- `.githooks/{pre-push,check-issue-ref,check-tree-budget,check-gate-ledger}` — the agent-agnostic guard tier
- `docs/OPEN-WORK-LEDGER.md`, `DONE.md`, `Obsidian-xeno-skills/Home.md` — memory layer
- `docs/agents/{workflow,issue-tracker,triage-labels,domain}.md` — workflow + tracker conventions
- `CONTEXT.md`, `UBIQUITOUS_LANGUAGE.md`, `PRODUCT.md`, `docs/reports/README.md`, `docs/plans/README.md`, `docs/research/README.md` — domain/product layer (Active tier)
- `.github/workflows/t4-verify.yml` — guards wired into the `tests` job (edit, scoped to pull_request)
- Labels: created `critical`, `Minor` (Severity group); rest already existed
- Ruleset `T4 main gate` — `deletion` + `non_fast_forward` + `pull_request` (block direct pushes to main, squash-only), `required_approving_review_count: 0`
- `tests/skills/test-repo-self-bootstrap.sh` — pins that THIS repo (the standard-shipper) has the operating layer applied to itself: marker armed, settings register the hooks, `.claude/hooks/` byte-identical to `hooks/`, `.githooks/` present, CI runs the guards, CLAUDE.md carries the standing-default wording. Written to close the gap where the existing suite only tests the *templates* against throwaway repos.

**Retroactive TDD note:** the bootstrap install itself was not red-first (it is scaffold/install work whose contracts the existing suite already covers). The genuinely new *behavior* — this repo's own operating layer — now has a pinning test, proven non-tautological by mutation (disarm verify / drop a guard / drop the CI guard wiring each turn it RED). It also caught a real defect during the write: `.claude/hooks/` had been copied from the *installed* skill (stale, pre-#82) instead of the repo's own `references/hooks/`; fixed and byte-verified.

**Validation:** `bash tests/hooks/run-all.sh` green (ALL TESTS PASSED); `tests/hooks/test-bootstrap-sync.sh` green (hook copies byte-identical to plugin `hooks/`); `test-wiring-parity.sh` green; `gh api rulesets` returns `T4 main gate` active; `main protected=True`; YAML of edited workflow validates.

**Deferred (billing blocker):** the required status checks (`tests`, `skill-discovery`) were NOT added to the ruleset because CI is billing-locked — every run fails at provisioning with "account is locked due to a billing issue" (0 steps, ~2s). Adding required checks over a CI that can't run would deadlock every merge. Fix billing → green run → add the two contexts to `required_status_checks` → close #109. This is logged in the ledger.

**Report:** closes #93. Resolves most of #109 (ruleset) — the required-checks half stays open pending billing.

**Next:** 🔴 #109 (add required checks after billing fix) and #72 (close with the merged-PR evidence); #123 ready-for-agent hooks bug is the next work item.

---

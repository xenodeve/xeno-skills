---
name: 2026-08-21-planning-before-measuring
description: The T4-Compact session — two plan revisions built on a capability nobody had run, one number read wrong, one false-green suite, and a PR body that was a commit message.
metadata:
  type: feedback
---

# 2026-08-21 — planning before measuring, and what it cost

**Session ran in `xeno-skills`.** Work: PRD #304 and seven slices for T4-Compact, three plan revisions,
the transport probe (#305), and the compaction-yield research. Everything below happened in it.

## 1. The big one: two full plan revisions rested on a capability nobody had run

**What the rule says** — `t4-dev-workflow`, *No verdict before evidence*: reasoning about code is not
observing it, and a claim's register never improves by being repeated.

**What I did.** I read strings out of the shipped `claude.exe` — `PreCompact`, `Compaction blocked by
PreCompact hook`, `/autocompact`, `tengu_auto_compact_*` — and **designed two complete plan revisions on
top of them**. Revision 1 rode the harness's auto-compaction. Revision 2 lowered the auto-compact window.
Both were merged, and both were wrong.

**The command that settled it took one probe run**, eight cheap Haiku turns: `/compact` sent as a user
message over `--input-format stream-json` **executes**. Had I run it before revision 1, neither revision
would have existed.

**And the register was not even the problem** — I labelled the strings *"suggestive, not evidence"* in
revision 2's own text, and then built the design on them anyway. **Marking a claim as unverified does not
stop it being load-bearing.** That is the gap: the rule governs what you *say*, and nothing governs what
you *build on*.

**The generalisable form, filed as [#324](https://github.com/xenodeve/xeno-skills/issues/324):** when a plan's load-bearing unknown is one
command away, the command comes before the plan — the exemption is *cost*, and cost is never a proof.

## 2. `cache_read` is not the context size

Reported that compaction cut the context **−46 %**, from a single usage field. The real figure was
**−9 %**: the size is `input + cache_creation + cache_read`, and compaction **moves** tokens from the
cached-read field into the created field rather than removing them.

**Caught by the developer**, who said he had watched Claude Code go from 90 % to under 10 %, which my
number could not explain. Measuring 113 real compactions then showed the median is **85 %** and my probe
was the pathological case — a ~9 K conversation on a ~41 K prefix, with nothing to compress.

**A single field that looks like the quantity you want is the trap**; the correction is now pinned in
`scripts/measure-compaction-yield.py`'s own docstring so the next reader meets it before the number.

## 3. A suite that was green because its assertion did not exist

`tests/skills/test-compact-transport-claim.sh` called `hasnt` **without defining it**. Bash printed
`command not found` to stderr, the pass/fail counters never moved, the suite exited 0 — **and the anchor
audit went green too, because it greps for the token `hasnt`, which was present as a broken call.**

**Only running the positive control caught it.** This is the repository's own rule one level up: a green
nobody has seen go red is not evidence, *and neither is a green whose helper does not exist*.

## 4. The PR body that was a commit message (#238, third occurrence)

PR #322 was opened with `--body-file` pointing at the commit-message file: English-only, no Thai mirror,
written as a commit. **Caught and replaced before the merge**, and recorded as a third occurrence on #238.

**What makes it recur is proximity, not laziness** — the commit message is the freshest complete text
about the change, the file is already open, and `--body-file "$SP/msg-*.txt"` is one character from the
correct call.

## 5. What went right, recorded because a log of only failures is also a selected sample

- **The census guard and the anchor audit both fired on their own author again**, and the byte budget
  refused an addition rather than being raised.
- **Every new suite got positive controls run and shown red** — four for the transport claim, and they
  are what caught §3.
- **The developer's corrections were taken as data rather than argued with**: three of them (the layer's
  premise, the 90 % observation, "the worker is not always Claude Code") each changed the design, and the
  last one **inverted** it for local workers.

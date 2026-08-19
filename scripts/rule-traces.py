#!/usr/bin/env python3
"""The reviewer-only trace file (#188), with the undecidable rules marked (#195).

Run:  python scripts/rule-traces.py            # write docs/research/rule-traces.md
      python scripts/rule-traces.py --check    # exit 1 if it is stale

WHY IT LIVES HERE AND NOT IN A SKILL BODY. A load is not free -- one skill was
re-injected three times in a single session at roughly 3,700 bytes each -- and the
master gains nothing from data only the reviewer reads. They stay out of the family
map entirely, which is under a byte budget with almost no headroom.

WHAT A TRACE IS. A SEQUENCE FACT, never a quality criterion. "a message listing the
files to be changed appears before the message containing the plan" is a trace.
"the survey was thorough" is not, and a reviewer handed it will invent a verdict.

EVERY RULE GETS EXACTLY ONE STATE, and that is the whole point of #195:

  traced        -- the rule names an order, and the trace states it as two
                   observable messages and the relation between them.
  machine       -- settled by a script without a transcript. No trace needed.
  untraced      -- the census says it needs a trace and none is written yet. A
                   SEPARATE state from out-of-scope, or work-not-done reads as
                   work-impossible.
  out-of-scope  -- undecidable from a transcript. Marked WITH ITS REASON, because
                   an unmarked gap reads as coverage: a reader who sees traces for
                   most rules and nothing for the rest concludes the rest passed.
  foreign       -- its trace is produced inside a foreign CLI. Marked DISTINCTLY
                   from out-of-scope, because it is not undecidable in principle --
                   it becomes reachable when xenodeve/openclink#116 lands.

Each row carries the sha of the rule text it was written against, so REWORDING A
RULE CANNOT SILENTLY ORPHAN ITS TRACE: the sha stops matching and the suite fails.
"""
import argparse
import hashlib
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "research", "rule-traces.md")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


# Import the census's own classifier rather than restating it. One source for the
# classification, or the two files disagree the day either is edited.
import importlib.util                                    # noqa: E402
_spec = importlib.util.spec_from_file_location(
    "rule_census", os.path.join(ROOT, "scripts", "rule-census.py"))
_rc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_rc)

QUALITY_WORDS = ("well", "thorough", "quality", "properly", "deeply", "good enough")

# The order keyword decides the shape of the derived trace. A trace derived from the
# rule's own words is checkable against them; an invented one is not, which is the
# failure a delegated worker already produced in this repo -- eleven assertions each
# grepping for a sentence the worker had made up.
ORDER_SHAPE = [
    (re.compile(r"\bbefore\b", re.I),
     "the record for '%(a)s' appears BEFORE the record for the action it gates"),
    (re.compile(r"\bafter\b", re.I),
     "the record for '%(a)s' appears AFTER the action that triggers it"),
    (re.compile(r"\bfirst\b", re.I),
     "the record for '%(a)s' is the first of its kind in the segment"),
    (re.compile(r"at session start", re.I),
     "the record for '%(a)s' appears before any tool-use record in the session"),
    (re.compile(r"at session end", re.I),
     "the record for '%(a)s' appears after the last tool-use record in the session"),
    (re.compile(r"red\s*(?:→|->|-)\s*green|\bred\b.*\bgreen\b", re.I),
     "a failing-test record appears BEFORE the record that adds the implementation"),
    (re.compile(r"re-?route|every time|each time", re.I),
     "a record for '%(a)s' appears in every segment that contains its trigger"),
]

REASONS = {
    "quality": "asks whether the work was done well; no sequence of messages settles that",
    "judgement": "requires reading the content of the work, not the order of the records",
}

# TRACES WRITTEN RATHER THAN DERIVED (#194). The shape library covers rules whose
# order word is one of a handful; these five state an order in words no pattern is
# going to generalise, and #194 asks for a trace to be WRITTEN, not for the library
# to be stretched until a one-rule regex counts as a derivation.
#
# KEYED BY THE RULE'S SHA, which is the point. Reword the rule and the key stops
# matching: the row falls back to `untraced` and the suite goes red, so someone
# re-reads the pair instead of inheriting a trace that no longer describes anything.
# Each of these is a statement the reviewer can check against a transcript alone.
WRITTEN = {
    "139fcdd52969":                  # Another agent said so.
        "a record checking the claim appears BETWEEN the subagent report that made it "
        "and the record that asserts it as fact",
    "8d2011e49489":                  # Index-then-open, never whole-file scan.
        "the record reading the index appears BEFORE the record opening any slice it "
        "points to",
    "7dcf8fc1962a":                  # One section, one answer, then the next.
        "each question record is followed by its answer record before the next question "
        "record appears",
    "782682677c5a":                  # Deferring the memory layer.
        "the record installing the memory layer appears in the bootstrap segment, not in "
        "a later one",
    "0263e78d6ba6":                  # Do not narrate what you are about to do at length
        "the tool-use record appears BEFORE the record describing what was done",
}

# RECLASSIFIED OUT OF SCOPE, EACH WITH ITS OWN REASON. Read in full, these four state
# no order at all -- the census reached them through a word in their sentence that is
# not doing ordering work there. Writing traces for them would mean inventing
# sequences, which is the failure the whole file is built against.
#
# THEY DO NOT GET THE BLANKET REASON. An argued reclassification and a rule that was
# undecidable from the start look identical the moment they share a sentence, and the
# suite counts the blanket-reason rows separately so this can never become the quiet
# way to drive `untraced` to zero.
RECLASSIFIED = {
    "22ad4c76b7d9":                  # Write memory a future agent can act on, not a diary.
        "judges the content of the memory written, not the order of the records",
    "432c4004664d":                  # Name the skill file and quote what was written
        "judges what a record contains, not where it sits in the sequence",
    "e9adff722b2e":                  # Prose with no file:line / commit SHA.
        "judges what a record contains, not where it sits in the sequence",
    "e21292c66630":                  # The plan names the question and names who answers it
        "settling it needs the plan document, which is not in the transcript",
}


# ALREADY OUT OF SCOPE, BUT NOT FOR THE BLANKET REASON. These are not rules about how
# work is done -- they are FACTS ABOUT A TOOL that a reader must hold in order to use the
# surrounding rule correctly. "Asks whether the work was done well" is simply false of
# them, and letting them inherit it inflates the blanket population, which is the exact
# measure the suite pins so that reclassification cannot become a quiet dumping ground.
ARGUED = {
    "6f24fbd6fc60":                  # The rollup counts DIRECT CHILDREN only.
        "states a fact about the tracker's API, not a behaviour performed in any order",
    "7994bc1ca25f":                  # A child has exactly one parent
        "states a constraint the tracker enforces, which no transcript can evidence",
    "ae4da41e11fb":                  # If you notice something incomplete, mention it
        "the transcript shows an edit, never the incompleteness the agent DECLINED to "
        "finish -- a compliant session and one that saw nothing produce identical records",
}


def sha(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:12]


def skill_versions():
    """The version of each family skill, and it is the sha of the FILE (#200).

    NO SKILL.md CARRIES A `version:` FIELD, and inventing one would be worse than
    none: a version nobody remembers to bump is a version that lies, and this layer
    exists precisely to catch a skill that changed without anyone announcing it. The
    file's own hash cannot drift from the file.

    What it buys: this repository edits its own skills constantly, and without a
    version a reviewer at a later segment checks version B's declared traces against
    behaviour produced under version A -- and reports a violation THAT NEVER
    HAPPENED. With it, the mismatch is visible instead of silent, and the reviewer
    resolves it to unknown rather than to a finding.
    """
    out = []
    for rel in _rc.FAMILY:
        path = os.path.join(ROOT, rel)
        try:
            with open(path, "rb") as f:
                ver = hashlib.sha256(f.read()).hexdigest()[:12]
        except OSError:
            continue
        out.append((os.path.basename(os.path.dirname(rel)), ver, rel.replace("\\", "/")))
    return sorted(out)


def trace_for(rule, text=None):
    """Derive from the FULL rule line, name it by its label.

    The two arguments are the whole fix for #194's twenty-one owed rules. The census
    decides `decidability` on label + sentence and used to hand this function the
    label alone, so a rule classed as needing a trace BECAUSE its sentence said
    "before" was then judged by four words that said no such thing. Matching on the
    sentence and interpolating the label keeps the derived trace checkable against
    the rule's own words -- which is the property that separates it from an invented
    one, and this repo has already shipped eleven assertions grepping for sentences a
    worker made up."""
    short = rule if len(rule) <= 60 else rule[:57] + "..."
    for pattern, shape in ORDER_SHAPE:
        if pattern.search(text or rule):
            return shape % {"a": short}
    return None


def rows():
    out = []
    for r in _rc.rules():
        rule = r["rule"]
        rid = "%s/%s" % (r["skill"], sha(rule))
        if r["producer"] == "foreign":
            state, detail = "foreign", ("produced inside a foreign CLI; reachable when "
                                        "xenodeve/openclink#116 lands")
        elif r["decidability"] == "machine":
            state, detail = "machine", "settled by a script; no transcript needed"
        elif r["decidability"] == "trace":
            # A written trace beats a derived one: it was read from the whole rule by
            # someone, where the shape library matched a keyword.
            t = WRITTEN.get(sha(rule)) or trace_for(rule, r.get("text"))
            if t:
                state, detail = "traced", t
            elif sha(rule) in RECLASSIFIED:
                state, detail = "out-of-scope", RECLASSIFIED[sha(rule)]
            else:
                # The census says this rule names an order; the shape library cannot
                # yet state that order as observable records. It gets its OWN state
                # rather than falling into out-of-scope, because folding it in is the
                # same failure #195 exists to prevent, one level up: the gap would
                # read as "undecidable" when it is really "not written yet".
                state, detail = "untraced", ("the census classes this as needing a trace; "
                                             "no trace shape covers it yet")
        else:
            state, detail = "out-of-scope", ARGUED.get(sha(rule), REASONS["quality"])
        out.append({"id": rid, "skill": r["skill"], "rule": rule,
                    "sha": sha(rule), "state": state, "detail": detail})
    return out


def render(rs):
    n = lambda s: sum(1 for r in rs if r["state"] == s)
    nre = lambda rs: sum(1 for r in rs if r["detail"] in RECLASSIFIED.values()
                         and r["state"] == "out-of-scope")
    L = []
    A = L.append
    A("# Rule traces — reviewer-only")
    A("")
    A("**Generated by `scripts/rule-traces.py`. Do not hand-edit — re-run it.**")
    A("")
    A("This file is read by the compliance reviewer and by nothing else. It is")
    A("deliberately not in any skill body and not in the family map: a load is not")
    A("free — one skill was re-injected three times in a single session at roughly")
    A("3,700 bytes each — and the master gains nothing from data only the reviewer")
    A("reads.")
    A("")
    A("**A trace is a sequence fact, never a quality criterion.** *\"the record for X")
    A("appears before the record for Y\"* is a trace. *\"the survey was thorough\"* is")
    A("not, and a reviewer handed it will invent a verdict.")
    A("")
    A("## Coverage")
    A("")
    A("| State | Count | Meaning |")
    A("|---|---|---|")
    A("| `traced` | %d | The rule names an order, and the trace states it as observable records |" % n("traced"))
    A("| `machine` | %d | Settled by a script without a transcript |" % n("machine"))
    A("| `untraced` | %d | **Needs a trace; none written yet — work not done, not work impossible** |" % n("untraced"))
    A("| `out-of-scope` | %d | **Undecidable from a transcript, marked with its reason** |" % n("out-of-scope"))
    A("| -- of which reclassified from `trace` | %d | **Argued one by one, never with the blanket reason** |" % nre(rs))
    A("| `foreign` | %d | Its trace is produced inside a foreign CLI |" % n("foreign"))
    A("| **total** | **%d** | |" % len(rs))
    A("")
    A("**The out-of-scope count is the size of the blind spot, and it is published on")
    A("purpose.** An unmarked gap reads as coverage: a reader who sees traces for most")
    A("rules and nothing for the rest concludes the rest were checked and passed.")
    A("Saying so is the difference between a known limit and a silent one.")
    A("")
    A("**The arithmetic is published so neither half can hide the other.** The census")
    A("classes %d rules as needing a trace. %d have one, %d were read in full, state no" % (n("traced") + n("untraced") + nre(rs), n("traced"), nre(rs)))
    A("order at all, and were reclassified out of scope with an individual reason, and")
    A("%d are named as owed. `untraced` is the honest half: folding the owed into the" % n("untraced"))
    A("undecidable would make work-not-done read as work-impossible, which is the same")
    A("failure this file exists to prevent.")
    A("")
    A("**A reclassification never borrows the blanket reason.** An argued move and a")
    A("rule that was undecidable from the start look identical the moment they share a")
    A("sentence, so `tests/skills/test-rule-traces.sh` counts the blanket-reason rows")
    A("separately — driving `untraced` to zero by quietly widening the blind spot fails.")
    A("")
    A("**`foreign` is marked distinctly from `out-of-scope`** because it is not")
    A("undecidable in principle. Those traces become reachable when")
    A("`xenodeve/openclink#116` lands and the worker's event stream stops being")
    A("discarded; an out-of-scope rule never becomes reachable.")
    A("")
    A("## Why each row carries a sha")
    A("")
    A("The `sha` is of the rule text the row was written against. **Rewording a rule")
    A("cannot silently orphan its trace** — the sha stops matching and")
    A("`tests/skills/test-rule-traces.sh` fails, so someone re-reads the pair instead")
    A("of inheriting a trace that no longer describes anything.")
    A("")
    A("## Skill versions")
    A("")
    A("**The version is the sha of the `SKILL.md` file**, because no skill carries a")
    A("`version:` field and inventing one would be worse than none — a version nobody")
    A("remembers to bump is a version that lies, and this layer exists to catch a skill")
    A("that changed without anyone announcing it.")
    A("")
    A("A reviewer that finds a skill's current sha different from the one below is")
    A("holding traces written for a different skill. It resolves that to **unknown with")
    A("the reason stated**, never to a finding: reporting a violation produced under a")
    A("version the trace was not written for is a false positive, and a critic that")
    A("cries wolf gets switched off along with its true findings.")
    A("")
    A("| skill | version | path |")
    A("|---|---|---|")
    for skill, ver, path in skill_versions():
        A("| `%s` | `%s` | `%s` |" % (skill, ver, path))
    A("")
    A("## Traces")
    A("")
    A("| id | skill | state | rule | trace / reason |")
    A("|---|---|---|---|---|")
    for r in sorted(rs, key=lambda r: (r["skill"], r["rule"])):
        rule = r["rule"].replace("|", "\\|")
        if len(rule) > 72:
            rule = rule[:69] + "…"
        detail = r["detail"].replace("|", "\\|")
        if len(detail) > 96:
            detail = detail[:93] + "…"
        A("| `%s` | `%s` | %s | %s | %s |" % (r["id"], r["skill"], r["state"], rule, detail))
    A("")
    return "\n".join(L)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    fresh = render(rows())
    if args.check:
        try:
            with open(OUT, encoding="utf-8") as f:
                if f.read() == fresh:
                    return 0
        except OSError:
            print("rule-traces.md is missing -- run scripts/rule-traces.py", file=sys.stderr)
            return 1
        print("rule-traces.md is stale -- re-run scripts/rule-traces.py", file=sys.stderr)
        return 1
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(fresh)
    rs = rows()
    print("wrote %s (%d rules)" % (os.path.relpath(OUT, ROOT), len(rs)))
    return 0


if __name__ == "__main__":
    sys.exit(main())

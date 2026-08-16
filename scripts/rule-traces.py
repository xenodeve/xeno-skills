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


def sha(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:12]


def trace_for(rule):
    short = rule if len(rule) <= 60 else rule[:57] + "..."
    for pattern, shape in ORDER_SHAPE:
        if pattern.search(rule):
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
            t = trace_for(rule)
            if t:
                state, detail = "traced", t
            else:
                # The census says this rule names an order; the shape library cannot
                # yet state that order as observable records. It gets its OWN state
                # rather than falling into out-of-scope, because folding it in is the
                # same failure #195 exists to prevent, one level up: the gap would
                # read as "undecidable" when it is really "not written yet".
                state, detail = "untraced", ("the census classes this as needing a trace; "
                                             "no trace shape covers it yet")
        else:
            state, detail = "out-of-scope", REASONS["quality"]
        out.append({"id": rid, "skill": r["skill"], "rule": rule,
                    "sha": sha(rule), "state": state, "detail": detail})
    return out


def render(rs):
    n = lambda s: sum(1 for r in rs if r["state"] == s)
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
    A("| `foreign` | %d | Its trace is produced inside a foreign CLI |" % n("foreign"))
    A("| **total** | **%d** | |" % len(rs))
    A("")
    A("**The out-of-scope count is the size of the blind spot, and it is published on")
    A("purpose.** An unmarked gap reads as coverage: a reader who sees traces for most")
    A("rules and nothing for the rest concludes the rest were checked and passed.")
    A("Saying so is the difference between a known limit and a silent one.")
    A("")
    A("**`untraced` is the honest half of this file.** The census classes %d rules as" % (n("traced") + n("untraced")))
    A("needing a trace and %d have one, so %d are named as owed rather than quietly" % (n("traced"), n("untraced")))
    A("filed under undecidable. Folding them in would make work-not-done read as")
    A("work-impossible, which is the same failure this file exists to prevent.")
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

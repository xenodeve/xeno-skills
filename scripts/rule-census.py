#!/usr/bin/env python3
"""Re-cut the rule census, and ask who produces each trace (#181).

Run:  python scripts/rule-census.py            # write docs/research/rule-census.md
      python scripts/rule-census.py --check    # exit 1 if the committed census is stale

WHY THIS IS A CLASSIFIER AND NOT A HAND-LABELLED TABLE. The acceptance criterion
is "the counts published with the method, so a later re-count is comparable". A
hand-labelled table is not comparable: nobody can reproduce the labels, so the
next count measures a different judgement rather than a changed repository. A
stated classifier is reproducible by construction -- re-run it and the delta is
the repository's, not the counter's.

WHAT THE INHERITED NUMBERS WERE. 33 machine-decidable / 68 needing a trace / 25
undecidable. They were counted before the delegation question existed and nobody
has re-counted since, so every downstream slice size rested on a number no one
produced. This replaces them, and states its own method so the same is not true
of these.

THE TWO CLASSIFICATIONS

1. DECIDABILITY -- can a script settle it without a model?
   machine  : the rule names a checkable artifact -- a command, a file, an exit
              code, a label. A script can look and know.
   trace    : the rule names an ORDER -- this before that. Deciding it needs the
              sequence of what happened, which is what a transcript carries.
   undecid. : neither. It asks whether work was done WELL, and no trace settles
              that. These are the rules the reviewer must be told to leave alone,
              or it will invent verdicts about them.

2. TRACE PRODUCER -- whose transcript would carry the evidence?
   master   : the master's own session.
   subagent : a native subagent, followed through its own transcript.
   foreign  : a worker inside a foreign CLI, reached only across the clink
              boundary. LISTED SEPARATELY rather than folded into undecidable,
              because the distinction is actionable: foreign traces become
              reachable when openclink#116 lands, and undecidable ones never do.
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "research", "rule-census.md")

# The T4 family plus the coding guardrails. The clink skills are NOT in scope: the
# compliance reviewer judges the master's own conduct, and a clink skill's rules
# govern a delegation that has its own reviewer (openclink#119). Stated rather than
# assumed, because an unstated scope reads as a count of everything.
FAMILY = [
    "skills/t4/using-t4/SKILL.md",
    "skills/t4/t4-dev-workflow/SKILL.md",
    "skills/t4/t4-agent-memory/SKILL.md",
    "skills/t4/t4-engineering-records/SKILL.md",
    "skills/t4/t4-project-bootstrap/SKILL.md",
    "skills/t4/t4-afk/SKILL.md",
    "skills/t4/t4-bro/SKILL.md",
    "skills/karpathy-guidelines/SKILL.md",
]

# A rule is a bolded imperative line. Bold alone is emphasis; the imperative is
# what makes it a rule someone could fail to follow.
RULE_LINE = re.compile(r"^\s*(?:[-*]|\|)\s*\*\*(.+?)\*\*(.*)$")

ARTIFACT = re.compile(r"""\b(
    gh\s|git\s|commit|branch|\bPR\b|issue|label|test|suite|exit|file|path|
    \.md\b|\.json\b|\.sh\b|hook|frontmatter|trailer|receipt|id\b|sha\b|command
)\b""", re.X | re.I)

ORDER = re.compile(r"""\b(
    before|after|first|then|until|prior\s+to|precede|preceded|next|
    at\s+session\s+(?:start|end)|each\s+time|every\s+time|re-?route|
    red\s*(?:→|->|-)\s*green|start\s+of|end\s+of
)\b""", re.X | re.I)

QUALITY = re.compile(r"""\b(
    well|quality|deep|deeply|thorough|simplest|elegant|taste|clear|
    readable|appropriate|reasonable|sensible|good\b|better\b
)\b""", re.X | re.I)

FOREIGN = re.compile(r"\b(clink|foreign\s+CLI|delegat\w+|worker|subagent|codex|cursor|antigravity)\b", re.I)
SUBAGENT = re.compile(r"\b(subagent|native\s+subagent|Task\b|agent\s+tree)\b", re.I)


def decidability(text):
    """Order first: a rule that names a sequence needs a trace even when it also
    names an artifact -- 'red before green' mentions tests and is still a
    sequence. Getting this precedence backwards is what inflates the
    machine-decidable count."""
    if ORDER.search(text):
        return "trace"
    if QUALITY.search(text) and not ARTIFACT.search(text):
        return "undecidable"
    if ARTIFACT.search(text):
        return "machine"
    return "undecidable"


def producer(text):
    if FOREIGN.search(text) and not SUBAGENT.search(text):
        return "foreign"
    if SUBAGENT.search(text):
        return "subagent"
    return "master"


def rules():
    out = []
    for rel in FAMILY:
        path = os.path.join(ROOT, rel)
        try:
            with open(path, encoding="utf-8") as f:
                lines = f.readlines()
        except OSError:
            continue
        for line in lines:
            m = RULE_LINE.match(line.rstrip("\n"))
            if not m:
                continue
            head, tail = m.group(1).strip(), m.group(2).strip()
            text = (head + " " + tail).strip()
            if len(head) < 8:            # a bolded fragment, not a rule
                continue
            out.append({
                "skill": os.path.basename(os.path.dirname(rel)),
                "rule": head,
                "decidability": decidability(text),
                "producer": producer(text),
            })
    return out


def render(rs):
    def n(**kw):
        return sum(1 for r in rs if all(r[k] == v for k, v in kw.items()))

    lines = []
    A = lines.append
    A("# Rule census — decidability, and who produces the trace")
    A("")
    A("**Generated by `scripts/rule-census.py`. Do not hand-edit — re-run it.**")
    A("")
    A("The previous split — 33 machine-decidable / 68 needing a trace / 25 undecidable —")
    A("was counted before the delegation question existed and nobody re-counted it since,")
    A("so every downstream slice size rested on a number no one produced. These numbers")
    A("come with the classifier that produced them, so a later re-count measures the")
    A("repository rather than a different person's judgement.")
    A("")
    A("**Scope, stated:** the T4 family and `karpathy-guidelines`. The clink skills are")
    A("out of scope — the compliance reviewer judges the master's own conduct, and a")
    A("clink skill's rules govern a delegation that has its own reviewer")
    A("(`xenodeve/openclink#119`).")
    A("")
    A("## Counts")
    A("")
    A("| | machine-decidable | needs a trace | undecidable | **total** |")
    A("|---|---|---|---|---|")
    A("| **master** | %d | %d | %d | **%d** |" % (
        n(producer="master", decidability="machine"),
        n(producer="master", decidability="trace"),
        n(producer="master", decidability="undecidable"),
        n(producer="master")))
    A("| **native subagent** | %d | %d | %d | **%d** |" % (
        n(producer="subagent", decidability="machine"),
        n(producer="subagent", decidability="trace"),
        n(producer="subagent", decidability="undecidable"),
        n(producer="subagent")))
    A("| **foreign CLI worker** | %d | %d | %d | **%d** |" % (
        n(producer="foreign", decidability="machine"),
        n(producer="foreign", decidability="trace"),
        n(producer="foreign", decidability="undecidable"),
        n(producer="foreign")))
    A("| **total** | **%d** | **%d** | **%d** | **%d** |" % (
        n(decidability="machine"), n(decidability="trace"),
        n(decidability="undecidable"), len(rs)))
    A("")
    A("**What the foreign row means.** Those rules are listed separately rather than")
    A("folded into undecidable because the distinction is actionable: a foreign trace")
    A("becomes reachable when `xenodeve/openclink#116` lands and the worker's event")
    A("stream stops being discarded. An undecidable rule never becomes reachable.")
    A("")
    A("**What the undecidable column means.** Those rules ask whether work was done")
    A("*well*. No trace settles that, so the reviewer must be told to leave them alone")
    A("or it will invent verdicts about them — which is #195.")
    A("")
    A("## The method")
    A("")
    A("A rule is a **bolded imperative line** in a family `SKILL.md`. Bold alone is")
    A("emphasis; the imperative is what makes it something an agent could fail to do.")
    A("")
    A("Decidability, in this precedence:")
    A("")
    A("1. **needs a trace** — the rule names an ORDER (*before*, *then*, *at session")
    A("   start*, *red → green*). Order is checked first on purpose: *red before green*")
    A("   also names tests, and classifying it as machine-decidable is what inflates")
    A("   that count.")
    A("2. **undecidable** — it asks about quality (*well*, *thorough*, *simplest*) with")
    A("   no artifact named.")
    A("3. **machine-decidable** — it names a checkable artifact: a command, a file, an")
    A("   exit code, a label, a trailer.")
    A("")
    A("Producer: **foreign** when the rule names the clink boundary or a delegation and")
    A("not a native subagent; **subagent** when it names the native tier; **master**")
    A("otherwise.")
    A("")
    A("**What this method cannot see, stated rather than implied:** a rule expressed as")
    A("prose without a bolded imperative, a rule that lives only in a `references/`")
    A("file, and a rule whose order is implied by context rather than by a keyword. The")
    A("count is therefore a floor, not a total.")
    A("")
    A("## The rules")
    A("")
    A("| Skill | Rule | Decidability | Trace producer |")
    A("|---|---|---|---|")
    for r in sorted(rs, key=lambda r: (r["skill"], r["rule"])):
        rule = r["rule"].replace("|", "\\|")
        if len(rule) > 96:
            rule = rule[:93] + "…"
        A("| `%s` | %s | %s | %s |" % (r["skill"], rule, r["decidability"], r["producer"]))
    A("")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    fresh = render(rules())
    if args.check:
        try:
            with open(OUT, encoding="utf-8") as f:
                if f.read() == fresh:
                    return 0
        except OSError:
            print("rule-census.md is missing -- run scripts/rule-census.py", file=sys.stderr)
            return 1
        print("rule-census.md disagrees with the skills -- re-run scripts/rule-census.py",
              file=sys.stderr)
        return 1
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(fresh)
    rs = rules()
    print("wrote %s (%d rules)" % (os.path.relpath(OUT, ROOT), len(rs)))
    return 0


if __name__ == "__main__":
    sys.exit(main())

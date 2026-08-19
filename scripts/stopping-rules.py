#!/usr/bin/env python3
"""The four stopping rules, as checked gates rather than paragraphs (#224).

Run:  python scripts/stopping-rules.py            # report every rule's state
      python scripts/stopping-rules.py --gate N   # exit non-zero unless slice N may proceed

WHY THIS EXISTS. `docs/plans/2026-08-13-skill-compliance-plan.md` wrote four
stopping rules "now rather than after the work", and gave the reason: *a gate
written after the effort has been spent is a gate nobody uses.* None of them was a
gate. #180 measures the baseline; nothing turned a count into a stop, so slice 2
and slice 3 could be paid for without anyone being required to look at the number
that decides whether they are worth building.

THE DEFAULT FOR AN UNMEASURED RULE IS `unknown`, AND UNKNOWN DOES NOT PASS. That
is the whole design. A gate whose missing measurement reads as a pass is worse than
no gate: it produces the paperwork of having checked. Proceeding past an unknown is
possible, with --allow-unmeasured, and it is then a recorded decision rather than
a silence.
"""
import argparse
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEASUREMENTS = os.path.join(ROOT, "docs", "research", "data", "compliance-baseline.json")

# Thresholds, with the reasoning for the number rather than the number alone.
THRESHOLDS = {
    # "Near zero" from the plan. 1 in 10 is the point below which the premise -- that
    # naming a specific missing thing changes behaviour -- is refuted rather than weak.
    "routed_then_loaded_rate": 0.10,
    # A reviewer that cries wolf has spent the only asset it has; nothing here blocks
    # anything, so its whole value is being believed.
    "false_positive_rate": 0.20,
    # Below this many master-produced traceable rules, slice 2 is not worth building
    # out and shrinks to the rules that have one.
    "min_traceable_rules": 10,
}


def measurements():
    try:
        with open(MEASUREMENTS, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def traceable_master_rules():
    """Rule 3 is measurable today: the census exists."""
    path = os.path.join(ROOT, "docs", "research", "rule-census.md")
    try:
        with open(path, encoding="utf-8") as f:
            doc = f.read()
    except OSError:
        return None
    m = re.search(r"\| \*\*master\*\* \| \d+ \| (\d+) \|", doc)
    return int(m.group(1)) if m else None


def off_switches_asserted():
    """Rule 4's checkable half: every layer's off switch has a test asserting it."""
    tests = os.path.join(ROOT, "tests")
    # Needles are quoted from the assertions themselves, so this cannot pass on a
    # test that was renamed away. Only layers that INJECT or GATE are listed -- the
    # canary is a command someone runs, not a layer with a switch.
    needed = {
        "the gap notice": "a MATCHED turn does not emit the route list",
        "sticky debt": "with no stickyDebt setting it says nothing",
        "the debt gate is unwired": "it ships tested and dark",
    }
    found = {}
    for dirpath, _d, files in os.walk(tests):
        for fn in files:
            if not fn.endswith(".sh"):
                continue
            # Skip the suite that PROBES this check. Its positive control contains
            # the needles as literal text, so including it makes the probe match
            # itself and the check can never trip -- which is how a detector ends up
            # reporting all clear forever. Found by the probe failing.
            if fn == "test-stopping-rules.sh":
                continue
            try:
                text = open(os.path.join(dirpath, fn), encoding="utf-8").read()
            except OSError:
                continue
            for layer, needle in needed.items():
                if needle in text:
                    found[layer] = fn
    return found, needed


def evaluate():
    m = measurements()
    out = []

    r = m.get("routed_then_loaded_rate")
    if r is None:
        out.append(("1 routed-then-loaded", "unknown",
                    "not measured yet -- #180 owns the number. Unknown does not pass."))
    elif r < THRESHOLDS["routed_then_loaded_rate"]:
        out.append(("1 routed-then-loaded", "STOP",
                    "%.3f is below %.2f: the premise is refuted and slices 2 and 3 rest "
                    "entirely on it" % (r, THRESHOLDS["routed_then_loaded_rate"])))
    else:
        out.append(("1 routed-then-loaded", "pass", "%.3f" % r))

    fp = m.get("false_positive_rate")
    if fp is None:
        out.append(("2 false-positive rate", "unknown",
                    "not measured yet -- Baseline B owns it. Unknown does not pass."))
    elif fp > THRESHOLDS["false_positive_rate"]:
        out.append(("2 false-positive rate", "DEGRADE",
                    "%.3f is above %.2f: slice 3 counts silently and raises nothing"
                    % (fp, THRESHOLDS["false_positive_rate"])))
    else:
        out.append(("2 false-positive rate", "pass", "%.3f" % fp))

    n = traceable_master_rules()
    if n is None:
        out.append(("3 traceable rules", "unknown", "the census could not be read"))
    elif n < THRESHOLDS["min_traceable_rules"]:
        out.append(("3 traceable rules", "SHRINK",
                    "%d master-produced traceable rules is below %d: slice 2 shrinks to "
                    "those rules rather than being built out"
                    % (n, THRESHOLDS["min_traceable_rules"])))
    else:
        out.append(("3 traceable rules", "pass",
                    "%d master-produced rules need a trace" % n))

    found, needed = off_switches_asserted()
    missing = sorted(set(needed) - set(found))
    if missing:
        out.append(("4 off switches", "STOP",
                    "no test asserts the off switch for: %s" % ", ".join(missing)))
    else:
        out.append(("4 off switches", "pass",
                    "every layer's off switch is asserted: %s"
                    % ", ".join("%s (%s)" % (k, v) for k, v in sorted(found.items()))))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gate", type=int, choices=(2, 3),
                    help="exit non-zero unless this slice may proceed")
    ap.add_argument("--allow-unmeasured", action="store_true",
                    help="treat unknown as pass, and say so -- a recorded decision, not a silence")
    args = ap.parse_args()

    rows = evaluate()
    width = max(len(r[0]) for r in rows)
    for name, state, detail in rows:
        print("%-*s  %-8s  %s" % (width, name, state, detail))

    if args.gate is None:
        return 0

    blocking = [r for r in rows if r[1] in ("STOP", "DEGRADE", "SHRINK")]
    unknown = [r for r in rows if r[1] == "unknown"]

    if blocking:
        print("\nslice %d MUST NOT proceed: %s"
              % (args.gate, "; ".join("%s -- %s" % (r[0], r[2]) for r in blocking)),
              file=sys.stderr)
        return 1
    if unknown and not args.allow_unmeasured:
        print("\nslice %d is NOT cleared: %d rule(s) unmeasured, and unknown does not pass. "
              "Measure them (#180), or pass --allow-unmeasured to proceed as a recorded "
              "decision." % (args.gate, len(unknown)), file=sys.stderr)
        return 1
    if unknown:
        print("\nslice %d proceeding with %d unmeasured rule(s), explicitly allowed."
              % (args.gate, len(unknown)))
    return 0


if __name__ == "__main__":
    sys.exit(main())

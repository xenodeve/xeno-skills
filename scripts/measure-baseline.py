#!/usr/bin/env python3
"""Count the baseline, before any layer is enabled (#180).

Run:  python scripts/measure-baseline.py [--sessions N] [--write]

WHY IT EXISTS. Every layer in the compliance plan assumes the master changes what
it does when it is told something, and #134 is the standing evidence against it: the
rules were injected on every prompt, they were in context, and behaviour did not
change. #224 turns that into a stopping rule -- and a stopping rule with no
measurement behind it does not stop anything.

THE POINT IS THE DENOMINATOR. This repository has already recorded a figure it could
not use, because only the failures were counted and nobody knew how many chances
there had been. Every count below is reported with the number it divides by.

WHAT THE METHOD CANNOT SEE, stated rather than implied:
  * A skill invoked by being READ rather than through the Skill tool or a slash
    command leaves no record either detector can find.
  * The routing table is keyword-based and narrow by design (#183), so a prompt
    that needed a skill the table does not associate with it counts as "not routed"
    rather than as a miss. This makes routed-then-loaded an OPTIMISTIC rate.
  * Sessions are whatever is on this machine. They are not a sample of anything.
  * A "turn" here is a `type: "user"` RECORD, which includes tool results, not only
    developer prompts. So the turn count is inflated against what a person would
    call a turn, and the routed PERCENTAGE is correspondingly small. The
    routed-then-loaded RATE is unaffected: both its numerator and its denominator
    come from routed records, so the inflation cancels.
"""
import argparse
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TABLE = os.path.join(ROOT, "hooks", "routing-table.json")
OUT = os.path.join(ROOT, "docs", "research", "data", "compliance-baseline.json")

CMD = re.compile(r"<command-name>\s*/?([A-Za-z0-9._-]+)\s*</command-name>")


def sessions(limit):
    home = os.path.expanduser("~")
    paths = glob.glob(os.path.join(home, ".claude", "projects", "*", "*.jsonl"))
    paths.sort(key=lambda p: os.path.getsize(p), reverse=True)
    return paths[:limit]


def records(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    rec = json.loads(line)
                except Exception:
                    continue
                if isinstance(rec, dict):
                    yield rec
    except OSError:
        return


def analyse(path, routes):
    """One pass. Returns (turns, routed_turns, routed_then_loaded, invocations)."""
    turns = routed = loaded_after = 0
    invoked = set()
    pending = []          # prompts that routed and are waiting to see the skill load

    for rec in records(path):
        msg = rec.get("message") or {}
        content = msg.get("content")

        # A user prompt opens a turn.
        text = None
        if rec.get("type") == "user":
            if isinstance(content, str):
                text = content
            elif isinstance(content, list):
                text = " ".join(b.get("text", "") for b in content
                                if isinstance(b, dict) and isinstance(b.get("text"), str))
        if text is not None:
            turns += 1
            low = text.lower()
            want = set()
            for r in routes:
                if any(t and t.lower() in low for t in r.get("triggers_th", [])):
                    want.add(r["skill"])
                    continue
                for t in r.get("triggers_en", []):
                    if t and re.search(r"(?<![a-z0-9])%s(?![a-z0-9])" % re.escape(t.lower()), low):
                        want.add(r["skill"])
                        break
            want -= invoked                      # already loaded is not a miss
            if want:
                routed += 1
                pending.append(want)

        # Skill invocations, both record types (#184).
        if isinstance(content, list):
            for b in content:
                if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") == "Skill":
                    n = (b.get("input") or {}).get("skill")
                    if n:
                        invoked.add(str(n))
        for t in ([content] if isinstance(content, str) else
                  [b.get("text") for b in (content or []) if isinstance(b, dict)]):
            if isinstance(t, str):
                for n in CMD.findall(t):
                    invoked.add(n)

        # A pending expectation is satisfied the moment its skill appears.
        still = []
        for want in pending:
            if want & invoked:
                loaded_after += 1
            else:
                still.append(want)
        pending = still

    return turns, routed, loaded_after, len(invoked)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sessions", type=int, default=12)
    ap.add_argument("--write", action="store_true",
                    help="write docs/research/data/compliance-baseline.json for #224")
    args = ap.parse_args()

    try:
        table = json.load(open(TABLE, encoding="utf-8"))["routes"]
    except Exception:
        print("no routing table -- run scripts/generate-routing-table.py", file=sys.stderr)
        return 1

    paths = sessions(args.sessions)
    if not paths:
        print("no transcripts found", file=sys.stderr)
        return 1

    T = R = L = 0
    print("%-46s %7s %7s %7s" % ("session", "records", "routed", "loaded"))
    for p in paths:
        t, r, l, _n = analyse(p, table)
        T += t; R += r; L += l
        print("%-46s %7d %7d %7d" % (os.path.basename(p)[:46], t, r, l))

    rate = (L / R) if R else None
    print("\n%-46s %7d %7d %7d" % ("TOTAL", T, R, L))
    print("\nturns measured:            %d   <- the denominator" % T)
    print("records that routed:       %d   (%.1f%% of records)" % (R, 100.0 * R / T if T else 0))
    print("routed AND then loaded:    %d" % L)
    if rate is None:
        print("routed-then-loaded rate:   n/a -- nothing routed")
    else:
        print("routed-then-loaded rate:   %.3f   <- #224's rule 1 reads this" % rate)

    if args.write:
        os.makedirs(os.path.dirname(OUT), exist_ok=True)
        payload = {
            "measured_by": "scripts/measure-baseline.py",
            "sessions": len(paths),
            "user_records": T,
            "routed_turns": R,
            "routed_then_loaded": L,
            "routed_then_loaded_rate": rate,
            "note": ("Optimistic: the routing table is narrow by design, so a prompt "
                     "needing a skill the table does not associate with it counts as "
                     "not routed rather than as a miss. false_positive_rate is absent "
                     "on purpose -- Baseline B has not been run, and unknown does not "
                     "pass in #224."),
        }
        with open(OUT, "w", encoding="utf-8", newline="\n") as f:
            json.dump(payload, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print("\nwrote %s" % os.path.relpath(OUT, ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Validate a delegation request or response against the v1 contract (#217 Phase B).

Run:  python scripts/validate-delegation.py request  [PATH]   # or on stdin
      python scripts/validate-delegation.py response [PATH]

Exit 0 when valid. Non-zero when not, with the failing field and the reason on
stderr. Nothing else -- no formatting, no summary.

WHY A COMMAND-LINE CONTRACT AND NOT A LIBRARY. This repository has exactly one test
seam: `bash tests/hooks/run-all.sh` discovers every `tests/**/test-*.sh`. A bash
test can drive an exit code and stderr; it cannot import a Python module. Choosing
the interface this way means the validator is covered by the seam that already
exists instead of arriving with a second one.

WHAT IT DOES NOT DO. It does not judge the CONTENT. A response whose Findings are
wrong is valid; a response with no Evidence boundary is not. Shape is what a script
can settle, and pretending otherwise would put judgement back in a place that
cannot hold it.
"""
import argparse
import json
import re
import sys

REQUEST_REQUIRED = ["protocol", "version", "problem", "objective", "questions"]
RESPONSE_META = ["protocol", "version", "decision_status", "confidence"]
RESPONSE_SECTIONS = ["Summary", "Findings", "Recommendation", "Evidence boundary"]
STATES = ("ready", "needs_more_analysis", "needs_user_input", "blocked")
CONFIDENCE = ("high", "medium", "low")

SUPPORTED_VERSIONS = (1,)


def fail(field, why):
    print("%s: %s" % (field, why), file=sys.stderr)
    return 1


def load_yamlish(text):
    """The request is YAML-shaped. Rather than take a dependency for a handful of
    keys, read the fields this contract actually requires -- and read them
    strictly, so a missing one is missing rather than silently defaulted."""
    out = {}
    for key in ("protocol", "version"):
        m = re.search(r"^%s:\s*(\S+)\s*$" % key, text, re.M)
        if m:
            out[key] = m.group(1)
    for key in ("problem", "objective"):
        m = re.search(r"^\s*%s:\s*(?:>|\|)?\s*\n((?:\s{2,}\S.*\n?)+)" % key, text, re.M)
        if m and m.group(1).strip():
            out[key] = m.group(1).strip()
        else:
            m2 = re.search(r"^\s*%s:\s*(\S.*)$" % key, text, re.M)
            if m2 and m2.group(1).strip():
                out[key] = m2.group(1).strip()
    # A list key counts as present only when it has at least one entry: an empty
    # `questions:` is the same as no questions, and treating it as present is how a
    # delegation ships with nothing to answer.
    for key in ("questions",):
        m = re.search(r"^\s*%s:\s*\n((?:\s*-\s+\S.*\n?)+)" % key, text, re.M)
        if m:
            out[key] = [l for l in m.group(1).splitlines() if l.strip().startswith("-")]
        else:
            m2 = re.search(r"^\s*%s:\s*\[(.*?)\]" % key, text, re.M | re.S)
            if m2 and m2.group(1).strip() and m2.group(1).strip() != "...":
                out[key] = [m2.group(1)]
    out["_has_scope_exclude"] = bool(re.search(r"^\s*exclude:\s*(\[.*\S.*\]|\n\s*-\s+\S)",
                                               text, re.M))
    m = re.search(r"^\s*execute_commands:\s*(\S+)", text, re.M)
    out["execute_commands"] = m.group(1) if m else None
    return out


def validate_request(text):
    d = load_yamlish(text)
    for key in REQUEST_REQUIRED:
        if key not in d:
            return fail(key, "required by BrainstormRequest v1 and absent")
    try:
        if int(d["version"]) not in SUPPORTED_VERSIONS:
            return fail("version", "unsupported: %r" % d["version"])
    except (TypeError, ValueError):
        return fail("version", "not an integer: %r" % d["version"])
    if not d["_has_scope_exclude"]:
        return fail("scope.exclude",
                    "required and empty. A worker told what to look at still expands; "
                    "one told what it may not touch has a boundary you can check")
    return 0


def split_front_matter(text):
    m = re.match(r"^\s*---\s*\n(.*?)\n---\s*\n(.*)$", text, re.S)
    if not m:
        return None, text
    meta = {}
    for line in m.group(1).splitlines():
        mm = re.match(r"^([A-Za-z_]+):\s*(.+?)\s*$", line)
        if mm:
            meta[mm.group(1)] = mm.group(2)
    return meta, m.group(2)


def validate_response(text, normalise=False):
    meta, body = split_front_matter(text)
    if meta is None:
        return fail("front matter", "no --- metadata block")
    for key in RESPONSE_META:
        if key not in meta:
            return fail(key, "required by BrainstormResponse v1 and absent")
    try:
        if int(meta["version"]) not in SUPPORTED_VERSIONS:
            return fail("version", "unsupported: %r" % meta["version"])
    except ValueError:
        return fail("version", "not an integer: %r" % meta["version"])
    if meta["decision_status"] not in STATES:
        return fail("decision_status", "not one of %s" % (STATES,))
    if meta["confidence"] not in CONFIDENCE:
        return fail("confidence",
                    "must be high, medium or low. A percentage with no calibration "
                    "behind it is a decoration that reads as rigour")
    for section in RESPONSE_SECTIONS:
        if not re.search(r"^##\s+%s\s*$" % re.escape(section), body, re.M):
            return fail(section,
                        "required section absent. Omitting a risk that does not exist "
                        "is honest; omitting what was never checked is "
                        "indistinguishable from having checked it"
                        if section == "Evidence boundary" else "required section absent")

    # THE ONE CONTRADICTION THAT IS NORMALISED RATHER THAN REJECTED. The worker got
    # the substance right and the metadata wrong; rejecting the whole response would
    # lose the substance.
    if meta["decision_status"] == "ready" and meta.get("user_decision_required") == "true":
        if normalise:
            print("needs_user_input")
            return 0
        return fail("decision_status",
                    "ready with user_decision_required: true is contradictory. "
                    "Normalise to needs_user_input with --normalise rather than "
                    "rejecting: the substance is right and only the metadata is wrong")
    if normalise:
        print(meta["decision_status"])
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("kind", choices=("request", "response"))
    ap.add_argument("path", nargs="?")
    ap.add_argument("--normalise", action="store_true",
                    help="print the effective decision_status, normalising the one "
                         "contradictory pair instead of failing on it")
    args = ap.parse_args()

    text = open(args.path, encoding="utf-8").read() if args.path else sys.stdin.read()
    if args.kind == "request":
        return validate_request(text)
    return validate_response(text, normalise=args.normalise)


if __name__ == "__main__":
    sys.exit(main())

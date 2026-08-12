#!/usr/bin/env python3
"""Every SKILL.md frontmatter must parse as a YAML document, not merely contain
the right strings.

`t4-bro` shipped to main with `description: Sets the register: plain Thai ...`.
An unquoted scalar carrying a colon-space is a nested mapping, which is illegal
there, so the whole document failed to parse and `npx skills` SKIPPED the file
with a warning — the skill installed nowhere. Every assertion in
test-skill-manifest.sh passed on it, because grep sees strings and the installer
sees a document.

CI's skill-discovery job compares the installer's count against the file count
and would have caught it. It never ran: Actions is billing-locked in this repo,
so a CI-only guard is not a guard. Hence this check is local. (#147)

Exit 0 = every frontmatter parses. Exit 1 = one does not, or no parser was
available — a check that cannot check must not pass by default.
"""
import glob
import re
import sys

FM = re.compile(r"^---\r?\n(.*?)\r?\n---\r?\n", re.S)
KEY = re.compile(r"^([A-Za-z0-9_-]+):[ \t]+(.*)$")

try:
    import yaml
    MODE = "pyyaml"
except ImportError:
    yaml = None
    MODE = "fallback"


def defects(path, fm):
    """Return a list of reasons this frontmatter is not a valid YAML document."""
    if MODE == "pyyaml":
        try:
            yaml.safe_load(fm)
        except Exception as exc:                       # noqa: BLE001 - any parse error counts
            return [str(exc).splitlines()[0]]
        return []
    # Dependency-free path: catch the one defect that has actually shipped —
    # an unquoted top-level value carrying a colon-space. Narrower than a real
    # parser, and it says so, rather than implying full coverage.
    found = []
    for line in fm.splitlines():
        m = KEY.match(line)
        if not m:
            continue
        value = m.group(2).strip()
        if value[:1] in ("'", '"'):
            continue
        if ": " in value:
            found.append("unquoted '%s' contains a colon-space" % m.group(1))
    return found


def main():
    print("    parser: %s" % MODE)
    bad = []
    for path in sorted(glob.glob("skills/**/SKILL.md", recursive=True)):
        text = open(path, encoding="utf-8").read()
        m = FM.match(text)
        if not m:
            bad.append((path, "no frontmatter block"))
            continue
        for reason in defects(path, m.group(1)):
            bad.append((path, reason))
    for path, reason in bad:
        print("    %s -> %s" % (path, reason))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())

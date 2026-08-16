#!/usr/bin/env python3
"""Generate the routing table and the classifier's closed list from the skill graph (#183).

Run:  python scripts/generate-routing-table.py            # write hooks/routing-table.json
      python scripts/generate-routing-table.py --check    # exit 1 if the artifact is stale

WHY THIS IS GENERATED AND NOT WRITTEN. A second table maintained by hand is a
second routing universe, and it drifts the day someone edits one and not the
other -- the duplicate-site defect the survey rule exists to catch, built in on
purpose. The source of truth is every `skills/**/SKILL.md` frontmatter.

WHY ONE FILE AND NOT TWO. The issue asks for two artifacts: the routing table and
the classifier's closed list. They are emitted as two keys of one file rather than
two files, because the closed list is exactly the set of names in the table -- two
files would reintroduce the drift this issue exists to remove, one layer down.

WHY THERE IS A THAI MAP IN HERE. The developer writes in Thai. A table built from
English frontmatter matches almost nothing and falls through on nearly every turn,
which is the same as having no table. The Thai terms cannot be derived from the
frontmatter because the frontmatter is English, so they live here -- in the
generator, in ONE place, generated into the artifact. Adding a Thai term is an
edit to this file followed by a regenerate; it is never an edit to the artifact.
"""
import argparse
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARTIFACT = os.path.join(ROOT, "hooks", "routing-table.json")

# Thai trigger terms per skill. English triggers come from the frontmatter; these
# cannot, because the frontmatter is English. Keep them short and specific -- a
# term that matches everything routes everything, which is worse than no route.
THAI_TRIGGERS = {
    "using-t4":              ["ทำยังไง", "ขั้นตอน", "เริ่มงาน", "สกิลไหน"],
    "t4-dev-workflow":       ["เปิด issue", "เปิด pr", "แตก issue", "ทำ prd", "merge"],
    "t4-bro":                ["อธิบาย", "สรุปให้ฟัง", "รายงาน", "ตอบมา"],
    "t4-agent-memory":       ["ค้างอยู่", "ทำถึงไหน", "จำไว้", "บันทึกไว้"],
    "t4-afk":                ["ทำต่อเลย", "จัดการให้หมด", "ไม่ต้องถาม", "เคลียร์คิว"],
    "t4-engineering-records": ["บันทึกการตัดสินใจ", "post-mortem", "adr"],
    "t4-project-bootstrap":  ["ตั้ง repo", "ติดตั้งมาตรฐาน", "repo ใหม่"],
    "karpathy-guidelines":   ["เขียนโค้ด", "แก้โค้ด", "refactor"],
    "using-clink":           ["ส่งให้ ai อื่น", "ถามตัวอื่น", "delegate"],
    "clink-brainstorm":      ["ระดมความคิด", "ขอความเห็น", "หลายโมเดล", "brainstorm"],
    "clink-subagents":       ["แบ่งงาน", "ให้ตัวอื่นทำ", "subagent"],
    "clink-debug":           ["หาบั๊ก", "ทำไมพัง", "debug"],
    "clink-masteragent":     ["เลือกโมเดล", "ใครควรทำ", "โมเดลไหน"],
    "ask-xeno":              ["มีสกิลไหม", "ใช้สกิลอะไร", "ไม่รู้จะใช้อะไร"],
    "using-design":          ["ออกแบบ", "หน้าเว็บ", "ui", "ดีไซน์"],
    "design-audit":          ["ตรวจดีไซน์", "รีวิว ui"],
    "design-psychology":     ["จิตวิทยาการออกแบบ"],
    "design-rules":          ["กฎการออกแบบ", "typography", "สี"],
    "design-setup":          ["เริ่มโปรเจกต์ดีไซน์", "ตั้งค่าดีไซน์"],
}

# Phase words and the route each IMPLIES (#191). A prompt can match one skill
# cleanly and still carry a word saying the work is at a different phase -- and a
# table that only reports what it matched cannot notice that. These live here for
# the same reason the Thai terms do: they are not derivable from the frontmatter,
# so they belong in the generator, in ONE place, generated into the artifact.
#
# THEY ARE DELIBERATELY NOT TRIGGERS. A trigger says "this prompt is about X"; a
# phase word says "whatever this prompt is about, the work is at phase Y". Promoting
# these to triggers would make every "ship it" route to t4-dev-workflow outright,
# which is the over-broad matching the weak-trigger rule exists to catch.
# `merge` is absent on purpose -- it is already a Thai trigger of t4-dev-workflow,
# so the table catches it and there is nothing for a phase word to add.
PHASE_WORDS = {
    "ship":        "t4-dev-workflow",      # the issue/PR/gate lifecycle
    "ปิด issue":    "t4-dev-workflow",
    "handoff":     "t4-agent-memory",      # session end
    "จบ session":  "t4-agent-memory",
    "unattended":  "t4-afk",
    "ปล่อยไว้":     "t4-afk",
}

def read_frontmatter(path):
    """-> (name, description) or None. Deliberately tolerant: a malformed skill is
    skipped rather than fatal, because this runs in a test and a broken SKILL.md
    should fail that skill's own suite, not this generator."""
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read()
    except OSError:
        return None
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.S)
    if not m:
        return None
    block = m.group(1)
    name = re.search(r"^name:\s*(.+?)\s*$", block, re.M)
    desc = re.search(r"^description:\s*(.+?)\s*$", block, re.M | re.S)
    if not name:
        return None
    return name.group(1).strip(), (desc.group(1).strip() if desc else "")


def english_triggers(name, description):
    """The skill's own name and its parts, plus the quoted phrases of its
    `Triggers include ...` sentence where the frontmatter has one.

    NOT every word of the description. That was the first version and it was
    over-broad: three skills mention "issue", so a prompt containing that word
    routed to all three and the notice named two skills that were never required.
    False positives are not the safe direction here -- a notice that cries wolf
    gets ignored, and its true findings go with it. Description-wide matching is
    the CLASSIFIER's job (#187), which is allowed to be fuzzy because it returns a
    score; this table is the cheap deterministic half and has to be narrow."""
    out = {name.lower()}
    out.update(p for p in name.lower().split("-") if len(p) > 2)
    m = re.search(r"[Tt]riggers include(.+?)(?:\.\s|$)", description, re.S)
    if m:
        for phrase in re.findall(r'"([^"]+)"', m.group(1)):
            phrase = phrase.strip().lower()
            if len(phrase) > 3:
                out.add(phrase)
    return sorted(out)


def build():
    routes = []
    for dirpath, _dirnames, filenames in os.walk(os.path.join(ROOT, "skills")):
        if "SKILL.md" not in filenames:
            continue
        fm = read_frontmatter(os.path.join(dirpath, "SKILL.md"))
        if not fm:
            continue
        name, description = fm
        routes.append({
            "skill": name,
            # A FAMILY ENTRY is a top-of-family router. Marked here, derived from the
            # naming convention, so the hook never carries its own second list of
            # which skills are entries -- that would be the drift this file removes.
            "family": name == "ask-xeno" or name.startswith("using-"),
            "path": os.path.relpath(os.path.join(dirpath, "SKILL.md"), ROOT).replace("\\", "/"),
            "triggers_en": english_triggers(name, description),
            "triggers_th": THAI_TRIGGERS.get(name, []),
        })
    routes.sort(key=lambda r: r["skill"])
    return {
        "generated_by": "scripts/generate-routing-table.py",
        "source": "skills/**/SKILL.md frontmatter",
        "note": "Generated. Do not hand-edit -- regenerate. Thai terms live in the generator.",
        "skills": [r["skill"] for r in routes],     # the classifier's closed list
        "routes": routes,                           # the routing table
        # Only the phase words whose implied skill actually exists. A phase word
        # pointing at a skill that was renamed away would make every prompt carrying
        # it look like a mismatch, forever.
        "phases": {w: s for w, s in sorted(PHASE_WORDS.items())
                   if s in {r["skill"] for r in routes}},
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true",
                    help="exit 1 if the committed artifact disagrees with the skill graph")
    args = ap.parse_args()

    fresh = json.dumps(build(), indent=2, ensure_ascii=False) + "\n"

    if args.check:
        try:
            with open(ARTIFACT, encoding="utf-8") as f:
                on_disk = f.read()
        except OSError:
            print("routing-table.json is missing -- run scripts/generate-routing-table.py",
                  file=sys.stderr)
            return 1
        if on_disk != fresh:
            print("routing-table.json disagrees with the skill graph -- regenerate it",
                  file=sys.stderr)
            return 1
        return 0

    with open(ARTIFACT, "w", encoding="utf-8", newline="\n") as f:
        f.write(fresh)
    print("wrote %s (%d skills)" % (os.path.relpath(ARTIFACT, ROOT), len(build()["skills"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())

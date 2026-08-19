#!/usr/bin/env bash
# The bootstrap session is the one session with no T4 wiring, so it must load the
# disciplines itself (#244).
#
# A documentation-integrity suite, and labelled one: it detects deletion and softening of the
# rule. It cannot detect an agent skipping the step anyway -- nothing can, which is the whole
# finding. #244 is a report of exactly that: `ask-xeno` was invoked, `using-t4` was never
# entered, and several thousand words of Thai went to the developer with `t4-bro` never loaded.
#
# WHY THE STEP CANNOT BE REPLACED BY THE HOOK THAT EXISTS FOR THIS. Every mechanism that
# surfaces the disciplines -- the `.claude/t4.json` marker, the session-start injection, the
# `CLAUDE.md` standing default, the snapshot -- is an artifact THIS SKILL INSTALLS, in steps 3
# and 6. During the bootstrap session none of them exist yet. The wiring that would have loaded
# `using-t4` is the thing being written, and it cannot fire before it is written.
#
# So the step and the hook cover DIFFERENT SESSIONS, and the file has to say so: a maintainer
# reading them as duplicates deletes the step, and the deletion is invisible because the output
# of a bootstrap that skipped the disciplines is byte-identical to one that followed them.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/t4/t4-project-bootstrap/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$SKILL" ] && ok "t4-project-bootstrap is present" || { bad "the skill is missing"; exit 1; }

echo ""
echo "BOTH SKILLS ARE NAMED, AS SOMETHING TO INVOKE, before the repo is read:"
# Scoped to the first prerequisite rather than to the file. `using-t4` appears elsewhere here as
# prose about what step 3 WRITES INTO CLAUDE.md -- a different claim, and a file-wide assertion
# would pass on a file with this step deleted.
PYTHONIOENCODING=utf-8 python - "$SKILL" <<'PY'
import sys, re
doc = open(sys.argv[1], encoding="utf-8").read()

# The instruction must be an invocation, not a mention. `using-t4` appears elsewhere in this
# file as prose about what step 3 WRITES INTO CLAUDE.md -- that is a different claim, and an
# assertion that matched it would pass on a file with the step deleted.
m = re.search(r"^###\s*1\..*$", doc, re.M)
assert m, "the 'Before you start' section has no first subsection"
head = doc[m.start(): m.start() + 2600]
assert "t4-bro" in head, "t4-bro is not in the FIRST prerequisite -- it is not what opens the procedure"
assert "using-t4" in head, "using-t4 is not in the first prerequisite"
assert re.search(r"\binvoke\b", head, re.I), "the first prerequisite never says to invoke anything"

# It has to come before reading the target repo, which is step 1 of the procedure.
proc = doc.find("## Bootstrap procedure")
assert proc != -1 and m.start() < proc, "the step does not precede the bootstrap procedure"

# The reason has to be on the page, or a maintainer deletes it as redundant with the hook.
assert re.search(r"(cannot have fired|cannot fire|does not exist yet|none of them exist)", head, re.I), \
    "the step does not say WHY it exists -- that the wiring installed later cannot have fired yet"

# And the two must be distinguished as covering different sessions, not as duplicates.
assert re.search(r"different sessions?|not a duplicate|not duplicates", head, re.I), \
    "the step and the session-start hook are not documented as covering different sessions"
PY
[ $? -eq 0 ] && ok "using-t4 and t4-bro are both invoked in the opening step, with its rationale" \
             || bad "the opening step is missing, is a mention rather than an invocation, or has no rationale"

echo ""
echo "THE COUNT THIS RULE REPLACED IS GONE, not sitting beside the new one:"
# The section carried two prerequisites before this rule and now carries three. A suite that
# only asserts the new sentence stays green while the old count sits one line above it, and the
# skill contradicts itself in the file an agent loads. This is the assertion that retires it.
hasnt "$SKILL" "Two prerequisites, and both fail" "the two-prerequisite count is retired, not duplicated"
has   "$SKILL" "Three prerequisites"              "and the section counts three"

echo ""
echo "the audit #244 asked for is on the page, not left implied:"
has "$SKILL" "before the wiring exists" "the pre-wiring audit is stated"

echo ""
echo "bootstrap-disciplines-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

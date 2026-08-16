#!/usr/bin/env bash
# The loaded skill's version, and what a mismatch resolves to (#200).
#
# THE FAILURE THIS PREVENTS. This repository edits its own skills constantly. Without
# a version, a reviewer at a later segment checks version B's declared traces against
# behaviour produced under version A, and reports a violation THAT NEVER HAPPENED.
# The check has to be deterministic and the mismatch has to be visible, not silent.
#
# THERE IS NO `version:` FIELD IN ANY SKILL.md, so the version is the sha of the file
# itself -- the same mechanism the trace rows already use for rule text. Nothing is
# invented: a version nobody maintains is a version that lies.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude/hooks" "$REPO/docs/research" "$REPO/skills/t4/t4-afk"
for f in t4-reviewer t4-segment t4-review-state; do
  cp "$REPO_ROOT/hooks/$f" "$REPO/.claude/hooks/" 2>/dev/null
done

SKILL="$REPO/skills/t4/t4-afk/SKILL.md"
RULE='Red before green.'
TRACE='a failing-test record appears BEFORE the record that adds the implementation'

write_skill() { printf '%s\n' "$1" > "$SKILL"; }
# The trace file as the generator writes it: a version table, then the traces.
write_traces() { python - "$REPO/docs/research/rule-traces.md" "$SKILL" "$RULE" "$TRACE" <<'PY'
import hashlib, sys
out, skill, rule, trace = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
ver = hashlib.sha256(open(skill, "rb").read()).hexdigest()[:12]
with open(out, "w", encoding="utf-8", newline="\n") as f:
    f.write("# Rule traces\n\n## Skill versions\n\n")
    f.write("| skill | version | path |\n|---|---|---|\n")
    f.write("| `t4-afk` | `%s` | `skills/t4/t4-afk/SKILL.md` |\n\n" % ver)
    f.write("## Traces\n\n| id | skill | state | rule | trace / reason |\n|---|---|---|---|---|\n")
    f.write("| `t4-afk/aaaaaaaaaaaa` | `t4-afk` | traced | %s | %s |\n" % (rule, trace))
PY
}
cfg() { python - "$REPO/.claude/t4.json" "$1" <<'PY'
import json, sys
with open(sys.argv[1], "w", encoding="utf-8", newline="\n") as f:
    json.dump({"t4": True, "reviewer": sys.argv[2]}, f)
PY
}
cat > "$TMP/t.jsonl" <<'JSONL'
{"type":"user","uuid":"u1","message":{"content":"do the thing"}}
{"type":"assistant","uuid":"a1","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"git commit"}}]}}
JSONL
VERDICT='{"verdicts":[{"rule":"Red before green.","verdict":"violated","record":"a1","uuid":"a1"}]}'
run()   { (cd "$REPO" && bash .claude/hooks/t4-reviewer "$TMP/t.jsonl" 2>/dev/null); }
reset() { rm -f "$REPO/.claude/t4-review-state.json"; }
state() { python - "$REPO/.claude/t4-review-state.json" "$1" <<'PY'
import json, os, sys
p, e = sys.argv[1], sys.argv[2]
d = json.load(open(p, encoding="utf-8")) if os.path.exists(p) else {}
try:
    print(eval(e, {"d": d}))
except Exception as ex:
    print("<%s>" % ex)
PY
}

[ -f "$REPO_ROOT/hooks/t4-reviewer" ] && ok "the reviewer exists" \
  || bad "hooks/t4-reviewer is missing; the absence assertions below are vacuous"

echo ""
echo "THE GENERATOR PUBLISHES A VERSION PER SKILL, and it is the file's own sha:"
grep -q "Skill versions" "$REPO_ROOT/docs/research/rule-traces.md" \
  && ok "rule-traces.md carries a skill-version table" || bad "no version table in the generated file"
python - "$REPO_ROOT" <<'PY'
import hashlib, re, sys, os
root = sys.argv[1]
doc = open(os.path.join(root, "docs/research/rule-traces.md"), encoding="utf-8").read()
rows = re.findall(r"^\| `([^`]+)` \| `([0-9a-f]{12})` \| `([^`]+)` \|$", doc, re.M)
assert rows, "no version rows parsed"
for skill, ver, path in rows:
    real = hashlib.sha256(open(os.path.join(root, path), "rb").read()).hexdigest()[:12]
    assert ver == real, "%s: published %s, file is %s" % (skill, ver, real)
print("    %d skills, every published version matches its file" % len(rows))
PY
[ $? -eq 0 ] && ok "and every published version is the sha of the file it names" \
             || bad "a published version does not match its file"

echo ""
echo "MATCHING VERSION -- the verdict stands, and the row records which version:"
write_skill "the original skill body"; write_traces
reset; cfg "cat >/dev/null; printf '%s' '$VERDICT'"; run
[ "$(state 'len(d.get("findings",[]))')" = "1" ] && ok "a violation is raised under the version it was written for" \
                                                 || bad "no finding: $(state 'd')"

echo ""
echo "A SKILL EDITED BETWEEN TWO SEGMENTS OF ONE SESSION:"
# Segment one under the original body; segment two after the edit, traces untouched --
# which is exactly the state this repo is in every time someone changes a skill and has
# not re-run the generator yet.
write_skill "the skill body, edited mid-session"
reset; run
[ "$(state 'len(d.get("findings",[]))')" = "0" ] \
  && ok "a mismatch NEVER yields a finding" || bad "a stale version produced a finding"
[ "$(state 'len(d.get("unknown",[]))')" = "1" ] \
  && ok "it resolves to unknown instead" || bad "it did not open an unknown row: $(state 'd')"
case "$(state 'd["unknown"][0].get("reason","")')" in
  *edited*|*version*) ok "and the row STATES the reason, so the gap is visible not silent";;
  *) bad "the unknown row does not say why: $(state 'd["unknown"][0]')";;
esac
[ "$(state 'len(str(d["unknown"][0].get("version","")))')" = "12" ] \
  && ok "the row records the version it was judged against" || bad "no version on the row"

echo ""
echo "AND IT IS THE EDIT THAT DID IT -- restoring the file restores the verdict:"
# The control. Without it, 'always unknown' passes every assertion above.
write_skill "the original skill body"
reset; run
[ "$(state 'len(d.get("findings",[]))')" = "1" ] \
  && ok "the same segment and the same verdict raise a finding again" \
  || bad "the reviewer is stuck on unknown regardless of the version"

echo ""
echo "skill-version: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

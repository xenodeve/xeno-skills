#!/usr/bin/env bash
# Following a native delegation into its own transcript (#201).
#
# THE ISSUE'S STATED JOIN IS WRONG, AND THIS FILE IS WHERE THAT IS RECORDED. #201 says
# *"the agent id appears in the master's own transcript and is the filename, so the join
# costs a glob"*. Measured against a real 39-delegation session
# (`D--Github-MangaDock/a585a091-.../`): the agent id appears **zero** times in the
# master transcript, and the `toolUseId` in the sidecar's `.meta.json` appears **four**
# times -- same file, same run, which is the control that makes the zero mean something.
#
# So the join runs the other way: `tool_use.id` in the master -> `toolUseId` in
# `<session>/subagents/agent-*.meta.json` -> the sibling `.jsonl`. All 39 meta files
# carried the key. The issue already warns that an earlier draft got the delegation
# story wrong from a listing that did not descend; this is the same error one layer down.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-follow-delegation"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
PROJ="$TMP/proj"; SESSION="$PROJ/sess"; SUB="$SESSION/subagents"
mkdir -p "$SUB"
MASTER="$PROJ/sess.jsonl"
: > "$MASTER"

# A delegation as this harness actually writes it: the spawn tool's `id` is a
# `toolu_...`, and the sidecar meta is what points back at it.
delegate() { # <tool-use-id> <agent-id> <tool-name>
  printf '{"agentType":"general-purpose","description":"d","toolUseId":"%s","spawnDepth":1}\n' \
    "$1" > "$SUB/$2.meta.json"
  printf '{"type":"assistant","uuid":"s-%s","message":{"content":[{"type":"text","text":"worker %s ran the tests"}]}}\n' \
    "$2" "$2" > "$SUB/$2.jsonl"
}
spawn_record() { # <tool-use-id> <tool-name>
  printf '{"type":"assistant","uuid":"m1","message":{"content":[{"type":"tool_use","id":"%s","name":"%s","input":{"prompt":"go"}}]}}\n' "$1" "$2"
}
follow() { bash "$HOOK" "$MASTER" 2>/dev/null; }
field() { python - "$1" "$2" <<'PY'
import json, sys
try:
    d = json.loads(sys.argv[1])
except Exception:
    print("<unparseable>"); raise SystemExit
try:
    print(eval(sys.argv[2], {"d": d}))
except Exception as e:
    print("<%s>" % e)
PY
}

[ -f "$HOOK" ] && ok "the follower exists -- the absence assertions below mean something" \
               || bad "hooks/t4-follow-delegation is missing"

echo ""
echo "ONE DELEGATION -- resolved to its transcript and read:"
delegate "toolu_A" "agent-aaa" "Agent"
out="$(spawn_record toolu_A Agent | follow)"
[ "$(field "$out" 'len(d["followed"])')" = "1" ] && ok "one delegation followed" || bad "not followed: $out"
case "$(field "$out" 'd["followed"][0]["records"][0]["message"]["content"][0]["text"]')" in
  *"worker agent-aaa ran the tests"*) ok "and its records are actually read, not just located";;
  *) bad "the subagent's records were not read";;
esac
[ "$(field "$out" 'd["followed"][0]["agent"]')" = "agent-aaa" ] \
  && ok "the evidence names WHICH side of the boundary it came from" || bad "the source is not named"
[ "$(field "$out" 'len(d["missing"])')" = "0" ] && ok "nothing missing" || bad "a resolvable id was called missing"

echo ""
echo "SEVERAL IN ONE SEGMENT, across two harnesses' spawn names:"
delegate "toolu_B" "agent-bbb" "Agent"
delegate "toolu_C" "agent-ccc" "Task"
out="$( { spawn_record toolu_A Agent; spawn_record toolu_B spawn_agent; spawn_record toolu_C Task; } | follow)"
[ "$(field "$out" 'len(d["followed"])')" = "3" ] && ok "three delegations, three transcripts" \
  || bad "followed $(field "$out" 'len(d["followed"])') of 3"
[ "$(field "$out" 'sorted(x["agent"] for x in d["followed"])')" = "['agent-aaa', 'agent-bbb', 'agent-ccc']" ] \
  && ok "each is joined to its own file, not to the first one found" || bad "the join is not per-delegation"

echo ""
echo "AN AGENT ID WITH NO MATCHING FILE -- reported missing, never guessed at:"
out="$( { spawn_record toolu_A Agent; spawn_record toolu_GONE Agent; } | follow)"
[ "$(field "$out" 'd["missing"]')" = "['toolu_GONE']" ] && ok "the unresolvable one is named" \
  || bad "missing was $(field "$out" 'd["missing"]')"
[ "$(field "$out" 'len(d["followed"])')" = "1" ] \
  && ok "and the resolvable one is still followed -- one absence does not blind the segment" \
  || bad "a single missing file discarded the whole segment"

echo ""
echo "THE NEGATIVE THAT KEEPS THE REST HONEST -- a non-spawn tool is not followed:"
out="$(printf '%s\n' '{"type":"assistant","uuid":"m1","message":{"content":[{"type":"tool_use","id":"toolu_A","name":"Bash","input":{"command":"ls"}}]}}' | follow)"
[ "$(field "$out" 'len(d["followed"])')" = "0" ] \
  && ok "a Bash record with a resolvable id is not a delegation" \
  || bad "it followed a tool that spawns nothing -- the id alone was treated as the signal"

echo ""
echo "AND THE REVIEWER USES IT -- the two criteria that live on the other side:"
REPO="$TMP/repo"; mkdir -p "$REPO/.claude/hooks" "$REPO/docs/research"
for f in t4-reviewer t4-segment t4-review-state t4-follow-delegation; do
  cp "$REPO_ROOT/hooks/$f" "$REPO/.claude/hooks/" 2>/dev/null
done
cp "$REPO_ROOT/docs/research/rule-traces.md" "$REPO/docs/research/"
SEEN="$TMP/seen.json"
RULE="$(python - "$REPO/docs/research/rule-traces.md" <<'PY'
import re, sys
doc = open(sys.argv[1], encoding="utf-8").read().split("## Traces", 1)[1]
print(re.search(r"^\| `[^`]+` \| `[^`]+` \| traced \| (.+?) \| ", doc, re.M).group(1).strip())
PY
)"
mkcfg() { python - "$REPO/.claude/t4.json" "$1" <<'PY'
import json, sys
with open(sys.argv[1], "w", encoding="utf-8", newline="\n") as f:
    json.dump({"t4": True, "reviewer": sys.argv[2]}, f)
PY
}
rstate() { python - "$REPO/.claude/t4-review-state.json" "$1" <<'PY'
import json, os, sys
p, e = sys.argv[1], sys.argv[2]
d = json.load(open(p, encoding="utf-8")) if os.path.exists(p) else {}
try:
    print(eval(e, {"d": d}))
except Exception as ex:
    print("<%s>" % ex)
PY
}
review() { (cd "$REPO" && bash .claude/hooks/t4-reviewer "$MASTER" 2>/dev/null); }

# A resolvable delegation: the worker's records must reach the reviewer, tagged.
{ printf '%s\n' '{"type":"user","uuid":"u1","message":{"content":"go"}}'; spawn_record toolu_A Agent; } > "$MASTER"
rm -f "$REPO/.claude/t4-review-state.json"
mkcfg "cat > '$SEEN'; printf '%s' '{\"verdicts\":[]}'"
review
payload="$(cat "$SEEN" 2>/dev/null || true)"
case "$payload" in *"worker agent-aaa ran the tests"*) ok "the subagent's records reach the reviewer";; *) bad "the delegated evidence never arrived";; esac
# Parsed, not grepped: json.dump's default separators put a space after the colon, so a
# literal `"t4_source":"..."` misses a payload that carries the tag perfectly well.
python - "$SEEN" <<'PY'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
tagged = [r for r in d["segment"] if r.get("t4_source") == "subagent:agent-aaa"]
assert tagged, "no record carries the subagent tag"
assert any(not r.get("t4_source") for r in d["segment"]), \
    "everything is tagged as delegated -- the master's own records lost their identity"
PY
[ $? -eq 0 ] && ok "tagged with which side of the boundary produced it, and only that side" \
             || bad "the delegated evidence is untagged, or the tag swallowed the master's"

# An unreadable delegation: a violation is downgraded, not reported.
{ printf '%s\n' '{"type":"user","uuid":"u1","message":{"content":"go"}}'; spawn_record toolu_GONE Agent; } > "$MASTER"
rm -f "$REPO/.claude/t4-review-state.json"
mkcfg "cat >/dev/null; printf '%s' '{\"verdicts\":[{\"rule\":\"$RULE\",\"verdict\":\"violated\",\"record\":\"m1\",\"uuid\":\"m1\"}]}'"
review
[ "$(rstate 'len(d.get("findings",[]))')" = "0" ] && ok "an unreadable delegation yields NO finding" \
  || bad "a violation was reported on evidence known to be incomplete"
[ "$(rstate 'len(d.get("unknown",[]))')" = "1" ] && ok "it resolves to unknown" || bad "no unknown row: $(rstate 'd')"
case "$(rstate 'd["unknown"][0].get("reason","")')" in
  *"could not be read"*) ok "and says so on the row";;
  *) bad "the unknown row does not say why";;
esac
# The control: with the SAME verdict and a resolvable delegation, the finding returns.
{ printf '%s\n' '{"type":"user","uuid":"u1","message":{"content":"go"}}'; spawn_record toolu_A Agent; } > "$MASTER"
rm -f "$REPO/.claude/t4-review-state.json"
review
[ "$(rstate 'len(d.get("findings",[]))')" = "1" ] \
  && ok "and a readable one raises it again -- not simply stuck on unknown" \
  || bad "the reviewer no longer raises anything at all"

: > "$MASTER"

echo ""
echo "guards:"
out="$(printf '%s' 'not json' | bash "$HOOK" "$MASTER" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "unparseable input: exit zero" || bad "unparseable input: exit $rc"
out="$(spawn_record toolu_A Agent | bash "$HOOK" "$TMP/nope.jsonl" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "a master path with no sidecar directory: exit zero" || bad "exit $rc"

echo ""
echo "follow-delegation: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

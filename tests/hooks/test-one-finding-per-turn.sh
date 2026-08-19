#!/usr/bin/env bash
# At most one finding per turn, ranked by the earliest missing step (#223).
#
# A segment can fail several traces at once and nothing decided which one the
# master hears. Injecting all of them turns a correction into a wall of text that
# gets skimmed -- and nothing here blocks anything, so a reviewer that produces four
# objections in one turn has spent the master's attention and bought nothing.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
# The op reads the trace file relative to the state file's parent, so mirror the
# real layout: <repo>/.claude/<state> and <repo>/docs/research/rule-traces.md
REPO="$TMP/repo"; mkdir -p "$REPO/.claude/hooks" "$REPO/docs/research"
printf '{"t4":true}\n' > "$REPO/.claude/t4.json"
cp "$REPO_ROOT/hooks/t4-review-state" "$REPO/.claude/hooks/t4-review-state"
cp "$REPO_ROOT/docs/research/rule-traces.md" "$REPO/docs/research/rule-traces.md"

st() { (cd "$REPO" && printf '%s' "$1" | bash .claude/hooks/t4-review-state 2>&1); }

# Two rules whose order in the trace file is known, plus one that is not in it.
EARLY="$(python - "$REPO/docs/research/rule-traces.md" <<'PY'
import re,sys
b=open(sys.argv[1],encoding='utf-8').read().split('## Traces',1)[1]
rows=[re.match(r"^\| `[^`]+` \| `[^`]+` \| \S+ \| (.+?) \|", l) for l in b.splitlines()]
rows=[m.group(1).strip() for m in rows if m]
print(rows[0])
PY
)"
LATE="$(python - "$REPO/docs/research/rule-traces.md" <<'PY'
import re,sys
b=open(sys.argv[1],encoding='utf-8').read().split('## Traces',1)[1]
rows=[re.match(r"^\| `[^`]+` \| `[^`]+` \| \S+ \| (.+?) \|", l) for l in b.splitlines()]
rows=[m.group(1).strip() for m in rows if m]
print(rows[-1])
PY
)"

mkfinding() { st "{\"op\":\"open\",\"rule\":\"$1\",\"record\":1,\"uuid\":\"u\"}" >/dev/null
              st "{\"op\":\"violate\",\"rule\":\"$1\"}" >/dev/null; }

echo "with nothing open it says nothing:"
out="$(st '{"op":"next"}')"
[ -z "$out" ] && ok "no findings -> no output" || bad "emitted: $out"

echo ""
echo "four failing traces deliver exactly one finding:"
mkfinding "$LATE"; mkfinding "$EARLY"; mkfinding "zzz-not-in-the-trace-file"
out="$(st '{"op":"next"}')"
n=$(printf '%s' "$out" | grep -c '"finding"')
[ "$n" = "1" ] && ok "exactly one finding is returned" || bad "returned $n findings"

echo ""
echo "the one delivered is the earliest by workflow position, not by discovery order:"
case "$out" in *"$EARLY"*) ok "the earliest-ranked rule wins over the one violated first";;
  *) bad "expected the early rule, got: ${out:0:100}";; esac

echo ""
echo "the others remain -- they are not discarded:"
python - "$REPO/.claude/t4-review-state.json" <<'PY'
import json,sys
s=json.load(open(sys.argv[1],encoding='utf-8'))
assert len(s["findings"]) == 3, "expected 3 findings kept, got %d" % len(s["findings"])
assert not s["decided"], "nothing should have been decided by a read"
PY
[ $? -eq 0 ] && ok "all three findings are still recorded, none discarded" || bad "findings were lost"

echo ""
echo "an unranked rule never jumps ahead of a ranked one:"
case "$out" in *"zzz-not-in-the-trace-file"*) bad "an unranked rule was promoted";; *) ok "unranked sorts last";; esac

echo ""
echo "dismissing the first promotes the next, and only then:"
fid="$(printf '%s' "$out" | python -c 'import json,sys; print(json.load(sys.stdin)["finding"])')"
st "{\"op\":\"dismiss\",\"finding\":\"$fid\",\"reason\":\"misread\"}" >/dev/null
out2="$(st '{"op":"next"}')"
[ -n "$out2" ] && ok "a second finding becomes available after the first is decided" || bad "nothing followed"
case "$out2" in *"$fid"*) bad "the dismissed finding was re-raised";; *) ok "the dismissed one is not re-raised";; esac

echo ""
echo "the ranking is a stated function, not a model call:"
grep -q "INDEX IN THE GENERATED TRACE FILE" "$REPO_ROOT/hooks/t4-review-state" \
  && ok "the rank is documented where it is implemented" || bad "the ranking rule is not stated"
grep -qiE "model|prompt|llm|anthropic" "$REPO_ROOT/hooks/t4-subagent-stop" \
  && bad "a model call leaked into the boundary hook" || ok "no model call anywhere in the path"

echo ""
echo "one-finding-per-turn: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

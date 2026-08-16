#!/usr/bin/env bash
# hooks/t4-reviewer -- the reviewer call itself (#198).
#
# Seam: `t4-reviewer [--detach] <transcript>` -> verdicts written through the state
# machine's legal transitions. Nothing is returned to the caller; the finding reaches
# the master later, through delivery.
#
# THE FIVE VERDICTS AND THE THREE ROW STATES ARE NOT THE SAME VOCABULARY, so the
# mapping is asserted rather than assumed: satisfied and violated close a row,
# partial and delegated leave it PENDING (which is exactly what pending was defined
# as -- a half-seen trace carried across a segment boundary), and unknown opens an
# unknown row. No sixth transition is invented for any of them.
#
# AND A VERDICT WITHOUT A CITATION IS DROPPED. Every row must cite the record it
# rests on (#222); a reviewer that returns a verdict and no record gets that verdict
# discarded, never a citation invented for it.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude/hooks" "$REPO/docs/research"
for f in t4-reviewer t4-segment t4-review-state; do
  [ -f "$REPO_ROOT/hooks/$f" ] && cp "$REPO_ROOT/hooks/$f" "$REPO/.claude/hooks/"
done
cp "$REPO_ROOT/docs/research/rule-traces.md" "$REPO/docs/research/"

SEEN="$TMP/seen.json"          # what the reviewer was handed
CWD="$TMP/cwd.txt"             # where it was run from

cfg() { python - "$REPO/.claude/t4.json" "${1:-}" <<'PY'
import json, sys
path, command = sys.argv[1], sys.argv[2]
c = {"t4": True}
if command:
    c["reviewer"] = command
with open(path, "w", encoding="utf-8", newline="\n") as f:
    json.dump(c, f)
PY
}
# A stub "reviewer": records what it was given and where, then answers verbatim.
stub() { printf "cat > '%s'; pwd > '%s'; printf '%%s' '%s'" "$SEEN" "$CWD" "$1"; }

# A transcript with one tool-use record, which is what makes a segment reviewable.
mk_transcript() {
  cat > "$TMP/t.jsonl" <<'JSONL'
{"type":"user","uuid":"u1","message":{"content":"do the thing"}}
{"type":"assistant","uuid":"a1","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"git commit"}}]}}
JSONL
  printf '%s' "$TMP/t.jsonl"
}
run() { (cd "$REPO" && bash .claude/hooks/t4-reviewer "$@" 2>/dev/null); }
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
reset() { rm -f "$REPO/.claude/t4-review-state.json" "$SEEN" "$CWD"; }
T="$(mk_transcript)"

# Named first, because most of what follows asserts an ABSENCE -- no finding, no row,
# no call -- and every one of those passes when the script is missing. Fifteen of them
# did, on the run before it existed. This is the assertion that says why.
[ -x "$REPO_ROOT/hooks/t4-reviewer" ] || [ -f "$REPO_ROOT/hooks/t4-reviewer" ] \
  && ok "the reviewer exists -- the absence assertions below mean something" \
  || bad "hooks/t4-reviewer is missing; every absence assertion below is vacuous"

echo ""
echo "OFF BY DEFAULT -- with no reviewer configured it does not run at all:"
reset; cfg ''
run "$T"
[ ! -f "$SEEN" ] && ok "the reviewer was never invoked" || bad "it ran while unconfigured"
[ ! -f "$REPO/.claude/t4-review-state.json" ] && ok "and no state was written" || bad "state was written"

echo ""
echo "WHAT IT IS HANDED: the segment and the declared traces, and nothing else:"
reset; cfg "$(stub '{"verdicts":[]}')"
run "$T"
[ -f "$SEEN" ] && ok "it was invoked" || bad "it was not invoked"
payload="$(cat "$SEEN" 2>/dev/null || true)"
case "$payload" in *"git commit"*) ok "the segment is in the payload";; *) bad "no segment: ${payload:0:80}";; esac
case "$payload" in *"appears BEFORE the record"*) ok "and the declared traces are too";; *) bad "no traces in the payload";; esac
# NOT A SANDBOX, AND IT DOES NOT CLAIM TO BE. What is enforceable is that the payload
# carries no path into the repository and the command runs from outside it, so a
# relative path resolves nowhere. Whether a configured command reaches the repo by
# absolute path is the operator's choice, and saying so beats claiming containment.
case "$payload" in *"$REPO"*) bad "the payload leaks a repository path";; *) ok "no repository path is in the payload";; esac
case "$(cat "$CWD" 2>/dev/null || true)" in
  *repo*) bad "it ran inside the repository";;
  "") bad "no cwd recorded";;
  *) ok "and it runs from outside the repository";;
esac

echo ""
echo "THE FIVE VERDICTS MAP ONTO THE LEGAL TRANSITIONS, and onto no others:"
V='{"rule":"%s","verdict":"%s","record":"a1","uuid":"a1"}'
verd() { printf "{\"verdicts\":[$V]}" "$1" "$2"; }

reset; cfg "$(stub "$(verd 'Red before green.' satisfied)")"; run "$T"
[ "$(state 'len(d.get("findings",[]))')" = "0" ] && ok "satisfied: no finding" || bad "satisfied raised a finding"
[ "$(state 'len(d.get("active",[]))')" = "0" ] && ok "satisfied: the row is closed, not left open" || bad "the row stayed open"

reset; cfg "$(stub "$(verd 'Red before green.' violated)")"; run "$T"
[ "$(state 'len(d.get("findings",[]))')" = "1" ] && ok "violated: exactly one finding" || bad "violated: $(state 'd.get("findings")')"
[ "$(state 'd["findings"][0]["rule"]')" = "Red before green." ] && ok "and it names the rule" || bad "the finding does not name the rule"
[ "$(state 'd["findings"][0]["uuid"]')" = "a1" ] && ok "and cites the record it rests on" || bad "the finding is uncited"

reset; cfg "$(stub "$(verd 'Red before green.' partial)")"; run "$T"
[ "$(state 'len(d.get("pending",[]))')" = "1" ] && ok "partial: a pending row, carried to the next segment" || bad "partial did not become pending"
[ "$(state 'len(d.get("findings",[]))')" = "0" ] && ok "and no finding" || bad "partial raised a finding"

reset; cfg "$(stub '{"verdicts":[{"rule":"Red before green.","verdict":"delegated","record":"a1","uuid":"a1","source":"clink:codex"}]}')"; run "$T"
[ "$(state 'len(d.get("pending",[]))')" = "1" ] && ok "delegated: pending, because the trace continues elsewhere" || bad "delegated did not become pending"
[ "$(state 'd["pending"][0]["source"]')" = "clink:codex" ] && ok "and it names WHOSE transcript holds the rest" || bad "the delegate is not named"

reset; cfg "$(stub "$(verd 'Red before green.' unknown)")"; run "$T"
[ "$(state 'len(d.get("unknown",[]))')" = "1" ] && ok "unknown: an unknown row" || bad "unknown did not open a row"
[ "$(state 'len(d.get("findings",[]))')" = "0" ] && ok "and no finding" || bad "unknown raised a finding"

echo ""
echo "A SEGMENT IT CANNOT JUDGE YIELDS UNKNOWN, NEVER A FINDING:"
for junk in 'I think the agent did fine' '{"verdicts":"not-a-list"}' ''; do
  reset; cfg "$(stub "$junk")"; run "$T"
  [ "$(state 'len(d.get("findings",[]))')" = "0" ] \
    && ok "an unusable return (${junk:0:22}…) raises no finding" \
    || bad "an unusable return raised a finding"
done
reset; cfg 'exit 7'; run "$T"
[ "$(state 'len(d.get("findings",[]))')" = "0" ] && ok "and a reviewer that fails outright raises none either" \
                                                 || bad "a failed reviewer raised a finding"

echo ""
echo "A VERDICT WITH NO CITATION IS DROPPED, never given an invented one (#222):"
reset; cfg "$(stub '{"verdicts":[{"rule":"Red before green.","verdict":"violated"}]}')"; run "$T"
[ "$(state 'len(d.get("findings",[]))')" = "0" ] && ok "an uncited violation is discarded" || bad "an uncited violation became a finding"
[ "$(state 'len(d.get("active",[]))+len(d.get("pending",[]))+len(d.get("unknown",[]))')" = "0" ] \
  && ok "and no row was opened for it" || bad "an uncited row was opened"

echo ""
echo "AN IDLE SEGMENT COSTS NOTHING -- the reviewer is not called at all:"
reset; cfg "$(stub '{"verdicts":[]}')"
printf '%s\n' '{"type":"user","uuid":"u1","message":{"content":"hello"}}' > "$TMP/idle.jsonl"
run "$TMP/idle.jsonl"
[ ! -f "$SEEN" ] && ok "no tool use in the segment: no reviewer call" || bad "it spawned on an idle turn"

echo ""
echo "DETACHED -- the turn does not wait for it (#198's first criterion):"
reset; cfg "$(stub '{"verdicts":[]}')"
# The measurement is against a reviewer that takes far longer than the assertion
# allows, so a synchronous implementation cannot pass by being fast.
cfg "sleep 8; $(stub '{"verdicts":[]}')"
t0=$(date +%s); run --detach "$T"; t1=$(date +%s)
[ $((t1 - t0)) -le 3 ] && ok "--detach returns in $((t1-t0))s while the reviewer sleeps 8" \
                       || bad "the caller waited $((t1-t0))s"

echo ""
echo "guards -- it fails to silence, never to a crash:"
PLAIN="$TMP/plain"; mkdir -p "$PLAIN/.claude/hooks"
cp "$REPO_ROOT/hooks/t4-reviewer" "$PLAIN/.claude/hooks/" 2>/dev/null
out="$( (cd "$PLAIN" && bash .claude/hooks/t4-reviewer "$T" 2>&1) )"; rc=$?
{ [ "$rc" -eq 0 ] && [ -z "$out" ]; } && ok "no marker file: silent, exit zero" || bad "rc=$rc out=$out"
reset; cfg "$(stub '{"verdicts":[]}')"
out="$(run "$TMP/does-not-exist.jsonl" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "a missing transcript: exit zero" || bad "a missing transcript: exit $rc"

echo ""
echo "reviewer: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

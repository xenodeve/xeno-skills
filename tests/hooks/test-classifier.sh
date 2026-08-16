#!/usr/bin/env bash
# The classifier: closed list, structured return, threshold, time cap (#187),
# invocations counted (#192), off by default (#193).
#
# The re-cut is the part to read first. #187 was written when the classifier ran
# inside a hook. A hook is a synchronous barrier on every host, so no model call may
# sit in one; the plan puts judgement in a detached worker, and this is a component
# that worker calls. Nothing here is wired into a hook.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude/hooks"
cp "$REPO_ROOT/hooks/t4-classifier" "$REPO/.claude/hooks/"
cp "$REPO_ROOT/hooks/routing-table.json" "$REPO/.claude/hooks/"
# cfg <classifier-command> [extra-json-pairs] -- written THROUGH json.dumps. Hand-built
# JSON was the first version and every classifier command contains quotes, so t4.json
# came out malformed, the script exited early, and four assertions passed on an empty
# answer while asserting nothing at all.
cfg() { python - "$REPO/.claude/t4.json" "$1" "${2:-}" <<'PY'
import json, sys
path, command, extra = sys.argv[1], sys.argv[2], sys.argv[3]
cfg = {"t4": True}
if extra:
    cfg.update(json.loads(extra))
if command:
    cfg["classifier"] = command
with open(path, "w", encoding="utf-8", newline="\n") as f:
    json.dump(cfg, f)
PY
}
run() { (cd "$REPO" && printf '%s' "${1:-a prompt}" | bash .claude/hooks/t4-classifier 2>/dev/null); }
cnt() { python - "$REPO/.claude/t4-classifier-counts.json" "$1" <<'PY'
import json,sys,os
p,k=sys.argv[1],sys.argv[2]
print(json.load(open(p,encoding='utf-8')).get(k,0) if os.path.exists(p) else 0)
PY
}
# A stub "model": consumes its input and returns a fixed answer.
stub() { printf "cat >/dev/null; printf '%%s' '%s'" "$1"; }

echo "#193 OFF BY DEFAULT -- and the skip is counted, not silent:"
cfg ''
[ -z "$(run)" ] && ok "no classifier configured: silent" || bad "it ran while off"
[ "$(cnt skipped_off)" = "1" ] && ok "and the skip is counted" || bad "the skip was not counted"

echo ""
echo "#187 it answers, and only from the CLOSED list:"
cfg "$(stub '{"skills":["t4-bro","not-a-real-skill"]}')"
out="$(run)"
case "$out" in *"t4-bro"*) ok "a real skill is returned";; *) bad "nothing returned: $out";; esac
case "$out" in *"not-a-real-skill"*) bad "an invented name was returned";; *) ok "an invented name is dropped";; esac
[ "$(cnt dropped_off_list)" = "1" ] && ok "and the drop is counted -- an invented name reads like a real one" \
                                    || bad "the off-list drop was not counted"

echo ""
echo "the threshold is applied:"
cfg "$(stub '{"skills":[{"skill":"t4-bro","confidence":0.5}]}')" '{"classifierThreshold":0.8}'
[ -z "$(run)" ] && ok "below the threshold is not returned" || bad "a low-confidence pick was returned"
cfg "$(stub '{"skills":[{"skill":"t4-bro","confidence":0.5}]}')" '{"classifierThreshold":0.4}'
[ -n "$(run)" ] && ok "above it is" || bad "a passing pick was dropped"

echo ""
echo "#187 the return must be STRUCTURED -- prose is a failure, not an answer:"
cfg "$(stub 'I think you want t4-bro')"
[ -z "$(run)" ] && ok "prose returns nothing" || bad "prose was parsed as an answer"
[ "$(cnt failed_unstructured)" = "1" ] && ok "and is counted as a failure, not as an empty answer" \
                                       || bad "unstructured output was not counted as a failure"

echo ""
echo "#187 the time cap holds, and a timeout is counted:"
cfg 'sleep 10' '{"classifierTimeoutSeconds":1}'
t0=$(date +%s); run >/dev/null; t1=$(date +%s)
[ $((t1 - t0)) -le 5 ] && ok "a slow classifier is cut off (took $((t1-t0))s against a 1s cap)" \
                       || bad "the cap did not hold: $((t1-t0))s"
[ "$(cnt timed_out)" = "1" ] && ok "and the timeout is counted" || bad "the timeout was not counted"

echo ""
echo "#192 a failing classifier is counted, and never breaks the caller:"
cfg 'exit 3'
out="$(run)"; rc=$?
{ [ "$rc" -eq 0 ] && [ -z "$out" ]; } && ok "a non-zero classifier: exit 0, silent" || bad "rc=$rc out=$out"
[ "$(cnt failed)" = "1" ] && ok "and is counted" || bad "the failure was not counted"

echo ""
echo "the re-cut is stated where someone would otherwise re-introduce it:"
grep -qi "synchronous barrier on every host" "$REPO_ROOT/hooks/t4-classifier" \
  && ok "the script says why it is not in a hook" || bad "the re-cut is not recorded"
grep -q "t4-classifier" "$REPO_ROOT/hooks/hooks.json" \
  && bad "it was wired into a hook, which is the thing the measurement forbids" \
  || ok "and it is not wired into any hook"

echo ""
echo "guards:"
PLAIN="$TMP/plain"; mkdir -p "$PLAIN/.claude/hooks"; cp "$REPO_ROOT/hooks/t4-classifier" "$PLAIN/.claude/hooks/"
out="$( (cd "$PLAIN" && printf 'x' | bash .claude/hooks/t4-classifier 2>&1) )"; rc=$?
{ [ "$rc" -eq 0 ] && [ -z "$out" ]; } && ok "no marker file: silent, exit zero" || bad "rc=$rc out=$out"

echo ""
echo "classifier: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

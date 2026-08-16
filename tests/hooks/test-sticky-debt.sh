#!/usr/bin/env bash
# Sticky debt: an unpaid finding gates the NEXT action (#218).
#
# Everything else in this design reports and never gates. #199's own body says why
# that is the ceiling -- a non-blocking hook cannot compel an answer -- so a verdict
# arriving after the turn that earned it has no consequence at all. This is the
# consequence, and it is a REAL deny at a real seam rather than a request to comply.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; mkdir -p "$REPO/.claude/hooks"
for f in t4-review-state t4-debt-gate; do cp "$REPO_ROOT/hooks/$f" "$REPO/.claude/hooks/$f"; done
marker() { printf '%s\n' "$1" > "$REPO/.claude/t4.json"; }
st()   { (cd "$REPO" && printf '%s' "$1" | bash .claude/hooks/t4-review-state >/dev/null 2>&1); }
fire() { (cd "$REPO" && printf '%s' "${1:-{\"hook_event_name\":\"PreToolUse\"\}}" | bash .claude/hooks/t4-debt-gate 2>/dev/null); }

marker '{"t4":true}'
st '{"op":"open","rule":"tdd","record":1,"uuid":"u1"}'
st '{"op":"violate","rule":"tdd"}'

echo "OFF BY DEFAULT -- an enforcement path that arrives switched on is one nobody chose:"
out="$(fire)"
[ -z "$out" ] && ok "with no stickyDebt setting it says nothing, even with debt open" \
              || bad "it denied while off: $out"

echo ""
echo "switched on, unpaid debt denies the NEXT action:"
marker '{"t4":true,"stickyDebt":true}'
out="$(fire)"
case "$out" in *'"permissionDecision":"deny"'*) ok "it denies";; *) bad "no deny: ${out:0:80}";; esac
case "$out" in *"F-001"*) ok "and names the finding";; *) bad "the finding is not named";; esac
case "$out" in *"tdd"*) ok "and the rule it came from";; *) bad "the rule is not named";; esac
case "$out" in *"gates this action rather than that one"*) ok "and says it gates the NEXT action, not the one that earned it";;
  *) bad "the sticky property is not stated in the reason";; esac
case "$out" in *"DISMISS"*) ok "and tells the master how to clear it";; *) bad "no way out is offered";; esac

echo ""
echo "resolving it clears the debt:"
st '{"op":"dismiss","finding":"F-001","reason":"the survey is in the issue body"}'
out="$(fire)"
[ -z "$out" ] && ok "a dismissed finding stops gating" || bad "still denying after dismissal: ${out:0:60}"

echo ""
echo "no second state file -- it reads the one the reviewer already writes:"
n=$(ls "$REPO/.claude"/*.json 2>/dev/null | wc -l)
[ "$n" -le 2 ] && ok "only t4.json and the review state exist ($n files)" || bad "$n json files in .claude"
grep -q "t4-review-state.json" "$REPO_ROOT/hooks/t4-debt-gate" && ok "it reads the reviewer's own state file" \
                                                               || bad "it uses a different store"

echo ""
echo "EXPIRY IS #178'S NUMBER AND IS NOT GUESSED:"
grep -q "no default here" "$REPO_ROOT/hooks/t4-debt-gate" \
  && ok "with no configured value debt does not expire, and the absence is visible" \
  || bad "an expiry default was invented"
st '{"op":"open","rule":"verify","record":2,"uuid":"u2"}'
st '{"op":"violate","rule":"verify"}'
marker '{"t4":true,"stickyDebt":true,"stickyDebtExpirySegments":1}'
out="$( (cd "$REPO" && printf '{"hook_event_name":"PreToolUse","segment_index":9}' \
        | bash .claude/hooks/t4-debt-gate 2>"$TMP/err") )"
[ -z "$out" ] && ok "past the configured age it stops gating" || bad "expired debt still denied"
grep -q "expired after" "$TMP/err" && ok "and the expiry is LOGGED, never silent" || bad "an expiry was dropped silently"

echo ""
echo "guards:"
PLAIN="$TMP/plain"; mkdir -p "$PLAIN/.claude/hooks"; cp "$REPO_ROOT/hooks/t4-debt-gate" "$PLAIN/.claude/hooks/"
out="$( (cd "$PLAIN" && printf '{}' | bash .claude/hooks/t4-debt-gate 2>&1) )"; rc=$?
{ [ "$rc" -eq 0 ] && [ -z "$out" ]; } && ok "no marker file: silent, exit zero" || bad "rc=$rc out=$out"

echo ""
echo "it is NOT wired into the live chain -- that is a trust-boundary decision:"
grep -q "t4-debt-gate" "$REPO_ROOT/hooks/hooks.json" \
  && bad "it was wired into the live PreToolUse chain unattended" \
  || ok "it ships tested and dark, as the header states"

echo ""
echo "sticky-debt: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

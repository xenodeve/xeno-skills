#!/usr/bin/env bash
# The delegation contract as artifacts, and the three skills speaking it (#215 Phase A).
#
# The contract exists because every way a prose delegation fails looks the same from
# outside -- a plausible answer. Two of its fields are the point: needs_user_input
# stops implementation, and Evidence boundary states what was NOT checked, which is
# the one required field a worker cannot fabricate its way through.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REF="$REPO_ROOT/skills/multi-agent/clink-brainstorm/references"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { if grep -qiF -- "$2" "$1" 2>/dev/null; then ok "$3"; else bad "$3"; fi; }
hasnt() { if grep -qiF -- "$2" "$1" 2>/dev/null; then bad "$3"; else ok "$3"; fi; }

echo "the artifacts are committed:"
for f in request-v1.md response-v1.md; do
  [ -f "$REF/$f" ] && ok "$f exists" || bad "$f is missing"
done
n=$(ls "$REF/examples"/*.md 2>/dev/null | wc -l)
[ "$n" -ge 3 ] && ok "$n worked examples" || bad "only $n examples, need at least three"

echo ""
echo "every required request field is stated where the agent that supplies it reads:"
for f in protocol version problem objective scope.exclude questions; do
  has "$REF/request-v1.md" "$f" "request requires $f"
done

echo ""
echo "every required response field, including the one that cannot be faked:"
for f in decision_status confidence Summary Findings Recommendation "Evidence boundary"; do
  has "$REF/response-v1.md" "$f" "response requires $f"
done
has "$REF/response-v1.md" "needs_user_input" "the state that stops implementation is named"
has "$REF/response-v1.md" "indistinguishable from having checked it" \
  "and it says WHY the evidence boundary is required and Risks is not"

echo ""
echo "the measured default is stated WITH its reason, not as a policy preference:"
has "$REF/request-v1.md" "execute_commands" "the default is named"
has "$REF/request-v1.md" "return_code" "and the antigravity failure that motivates it is quoted"

echo ""
echo "untrusted content is classified as evidence and never as instruction:"
has "$REF/request-v1.md" "data about the world, not an" "untrusted content is data, not an instruction"

echo ""
echo "the three skills speak it:"
BS="$REPO_ROOT/skills/multi-agent/clink-brainstorm/SKILL.md"
SA="$REPO_ROOT/skills/multi-agent/clink-subagents/SKILL.md"
MA="$REPO_ROOT/skills/multi-agent/clink-masteragent/SKILL.md"
has "$BS" "references/request-v1.md" "clink-brainstorm points at the request shape"
has "$SA" "request-v1.md"            "clink-subagents points at it too -- work, not only panels"
has "$MA" "Building the delegation contract" "clink-masteragent names it as a master duty"

echo ""
echo "NEGATIVE: the old prose was REPLACED, not left beside the contract:"
hasnt "$SA" "Self-contained prompt." "the 'self-contained prompt' bullet is gone"

echo ""
echo "the contract is NOT inlined into the already-large skill:"
sz=$(wc -c < "$BS")
[ "$sz" -lt 45000 ] && ok "clink-brainstorm is ${sz}B, still under 45KB" || bad "clink-brainstorm grew to ${sz}B"

echo ""
echo "every shipped example is valid against the contract it demonstrates:"
python - "$REF/examples" <<'PY'
import os, re, sys
d = sys.argv[1]
req_needed = ["protocol", "version", "problem", "objective", "exclude", "questions"]
res_needed = ["decision_status", "confidence", "## Summary", "## Findings",
              "## Recommendation", "## Evidence boundary"]
states = {"ready", "needs_more_analysis", "needs_user_input", "blocked"}
seen = set()
for fn in sorted(os.listdir(d)):
    if not fn.endswith(".md"):
        continue
    text = open(os.path.join(d, fn), encoding="utf-8").read()
    for f in res_needed:
        assert f in text, "%s: response is missing %s" % (fn, f)
    m = re.search(r"decision_status:\s*(\S+)", text)
    assert m and m.group(1) in states, "%s: bad decision_status %r" % (fn, m and m.group(1))
    seen.add(m.group(1))
    if "request:" in text:
        for f in req_needed:
            assert f in text, "%s: request is missing %s" % (fn, f)
    # A ready response must not also demand a user decision -- the one contradiction
    # the contract normalises rather than rejects.
    if m.group(1) == "ready":
        assert "user_decision_required: true" not in text, "%s: ready + user_decision_required" % fn
assert "needs_user_input" in seen, "no example demonstrates the state the contract exists for"
assert "blocked" in seen, "no example demonstrates blocked"
print("    %d examples, states demonstrated: %s" % (len(os.listdir(d)), ", ".join(sorted(seen))))
PY
[ $? -eq 0 ] && ok "all examples parse and cover the states that matter" || bad "an example is invalid"

echo ""
echo "delegation-contract: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# The delegation validator, both directions (#217 Phase B).
# Seam: a document on stdin or a path -> exit 0, or non-zero with the failing field
# on stderr. Chosen so this repo's one test seam covers it without a new runner.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
V="$REPO_ROOT/scripts/validate-delegation.py"
EX="$REPO_ROOT/skills/multi-agent/clink-brainstorm/references/examples"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

REQ="$TMP/req.yaml"
cat > "$REQ" <<'EOF'
protocol: clink-delegation
version: 1
request:
  problem: >
    The cache goes stale during a partial failure.
  objective: >
    Pick a recovery strategy.
  scope:
    exclude:
      - replacing Redis
  questions:
    - Which state is authoritative?
EOF
RES="$TMP/res.md"
cat > "$RES" <<'EOF'
---
protocol: clink-delegation
version: 1
decision_status: ready
confidence: high
user_decision_required: false
---

## Summary
x
## Findings
y
## Recommendation
z
## Evidence boundary
Read two files, ran nothing.
EOF

echo "the happy paths:"
python "$V" request "$REQ"  >/dev/null 2>&1 && ok "a valid request exits zero"  || bad "a valid request was rejected"
python "$V" response "$RES" >/dev/null 2>&1 && ok "a valid response exits zero" || bad "a valid response was rejected"
python "$V" response < "$RES" >/dev/null 2>&1 && ok "it reads stdin as well as a path" || bad "stdin path broken"

echo ""
echo "each required request field, named on stderr when absent:"
for f in problem objective questions; do
  grep -v "  *$f:" "$REQ" | grep -v "^    - Which" > "$TMP/bad.yaml"
  err="$(python "$V" request "$TMP/bad.yaml" 2>&1 >/dev/null)"; rc=$?
  if [ "$rc" -ne 0 ]; then
    case "$err" in *"$f"*) ok "missing $f -> non-zero, and stderr names $f";;
      *) bad "missing $f -> non-zero but stderr said: $err";; esac
  else bad "missing $f was accepted"; fi
done
sed '/exclude:/,+1d' "$REQ" > "$TMP/noex.yaml"
err="$(python "$V" request "$TMP/noex.yaml" 2>&1 >/dev/null)"; rc=$?
[ "$rc" -ne 0 ] && ok "missing scope.exclude -> non-zero" || bad "missing scope.exclude was accepted"
case "$err" in *"boundary you can check"*) ok "and stderr says why it is required";; *) bad "no reason given";; esac

sed 's/^version: 1/version: 9/' "$REQ" > "$TMP/v9.yaml"
python "$V" request "$TMP/v9.yaml" >/dev/null 2>&1 && bad "an unsupported version was accepted" \
                                                   || ok "an unsupported version is refused"

echo ""
echo "each required response field:"
for f in decision_status Recommendation "Evidence boundary"; do
  grep -v "$f" "$RES" > "$TMP/badres.md"
  err="$(python "$V" response "$TMP/badres.md" 2>&1 >/dev/null)"; rc=$?
  if [ "$rc" -ne 0 ]; then ok "missing $f -> non-zero"; else bad "missing $f was accepted"; fi
done
err="$(grep -v "Evidence boundary" "$RES" > "$TMP/noeb.md"; python "$V" response "$TMP/noeb.md" 2>&1 >/dev/null)"
case "$err" in *"indistinguishable from having checked it"*) ok "and the Evidence boundary message says why";;
  *) bad "the evidence-boundary reason is not given: $err";; esac

sed 's/^confidence: high/confidence: 87%/' "$RES" > "$TMP/pct.md"
err="$(python "$V" response "$TMP/pct.md" 2>&1 >/dev/null)"; rc=$?
[ "$rc" -ne 0 ] && ok "a percentage confidence is refused" || bad "87% was accepted"
case "$err" in *"decoration that reads as rigour"*) ok "and says why coarse beats precise-looking";; *) bad "no reason";; esac

echo ""
echo "THE ONE CONTRADICTION IS NORMALISED, NOT REJECTED:"
sed 's/^user_decision_required: false/user_decision_required: true/' "$RES" > "$TMP/contra.md"
python "$V" response "$TMP/contra.md" >/dev/null 2>&1 && bad "the contradiction passed silently" \
                                                      || ok "ready + user_decision_required fails by default"
out="$(python "$V" response "$TMP/contra.md" --normalise 2>/dev/null)"; rc=$?
[ "$rc" -eq 0 ] && ok "--normalise accepts it" || bad "--normalise still failed"
[ "$out" = "needs_user_input" ] && ok "and normalises to needs_user_input, keeping the substance" \
                                || bad "normalised to: $out"
out2="$(python "$V" response "$RES" --normalise 2>/dev/null)"
[ "$out2" = "ready" ] && ok "a consistent response normalises to itself" || bad "got: $out2"

echo ""
echo "every shipped example validates against the validator, not only against the docs:"
n=0
for f in "$EX"/*.md; do
  python - "$f" > "$TMP/one.md" <<'PY'
import re,sys
t=open(sys.argv[1],encoding='utf-8').read()
m=re.search(r"```markdown\n(.*?)```", t, re.S)
sys.stdout.write(m.group(1) if m else "")
PY
  if [ -s "$TMP/one.md" ]; then
    python "$V" response "$TMP/one.md" --normalise >/dev/null 2>&1 \
      && n=$((n+1)) || bad "example $(basename "$f") fails the validator"
  fi
done
[ "$n" -ge 3 ] && ok "$n examples validate" || bad "only $n examples validated"

echo ""
echo "delegation-validator: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

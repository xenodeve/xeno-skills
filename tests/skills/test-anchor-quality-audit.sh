#!/usr/bin/env bash
# The anchor-quality audit has teeth, and something closes them (#142).
#
# The audit detected a real defect class and was configured never to report it as a
# failure: it ran, printed its finding, and exited 0. Finding A -- a corrective suite
# that makes `has` calls and never a `hasnt` -- is the one category that is
# MECHANICALLY decidable, so it is the one that now fails.
#
# It is also not discovered by run-all.sh, which globs test-*.sh. THIS WRAPPER is
# what puts it in the suite; without it the audit could pass or fail and nothing
# would notice either way, which is the same shape as the defect it audits for.
#
# `--only-a` here: the full audit costs ~23 s because findings B and C match every
# anchor against its target file, and `.claude/t4.json`'s `verify` runs before every
# ship action. A check that adds half a minute to that is one people route around.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AUDIT="$REPO_ROOT/tests/audit-anchor-quality.sh"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
hasnt() { if grep -qF -- "$2" "$1"; then bad "$3"; else ok "$3"; fi; }

[ -f "$AUDIT" ] && ok "the audit is committed" || bad "the audit is missing"

echo ""
echo "it is clean today, and it FAILS rather than reports:"
if bash "$AUDIT" --only-a >/dev/null 2>&1; then
  ok "no positive-only corrective suite in the tree"
else
  bad "the audit is red -- run tests/audit-anchor-quality.sh --only-a to see which"
fi
grep -q "exit 1" "$AUDIT" && ok "finding A exits non-zero, so it can fail a build" \
                          || bad "the audit still cannot fail anything"

echo ""
echo "NEGATIVE -- the report-only framing was retired, not left beside the new one:"
# Not invented: both sentences were the audit's own header until #142 replaced them.
hasnt "$AUDIT" "Never fails a build"         "the 'never fails a build' claim is gone"
hasnt "$AUDIT" "prints findings and exits 0" "and so is 'prints findings and exits 0'"

echo ""
echo "the gating path is cheap because it does less, not because it hurries:"
out_fast="$(bash "$AUDIT" --only-a 2>&1)"
case "$out_fast" in
  *"B. SHADOWED"*|*"C. LOOSE"*) bad "the gating path still runs B or C, which is where the time goes";;
  *) ok "it skips findings B and C";;
esac
case "$out_fast" in
  *"positive-only suites (A)"*) ok "and still evaluates A, which is what gates";;
  *) bad "the gating path stopped evaluating A";;
esac
grep -q "PURE BASH" "$AUDIT" && ok "and extraction spawns no subprocess per assertion" \
                             || bad "the per-assertion subprocesses are back"

echo ""
echo "POSITIVE CONTROL -- a new positive-only corrective suite MUST be caught:"
PROBE="$REPO_ROOT/tests/skills/test-zz-probe-positive-only.sh"
# The probe writes a file this suite OWNS and nothing else reads, and removes it
# from a trap. Three probes in this branch mutated a file the repository tracks and
# left it dirty when a run ended early; a probe must not be able to do that.
trap 'rm -f "$PROBE"' EXIT
cat > "$PROBE" <<'PROBESH'
#!/usr/bin/env bash
# Written and removed by tests/skills/test-anchor-quality-audit.sh. Deliberately
# positive-only. If this file survives a run, that run died before its trap.
set -uo pipefail
ok() { echo "  PASS: $1"; }
has() { case "$1" in *"$2"*) ok "$3";; esac; }
has "some text" "some" "a positive assertion and nothing else"
PROBESH
bash "$AUDIT" --only-a >/dev/null 2>&1; rc=$?
rm -f "$PROBE"
[ "$rc" -ne 0 ] && ok "a positive-only corrective suite makes the audit fail" \
                || bad "the audit stayed green on a suite that can only ever add"
bash "$AUDIT" --only-a >/dev/null 2>&1 && ok "removing it makes the audit pass again" \
                                       || bad "the audit stayed red after cleanup"

echo ""
echo "the exemption list is stated per suite with a reason, not a bare list:"
grep -q "PRESERVATION" "$AUDIT" && ok "PRESERVATION is defined" || bad "no PRESERVATION reason"
grep -q "STRUCTURAL"   "$AUDIT" && ok "STRUCTURAL is defined"   || bad "no STRUCTURAL reason"
grep -q "would fail on the CORRECTED text" "$AUDIT" \
  && ok "and the trap that makes a naive hasnt worse than none is recorded" \
  || bad "the naive-hasnt trap is not recorded"

echo ""
echo "anchor-quality-audit: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

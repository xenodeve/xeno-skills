#!/usr/bin/env bash
# Every actionable figure an agent reads must be traceable to a measured record.
#
# The defect this guards is not a wrong number — it is a number nobody can check.
# `clink-subagents` and `clink-brainstorm` each grew their own copy of the routing
# figures, both sourced from a research document that had gone stale in four
# separate ways before anyone noticed, and only noticed because an unrelated
# investigation happened to look. Two copies of one decision drift silently,
# because nothing fails when they disagree.
#
# So the rule is checkable rather than editorial: figures live in one delimited
# block per skill, the block names the structured file it came from, and every
# figure in it must appear in that file.
#
# Tested against FIXTURES, not only against the real skills. A test that runs
# only against real files passes the day the real files happen to be right and
# proves nothing about the rule — and this repo has already shipped a test that
# pinned wording rather than behaviour.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CHECKER="$REPO_ROOT/docs/research/scripts/check-figures-sourced.sh"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- fixture source: a structured file with known values ---------------------
mkdir -p "$WORK/data"
cat > "$WORK/data/source.csv" <<'CSV'
name,intelligenceIndex,costTotal
Alpha (max),58.89,3442.81
Beta (low),41.20,299.27
Gamma (xhigh),60.0681611916281,1.802080556320042
CSV

# --- fixture skills ----------------------------------------------------------
mkdir -p "$WORK/skills/backed" "$WORK/skills/unbacked" "$WORK/skills/nosource" "$WORK/skills/rounded"

# A generated document quotes readable figures; the source keeps full precision.
# Without this fixture the rounding path is never exercised and could be removed
# with the suite still green — the whole rule would then reject every correctly
# derived number, which is the failure that gets a rule switched off.
cat > "$WORK/skills/rounded/SKILL.md" <<'MD'
# Rounded
<!-- figures:start source=data/source.csv -->
| model | index | cost |
|---|---|---|
| Gamma (xhigh) | 60.07 | 1.80 |
<!-- figures:end -->
MD

cat > "$WORK/skills/backed/SKILL.md" <<'MD'
# Backed
Prose may contain 3 rounds and version 4.5 — those are not figures.
<!-- figures:start source=data/source.csv -->
| model | index | cost |
|---|---|---|
| Alpha (max) | 58.89 | 3442.81 |
<!-- figures:end -->
MD

cat > "$WORK/skills/unbacked/SKILL.md" <<'MD'
# Unbacked
<!-- figures:start source=data/source.csv -->
| model | index | cost |
|---|---|---|
| Alpha (max) | 58.89 | 3442.81 |
| Ghost (max) | 61.00 | 9999.99 |
<!-- figures:end -->
MD

cat > "$WORK/skills/nosource/SKILL.md" <<'MD'
# No source declared
<!-- figures:start source=data/does-not-exist.csv -->
| model | index |
|---|---|
| Alpha (max) | 58.89 |
<!-- figures:end -->
MD

# The checker signals a rule violation with exit code 2, and ONLY that.
# Anything else — 127 for a missing file, 1 for a bash error — is a broken
# harness, not a rejection. Without this distinction the two "must be rejected"
# cases below pass while the checker does not exist at all: `command not found`
# exits non-zero, the test reads that as "rejected", and the suite goes green on
# a rule that has never run. That happened on the first run of this file.
VIOLATION=2

if [ ! -x "$CHECKER" ]; then
  echo "  FAIL: checker missing or not executable: $CHECKER"
  echo ""
  echo "figures-sourced: 0 passed, 1 failed (harness)"
  exit 1
fi

run_checker() { "$CHECKER" "$WORK/$1" "$WORK"; }

rejected() {  # usage: rejected <skill-path>  -> sets $out, returns 0 if a real violation
  out="$(run_checker "$1" 2>&1)"; local rc=$?
  [ "$rc" -eq "$VIOLATION" ]
}

# --- case A: every figure in the block is in the source ----------------------
echo "A) a block whose figures are all in the source is accepted:"
if out="$(run_checker skills/backed/SKILL.md 2>&1)"; then
  ok "backed figures pass"
else
  bad "backed figures were rejected — the check cannot tell right from wrong: $out"
fi

# --- case B: a figure absent from the source is rejected ---------------------
# This is the rule. If this case does not fail, the test is decoration.
echo "B) a figure that is NOT in the source is rejected:"
if rejected skills/unbacked/SKILL.md; then
  ok "unbacked figure rejected"
  case "$out" in
    *9999.99*) ok "the report names the offending value" ;;
    *)         bad "rejected, but the report does not name which figure: $out" ;;
  esac
else
  bad "an unbacked figure was not rejected with code $VIOLATION — the rule does not bite: $out"
fi

# --- case C': the declared source must exist ---------------------------------
echo "C) a block naming a source file that does not exist is rejected:"
if rejected skills/nosource/SKILL.md; then
  ok "missing source rejected"
else
  bad "a block pointing at a missing source was not rejected with code $VIOLATION: $out"
fi

# --- case D: a rounded quote of a full-precision source value is accepted ----
echo "D) a figure rounded from a full-precision source value is accepted:"
if out="$(run_checker skills/rounded/SKILL.md 2>&1)"; then
  ok "60.07 accepted against a source holding 60.0681611916281"
else
  bad "a correctly rounded figure was rejected — the rule would forbid every generated document: $out"
fi

echo ""
echo "figures-sourced: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

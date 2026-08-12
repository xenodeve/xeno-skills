#!/usr/bin/env bash
# The skill-usage log is the repo's answer to "how do we improve a skill without
# running a benchmark". Three things in it are load-bearing and each is the kind
# a rewrite quietly drops:
#
#   - RECORD THE SKIP. A log of only the memorable sessions is the same
#     failure-selected sample that invalidated an earlier rate claim here. The
#     unremarkable entries ARE the denominator.
#   - "none observed" written out. Omitting an empty section is how silence gets
#     read as compliance — the same failure `check-gate-ledger` exists to stop.
#   - THE HONEST CEILING. Writing the entry is agent discipline, not a hook. The
#     moment this file says the log happens automatically, it is describing
#     enforcement that does not exist (ADR 0001:36), which is the precise defect
#     `hooks-layer.md` records against pal-mcp-server.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MEM="$REPO_ROOT/skills/t4/t4-agent-memory/SKILL.md"
ART="$REPO_ROOT/skills/t4/t4-agent-memory/references/memory-artifacts.md"
GOV="$REPO_ROOT/skills/t4/t4-project-bootstrap/references/governance-docs.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { if [ -f "$1" ] && grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }
hasnt() { if [ -f "$1" ] && grep -qiF -- "$2" "$1"; then bad "$3"; else ok "$3"; fi; }

echo "t4-agent-memory carries the layer:"
has "$MEM" "Skill-usage log"     "the layer is named in the memory-layer table"
has "$MEM" "skill-usage/"        "its location is given"
has "$MEM" "before changing a skill" "the read-trigger is stated — this is what replaces a benchmark"

echo "the three writing rules:"
has "$MEM" "A session that skipped a rule must record the skip" "the skip is recorded, not omitted"
has "$MEM" "silence is indistinguishable from compliance"       "and why: the check-gate-ledger principle"
has "$MEM" "Only what happened in this session"                 "no reconstructed retrospectives"
has "$MEM" "quote what was actually written or done"            "a finding carries its artifact"

echo "it is separated from the vault-note threshold it would otherwise violate:"
has "$MEM" "not a vault note" "the strict add/update threshold does not apply to this layer"

echo "the honest ceiling — this is discipline, not a hook:"
has "$MEM" "Writing the entry is agent discipline" "the ceiling is stated in the skill itself"
hasnt "$MEM" "logged automatically" "the log is never described as automatic"

echo "the entry skeleton ships with the other memory artifacts:"
has "$ART" "Skill-usage log entry"        "the skeleton exists"
has "$ART" "Rules that did not hold"      "the section that carries the findings"
has "$ART" "none observed"                "an empty section is written out, not dropped"
has "$ART" "skills:"                      "the entry records which skills were actually loaded"

echo "a bootstrapped repo gets it through its CLAUDE.md:"
has "$GOV" "skill-usage" "the CLAUDE.md skeleton names the session-end step"

echo ""
echo "usage-log-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

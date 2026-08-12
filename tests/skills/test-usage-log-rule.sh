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
MAP="$REPO_ROOT/skills/t4/using-t4/SKILL.md"

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
has "$GOV" "skill-feedback" "the CLAUDE.md skeleton names the session-end step"

# #146: the log reached three files in one family while ten of seventeen skills
# sat outside it — and the families it missed (multi-agent, karpathy) are where
# #131, #136, #137 and #138 came from. Every entry point an agent can arrive
# through has to name the obligation, or the loop is aimed away from its own
# evidence. The rules stay in ONE file; these only point at it.
echo "every entry point an agent can arrive through names it (#146):"
has "$MAP" "skill-feedback" "using-t4 — the file injected verbatim every session"
for f in skills/multi-agent/clink-masteragent/SKILL.md \
         skills/design/using-design/SKILL.md \
         skills/karpathy-guidelines/SKILL.md; do
  has "$REPO_ROOT/$f" "skill-feedback"    "$(basename "$(dirname "$f")") names the obligation"
  has "$REPO_ROOT/$f" "t4-agent-memory"  "$(basename "$(dirname "$f")") points at the rules instead of copying them"
done

# A falsify seat (fresh lineage, per clink-debug's provenance rule) refuted the
# file-first design on four predicates. Two stuck and decided the redesign:
#   - the vault sat inside a git checkout, so `git switch` made the destination
#     vanish — a directory that flickers with the branch is not a database;
#   - a session that ends by crashing or cancellation never reaches "session
#     end" at all, so a file written there is written never.
# A GitHub issue has neither property. Hence: the issue is the record, and the
# note is demoted to a local working copy for xeno-skills development only.
echo "the issue is the record, reachable from any repo and any session:"
has "$MEM" "The GitHub issue is the record"  "the durable destination is the tracker, not a file"
has "$MEM" "One issue per rule, not per session" "the comment count is the frequency signal"
has "$MEM" "skill-feedback"                   "the label that makes them findable as a set"

echo "the two gh flags that decide whether this works at all:"
has "$MEM" "--state all"                      "closed issues carry the analysis and the deliberate-by-design cases"
has "$MEM" "--repo xenodeve/xeno-skills"      "gh defaults to the repo you are standing in"

echo "the note survives, scoped to developing the library itself:"
has "$MEM" "only when the session ran inside" "a session in another repo files the issue and writes no note"

echo ""
echo "usage-log-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

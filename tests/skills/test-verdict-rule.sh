#!/usr/bin/env bash
# "No verdict before evidence" is the rule most likely to be lost to a rewrite
# that makes the prose sound more confident — the failure it prevents is
# stylistic (sounding decisive) before it is factual.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MAP="$REPO_ROOT/skills/t4/using-t4/SKILL.md"
WF="$REPO_ROOT/skills/t4/t4-dev-workflow/SKILL.md"
AFK="$REPO_ROOT/skills/t4/t4-afk/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "the injected map carries the rule:"
has "$MAP" "Don't state as settled what you haven't verified" "using-t4 forbids asserting the unverified"
has "$MAP" "never improves by being repeated"                 "using-t4 blocks laundering a guess into a fact"
has "$MAP" "Evidence before verdict, fix, or exemption"       "the three evidence rules are stated as one principle"
has "$MAP" "Should ≠ does"                                    "red-flags rebut 'it should work — call it fixed'"

echo "the workflow skill carries the discipline:"
has "$WF" "No verdict before evidence"        "t4-dev-workflow has the verdict section"
has "$WF" "Verified"                          "register: verified"
has "$WF" "Hypothesis"                        "register: hypothesis"
has "$WF" "Unknown"                           "register: unknown"
has "$WF" "requires a named artifact"         "a verdict word must come with its artifact"
has "$WF" "These are not evidence"            "lists what does not count as evidence"
has "$WF" "laundering failure mode"           "names the repeat-until-true failure mode"
has "$WF" "Another agent said so"             "a subagent/bot report is a hypothesis until checked"
has "$WF" "is a complete, acceptable sentence" "reporting 'tests not run' is acceptable"

echo "AFK: the digest is the only report, so registers must be marked:"
has "$AFK" "indistinguishable from a verified one" "t4-afk requires verified/hypothesis marking in the digest"

echo ""
echo "verdict-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

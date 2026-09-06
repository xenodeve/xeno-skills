#!/usr/bin/env bash
# `qwen38-claude-code` (#355): the tool guide for Qwen3.8-27B inside Claude Code.
# Pins the figures from the 44 streams of 2026-09-05 (14 tool errors in 9 cells;
# 6 of them a Read on a guessed SKILL.md path; 2 Thai-line Edit misses in
# A-gateonly-r2; 87 of 195 Bash calls prefixed with a cd; two runs that ended by
# asking a developer who was not there), the no-skip sentences (never Agent, never
# AskUserQuestion, the missing-tool escape), the shared report line, and the boundary.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
F="$REPO_ROOT/skills/qwen38/qwen38-claude-code/SKILL.md"
ROUTER="$REPO_ROOT/skills/qwen38/using-qwen38/SKILL.md"
pass=0 fail=0
ok()  { pass=$((pass+1)); }
bad() { echo "FAIL: $1"; fail=$((fail+1)); }
has()   { grep -qF -- "$1" "$F" && ok || bad "missing: $1"; }
hasnt() { grep -qF -- "$1" "$F" && bad "present: $1" || ok; }

[ -f "$F" ] && ok || bad "SKILL.md missing"
has "target-model: Qwen3.8-27B"
has "| you want | use | not | pass condition |"

echo "  figures from the runs, not adjectives:"
has "14 tool errors"
has "6 of the 14 errors"
has "27 \`ls\` + 4 \`find\` calls vs 5 Glob"
has "87 of 195 Bash calls"
has "A-gateonly-r2"
has "A-noskill-r2"
has "B-skill-r1"
has "A-skill-r1"
has "String to replace not found"
has "A-ccguide-r1"
has "with this guide loaded"
has "Write** it to a file, then Bash"

echo "  the no-skip sentences:"
has "never **Agent**"
has "AskUserQuestion"
has "is not available; continuing without it"
has "Read in this session"
has "never a third try from memory"

echo "  the error table (2026-09-06, the developer: what to do on a denial, a subagent error, ...):"
has "## When a tool comes back with an error"
has "auto mode classifier"
has "do not retry it and do not route around it"
has "a refused \`Agent\` → do the work yourself"
has "a result, not an error"
has "retry the **same** step once"
has "never the same long command again"

echo "  the shared report shape (rule 9): a line added after THINK and the gate, not a new report:"
has "CC: tool calls <n> · tool errors <e> · asked the developer: no"
has "after the \`THINK:\` line and the gate line"
hasnt "GATE: n/8"

echo "  boundary and size:"
has "## What this does not touch"
bytes=$(wc -c < "$F"); [ "$bytes" -le 8000 ] && ok || bad "SKILL.md is $bytes bytes, over the ~6 KB budget"

echo "  the router points at it before the first tool call:"
grep -qF "qwen38-claude-code" "$ROUTER" && ok || bad "using-qwen38 does not name qwen38-claude-code"

echo "qwen38-claude-code: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

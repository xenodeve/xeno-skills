#!/usr/bin/env bash
# `clink-subagents` presents the codex effort ladder as one scale ending at
# `max`. Read from ~/.codex/models_cache.json on 2026-08-05 that is wrong in
# both directions, and each way costs a call (#72):
#
#   - THREE MODELS HAVE NO `max` AT ALL. gpt-5.5, gpt-5.4 and gpt-5.4-mini stop
#     at `xhigh`, so asking those for `max` is a request the model cannot serve.
#   - FOUR MODELS GO BEYOND IT, to `ultra`: gpt-5.6-sol, gpt-5.6-sol-wm,
#     codex-auto-review and gpt-5.6-terra. `gpt-5.6-luna` — the cheap tier this
#     repo routes bulk work to — is NOT among them.
#
# Anchors are the model ids and the two rung names, which are facts a reader can
# check against the cache file, not a wording chosen here. The figures live in
# docs/research/2026-08-05-clink-model-inventory-refresh.md.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUB="$REPO_ROOT/skills/multi-agent/clink-subagents/SKILL.md"
DOC="$REPO_ROOT/docs/research/2026-08-05-clink-model-inventory-refresh.md"
CSV="$REPO_ROOT/docs/research/data/codex-models-2026-08-05.csv"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }
hasnt() { if grep -qiF -- "$2" "$1"; then bad "$3"; else ok "$3"; fi; }

echo "the ladder is not presented as one scale ending at max:"
has "$SUB" "not one ladder" "clink-subagents says the ladder is per-model"
has "$SUB" "stop at \`xhigh\`" "and names the models that never reach max"
has "$SUB" "ultra" "and the rung above max"

echo
echo "the cheap tier's own ceiling is stated, since that is the one bulk work uses:"
# Anchored on prose rather than on markdown: the sentence carries `**` and
# backticks that a literal-match assertion has no reason to depend on.
has "$SUB" "is the cheap tier this skill routes bulk work to" "luna's ceiling is called out"

echo
echo "the research note records the inventory it was read from:"
has "$DOC" "gpt-5.6-sol-wm" "the model absent from every prior doc"
has "$DOC" "272,000" "the codex context cap"
has "$DOC" "cursor-agent\` is not installed" "and says plainly what could NOT be verified"

echo
echo "the claims trace to saved data, not to prose:"
has "$CSV" "gpt-5.4-mini" "the raw inventory is committed"
has "$CSV" "low|medium|high|xhigh|max|ultra" "including the full ladder string"

echo
echo "the withdrawn claim is gone, not left beside the new one:"
# The old cell asserted a single flat ladder for every codex model. Anchored on
# its parenthetical, which is the claim in its ASSERTED form — the rung names
# themselves still appear, correctly, in the per-model breakdown.
hasnt "$SUB" "(reasoning tokens scale with it)" "the flat-ladder claim is withdrawn"

echo
if [ "$fail" -gt 0 ]; then echo "FAILED: $fail, passed: $pass"; exit 1; fi
echo "OK: $pass passed"

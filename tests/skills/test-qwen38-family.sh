#!/usr/bin/env bash
# The `qwen38` family (#354): a router the model loads, and an authoring standard
# for whoever writes a skill it will follow. Both were calibrated on the
# 2026-09-05 runs (Qwen-3.8-27B-Tuning docs/results/11-quality-bench-2026-09-05.md,
# xeno-skills #353), and this test pins the parts a rewrite would smooth away:
#
#   - the router's rules are the ones the runs demanded, in the model's own
#     failure terms (the table first, outputs pasted, never install, stop);
#   - the router points at a gate for every row that has one and admits the
#     rows that do not, instead of inventing a gate;
#   - the standard's eight rules each carry a figure from a run;
#   - the missing-tool escape is written, because two runs were lost to its
#     absence (a `gh` hunt, a spellchecker install);
#   - both files declare the target model, so nobody applies them to Claude.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROUTER="$REPO_ROOT/skills/qwen38/using-qwen38/SKILL.md"
STYLE="$REPO_ROOT/skills/qwen38/qwen38-skill-style/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { if [ -f "$1" ] && grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }
hasnt() { if [ -f "$1" ] && ! grep -qiF -- "$2" "$1"; then ok "$3"; else bad "$3"; fi; }

echo "both files exist and name their target model:"
for f in "$ROUTER" "$STYLE"; do
  [ -f "$f" ] && ok "$(basename "$(dirname "$f")")/SKILL.md exists" || bad "$f is missing"
  has "$f" "target-model: Qwen3.8-27B" "$(basename "$(dirname "$f")") declares target-model"
done

echo "the router maps tasks to a skill and a gate, and admits where no gate exists:"
has "$ROUTER" "| the task | load | finish with |" "the map is a three-column table"
has "$ROUTER" "design-ship-gate" "web pages end with design-ship-gate"
has "$ROUTER" "using-design" "web pages load using-design"
has "$ROUTER" "karpathy-guidelines" "code changes load karpathy-guidelines"
has "$ROUTER" "nothing yet" "a row with no gate says so instead of inventing one"

echo "the router defines METHOD, not craft (#366): no page deliverable is named here"
hasnt "$ROUTER" "dark mode" "no dark mode in the router"
hasnt "$ROUTER" "Open Graph" "no Open Graph in the router"
has "$ROUTER" "the skill in the middle column names them" "rule 1 defers the unnamed deliverables to the domain skill"
has "$ROUTER" "method, not craft" "the file says what it is"

echo "the choice rule, domain-neutral (#366: the developer preferred pages built without this router):"
has "$ROUTER" "A choice you would have made for any brief is a default, not a decision" "the choice rule"
has "$ROUTER" "say where it came from" "and it has to be written down"

echo "the router's five rules are the runs' failures:"
has "$ROUTER" "Write the brief table before the first file" "rule 1: the table first"
has "$ROUTER" "A check you did not run is a check that failed" "rule 2: run and paste"
has "$ROUTER" "Never install, never search for tools, never spawn agents" "rule 3: the escape"
has "$ROUTER" "Stop at the report" "rule 5: stop"
has "$ROUTER" "is always first, whatever gate follows" "one report shape: THINK first"
has "$ROUTER" "Thai spellchecker" "rule 3 names the spellchecker run"
has "$ROUTER" "hunting for \`gh\`" "rule 3 names the gh run"
has "$ROUTER" "omitted the same two deliverables" "rule 1 names the omission runs"

echo "the standard's rules each carry a run figure:"
has "$STYLE" "Open Graph 0 / 3 and dark mode 0 / 3" "rule 1: the omission counts"
has "$STYLE" "4 times out of 9" "rule 2: prose transfer rate"
has "$STYLE" "six of them, unprompted" "rule 2: the commands the model ran"
has "$STYLE" "Three rounds of shell/Python escaping" "rule 4: why scripts are files"
has "$STYLE" "if a tool is missing, say so in one line and continue" "rule 5: the escape sentence, verbatim"
has "$STYLE" "5 / 9" "rule 6: a measured anchor"
has "$STYLE" "One with/without pair before merge" "rule 8: the A/B requirement"
has "$STYLE" "isolated \`CLAUDE_CONFIG_DIR\`" "rule 8: isolation, so nothing else reaches the session"
has "$STYLE" "One report shape for the whole family" "rule 9: the shared report"
has "$STYLE" "Done. CODE GATE: 6/6" "rule 9 names the run that lost its pushback"

echo "both state a boundary:"
has "$ROUTER" "What this file does not do" "router boundary"
has "$STYLE" "What this does not touch" "standard boundary"
hasnt "$ROUTER" "60-30-10" "the router restates no design rule"

echo "size: the model reads the router on every task"
r=$(wc -c < "$ROUTER"); [ "$r" -lt 6144 ] && ok "router is $r bytes (< 6 KB)" || bad "router is $r bytes (>= 6 KB)"

echo
echo "qwen38-family: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

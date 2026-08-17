#!/usr/bin/env bash
# The bootstrap RESOLVES A TOOL before declaring it missing, instead of trusting PATH.
#
# WHY THIS RULE EXISTS, measured rather than supposed. On the developer's machine `gh`
# is NOT on the PATH that agent tool shells inherit — `command -v gh` fails while
# `C:\Program Files\GitHub CLI\gh.exe` is installed and working. The bootstrap shells
# out to `gh` in two steps (labels in step 5, the ruleset in step 7), and both fail
# with `gh: command not found` on a machine where GitHub CLI is perfectly fine.
#
# The failure is quiet in the way this repo cares about: steps 1–5 each leave a visible
# file behind, so a bootstrap that could not create a single label looks like one that
# did. That is the same shape as step 11's own argument for reporting the hooks layer
# out loud.
#
# AND THE ORDER MATTERS: this instruction could not have been written before #84. Until
# then an executable invoked by absolute path escaped the gate entirely, so telling an
# agent to fall back to `"C:\...\gh.exe"` would have been telling it how to bypass the
# gate — with no signal that anything was being skipped. #84 made the gate reduce an
# executable to its basename first, which is what makes this advice safe to give.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/t4/t4-project-bootstrap/SKILL.md"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has()   { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$SKILL" ] && ok "the bootstrap skill is present" || bad "SKILL.md is missing"

echo ""
echo "the prerequisite exists, and names the portable check first:"
has "$SKILL" "command -v <tool>" "it checks with 'command -v', which works in every shell it runs in"
has "$SKILL" "where <tool>"      "and names the Windows fallback the developer asked for"
has "$SKILL" "absolute path"     "and says to use the resolved absolute path"

echo ""
echo "IT IS A RULE ABOUT TOOLS, NOT ABOUT gh. `bun` failed the same way in an earlier"
echo "session, and a rule written for one binary would not have covered it:"
has "$SKILL" "bun"         "bun is named alongside gh"
has "$SKILL" ".bun/bin"    "with where it actually lives when PATH misses it"
has "$SKILL" "run-hook.cmd" "and the rule cites the precedent this repo already ships for bash"
has "$SKILL" "#129"        "and the recorded incident where a present tool was called absent"
# The measurement is the argument. A table that lists only the failures reads as
# "PATH is broken here"; the tools that DO resolve are what make it a distinction.
has "$SKILL" "resolve" "the table separates tools that resolve from tools that do not"

echo ""
echo "it covers BOTH steps that shell out, not just the one nearest the text:"
has "$SKILL" "gh label create" "step 5 still creates the labels"
python - "$SKILL" <<'PY'
import re, sys
doc = open(sys.argv[1], encoding="utf-8").read()
# The rule has to be stated BEFORE the first step that uses gh, or an agent reads it
# after it has already failed. Position is the whole point of a prerequisite.
rule = doc.find("command -v <tool>")
first_use = doc.find("gh label create")
assert rule != -1 and first_use != -1, "one of the anchors is missing"
assert rule < first_use, "the rule appears AFTER the first `gh` call it governs"
PY
[ $? -eq 0 ] && ok "and the rule is stated before the first gh call, not after it" \
             || bad "the rule sits after the step it is supposed to precede"

echo ""
echo "it says WHY the absolute-path fallback is safe, which it was not until #84:"
has "$SKILL" "#84" "it cites the fix that made an absolute path visible to the gate"

echo ""
echo "NEGATIVE — the fallback must not be offered as a way around the gate:"
# Not invented wording: these are the two things a helpful-sounding draft of this rule
# would say, and each turns it into something else. "bypass" would frame the fallback
# as a way around the gate — which, before #84, is exactly what it was. Telling the
# agent to put gh on PATH makes a bootstrap step into a change to the developer's
# machine, which no other step in this skill does.
hasnt "$SKILL" "bypass"          "it never frames the absolute path as a way around anything"
hasnt "$SKILL" "add gh to PATH"  "and it does not tell the agent to edit the developer's environment"

echo ""
echo "THE COMPANION ECOSYSTEMS get the same treatment, for the same reason:"
# Step 5 already INVOKES /setup-matt-pocock-skills. It never checked whether that skill
# is installed — so on a machine without it the step fails exactly the way a missing
# `gh` does, and leaves the same misleading trail: the docs land, the tracker
# conventions do not, and the bootstrap looks finished.
has "$SKILL" "the five canonical triage roles" "matt pocock is named, with what the bootstrap uses it FOR"
has "$SKILL" "debug-mantra"             "9arm is named by a skill you can actually look for"
has "$SKILL" "superpowers:using-superpowers" "superpowers is named the same way"
has "$SKILL" "npx skills add thananon/9arm-skills" \
    "and the 9arm install command is the one using-t4 records, not one invented here"

echo ""
echo "the choice belongs to the developer — offer, never install:"
has "$SKILL" "ask the user whether to install"  "it asks rather than installing"
# The trap this forecloses. Installing onto the developer's machine is outward-facing
# and hard to undo, and `t4-dev-workflow` reserves that class of action. An agent that
# reads "the bootstrap needs X" as licence to install X has widened the job.
hasnt "$SKILL" "install them for the user" "it never installs an ecosystem on its own"
python - "$SKILL" <<'PY'
import sys
doc = open(sys.argv[1], encoding="utf-8").read()
# Superpowers has no install command recorded anywhere in this family, so the skill
# must not print one. A plausible-looking invented command is worse than saying ask:
# it fails on the developer's machine with the skill's name on it.
i = doc.find("superpowers")
assert i != -1
window = doc[max(0, i - 400): i + 400]
for invented in ("npx skills add superpowers", "npx skills add obra/superpowers"):
    assert invented not in window, "invented a superpowers install command: %s" % invented
PY
[ $? -eq 0 ] && ok "and it does not invent an install command for the one nobody recorded" \
             || bad "an install command was invented for superpowers"

echo ""
echo "tool-resolution-rule: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

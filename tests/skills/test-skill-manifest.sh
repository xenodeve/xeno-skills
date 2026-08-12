#!/usr/bin/env bash
# Every skill on disk must actually ship.
#
# `skills/design/` sat untracked for an entire development cycle: not in git, so
# `npx skills add` never installed it, the plugin never shipped it, and no test
# noticed — because nothing here enumerated the skills. This closes that.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

skills="$(find skills -name SKILL.md | sort)"
[ -n "$skills" ] && ok "found $(echo "$skills" | wc -l | tr -d ' ') SKILL.md files" || bad "no skills found at all"

echo "every skill is tracked by git (an untracked skill ships to nobody):"
untracked=""
while IFS= read -r f; do
  git ls-files --error-unmatch "$f" >/dev/null 2>&1 || untracked="$untracked $f"
done <<< "$skills"
[ -z "$untracked" ] && ok "all SKILL.md files are tracked" || bad "untracked:$untracked"

echo "every skill declares name + description, and name matches its directory:"
badmeta="" badname=""
while IFS= read -r f; do
  head -12 "$f" | grep -q '^name:' && head -12 "$f" | grep -q '^description:' || badmeta="$badmeta $f"
  declared="$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1 | tr -d '\r')"
  dir="$(basename "$(dirname "$f")")"
  [ "$declared" = "$dir" ] || badname="$badname $f(name=$declared dir=$dir)"
done <<< "$skills"
[ -z "$badmeta" ] && ok "all carry name + description frontmatter" || bad "missing frontmatter:$badmeta"
[ -z "$badname" ] && ok "every declared name matches its directory" || bad "name/dir mismatch:$badname"

echo "no skill is nested inside another skill (npx skills would never find it):"
# skills@1.5.x stops descending the moment a directory has its own SKILL.md
# (dist/cli.mjs: `if (await tryAddSkillAt(childDir) || !walkDeep) continue;`).
# A family directory must therefore NOT be a skill itself, or its children are
# invisible to the installer — which is exactly how 4 design skills shipped
# unusable.
nested=""
while IFS= read -r f; do
  parent="$(dirname "$(dirname "$f")")"
  [ -f "$parent/SKILL.md" ] && nested="$nested $f"
done <<< "$skills"
[ -z "$nested" ] && ok "no SKILL.md sits inside another skill's directory" || bad "undiscoverable (nested):$nested"

echo "every frontmatter PARSES as YAML (grep sees strings; the installer sees a document):"
# t4-bro passed every assertion above and the installer skipped it — an unquoted
# colon-space in `description` made the document invalid. CI's skill-discovery
# job would have caught it and never ran (billing lock), so the check is local.
if python "$(dirname "$0")/check-frontmatter.py"; then
  ok "every SKILL.md frontmatter parses"
else
  bad "a SKILL.md frontmatter does not parse, or no parser was available (see 'parser:' above)"
fi

echo "no machine-specific absolute paths in shipped skill content:"
abs="$(grep -rln 'file:///' skills/ 2>/dev/null)"
[ -z "$abs" ] && ok "no file:/// links (they break on every machine but the author's)" || bad "absolute file:/// links in: $abs"

echo "every skill family is documented in BOTH READMEs:"
missing=""
for fam in $(find skills -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort); do
  for r in README.md README.en.md; do
    grep -qF "skills/$fam/" "$r" || missing="$missing $r:$fam"
  done
done
[ -z "$missing" ] && ok "each family under skills/ is linked from both READMEs" || bad "undocumented:$missing"

echo ""
echo "skill-manifest: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

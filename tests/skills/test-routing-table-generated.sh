#!/usr/bin/env bash
# The routing table and the classifier's closed list are GENERATED from the skill
# graph (#183). A second table maintained by hand is a second routing universe,
# and it drifts the day someone edits one and not the other.
#
# The Thai assertion is not a nicety. The developer writes in Thai; a table built
# from English frontmatter matches almost nothing and falls through on nearly every
# turn, which is the same as having no table at all.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN="$REPO_ROOT/scripts/generate-routing-table.py"
ART="$REPO_ROOT/hooks/routing-table.json"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

echo "the artifact exists and agrees with its source:"
[ -f "$GEN" ] && ok "the generator is committed" || bad "the generator is missing"
[ -f "$ART" ] && ok "the artifact is committed" || bad "the artifact is missing"
if python "$GEN" --check; then ok "the artifact matches the skill graph"
else bad "the artifact is stale -- regenerate it"; fi

echo ""
echo "both artifacts are present, and the closed list is the table's own names:"
python - "$ART" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding="utf-8"))
assert d["skills"] == [r["skill"] for r in d["routes"]], "closed list and table disagree"
assert len(d["skills"]) >= 15, "only %d skills found" % len(d["skills"])
PY
[ $? -eq 0 ] && ok "the closed list is exactly the table's names, so they cannot drift" \
             || bad "the closed list and the table disagree"

echo ""
echo "a Thai prompt matches, which is the case a keyword table usually fails:"
match() { python - "$ART" "$1" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding="utf-8")); p=sys.argv[2].lower()
hits=[r["skill"] for r in d["routes"]
      if any(t and t.lower() in p for t in r["triggers_th"]) or any(t in p for t in r["triggers_en"])]
print(" ".join(sorted(set(hits))))
PY
}
got="$(match 'ช่วยเปิด issue ให้หน่อย')"
case "$got" in *"t4-dev-workflow"*) ok "a Thai prompt routes to the workflow skill";; *) bad "Thai prompt matched: [$got]";; esac
got="$(match 'ระดมความคิดกับหลายโมเดลหน่อย')"
case "$got" in *"clink-brainstorm"*) ok "a second Thai prompt routes to the panel skill";; *) bad "Thai prompt matched: [$got]";; esac
got="$(match 'ทำต่อเลย ไม่ต้องถาม')"
case "$got" in *"t4-afk"*) ok "a third Thai prompt routes to the unattended-batch skill";; *) bad "Thai prompt matched: [$got]";; esac

echo ""
echo "every skill in the graph carries at least one trigger:"
python - "$ART" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding="utf-8"))
empty=[r["skill"] for r in d["routes"] if not r["triggers_en"] and not r["triggers_th"]]
assert not empty, "no triggers for: %s" % empty
PY
[ $? -eq 0 ] && ok "no skill is unroutable" || bad "some skill has no trigger at all"

echo ""
echo "adding a skill to the graph produces it with no hand editing:"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"; rm -rf "$REPO_ROOT/skills/.t4-probe-skill"' EXIT
mkdir -p "$REPO_ROOT/skills/.t4-probe-skill"
printf -- '---\nname: t4-probe-skill\ndescription: A temporary probe skill for the generator test.\n---\n\n# probe\n' \
  > "$REPO_ROOT/skills/.t4-probe-skill/SKILL.md"
if python "$GEN" --check >/dev/null 2>&1; then
  bad "adding a skill did NOT make the check fail -- the check detects nothing"
else
  ok "adding a skill makes the check fail, so the check detects drift"
fi
rm -rf "$REPO_ROOT/skills/.t4-probe-skill"
python "$GEN" --check >/dev/null 2>&1 && ok "removing it makes the check pass again" \
                                      || bad "the check stayed red after the probe was removed"

echo ""
echo "routing-table-generated: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

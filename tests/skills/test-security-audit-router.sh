#!/usr/bin/env bash
# using-security-audit (#420) is a POINTER skill: upstream's security-audit skill changes
# continuously, so no copy of it lives here — only the instruction to install it. Each
# group below is a way the pointer silently stops working. Identity, README listing and
# ask-xeno reachability are owned by test-skill-manifest.sh and test-ask-xeno-router.sh.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
S="$REPO_ROOT/skills/security-audit/using-security-audit/SKILL.md"
BUDGET=5000

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { [ -f "$S" ] && grep -qF -- "$1" "$S"; }

cd "$REPO_ROOT" || exit 1
[ -f "$S" ] && ok "SKILL.md exists" || bad "$S is missing"

echo "the exact install command (checked 2026-10-12: --list names only security-audit):"
has 'npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit' \
  && ok "install command names the upstream URL and --skill" || bad "install command missing or altered"

echo "where it runs, and why (npx skills add inside this repo destroyed it on 2026-08-12):"
has 'Run it from outside xeno-skills' && ok "tells the agent to run it outside xeno-skills" \
  || bad "does not say 'Run it from outside xeno-skills'"
has 'destroyed' && ok "states the incident" || bad "does not state why"

echo "upstream's requirements and the hand-off when they are not met:"
for req in "sub-agent" "Node.js" "sandbox" "needs_validation" "security-review"; do
  has "$req" && ok "names: $req" || bad "does not name: $req"
done

echo "the untested part is labelled:"
has 'unverified' && ok "pinning is marked unverified" || bad "no 'unverified' label"

echo "nothing from upstream is vendored (a directory named security-audit holding a SKILL.md):"
vendored() { find "$1" -path '*/security-audit/SKILL.md'; }
[ -z "$(vendored "$REPO_ROOT/skills")" ] && ok "no skills/**/security-audit/SKILL.md" \
  || bad "upstream was vendored: $(vendored "$REPO_ROOT/skills")"
ctl="$(mktemp -d)"; trap 'rm -rf "$ctl"' EXIT
mkdir -p "$ctl/skills/x/security-audit"; : > "$ctl/skills/x/security-audit/SKILL.md"
[ -n "$(vendored "$ctl/skills")" ] && ok "control: the detector flags a planted copy" \
  || bad "control: the detector cannot see a vendored copy"

echo "size — a pointer that grows is becoming a copy:"
if [ -f "$S" ]; then
  bytes=$(wc -c < "$S" | tr -d ' ')
  [ "$bytes" -le "$BUDGET" ] && ok "SKILL.md ${bytes}B <= ${BUDGET}B" || bad "SKILL.md ${bytes}B exceeds ${BUDGET}B"
else bad "cannot measure size, skill is missing"; fi

echo ""
echo "security-audit-router: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

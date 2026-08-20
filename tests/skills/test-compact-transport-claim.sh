#!/usr/bin/env bash
# The plan's transport claims must not exceed the evidence recorded for them (#305, PRD #304).
#
# A documentation-integrity suite, and a narrow one: it does NOT test the CLI. It tests that
# `docs/plans/2026-08-21-t4-compact.md` and the fixture agree -- that every capability the
# plan builds on appears in the run that was actually observed.
#
# WHY THIS SHAPE. Two revisions of that plan were wrong because a string in a binary was read
# as a capability. The correction was to RUN it: `scripts/probe-stream-transport.py` drove a
# real session, sent /compact as a user message, and recorded what came back. This suite
# pins the claim to that recording, so a later edit cannot quietly widen the claim past it.
#
# WHAT A GREEN HERE DOES NOT MEAN. The fixture is from claude 2.1.222 on 2026-08-21. A newer
# build can change the contract and this stays green -- which is why the probe script exists
# and says RUN THIS, DO NOT TRUST THE FIXTURE, and why the plan's rows carry their date.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLAN="${1:-$REPO_ROOT/docs/plans/2026-08-21-t4-compact.md}"
FIX="${2:-$REPO_ROOT/tests/hooks/fixtures/t4-compact-stream-transport.jsonl}"
PROBE="$REPO_ROOT/scripts/probe-stream-transport.py"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }
has() { case "$(cat "$1")" in *"$2"*) ok "$3";; *) bad "$3 (missing: $2)";; esac; }
hasnt() { case "$(cat "$1")" in *"$2"*) bad "$3 (found: $2)";; *) ok "$3";; esac; }

[ -f "$PLAN" ]  && ok "the plan is present"    || { bad "the plan is missing"; exit 1; }
[ -f "$FIX" ]   && ok "the fixture is present" || { bad "the fixture is missing"; exit 1; }
[ -f "$PROBE" ] && ok "the probe script is present, so the fixture can be re-earned" \
                || bad "the probe script is gone — the fixture becomes unfalsifiable"

echo ""
echo "THE FIXTURE CARRIES THE OBSERVATION THE PLAN RESTS ON:"
has "$FIX" '"status": "compacting"' "the compaction started"
has "$FIX" '"compact_result": "success"' "and finished — the slash command EXECUTED"
has "$FIX" '"compact_boundary"' "the transcript boundary a validator anchors freshness on"
has "$FIX" '"isCompactSummary": true' "and the summary record that follows it"
has "$FIX" '"cache_read_input_tokens"' "per-result usage, which is the running context size"

echo ""
echo "THE COMMANDS THE LAYER SENDS ARE ONES THE SESSION ADVERTISES:"
python - "$FIX" <<'PYX'
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1], encoding="utf-8") if l.strip()]
init = next((r for r in rows if r.get("subtype") == "init"), None)
assert init, "no init row in the fixture"
sample = init.get("slash_commands_sample") or []
for name in ("compact", "handoff"):
    assert name in sample, "the session did not advertise /%s" % name
PYX
[ $? -eq 0 ] && ok "/compact and /handoff were both advertised by the running session" \
             || bad "a command the design sends is not in the observed slash_commands"

echo ""
echo "AND THE PLAN DOES NOT CLAIM A MECHANISM IT NEVER OBSERVED:"
# The two revisions that were wrong both leaned on a capability nobody had run. The plan may
# describe the fallback, but it must not present console automation as the transport.
python - "$PLAN" <<'PYX'
import re, sys
doc = open(sys.argv[1], encoding="utf-8").read()
i = doc.lower().find("sendkeys")
if i != -1:
    window = doc[max(0, i-300):i+300].lower()
    assert "not" in window or "is not" in window, \
        "SendKeys appears without being ruled out"
assert "--input-format stream-json" in doc, "the transport is not named in the plan"
assert "--replay-user-messages" in doc, "the acknowledgement mechanism is not named"
PYX
[ $? -eq 0 ] && ok "the plan names the observed transport, and console automation only as excluded" \
             || bad "the plan's transport claim has drifted from the evidence"

echo ""
echo "THE NEGATIVE THAT CARRIES IT — the superseded mechanism must not sit beside the new one:"
# Revision 2 said the layer "moves the ceiling" instead of sending the command, and revision 1
# rode auto-compaction. Both were replaced once the transport was RUN. A plan that still
# presents either as the mechanism contradicts the run that is now its evidence -- and that
# contradiction is invisible to any assertion that only checks the new wording is present.
hasnt "$PLAN" "The layer moves the ceiling" \
      "revision 2's ceiling-moving mechanism is not still presented as the design"
hasnt "$PLAN" "the layer should stop trying to trigger compaction" \
      "revision 1's ride-the-harness mechanism is gone too"

echo ""
echo "the probe says out loud that a fixture is not a live contract:"
has "$PROBE" "DO NOT TRUST THE FIXTURE" "the re-probe instruction is in the script itself"

echo ""
echo "compact-transport-claim: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

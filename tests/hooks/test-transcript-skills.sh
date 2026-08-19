#!/usr/bin/env bash
# Which skills has this session actually invoked? (#184)
# Seam: a transcript path -> one skill name per line. A pure function over a file.
#
# The two properties that decide whether the answer is right or merely non-empty:
# both record types count, and counting starts at the LAST compaction boundary.
# A detector reading tool-use records alone reported a skill loaded three times as
# never loaded, on a real session.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-transcript-skills"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Record builders -- the shapes were read from a real transcript, not invented.
tooluse() { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"%s"}}]}}\n' "$1"; }
slash()   { printf '{"type":"user","message":{"content":"<command-name>/%s</command-name>"}}\n' "$1"; }
slashblk(){ printf '{"type":"user","message":{"content":[{"type":"text","text":"<command-name>/%s</command-name>"}]}}\n' "$1"; }
boundary(){ printf '{"type":"compact_boundary"}\n'; }
noise()   { printf '{"type":"attachment","message":{"content":[{"type":"tool_use","name":"Read","input":{"file_path":"x"}}]}}\n'; }

run() { bash "$HOOK" "$1" 2>/dev/null; }

echo "both record types count -- reading one kind is a wrong answer, not a partial one:"
F="$TMP/both.jsonl"; { tooluse using-t4; slash tdd; slashblk scrutinize; noise; } > "$F"
got="$(run "$F" | tr '\n' ' ')"
case "$got" in *"using-t4"*) ok "a tool-use invocation is counted";;   *) bad "tool-use missed: [$got]";; esac
case "$got" in *"tdd"*)      ok "a slash command in a string field is counted";; *) bad "slash-string missed: [$got]";; esac
case "$got" in *"scrutinize"*) ok "a slash command in a text block is counted";; *) bad "slash-block missed: [$got]";; esac
case "$got" in *"Read"*) bad "a non-Skill tool was counted as a skill";; *) ok "a non-Skill tool is not counted";; esac

echo ""
echo "counting starts at the LAST compaction boundary:"
F="$TMP/one.jsonl"; { tooluse before-one; boundary; tooluse after-one; } > "$F"
got="$(run "$F" | tr '\n' ' ')"
case "$got" in *"after-one"*)  ok "a skill invoked after the boundary is reported";; *) bad "missed after-boundary: [$got]";; esac
case "$got" in *"before-one"*) bad "a carried skill was reported as loaded";;        *) ok "a carried skill is reported as NOT loaded";; esac

F="$TMP/many.jsonl"; { tooluse a1; boundary; tooluse a2; boundary; tooluse a3; slash a4; } > "$F"
got="$(run "$F" | tr '\n' ' ')"
case "$got" in *"a3"*) ok "several boundaries: the last one wins";; *) bad "missed post-last-boundary: [$got]";; esac
case "$got" in *"a4"*) ok "and a slash command after it is counted";; *) bad "missed: [$got]";; esac
case "$got" in *"a2"*) bad "a skill from before the LAST boundary leaked in";; *) ok "an earlier segment does not leak in";; esac

F="$TMP/none.jsonl"; { tooluse solo; } > "$F"
[ "$(run "$F" | tr -d '[:space:]')" = "solo" ] && ok "no boundary: the whole file counts" || bad "no-boundary case wrong"

echo ""
echo "it fails to empty rather than raising:"
for case_name in missing empty garbage truncated; do
  case "$case_name" in
    missing)   T="$TMP/does-not-exist.jsonl" ;;
    empty)     T="$TMP/empty.jsonl";     : > "$T" ;;
    garbage)   T="$TMP/garbage.jsonl";   printf 'not json{\n\n[]\n' > "$T" ;;
    truncated) T="$TMP/trunc.jsonl";     { tooluse kept; printf '{"type":"assis' ; } > "$T" ;;
  esac
  out="$(bash "$HOOK" "$T" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then ok "$case_name: exit zero"; else bad "$case_name: exit $rc ($out)"; fi
done
[ "$(bash "$HOOK" "$TMP/trunc.jsonl" 2>/dev/null | tr -d '[:space:]')" = "kept" ] \
  && ok "a truncated final line does not discard the records before it" \
  || bad "a truncated final line lost earlier records"

echo ""
echo "the stated boundary: built-ins are returned, not filtered, and the header says so:"
F="$TMP/builtin.jsonl"; { slash compact; slash goal; tooluse using-t4; } > "$F"
got="$(run "$F" | tr '
' ' ')"
case "$got" in *"compact"*) ok "a built-in slash command is returned rather than silently dropped";; *) bad "built-in was filtered without a table to filter against: [$got]";; esac
if grep -q "the caller\s*$" "$HOOK" || grep -q "intersects with it" "$HOOK"; then
  ok "the header states that the caller must intersect with the routing table"
else
  bad "the over-reporting boundary is not stated where a caller would read it"
fi

echo ""
echo "no argument is a no-op, not an error:"
out="$(bash "$HOOK" 2>&1)"; rc=$?
{ [ "$rc" -eq 0 ] && [ -z "$out" ]; } && ok "no path: exit zero, no output" || bad "no path: exit $rc [$out]"

echo ""
echo "transcript-skills: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

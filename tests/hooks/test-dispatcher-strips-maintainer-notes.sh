#!/usr/bin/env bash
# `using-t4/SKILL.md` is injected VERBATIM by t4-session-start (line 41,
# `content="$(<"$f")"`), and the injected output is capped at 9000 B by
# tests/hooks/test-dispatcher-content.sh. Measured 2026-08-05 it was 8965 B —
# THIRTY-FIVE BYTES of headroom.
#
# #105 asks that the file carry a visible note saying it is under that ceiling.
# Written naively that note is self-defeating twice over: it does not fit, and
# its audience is the person EDITING the file, not the session receiving the
# map. Injecting "this file has a byte ceiling" into every session start and
# every compaction, forever, spends the very budget it is warning about.
#
# So the dispatcher strips HTML comments. A maintainer note costs the reader of
# the file everything and the injected budget nothing.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/hooks/t4-session-start"

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# A fake plugin root, so the fixture is what gets injected rather than the real skill.
mkdir -p "$TMP/plugin/skills/t4/using-t4"
cat > "$TMP/plugin/skills/t4/using-t4/SKILL.md" <<'FIXTURE'
# Using T4
<!-- MAINTAINERS: this file is injected verbatim and capped. NOTE_MUST_NOT_LEAK -->
Route first before you respond.
<!--
NOTE_MUST_NOT_LEAK_MULTILINE
-->
The map ends here.
FIXTURE

cat >> "$TMP/plugin/skills/t4/using-t4/SKILL.md" <<'FIXTURE2'
Prose with <!-- an inline note --> and LIVE_PROSE_AFTER_COMMENT that must survive.
FIXTURE2

mkdir -p "$TMP/repo/.claude"; printf '{"t4":true}\n' > "$TMP/repo/.claude/t4.json"
out="$( cd "$TMP/repo" && printf '{"session_id":"s1"}' \
  | CLAUDE_PLUGIN_ROOT="$TMP/plugin" T4_HOOK_LOCK_DIR="$TMP/l" bash "$HOOK" )"

echo "a maintainer note never reaches the session:"
case "$out" in
  *NOTE_MUST_NOT_LEAK_MULTILINE*) bad "multi-line HTML comment is stripped";;
  *) ok "multi-line HTML comment is stripped";;
esac
case "$out" in
  *NOTE_MUST_NOT_LEAK*) bad "single-line HTML comment is stripped";;
  *) ok "single-line HTML comment is stripped";;
esac

echo
echo "and the map itself still arrives — stripping must not eat content:"
case "$out" in
  *"Route first before you respond."*) ok "prose between comments survives";;
  *) bad "prose between comments survives";;
esac
case "$out" in
  *"The map ends here."*) ok "prose after a multi-line comment survives";;
  *) bad "prose after a multi-line comment survives";;
esac
case "$out" in
  *"# Using T4"*) ok "the heading survives";;
  *) bad "the heading survives";;
esac

# Traced 2026-08-05 while scrutinising #105: the first version dropped any line
# CONTAINING `<!--`, so a line mixing prose with a trailing note vanished
# whole. The limitation was documented and nothing enforced it — and the content
# test only guards five phrases, so losing any OTHER line passed silently. Only
# lines that are entirely a comment may be removed.
case "$out" in
  *LIVE_PROSE_AFTER_COMMENT*) ok "prose sharing a line with a comment is not dropped";;
  *) bad "prose sharing a line with a comment is not dropped";;
esac

echo
if [ "$fail" -gt 0 ]; then echo "FAILED: $fail, passed: $pass"; exit 1; fi
echo "OK: $pass passed"

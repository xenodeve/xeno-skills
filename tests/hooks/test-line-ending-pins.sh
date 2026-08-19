#!/usr/bin/env bash
# Everything git executes, or byte-compares, is pinned to LF (#260).
#
# THE FAILURE THIS PREVENTS, hit three times. `.gitattributes` pinned the INSTALLED side
# by glob and the CANONICAL side file-by-file -- four entries, written when `hooks/` held
# four files. It now holds two dozen. Every hook added since was unpinned on one side and
# pinned on the other, so a Windows checkout gave the two sides opposite endings and the
# byte-exact sync check reported DRIFTED on files whose content is identical.
#
# The CR was in the committed blob, not only in the checkout: `git show HEAD:hooks/t4-classifier`
# carried 182 of them. So these are bash scripts that git hands to an interpreter with CR
# on every line -- which `.gitattributes` own comment already says breaks the shebang and
# leaks into strings. It was stating that about the four files it pinned.
#
# WHY THIS TEST IS ABOUT THE CLASS AND NOT THE INSTANCE. A list of filenames is what
# failed: it cannot notice the file added tomorrow. The assertion is that every file in
# each of these directories resolves eol=lf, so a new hook is covered on the day it lands
# or this suite goes red naming it.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

pass=0 fail=0
ok()  { echo "  PASS: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1"; fail=$((fail+1)); }

# Executed by bash through run-hook.cmd, or by git, or byte-compared against each other.
DIRS="hooks .claude/hooks .githooks skills/t4/t4-project-bootstrap/references/hooks skills/t4/t4-project-bootstrap/references/guards"

echo "every file git executes or byte-compares is pinned eol=lf:"
for d in $DIRS; do
  [ -d "$d" ] || { bad "$d is missing"; continue; }
  unpinned=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$(git check-attr eol -- "$f" 2>/dev/null)" in
      *": lf") ;;
      *) unpinned="$unpinned $f" ;;
    esac
  done < <(git ls-files "$d")
  if [ -n "$unpinned" ]; then
    bad "$d has unpinned files:$unpinned"
  else
    ok "$d"
  fi
done

echo ""
echo "and every SKILL.md, because a skill's VERSION is the sha of its bytes:"
# tests/hooks/test-skill-version.sh: "the version is the sha of the file itself". An
# unpinned SKILL.md hashes differently per checkout, so docs/research/rule-traces.md
# publishes one machine's answer and every other machine reports a mismatch.
unpinned=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$(git check-attr eol -- "$f" 2>/dev/null)" in
    *": lf") ;;
    *) unpinned="$unpinned $f" ;;
  esac
done < <(git ls-files '*/SKILL.md')
[ -z "$unpinned" ] && ok "every SKILL.md is pinned" || bad "unpinned SKILL.md:$unpinned"

echo ""
echo "no CR survives in the committed blobs of those files:"
# The attribute governs future checkouts; this reads what is actually stored. Both are
# needed -- adding the pin without `git add --renormalize` leaves the blobs as they were.
withcr=""
for d in $DIRS; do
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in *.png|*.jpg|*.ico) continue;; esac
    if git show "HEAD:$f" 2>/dev/null | grep -q $'\r'; then withcr="$withcr $f"; fi
  done < <(git ls-files "$d")
done
[ -z "$withcr" ] && ok "no CR in any committed hook or guard blob" \
                 || bad "CR is in the committed blob of:$withcr"

echo ""
echo "and no RAW control byte is embedded in any of them:"
# THE DEFECT THIS CAUGHT, in code written the same day. `hooks/t4-gate` gained a
# _display_cmd that strips control bytes from PR-author-controlled text -- and the
# generator that wrote it emitted the RANGE as raw bytes instead of as the escape TEXT
# `tr` expects, so the file itself carried NUL, BS, VT, US and DEL. bash cannot hold NUL
# in a string, so `tr` was handed a different set than the one written down. The gate
# suite passed BOTH WAYS, which is the point: a behavioural assertion cannot see the
# difference between a set that works and a set that happens to work.
#
# Tab and newline are the only control characters a shell script has any business
# containing. Anything else is a generator bug, and it is invisible in a diff.
ctl=""
for d in $DIRS; do
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in *.png|*.jpg|*.ico) continue;; esac
    if LC_ALL=C perl -ne 'exit 1 if /[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/' "$f"; then :; else ctl="$ctl $f"; fi
  done < <(git ls-files "$d")
done
[ -z "$ctl" ] && ok "only tab and newline appear as control characters"               || bad "raw control bytes in:$ctl"

echo ""
echo "line-ending-pins: $pass passed, $fail failed"
[ "$fail" -eq 0 ]

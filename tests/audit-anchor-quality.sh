#!/usr/bin/env bash
# Report-only audit of assertion quality across the shell suites (#115).
# Never fails a build; prints findings and exits 0.
#
# WHAT THIS CAN AND CANNOT DECIDE — recorded because the first version of this
# script, written by a delegated worker, got it wrong in both directions:
#
#   - It flagged suites with ZERO anchors as defective. A suite that makes no
#     `has` call cannot need a `hasnt`; run-all.sh and test-figures-sourced.sh
#     are structural, not defective.
#   - It flagged every anchor containing no space, which condemns `446` — a
#     measured token count, and one of the best anchors in this repo precisely
#     because a reader can check it against reality. Whitespace is not a proxy
#     for quality.
#
# Ambiguity is NOT fully mechanically detectable: knowing that an anchor matched
# the WRONG line requires knowing which line was intended. So this reports the
# three things that ARE decidable and leaves the judgement to a human.
#
#   A. POSITIVE-ONLY — the suite makes `has` calls and never a `hasnt`, so a
#      partial edit that adds new wording BESIDE the old one passes. Counted
#      only for suites that actually assert on content.
#   B. SHADOWED ANCHOR — one anchor is a proper substring of another anchor in
#      the same suite. This is the exact shape of the #63 defect, where
#      `--check` passed on the strength of `--check-only`.
#   C. LOOSE MATCH — the anchor matches more than one line of its target file,
#      so which line satisfied it is not determined by the assertion.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT" || exit 0

suites=0; positive_only=0; shadowed=0; loose=0; anchors_total=0

echo "Anchor quality audit  (report only — nothing here fails a build)"
echo "==============================================================="
echo

for suite in tests/*/*.sh; do
  [ -f "$suite" ] || continue
  suites=$((suites + 1))

  mapfile -t calls < <(grep -oE '^[[:space:]]*(has|hasnt) +"[^"]*" +"[^"]*"' "$suite" 2>/dev/null || true)
  [ "${#calls[@]}" -eq 0 ] && continue

  # Anchors are kept WITH the target they assert against. Two anchors can only
  # shadow each other if they point at the same file — an early version of this
  # script compared them suite-wide and reported `not-run` (asserted on $REF)
  # as shadowed by `ran / not-run / n-a` (asserted on $AFK), which is not a
  # defect at all. That was the same over-broad flagging this script exists to
  # correct, reproduced by its own author.
  has_anchors=(); has_targets=(); hasnt_count=0
  for c in "${calls[@]}"; do
    anchor="$(printf '%s' "$c" | sed -E 's/^[[:space:]]*(has|hasnt) +"[^"]*" +"([^"]*)".*/\2/')"
    target_var="$(printf '%s' "$c" | sed -E 's/^[[:space:]]*(has|hasnt) +"\$\{?([A-Za-z_]+)\}?" +.*/\2/')"
    case "$c" in
      *hasnt*) hasnt_count=$((hasnt_count + 1)) ;;
      *)       has_anchors+=("$anchor"); has_targets+=("$target_var") ;;
    esac
    anchors_total=$((anchors_total + 1))
  done

  findings=""
  if [ "${#has_anchors[@]}" -gt 0 ] && [ "$hasnt_count" -eq 0 ]; then
    findings="${findings}  A. POSITIVE-ONLY — ${#has_anchors[@]} has, 0 hasnt: a stale claim left beside a new one passes\n"
    positive_only=$((positive_only + 1))
  fi

  for i in "${!has_anchors[@]}"; do
    for j in "${!has_anchors[@]}"; do
      [ "$i" = "$j" ] && continue
      # Same target file, or it is not shadowing.
      [ "${has_targets[$i]}" = "${has_targets[$j]}" ] || continue
      a="${has_anchors[$i]}"; b="${has_anchors[$j]}"
      [ "$a" = "$b" ] && continue
      case "$b" in
        *"$a"*)
          findings="${findings}  B. SHADOWED — \"$a\" is a substring of \"$b\" (both on \$${has_targets[$i]}); the shorter can pass on the longer\n"
          shadowed=$((shadowed + 1)); break ;;
      esac
    done
  done

  for target in $(grep -oE '^[A-Za-z_]+="\$REPO_ROOT/[^"]*"' "$suite" 2>/dev/null \
                  | sed -E 's/.*"\$REPO_ROOT\/([^"]*)"/\1/'); do
    [ -f "$target" ] || continue
    for a in "${has_anchors[@]}"; do
      n=$(grep -cF -- "$a" "$target" 2>/dev/null || true)
      [ -z "$n" ] && n=0
      if [ "$n" -gt 1 ]; then
        findings="${findings}  C. LOOSE — \"$a\" matches $n lines of $target\n"
        loose=$((loose + 1))
      fi
    done
  done

  if [ -n "$findings" ]; then
    echo "$suite"
    printf '%b' "$findings"
    echo
  fi
done

echo "Summary"
echo "-------"
echo "suites scanned:            $suites"
echo "anchors examined:          $anchors_total"
echo "positive-only suites (A):  $positive_only"
echo "shadowed anchors (B):      $shadowed"
echo "loose matches (C):         $loose"
echo
echo "A suite absent from the list above asserts on content and carries a negative check."
exit 0

#!/usr/bin/env bash
# Audit of assertion quality across the shell suites (#115, #142).
#
# FINDING A NOW FAILS. It was report-only, and #142 recorded what that bought: the
# script detected a real defect class, ran, printed it, and exited 0 -- so the
# finding was routed to stdout and nothing acted on it. A is the one category that
# is MECHANICALLY DECIDABLE: whether a file contains a `hasnt` call involves no
# judgement at all. B and C stay report-only, because deciding whether an anchor
# matched the WRONG line requires knowing which line was intended, and this script
# does not claim judgement it cannot exercise.
#
# The exemption list below is the whole of the discretion, and it is stated per
# suite with its reason rather than being a bare list of names.
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
#
# CLASSIFICATION (#115). "Positive-only" is a finding for a CORRECTIVE suite —
# one pinning wording that replaced something wrong — and noise for a
# PRESERVATION or STRUCTURAL one, where there is no withdrawn claim to exclude.
# Judged by reading each suite's stated purpose; a suite listed here is exempt
# from finding A, and one that is not listed is treated as corrective.
#
#   PRESERVATION — pins a rule that would rot by being deleted or softened, not
#   by acquiring a rival sentence. A negative assertion would have to invent the
#   wording it excludes, which is the defect #113 describes, in a mirror.
#     test-anti-sticking-rule · test-backgrounded-call-rule · test-exemption-rule
#     test-offered-skip-rule · test-root-cause-rule · test-verdict-rule
#     test-delegation-precondition
#
#   STRUCTURAL — asserts two places agree, or that generated artifacts match
#   their documentation. Nothing was ever withdrawn.
#     test-surgical-completion-rule (section 3 gained a case it did not reach --
#       completing something incomplete -- alongside improving and deleting. The
#       existing bullets are kept, so nothing was withdrawn; it also asserts the
#       section stayed SHORT, which is a size claim rather than a wording one.)
#     test-prompt-audit-rule (asserts step 1 and the convergence section agree and
#       reference each other. The rule ADDS a pre-call audit where the skill had
#       only post-hoc pressure; the convergence section's framing is kept, not
#       withdrawn, so there is no prior wording to retire.)
#     test-clink-prefix-rule (the skill's claim about hooks/t4-delegation-gate
#       is checked against that file; the rule ADDS a resolution step where the
#       family had none, so there is no prior wording to retire. Spelling the
#       prefix as `mcp__pal__clink` is not withdrawn either -- the rule keeps it
#       as this machine's instance and names it as such.)
#     test-ci-templates (job names == required-check contexts)
#     test-survey-rule  (the pipeline is listed in several places and must agree)
#     test-gate-ledger-rule (the trailer's vocabulary appears in every consumer)
#     test-bootstrap-wiring-rule
#     test-repo-self-bootstrap (this repo's own install against the standard it
#       ships — the repo root IS the system under test; nothing was withdrawn)
#
#   CLASSIFIED 2026-08-16 while giving finding A teeth (#142). Two suites were
#   corrective-by-omission rather than by judgement, and reading them says
#   otherwise:
#     test-bro-rule — PRESERVATION. Its own header says every device is "the kind
#       of thing a well-meaning rewrite deletes". And t4-bro QUOTES its retired
#       phrasings in a before/after table in order to reject them, so a `hasnt`
#       against them would fail on the CORRECTED text — the exact trap recorded
#       below.
#     test-repo-self-bootstrap — STRUCTURAL, listed above.
#
# THE TRAP THAT MAKES A NAIVE `hasnt` WORSE THAN NONE, found while classifying:
# a corrected document usually QUOTES the withdrawn claim in order to reject it.
# `t4-project-bootstrap` says *"goes in as a standing default, not as a pointer"*
# and then explains what a "pointer to the entry map" does wrong — so
# `hasnt "pointer to the entry map"` would fail against the CORRECTED text. A
# negative assertion has to target the claim in its ASSERTED form, not any
# mention of it. Where that form cannot be quoted, add nothing.
set -uo pipefail

# --only-a skips findings B and C. They cost ~51 s, because each anchor is matched
# against its target file -- and `.claude/t4.json`'s `verify` runs before every
# `gh pr merge`. A gate that adds a minute to every merge is a gate people route
# around. A is a `grep -c` and runs in under a second, and A is what fails a build;
# B and C stay a report someone runs deliberately.
ONLY_A=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --root SCANS SOMEWHERE ELSE, and it exists so the positive control does not have to
# write its probe into the tree this script globs. It did, and two concurrent runs
# then saw each other's probe -- reproduced 2026-08-17, one run red and one green on
# the same commit. `t4-gate` runs `verify` before every merge while the session may
# also be running it, so that flake denied a merge on a suite that was not failing.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --only-a) ONLY_A=1 ;;
    --root)   shift; REPO_ROOT="${1:-$REPO_ROOT}" ;;
    *)        ;;
  esac
  shift
done

# Suites exempt from finding A — see CLASSIFICATION above.
NOT_CORRECTIVE="test-anti-sticking-rule test-backgrounded-call-rule test-exemption-rule
test-offered-skip-rule test-root-cause-rule test-verdict-rule test-delegation-precondition
test-ci-templates test-survey-rule test-gate-ledger-rule test-bootstrap-wiring-rule
test-bro-rule test-repo-self-bootstrap test-clink-prefix-rule test-prompt-audit-rule test-surgical-completion-rule"
cd "$REPO_ROOT" || exit 0

suites=0; positive_only=0; shadowed=0; loose=0; anchors_total=0

echo "Anchor quality audit  (finding A fails; B and C report)"
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
  # Extraction is PURE BASH -- no subprocess per assertion. It used to spawn two
  # `sed` processes for every `has`/`hasnt` call in the tree, which cost ~29 s and
  # meant `--only-a` was no faster than the full audit: the "cheap path" that exists
  # to keep `verify` quick was not cheap. Measured before and after, not assumed.
  has_anchors=(); has_targets=(); hasnt_count=0
  for c in "${calls[@]}"; do
    rest="${c#*\"}"                      # drop up to the first quote
    target_raw="${rest%%\"*}"            # first quoted field -> the target
    rest="${rest#*\"}"; rest="${rest#*\"}"
    anchor="${rest%%\"*}"                # second quoted field -> the anchor
    target_var="${target_raw#\$}"; target_var="${target_var#\{}"; target_var="${target_var%\}}"
    case "$c" in
      *hasnt*) hasnt_count=$((hasnt_count + 1)) ;;
      *)       has_anchors+=("$anchor"); has_targets+=("$target_var") ;;
    esac
    anchors_total=$((anchors_total + 1))
  done

  findings=""
  name="$(basename "$suite" .sh)"
  corrective=1
  case " $(printf '%s' "$NOT_CORRECTIVE" | tr '\n' ' ') " in *" $name "*) corrective=0 ;; esac
  if [ "$corrective" -eq 1 ] && [ "${#has_anchors[@]}" -gt 0 ] && [ "$hasnt_count" -eq 0 ]; then
    findings="${findings}  A. POSITIVE-ONLY — ${#has_anchors[@]} has, 0 hasnt: a stale claim left beside a new one passes\n"
    positive_only=$((positive_only + 1))
  fi

  if [ "$ONLY_A" -eq 0 ]; then
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
  fi

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
echo "A is reported only for CORRECTIVE suites — see CLASSIFICATION in this file's header."
echo "A zero there is not self-evidently a clean result: add a suite that asserts"
echo "positively and is not in NOT_CORRECTIVE, and it must appear. If it does not,"
echo "this check is broken rather than satisfied."
echo
if [ "$positive_only" -gt 0 ]; then
  echo "FAIL: $positive_only corrective suite(s) can only ever ADD, never retire."
  echo "      Such a suite pins the new wording and cannot notice the old, now-wrong"
  echo "      wording sitting beside it: both sentences coexist, the suite is green,"
  echo "      and the skill contradicts itself in the file an agent actually loads."
  echo "      Either add a \`hasnt\` pinning the wording the rule REPLACED — in its"
  echo "      ASSERTED form, not any mention of it — or, if the rule replaced nothing,"
  echo "      classify the suite in NOT_CORRECTIVE with its reason. An explicit"
  echo "      exemption, never silence."
  exit 1
fi
echo "A: clean. B and C stay report-only: deciding whether an anchor matched the"
echo "WRONG line needs to know which line was intended, and this script does not"
echo "claim judgement it cannot exercise."
exit 0

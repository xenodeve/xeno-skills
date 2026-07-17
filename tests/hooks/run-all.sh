#!/usr/bin/env bash
# Run every hook contract test and aggregate the result.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
rc=0
for t in "$DIR"/test-*.sh; do
  echo "== $(basename "$t") =="
  bash "$t" || rc=1
  echo
done
if [ "$rc" -eq 0 ]; then echo "ALL HOOK TESTS PASSED"; else echo "SOME HOOK TESTS FAILED"; fi
exit "$rc"

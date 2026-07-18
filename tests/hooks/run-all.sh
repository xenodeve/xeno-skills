#!/usr/bin/env bash
# Run every contract test under tests/ (hooks + skills) and aggregate the result.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
rc=0
while IFS= read -r t; do
  echo "== ${t#"$ROOT"/} =="
  bash "$t" || rc=1
  echo
done < <(find "$ROOT" -name 'test-*.sh' | sort)
if [ "$rc" -eq 0 ]; then echo "ALL TESTS PASSED"; else echo "SOME TESTS FAILED"; fi
exit "$rc"

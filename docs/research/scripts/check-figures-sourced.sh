#!/usr/bin/env bash
# Fail if a skill quotes a figure that is not in the structured file it names.
#
# Usage: check-figures-sourced.sh <skill-file> [repo-root]
# Exit:  0 = no figures block, or every figure traced
#        2 = VIOLATION (this code and only this code means "rule broken")
#        1 = the check could not run
#
# The exit codes are load-bearing. A caller that treats any non-zero as
# "rejected" cannot tell a broken rule from a missing interpreter, and will go
# green while nothing is being checked.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SKILL="${1:-}"
ROOT="${2:-$(cd "$HERE/../../.." && pwd)}"

if [ -z "$SKILL" ] || [ ! -f "$SKILL" ]; then
  echo "usage: $(basename "$0") <skill-file> [repo-root]" >&2
  exit 1
fi

for py in python3 python; do
  if command -v "$py" >/dev/null 2>&1; then
    PYTHONIOENCODING=utf-8 "$py" "$HERE/_check_figures.py" "$SKILL" "$ROOT"
    exit $?
  fi
done

echo "cannot run: no python interpreter on PATH" >&2
exit 1

#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
LOG="$2"
errors=0

if ! grep -qi "banana" "$LOG"; then
  echo "FAIL: error message doesn't show the invalid state value"
  errors=$((errors + 1))
fi

exit "$errors"

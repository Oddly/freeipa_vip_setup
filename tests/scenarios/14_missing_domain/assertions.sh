#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
LOG="$2"
errors=0

# Should mention domain in error
if ! grep -qi "freeipa_domain" "$LOG"; then
  echo "FAIL: error message doesn't mention freeipa_domain"
  errors=$((errors + 1))
fi

exit "$errors"

#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
LOG="$2"
errors=0

# Should have completed without errors — that's the main test
# (no pre_state.sh = empty state = everything already absent)

# Verify no state was accidentally created
if [[ -f "${STATE}/dns_a/example.com/haproxy-vip" ]]; then
  echo "FAIL: A-record was created during absent run"
  errors=$((errors + 1))
fi
if [[ -f "${STATE}/hosts/haproxy-vip.example.com" ]]; then
  echo "FAIL: host was created during absent run"
  errors=$((errors + 1))
fi

exit "$errors"

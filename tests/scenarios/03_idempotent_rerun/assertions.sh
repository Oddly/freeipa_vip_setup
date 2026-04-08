#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
LOG="$2"
errors=0

# Check ansible output for changed=0
if grep -q 'changed=[1-9]' "$LOG"; then
  changed_count=$(grep -oP 'changed=\K[0-9]+' "$LOG" | tail -1)
  echo "FAIL: expected changed=0 on idempotent rerun, got changed=${changed_count}"
  errors=$((errors + 1))
fi

# A-record still has correct IP (not duplicated)
line_count=$(wc -l < "${STATE}/dns_a/example.com/haproxy-vip")
if [[ "$line_count" -ne 1 ]]; then
  echo "FAIL: A-record has ${line_count} entries (expected 1 — idempotent)"
  errors=$((errors + 1))
fi

exit "$errors"

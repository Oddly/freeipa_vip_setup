#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

# haproxy-vip should be removed
if [[ -f "${STATE}/dns_a/example.com/haproxy-vip" ]]; then
  echo "FAIL: haproxy-vip A-record not removed"
  errors=$((errors + 1))
fi
if [[ -f "${STATE}/hosts/haproxy-vip.example.com" ]]; then
  echo "FAIL: haproxy-vip host not removed"
  errors=$((errors + 1))
fi
if [[ -f "${STATE}/services/HTTP_haproxy-vip.example.com" ]]; then
  echo "FAIL: haproxy-vip service not removed"
  errors=$((errors + 1))
fi

# api-vip was already gone — no errors should have occurred
# (the main test is that the playbook didn't fail)

# Privilege should still exist
if [[ ! -f "${STATE}/privileges/Service Host Management" ]]; then
  echo "FAIL: privilege was removed"
  errors=$((errors + 1))
fi

exit "$errors"

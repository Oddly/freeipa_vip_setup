#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

# A-record should have new IP
if ! grep -qxF "10.128.2.200" "${STATE}/dns_a/example.com/haproxy-vip" 2>/dev/null; then
  echo "FAIL: A-record doesn't have new IP"
  errors=$((errors + 1))
fi
if grep -qxF "10.128.1.100" "${STATE}/dns_a/example.com/haproxy-vip" 2>/dev/null; then
  echo "FAIL: old IP still in A-record"
  errors=$((errors + 1))
fi

# New PTR should exist for new IP (200.2 in zone 128.10.in-addr.arpa)
new_ptr="${STATE}/dns_ptr/128.10.in-addr.arpa/200.2"
if ! grep -qxF "haproxy-vip.example.com." "$new_ptr" 2>/dev/null; then
  echo "FAIL: new PTR not created for new IP"
  errors=$((errors + 1))
fi

# Old PTR for old IP should be cleaned up
old_ptr="${STATE}/dns_ptr/128.10.in-addr.arpa/100.1"
if [[ -f "$old_ptr" ]] && [[ -s "$old_ptr" ]]; then
  echo "FAIL: old PTR (100.1) still exists — should have been cleaned up on IP change"
  errors=$((errors + 1))
fi

exit "$errors"

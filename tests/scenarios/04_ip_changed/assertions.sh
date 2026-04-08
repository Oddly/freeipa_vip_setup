#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

# Old IP should be gone
if grep -qxF "10.128.1.100" "${STATE}/dns_a/example.com/haproxy-vip" 2>/dev/null; then
  echo "FAIL: old IP 10.128.1.100 still present in A-record"
  errors=$((errors + 1))
fi

# New IP should be there
if ! grep -qxF "10.128.2.200" "${STATE}/dns_a/example.com/haproxy-vip" 2>/dev/null; then
  echo "FAIL: new IP 10.128.2.200 not in A-record"
  errors=$((errors + 1))
fi

# Should be exactly 1 entry
line_count=$(wc -l < "${STATE}/dns_a/example.com/haproxy-vip")
if [[ "$line_count" -ne 1 ]]; then
  echo "FAIL: A-record has ${line_count} entries (expected 1 after IP change)"
  errors=$((errors + 1))
fi

# Host, service, permission should still exist
if [[ ! -f "${STATE}/hosts/haproxy-vip.example.com" ]]; then
  echo "FAIL: host disappeared during IP change"
  errors=$((errors + 1))
fi
if [[ ! -f "${STATE}/services/HTTP_haproxy-vip.example.com" ]]; then
  echo "FAIL: service disappeared during IP change"
  errors=$((errors + 1))
fi

# Command log should show dnsrecord-del for old IP
if ! grep -q "dnsrecord-del.*10.128.1.100" "${STATE}/_command_log"; then
  echo "FAIL: no dnsrecord-del command for stale IP"
  errors=$((errors + 1))
fi

exit "$errors"

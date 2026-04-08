#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

# VIP 1: haproxy
if ! grep -qxF "10.128.1.100" "${STATE}/dns_a/example.com/haproxy-vip" 2>/dev/null; then
  echo "FAIL: haproxy-vip A-record missing or wrong"
  errors=$((errors + 1))
fi

# VIP 2: db with PTR
if ! grep -qxF "10.128.1.200" "${STATE}/dns_a/example.com/db-vip" 2>/dev/null; then
  echo "FAIL: db-vip A-record missing or wrong"
  errors=$((errors + 1))
fi
ptr_file="${STATE}/dns_ptr/128.10.in-addr.arpa/200.1"
if ! grep -qxF "db-vip.example.com." "$ptr_file" 2>/dev/null; then
  echo "FAIL: db-vip PTR record missing"
  errors=$((errors + 1))
fi

# VIP 3: cache + redis (two names, one IP)
if ! grep -qxF "10.128.2.50" "${STATE}/dns_a/example.com/cache-vip" 2>/dev/null; then
  echo "FAIL: cache-vip A-record missing"
  errors=$((errors + 1))
fi
if ! grep -qxF "10.128.2.50" "${STATE}/dns_a/example.com/redis-vip" 2>/dev/null; then
  echo "FAIL: redis-vip A-record missing"
  errors=$((errors + 1))
fi

# All hosts created
for fqdn in haproxy-vip.example.com db-vip.example.com cache-vip.example.com redis-vip.example.com; do
  if [[ ! -f "${STATE}/hosts/${fqdn}" ]]; then
    echo "FAIL: host ${fqdn} not created"
    errors=$((errors + 1))
  fi
done

# All services created
for fqdn in haproxy-vip.example.com db-vip.example.com cache-vip.example.com redis-vip.example.com; do
  if [[ ! -f "${STATE}/services/HTTP_${fqdn}" ]]; then
    echo "FAIL: service for ${fqdn} not created"
    errors=$((errors + 1))
  fi
done

# haproxy should NOT have a PTR (include_ip_in_cert not set)
# Check no PTR for 10.128.1.100
ptr_100="${STATE}/dns_ptr/128.10.in-addr.arpa/100.1"
if [[ -f "$ptr_100" ]] && [[ -s "$ptr_100" ]]; then
  echo "FAIL: haproxy-vip should not have a PTR record"
  errors=$((errors + 1))
fi

exit "$errors"

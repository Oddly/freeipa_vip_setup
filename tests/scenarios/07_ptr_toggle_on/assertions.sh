#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

# PTR record should now exist
# Reverse zone for 10.128.1.100 = 128.10.in-addr.arpa, record = 100.1
ptr_file="${STATE}/dns_ptr/128.10.in-addr.arpa/100.1"
if [[ ! -f "$ptr_file" ]]; then
  echo "FAIL: PTR record not created"
  errors=$((errors + 1))
elif ! grep -qxF "haproxy-vip.example.com." "$ptr_file"; then
  echo "FAIL: PTR record has wrong target, got: $(cat "$ptr_file")"
  errors=$((errors + 1))
fi

# A-record still intact
if ! grep -qxF "10.128.1.100" "${STATE}/dns_a/example.com/haproxy-vip"; then
  echo "FAIL: A-record lost during PTR toggle"
  errors=$((errors + 1))
fi

exit "$errors"

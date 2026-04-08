#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

# With custom /24 reverse_zone, the PTR record should be under that zone
# reverse_record = last two octets: 50.1
ptr_file="${STATE}/dns_ptr/1.168.192.in-addr.arpa/50.1"
if [[ ! -f "$ptr_file" ]]; then
  echo "FAIL: PTR record not created in custom reverse zone"
  echo "  Expected: ${ptr_file}"
  # Check if it went to the default zone instead
  default_ptr="${STATE}/dns_ptr/168.192.in-addr.arpa/50.1"
  if [[ -f "$default_ptr" ]]; then
    echo "  Found in default zone instead — reverse_zone override not working"
  fi
  errors=$((errors + 1))
elif ! grep -qxF "haproxy-vip.example.com." "$ptr_file"; then
  echo "FAIL: PTR has wrong target"
  errors=$((errors + 1))
fi

exit "$errors"

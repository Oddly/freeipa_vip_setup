#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

# PTR record should be GONE
ptr_file="${STATE}/dns_ptr/128.10.in-addr.arpa/100.1"
if [[ -f "$ptr_file" ]] && [[ -s "$ptr_file" ]]; then
  echo "FAIL: PTR record still exists after toggling include_ip_in_cert off"
  echo "  Contents: $(cat "$ptr_file")"
  errors=$((errors + 1))
fi

# A-record should still be there
if ! grep -qxF "10.128.1.100" "${STATE}/dns_a/example.com/haproxy-vip"; then
  echo "FAIL: A-record lost during PTR toggle off"
  errors=$((errors + 1))
fi

# Command log should show dnsrecord-del for the PTR
if ! grep -q "dnsrecord-del.*128.10.in-addr.arpa" "${STATE}/_command_log"; then
  echo "FAIL: no dnsrecord-del command for PTR removal"
  errors=$((errors + 1))
fi

exit "$errors"

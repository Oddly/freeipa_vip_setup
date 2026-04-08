#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

for name in haproxy-vip api-vip web-vip; do
  fqdn="${name}.example.com"

  if [[ ! -f "${STATE}/dns_a/example.com/${name}" ]]; then
    echo "FAIL: A-record for ${name} not created"
    errors=$((errors + 1))
  fi
  if [[ ! -f "${STATE}/hosts/${fqdn}" ]]; then
    echo "FAIL: host ${fqdn} not created"
    errors=$((errors + 1))
  fi
  if [[ ! -f "${STATE}/services/HTTP_${fqdn}" ]]; then
    echo "FAIL: service for ${fqdn} not created"
    errors=$((errors + 1))
  fi
  if [[ ! -f "${STATE}/permissions/Manage ${fqdn} managedBy" ]]; then
    echo "FAIL: permission for ${fqdn} not created"
    errors=$((errors + 1))
  fi
done

# All three permissions attached to privilege
for name in haproxy-vip api-vip web-vip; do
  fqdn="${name}.example.com"
  if [[ ! -f "${STATE}/privilege_perms/Service Host Management/Manage ${fqdn} managedBy" ]]; then
    echo "FAIL: permission for ${fqdn} not attached to privilege"
    errors=$((errors + 1))
  fi
done

exit "$errors"

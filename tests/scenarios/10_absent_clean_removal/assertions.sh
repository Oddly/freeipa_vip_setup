#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

# All A-records removed
for name in haproxy-vip api-vip; do
  if [[ -f "${STATE}/dns_a/example.com/${name}" ]]; then
    echo "FAIL: A-record for ${name} not removed"
    errors=$((errors + 1))
  fi
done

# PTR removed
if [[ -f "${STATE}/dns_ptr/128.10.in-addr.arpa/100.1" ]] && [[ -s "${STATE}/dns_ptr/128.10.in-addr.arpa/100.1" ]]; then
  echo "FAIL: PTR record not removed"
  errors=$((errors + 1))
fi

# Hosts removed
for fqdn in haproxy-vip.example.com api-vip.example.com; do
  if [[ -f "${STATE}/hosts/${fqdn}" ]]; then
    echo "FAIL: host ${fqdn} not removed"
    errors=$((errors + 1))
  fi
done

# Services removed
for fqdn in haproxy-vip.example.com api-vip.example.com; do
  if [[ -f "${STATE}/services/HTTP_${fqdn}" ]]; then
    echo "FAIL: service for ${fqdn} not removed"
    errors=$((errors + 1))
  fi
done

# Permissions removed
for fqdn in haproxy-vip.example.com api-vip.example.com; do
  if [[ -f "${STATE}/permissions/Manage ${fqdn} managedBy" ]]; then
    echo "FAIL: permission for ${fqdn} not removed"
    errors=$((errors + 1))
  fi
done

# Permissions detached from privilege
for fqdn in haproxy-vip.example.com api-vip.example.com; do
  if [[ -f "${STATE}/privilege_perms/Service Host Management/Manage ${fqdn} managedBy" ]]; then
    echo "FAIL: permission for ${fqdn} not detached from privilege"
    errors=$((errors + 1))
  fi
done

# Privilege and role should STILL exist (shared resources)
if [[ ! -f "${STATE}/privileges/Service Host Management" ]]; then
  echo "FAIL: privilege was removed (should be preserved)"
  errors=$((errors + 1))
fi
if [[ ! -f "${STATE}/roles/Certificate Manager" ]]; then
  echo "FAIL: role was removed (should be preserved)"
  errors=$((errors + 1))
fi

exit "$errors"

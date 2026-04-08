#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

# DNS A-record created
if [[ ! -f "${STATE}/dns_a/example.com/haproxy-vip" ]]; then
  echo "FAIL: A-record for haproxy-vip not created"
  errors=$((errors + 1))
elif ! grep -qxF "10.128.1.100" "${STATE}/dns_a/example.com/haproxy-vip"; then
  echo "FAIL: A-record has wrong IP"
  errors=$((errors + 1))
fi

# Host created
if [[ ! -f "${STATE}/hosts/haproxy-vip.example.com" ]]; then
  echo "FAIL: host not created"
  errors=$((errors + 1))
fi

# Service created
if [[ ! -f "${STATE}/services/HTTP_haproxy-vip.example.com" ]]; then
  echo "FAIL: service principal not created"
  errors=$((errors + 1))
fi

# Permission created
if [[ ! -f "${STATE}/permissions/Manage haproxy-vip.example.com managedBy" ]]; then
  echo "FAIL: permission not created"
  errors=$((errors + 1))
fi

# Privilege created
if [[ ! -f "${STATE}/privileges/Service Host Management" ]]; then
  echo "FAIL: privilege not created"
  errors=$((errors + 1))
fi

# Role created
if [[ ! -f "${STATE}/roles/Certificate Manager" ]]; then
  echo "FAIL: role not created"
  errors=$((errors + 1))
fi

# certadmin in role
if [[ ! -f "${STATE}/role_members/Certificate Manager/certadmin" ]]; then
  echo "FAIL: certadmin not added to role"
  errors=$((errors + 1))
fi

# No PTR (include_ip_in_cert defaults to false)
if ls "${STATE}/dns_ptr/" 2>/dev/null | grep -q .; then
  echo "FAIL: PTR record should not exist when include_ip_in_cert is false"
  errors=$((errors + 1))
fi

exit "$errors"

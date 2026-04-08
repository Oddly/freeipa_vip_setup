#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

# Original still intact
if ! grep -qxF "10.128.1.100" "${STATE}/dns_a/example.com/haproxy-vip"; then
  echo "FAIL: original A-record lost"
  errors=$((errors + 1))
fi

# New DNS name created
if [[ ! -f "${STATE}/dns_a/example.com/new-alias" ]]; then
  echo "FAIL: new-alias A-record not created"
  errors=$((errors + 1))
elif ! grep -qxF "10.128.1.100" "${STATE}/dns_a/example.com/new-alias"; then
  echo "FAIL: new-alias has wrong IP"
  errors=$((errors + 1))
fi

# New host, service, permission created
if [[ ! -f "${STATE}/hosts/new-alias.example.com" ]]; then
  echo "FAIL: host for new-alias not created"
  errors=$((errors + 1))
fi
if [[ ! -f "${STATE}/services/HTTP_new-alias.example.com" ]]; then
  echo "FAIL: service for new-alias not created"
  errors=$((errors + 1))
fi
if [[ ! -f "${STATE}/permissions/Manage new-alias.example.com managedBy" ]]; then
  echo "FAIL: permission for new-alias not created"
  errors=$((errors + 1))
fi

# Permission attached to privilege
if [[ ! -f "${STATE}/privilege_perms/Service Host Management/Manage new-alias.example.com managedBy" ]]; then
  echo "FAIL: new-alias permission not attached to privilege"
  errors=$((errors + 1))
fi

exit "$errors"

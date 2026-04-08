#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

# Service should use ldap/ prefix
if [[ ! -f "${STATE}/services/ldap_ldap-vip.example.com" ]]; then
  echo "FAIL: service with ldap/ prefix not created"
  if [[ -f "${STATE}/services/HTTP_ldap-vip.example.com" ]]; then
    echo "  Got HTTP/ instead — service_type override not working"
  fi
  errors=$((errors + 1))
fi

# Command log should show ldap/ in service-add
if ! grep -q "service-add ldap/" "${STATE}/_command_log"; then
  echo "FAIL: service-add didn't use ldap/ prefix"
  errors=$((errors + 1))
fi

exit "$errors"

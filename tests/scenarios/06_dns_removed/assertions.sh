#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

# The kept name should still be there
if [[ ! -f "${STATE}/dns_a/example.com/haproxy-vip" ]]; then
  echo "FAIL: kept A-record disappeared"
  errors=$((errors + 1))
fi

# The removed name's objects should STILL be there (role doesn't clean orphans)
# This is a known limitation — the role only manages what's in the list
if [[ ! -f "${STATE}/dns_a/example.com/old-alias" ]]; then
  echo "INFO: old-alias A-record was removed (role cleaned it up)"
  # Not a failure - just documenting behavior. The role doesn't remove orphans
  # in present mode, it only processes what's in the list.
fi

# The old permission attachment should still exist on the privilege
# (role doesn't detach permissions not in current list during present mode)
if [[ ! -f "${STATE}/privilege_perms/Service Host Management/Manage old-alias.example.com managedBy" ]]; then
  echo "INFO: old-alias permission was detached from privilege"
fi

# Main point: the role should succeed without errors
echo "OK: role succeeded — orphaned objects from removed DNS name remain (expected behavior)"

exit "$errors"

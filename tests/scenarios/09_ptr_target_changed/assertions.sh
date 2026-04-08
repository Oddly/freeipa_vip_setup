#!/usr/bin/env bash
set -euo pipefail
STATE="$1"
errors=0

ptr_file="${STATE}/dns_ptr/128.10.in-addr.arpa/100.1"

# Old PTR should be gone
if grep -qxF "old-reverse.example.com." "$ptr_file" 2>/dev/null; then
  echo "FAIL: old PTR target still present"
  errors=$((errors + 1))
fi

# New PTR should be there
if ! grep -qxF "new-reverse.example.com." "$ptr_file" 2>/dev/null; then
  echo "FAIL: new PTR target not set"
  errors=$((errors + 1))
fi

# Should be exactly 1 PTR entry
if [[ -f "$ptr_file" ]]; then
  line_count=$(wc -l < "$ptr_file")
  if [[ "$line_count" -ne 1 ]]; then
    echo "FAIL: PTR has ${line_count} entries (expected 1)"
    errors=$((errors + 1))
  fi
fi

exit "$errors"

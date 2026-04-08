#!/usr/bin/env bash
# Test harness for freeipa_vip_setup role
#
# Runs every scenario in tests/scenarios/ against the role using a stateful
# mock `ipa` CLI.  Each scenario is a directory containing:
#   vars.yml         - variables for the run
#   pre_state.sh     - (optional) seed IPA state before running
#   assertions.sh    - verify post-run state and command log
#   description.txt  - one-liner for the test report

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROLE_DIR="$(dirname "$SCRIPT_DIR")"
MOCK_BIN="${SCRIPT_DIR}/mock_bin"
PLAYBOOK="${SCRIPT_DIR}/test_playbook.yml"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass=0 fail=0 skip=0
failed_tests=()

run_scenario() {
  local scenario_dir="$1"
  local name
  name="$(basename "$scenario_dir")"
  local desc
  desc="$(cat "${scenario_dir}/description.txt" 2>/dev/null || echo "$name")"

  printf "  %-55s " "$desc"

  # Fresh state directory
  local state_dir
  state_dir="$(mktemp -d "/tmp/ipa_state_${name}_XXXXXX")"
  export IPA_STATE_DIR="$state_dir"
  touch "${state_dir}/_command_log"

  # Seed pre-existing state if provided
  if [[ -x "${scenario_dir}/pre_state.sh" ]]; then
    bash "${scenario_dir}/pre_state.sh" "$state_dir"
  fi

  # Run playbook
  local run_log="${state_dir}/_ansible.log"
  if ! ansible-playbook "$PLAYBOOK" \
    -e "@${scenario_dir}/vars.yml" \
    -c local \
    -i "localhost," \
    --extra-vars "ansible_python_interpreter=$(which python3)" \
    > "$run_log" 2>&1; then

    # Check if failure is expected
    if [[ -f "${scenario_dir}/expect_failure" ]]; then
      # Run assertions against the failed state
      if [[ -x "${scenario_dir}/assertions.sh" ]]; then
        local assert_out
        if assert_out=$(bash "${scenario_dir}/assertions.sh" "$state_dir" "$run_log" 2>&1); then
          echo -e "${GREEN}PASS${NC} (expected failure)"
          pass=$((pass + 1))
        else
          echo -e "${RED}FAIL${NC}"
          echo "    Assertion failures:"
          echo "$assert_out" | sed 's/^/    /'
          fail=$((fail + 1))
          failed_tests+=("$name")
        fi
      else
        echo -e "${GREEN}PASS${NC} (expected failure)"
        pass=$((pass + 1))
      fi
      rm -rf "$state_dir"
      return
    fi

    echo -e "${RED}FAIL${NC} (playbook error)"
    echo "    Ansible output (last 20 lines):"
    tail -20 "$run_log" | sed 's/^/    /'
    fail=$((fail + 1))
    failed_tests+=("$name")
    rm -rf "$state_dir"
    return
  fi

  # Unexpected success when failure was expected
  if [[ -f "${scenario_dir}/expect_failure" ]]; then
    echo -e "${RED}FAIL${NC} (expected failure but succeeded)"
    fail=$((fail + 1))
    failed_tests+=("$name")
    rm -rf "$state_dir"
    return
  fi

  # Run assertions
  if [[ -x "${scenario_dir}/assertions.sh" ]]; then
    local assert_out
    if assert_out=$(bash "${scenario_dir}/assertions.sh" "$state_dir" "$run_log" 2>&1); then
      echo -e "${GREEN}PASS${NC}"
      pass=$((pass + 1))
    else
      echo -e "${RED}FAIL${NC}"
      echo "    Assertion failures:"
      echo "$assert_out" | sed 's/^/    /'
      fail=$((fail + 1))
      failed_tests+=("$name")
    fi
  else
    echo -e "${YELLOW}SKIP${NC} (no assertions)"
    skip=$((skip + 1))
  fi

  rm -rf "$state_dir"
}

echo ""
echo "=========================================="
echo " freeipa_vip_setup — Edge-Case Test Suite"
echo "=========================================="
echo ""

# Ensure mock ipa is on PATH before real ipa
export PATH="${MOCK_BIN}:${PATH}"

# Verify mock works
_tmp_state=$(mktemp -d)
if ! IPA_STATE_DIR="$_tmp_state" ipa host-add test.example.com > /dev/null 2>&1; then
  echo "ERROR: mock ipa script not working" >&2
  rm -rf "$_tmp_state"
  exit 1
fi
rm -rf "$_tmp_state"

# Discover and run scenarios (sorted for deterministic ordering)
scenarios=()
for d in "${SCRIPT_DIR}"/scenarios/*/; do
  [[ -f "${d}/vars.yml" ]] && scenarios+=("$d")
done

IFS=$'\n' scenarios=($(printf '%s\n' "${scenarios[@]}" | sort))

echo "Running ${#scenarios[@]} scenarios..."
echo ""

for scenario in "${scenarios[@]}"; do
  run_scenario "$scenario"
done

echo ""
echo "=========================================="
printf "Results: ${GREEN}%d passed${NC}, ${RED}%d failed${NC}, ${YELLOW}%d skipped${NC}\n" "$pass" "$fail" "$skip"

if [[ ${#failed_tests[@]} -gt 0 ]]; then
  echo ""
  echo "Failed tests:"
  for t in "${failed_tests[@]}"; do
    echo "  - $t"
  done
fi

echo "=========================================="
echo ""

exit "$fail"

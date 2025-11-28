#!/usr/bin/env zsh
# Run all czruby tests

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Find test directory
TEST_DIR="${0:A:h}"
cd "$TEST_DIR"

echo "========================================"
echo "Running czruby test suite"
echo "========================================"
echo ""

# Track overall results
total_passed=0
total_failed=0
total_run=0
failed_suites=()

# Run each test file
for test_file in test_*.zsh; do
  [[ "$test_file" == "test_helper.zsh" ]] && continue

  echo ""
  echo "----------------------------------------"

  # Run test and capture output
  if output=$(zsh "$test_file" 2>&1); then
    # Parse results from output
    passed=$(echo "$output" | grep -o "Passed: [0-9]*" | grep -o "[0-9]*" || echo "0")
    failed=$(echo "$output" | grep -o "Failed: [0-9]*" | grep -o "[0-9]*" || echo "0")
    run=$(echo "$output" | grep -o "Total:  [0-9]*" | grep -o "[0-9]*" || echo "0")

    total_passed=$((total_passed + passed))
    total_failed=$((total_failed + failed))
    total_run=$((total_run + run))

    if [[ "$failed" -gt 0 ]]; then
      failed_suites+=("$test_file")
      echo "$output"
    else
      # Show just the summary for passing suites
      echo "$output" | tail -8
    fi
  else
    echo "${RED}ERROR${NC}: $test_file crashed"
    echo "$output"
    failed_suites+=("$test_file")
    total_failed=$((total_failed + 1))
    total_run=$((total_run + 1))
  fi
done

# Print final summary
echo ""
echo "========================================"
echo "Final Test Summary"
echo "========================================"
echo "Total tests:  $total_run"
echo "${GREEN}Total passed: $total_passed${NC}"
if [[ $total_failed -gt 0 ]]; then
  echo "${RED}Total failed: $total_failed${NC}"
  echo ""
  echo "Failed suites:"
  for suite in "${failed_suites[@]}"; do
    echo "  - $suite"
  done
else
  echo "Total failed: $total_failed"
fi
echo "========================================"

# Exit with failure if any tests failed
if [[ $total_failed -gt 0 ]]; then
  exit 1
fi

exit 0

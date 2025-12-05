#!/usr/bin/env zsh
# Test helper for czruby test suite
# Provides setup, teardown, and assertion functions

# Test counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0
typeset -g CURRENT_TEST=""

# Colors for output
typeset -g RED='\033[0;31m'
typeset -g GREEN='\033[0;32m'
typeset -g YELLOW='\033[0;33m'
typeset -g NC='\033[0m' # No Color

# Test environment variables
typeset -g TEST_DIR=""
typeset -g CZRUBY_ROOT=""

# Initialize test environment
setup_test_env() {
  # Create isolated test directory
  TEST_DIR=$(mktemp -d)
  export XDG_DATA_HOME="$TEST_DIR/data"
  export XDG_CACHE_HOME="$TEST_DIR/cache"
  export XDG_CONFIG_HOME="$TEST_DIR/config"
  mkdir -p "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"

  # Store original PATH
  typeset -g ORIGINAL_PATH="$PATH"
  typeset -g ORIGINAL_path=("${path[@]}")

  # Find czruby root (parent of test directory)
  CZRUBY_ROOT="${0:A:h:h}"

  # Source plugin config to initialize variables
  source "$CZRUBY_ROOT/czruby.plugin.conf"

  # Add functions to fpath and autoload
  fpath=("$CZRUBY_ROOT/functions" $fpath)
  for functions_file in "$CZRUBY_ROOT"/functions/*; do
    autoload -Uz "${functions_file:t}"
  done

  # Reset arrays
  rubies=()
  gem_path=()
  unset RUBY_ROOT RUBY_ENGINE RUBY_VERSION GEM_HOME
}

# Cleanup test environment
teardown_test_env() {
  if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi

  # Restore original PATH
  if [[ -n "$ORIGINAL_PATH" ]]; then
    export PATH="$ORIGINAL_PATH"
    path=("${ORIGINAL_path[@]}")
  fi

  # Clear variables
  unset TEST_DIR XDG_DATA_HOME XDG_CACHE_HOME XDG_CONFIG_HOME
  unset RUBY_ROOT RUBY_ENGINE RUBY_VERSION GEM_HOME RUBIES_DEFAULT
  unset rubies gem_path czruby_datadir
}

# Create a mock ruby installation
create_mock_ruby() {
  local name="$1"
  local ruby_dir="$TEST_DIR/rubies/$name"
  mkdir -p "$ruby_dir/bin"
  mkdir -p "$ruby_dir/lib/ruby/gems"

  # Create a mock ruby executable
  cat > "$ruby_dir/bin/ruby" << 'MOCKRUBY'
#!/bin/sh
echo "mock ruby"
MOCKRUBY
  chmod +x "$ruby_dir/bin/ruby"

  echo "$ruby_dir"
}

# Create system ruby mock
create_system_ruby() {
  # For testing, we'll create a mock at a predictable location
  mkdir -p "$TEST_DIR/usr/bin"
  cat > "$TEST_DIR/usr/bin/ruby" << 'MOCKRUBY'
#!/bin/sh
if [ "$1" = "-e" ] && [ "$2" = "print RUBY_VERSION" ]; then
  printf "3.0.0"
else
  echo "mock system ruby"
fi
MOCKRUBY
  chmod +x "$TEST_DIR/usr/bin/ruby"
}

# Assertion functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Values should be equal}"

  if [[ "$expected" == "$actual" ]]; then
    return 0
  else
    echo "  ${RED}ASSERTION FAILED${NC}: $message"
    echo "    Expected: '$expected'"
    echo "    Actual:   '$actual'"
    return 1
  fi
}

assert_not_equals() {
  local unexpected="$1"
  local actual="$2"
  local message="${3:-Values should not be equal}"

  if [[ "$unexpected" != "$actual" ]]; then
    return 0
  else
    echo "  ${RED}ASSERTION FAILED${NC}: $message"
    echo "    Unexpected: '$unexpected'"
    echo "    Actual:     '$actual'"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-String should contain substring}"

  if [[ "$haystack" == *"$needle"* ]]; then
    return 0
  else
    echo "  ${RED}ASSERTION FAILED${NC}: $message"
    echo "    String:    '$haystack'"
    echo "    Should contain: '$needle'"
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-String should not contain substring}"

  if [[ "$haystack" != *"$needle"* ]]; then
    return 0
  else
    echo "  ${RED}ASSERTION FAILED${NC}: $message"
    echo "    String:    '$haystack'"
    echo "    Should not contain: '$needle'"
    return 1
  fi
}

assert_file_exists() {
  local filepath="$1"
  local message="${2:-File should exist}"

  if [[ -f "$filepath" ]]; then
    return 0
  else
    echo "  ${RED}ASSERTION FAILED${NC}: $message"
    echo "    File not found: '$filepath'"
    return 1
  fi
}

assert_file_not_exists() {
  local filepath="$1"
  local message="${2:-File should not exist}"

  if [[ ! -f "$filepath" ]]; then
    return 0
  else
    echo "  ${RED}ASSERTION FAILED${NC}: $message"
    echo "    File exists: '$filepath'"
    return 1
  fi
}

assert_dir_exists() {
  local dirpath="$1"
  local message="${2:-Directory should exist}"

  if [[ -d "$dirpath" ]]; then
    return 0
  else
    echo "  ${RED}ASSERTION FAILED${NC}: $message"
    echo "    Directory not found: '$dirpath'"
    return 1
  fi
}

assert_symlink() {
  local filepath="$1"
  local message="${2:-Should be a symlink}"

  if [[ -L "$filepath" ]]; then
    return 0
  else
    echo "  ${RED}ASSERTION FAILED${NC}: $message"
    echo "    Not a symlink: '$filepath'"
    return 1
  fi
}

assert_array_contains() {
  local needle="$1"
  shift
  local -a haystack=("$@")
  local message="Array should contain '$needle'"

  for item in "${haystack[@]}"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done

  echo "  ${RED}ASSERTION FAILED${NC}: $message"
  echo "    Array: (${haystack[*]})"
  return 1
}

assert_array_not_contains() {
  local needle="$1"
  shift
  local -a haystack=("$@")
  local message="Array should not contain '$needle'"

  for item in "${haystack[@]}"; do
    if [[ "$item" == "$needle" ]]; then
      echo "  ${RED}ASSERTION FAILED${NC}: $message"
      echo "    Array: (${haystack[*]})"
      return 1
    fi
  done

  return 0
}

assert_success() {
  local exit_code="$1"
  local message="${2:-Command should succeed}"

  if [[ "$exit_code" -eq 0 ]]; then
    return 0
  else
    echo "  ${RED}ASSERTION FAILED${NC}: $message"
    echo "    Exit code: $exit_code (expected 0)"
    return 1
  fi
}

assert_failure() {
  local exit_code="$1"
  local message="${2:-Command should fail}"

  if [[ "$exit_code" -ne 0 ]]; then
    return 0
  else
    echo "  ${RED}ASSERTION FAILED${NC}: $message"
    echo "    Exit code: $exit_code (expected non-zero)"
    return 1
  fi
}

assert_empty() {
  local value="$1"
  local message="${2:-Value should be empty}"

  if [[ -z "$value" ]]; then
    return 0
  else
    echo "  ${RED}ASSERTION FAILED${NC}: $message"
    echo "    Value: '$value'"
    return 1
  fi
}

assert_not_empty() {
  local value="$1"
  local message="${2:-Value should not be empty}"

  if [[ -n "$value" ]]; then
    return 0
  else
    echo "  ${RED}ASSERTION FAILED${NC}: $message"
    return 1
  fi
}

# Run a single test
run_test() {
  local test_name="$1"
  local test_func="$2"

  CURRENT_TEST="$test_name"
  ((TESTS_RUN++))

  # Setup
  setup_test_env

  # Run test
  local test_output
  local test_result=0
  test_output=$($test_func 2>&1) || test_result=$?

  # Check result
  if [[ $test_result -eq 0 ]]; then
    echo "${GREEN}PASS${NC}: $test_name"
    ((TESTS_PASSED++))
  else
    echo "${RED}FAIL${NC}: $test_name"
    if [[ -n "$test_output" ]]; then
      echo "$test_output"
    fi
    ((TESTS_FAILED++))
  fi

  # Teardown
  teardown_test_env
}

# Print test summary
print_summary() {
  echo ""
  echo "========================================"
  echo "Test Summary"
  echo "========================================"
  echo "Total:  $TESTS_RUN"
  echo "${GREEN}Passed: $TESTS_PASSED${NC}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "${RED}Failed: $TESTS_FAILED${NC}"
  else
    echo "Failed: $TESTS_FAILED"
  fi
  echo "========================================"

  if [[ $TESTS_FAILED -gt 0 ]]; then
    return 1
  fi
  return 0
}

# Source function files directly (for testing)
source_functions() {
  for functions_file in "$CZRUBY_ROOT"/functions/*; do
    source "$functions_file"
  done
}

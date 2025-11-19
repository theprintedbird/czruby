#!/usr/bin/env zsh
# Tests for czruby_use function

source "${0:A:h}/test_helper.zsh"

# Test: Exact name match
test_exact_name_match() {
  # Setup
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "truffleruby-21.1.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Source the use function
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Test exact match
  czruby_use "truffleruby-21.1.0" 2>&1

  assert_equals "$ruby2" "$RUBY_ROOT" "Should match exact name" || return 1
}

# Test: Version match for MRI
test_version_match_mri() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_use "3.3.0" 2>&1

  assert_equals "$ruby2" "$RUBY_ROOT" "Should match by version" || return 1
}

# Test: Engine match
test_engine_match() {
  local ruby1=$(create_mock_ruby "3.3.0")
  local ruby2=$(create_mock_ruby "truffleruby-21.1.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_use "truffleruby" 2>&1

  assert_equals "$ruby2" "$RUBY_ROOT" "Should match by engine name" || return 1
}

# Test: Unknown ruby error
test_unknown_ruby_error() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  local output
  output=$(czruby_use "nonexistent" 2>&1)
  local result=$?

  assert_failure "$result" "Should return error for unknown ruby" || return 1
  assert_contains "$output" "unknown Ruby" "Should print unknown ruby message" || return 1
}

# Test: Ambiguous match error
test_ambiguous_match_error() {
  # Create multiple truffleruby versions
  local ruby1=$(create_mock_ruby "truffleruby-21.1.0")
  local ruby2=$(create_mock_ruby "truffleruby-22.0.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  local output
  output=$(czruby_use "truffleruby" 2>&1)
  local result=$?

  assert_failure "$result" "Should return error for ambiguous match" || return 1
  assert_contains "$output" "Too many matches" "Should print ambiguous match message" || return 1
}

# Test: Exact match takes priority
test_exact_match_priority() {
  # Create ruby where engine name matches another's version
  local ruby1=$(create_mock_ruby "3.3.0")
  local ruby2=$(create_mock_ruby "truffleruby-3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Looking for 3.3.0 should match MRI exactly
  czruby_use "3.3.0" 2>&1

  assert_equals "$ruby1" "$RUBY_ROOT" "Exact version match should take priority" || return 1
}

# Test: Partial version match
test_partial_version_no_match() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  local output
  output=$(czruby_use "3.3" 2>&1)
  local result=$?

  # Partial versions should not match
  assert_failure "$result" "Partial version should not match" || return 1
}

# Test: Case sensitivity
test_case_sensitivity() {
  local ruby_dir=$(create_mock_ruby "TruffleRuby-21.1.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Lowercase should not match uppercase
  local output
  output=$(czruby_use "truffleruby" 2>&1)
  local result=$?

  # This tests current behavior - case sensitive
  assert_failure "$result" "Matching should be case sensitive" || return 1
}

# Test: JRuby matching
test_jruby_matching() {
  local ruby1=$(create_mock_ruby "3.3.0")
  local ruby2=$(create_mock_ruby "jruby-9.4.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_use "jruby" 2>&1

  assert_equals "$ruby2" "$RUBY_ROOT" "Should match jruby by engine" || return 1
}

# Test: System ruby matching
test_system_ruby_matching() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_use "system" 2>&1

  # System ruby should set RUBY_ROOT to /usr
  assert_equals "/usr" "$RUBY_ROOT" "System ruby should set RUBY_ROOT to /usr" || return 1
}

# Test: First match wins for exact
test_first_match_wins() {
  # If there are duplicates, first should win
  local ruby1=$(create_mock_ruby "3.3.0")
  local ruby2="$TEST_DIR/other/3.3.0"
  mkdir -p "$ruby2/bin"
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_use "3.3.0" 2>&1

  assert_equals "$ruby1" "$RUBY_ROOT" "First match should win" || return 1
}

# Test: Empty rubies array
test_empty_rubies_array() {
  rubies=()

  # Need to setup but with empty rubies (system will be added)
  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  local output
  output=$(czruby_use "3.3.0" 2>&1)
  local result=$?

  assert_failure "$result" "Should fail with unknown ruby" || return 1
}

# Run all tests
echo "Running czruby_use tests..."
echo "========================================"

run_test "Exact name match" test_exact_name_match
run_test "Version match for MRI" test_version_match_mri
run_test "Engine match" test_engine_match
run_test "Unknown ruby error" test_unknown_ruby_error
run_test "Ambiguous match error" test_ambiguous_match_error
run_test "Exact match priority" test_exact_match_priority
run_test "Partial version no match" test_partial_version_no_match
run_test "Case sensitivity" test_case_sensitivity
run_test "JRuby matching" test_jruby_matching
run_test "System ruby matching" test_system_ruby_matching
run_test "First match wins" test_first_match_wins
run_test "Empty rubies array" test_empty_rubies_array

print_summary

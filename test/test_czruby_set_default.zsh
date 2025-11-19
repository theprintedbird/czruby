#!/usr/bin/env zsh
# Tests for czruby_set_default function

source "${0:A:h}/test_helper.zsh"

# Test: Sets RUBIES_DEFAULT variable
test_sets_rubies_default_var() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_set_default "3.3.0"

  assert_equals "3.3.0" "$RUBIES_DEFAULT" "RUBIES_DEFAULT should be set" || return 1
}

# Test: Creates default symlink
test_creates_default_symlink() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_set_default "3.3.0"

  assert_symlink "$czruby_datadir/default" "Default symlink should exist" || return 1
}

# Test: Symlink points to correct config
test_symlink_points_to_correct_config() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_set_default "3.3.0"

  # Check symlink target
  local target=$(readlink "$czruby_datadir/default")
  assert_equals "$czruby_datadir/3.3.0" "$target" "Symlink should point to config" || return 1
}

# Test: Error for non-existent ruby
test_error_nonexistent_ruby() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"
  source "$CZRUBY_ROOT/fn/czruby"

  local output
  output=$(czruby_set_default "nonexistent" 2>&1)
  local result=$?

  assert_failure "$result" "Should fail for non-existent ruby" || return 1
  assert_contains "$output" "not available" "Should print not available message" || return 1
}

# Test: Error for missing config file
test_error_missing_config() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  # Create datadir but don't setup
  mkdir -p "$czruby_datadir"

  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"
  source "$CZRUBY_ROOT/fn/czruby"

  local output
  output=$(czruby_set_default "3.3.0" 2>&1)
  local result=$?

  assert_failure "$result" "Should fail for missing config" || return 1
  assert_contains "$output" "not been set up" "Should print setup message" || return 1
}

# Test: Defaults to system when no argument
test_defaults_to_system() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Call with no argument
  czruby_set_default

  assert_equals "system" "$RUBIES_DEFAULT" "Should default to system" || return 1
}

# Test: Switches to default after setting
test_switches_to_default() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_set_default "3.3.0"

  assert_equals "$ruby_dir" "$RUBY_ROOT" "Should switch to default ruby" || return 1
}

# Test: Can change default
test_can_change_default() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Set first default
  czruby_set_default "3.2.0"
  assert_equals "3.2.0" "$RUBIES_DEFAULT" || return 1

  # Change default
  czruby_set_default "3.3.0"
  assert_equals "3.3.0" "$RUBIES_DEFAULT" || return 1
}

# Test: Symlink updated when default changed
test_symlink_updated() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_set_default "3.2.0"
  czruby_set_default "3.3.0"

  local target=$(readlink "$czruby_datadir/default")
  assert_equals "$czruby_datadir/3.3.0" "$target" "Symlink should be updated" || return 1
}

# Test: Set system as default
test_set_system_as_default() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_set_default "system"

  assert_equals "system" "$RUBIES_DEFAULT" || return 1
  assert_equals "/usr" "$RUBY_ROOT" || return 1
}

# Test: Set alternate engine as default
test_set_alternate_engine_default() {
  local ruby1=$(create_mock_ruby "3.3.0")
  local ruby2=$(create_mock_ruby "truffleruby-21.1.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_set_default "truffleruby-21.1.0"

  assert_equals "truffleruby-21.1.0" "$RUBIES_DEFAULT" || return 1
  assert_equals "$ruby2" "$RUBY_ROOT" || return 1
}

# Test: Empty argument returns error
test_empty_argument_error() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Empty string argument
  local result
  czruby_set_default ""
  result=$?

  assert_failure "$result" "Empty string should fail" || return 1
}

# Run all tests
echo "Running czruby_set_default tests..."
echo "========================================"

run_test "Sets RUBIES_DEFAULT variable" test_sets_rubies_default_var
run_test "Creates default symlink" test_creates_default_symlink
run_test "Symlink points to correct config" test_symlink_points_to_correct_config
run_test "Error for non-existent ruby" test_error_nonexistent_ruby
run_test "Error for missing config" test_error_missing_config
run_test "Defaults to system" test_defaults_to_system
run_test "Switches to default" test_switches_to_default
run_test "Can change default" test_can_change_default
run_test "Symlink updated" test_symlink_updated
run_test "Set system as default" test_set_system_as_default
run_test "Set alternate engine default" test_set_alternate_engine_default
run_test "Empty argument error" test_empty_argument_error

print_summary

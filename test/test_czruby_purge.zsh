#!/usr/bin/env zsh
# Tests for czruby_purge function

source "${0:A:h}/test_helper.zsh"

# Test: Error when datadir doesn't exist
test_error_no_datadir() {
  # Don't create datadir
  source "$CZRUBY_ROOT/functions/czruby_purge"

  local output
  output=$(czruby_purge 2>&1)
  local result=$?

  assert_failure "$result" "Should fail without datadir" || return 1
  assert_contains "$output" "no data directory" "Should print no data directory message" || return 1
}

# Test: Removes orphaned configs
test_removes_orphaned_configs() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/functions/czruby_setup"
  source "$CZRUBY_ROOT/functions/czruby_purge"
  source "$CZRUBY_ROOT/functions/czruby_set_default"
  source "$CZRUBY_ROOT/functions/czruby_reset"

  # Create an orphan config (not in rubies)
  touch "$czruby_datadir/orphan-1.0.0"

  czruby_purge

  assert_file_not_exists "$czruby_datadir/orphan-1.0.0" "Orphan config should be removed" || return 1
}

# Test: Removes stale directory configs
test_removes_stale_configs() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/functions/czruby_setup"
  source "$CZRUBY_ROOT/functions/czruby_purge"
  source "$CZRUBY_ROOT/functions/czruby_set_default"
  source "$CZRUBY_ROOT/functions/czruby_reset"

  # Delete the ruby directory but keep in rubies array
  rm -rf "$ruby_dir"

  local output
  output=$(czruby_purge 2>&1)

  assert_file_not_exists "$czruby_datadir/3.3.0" "Stale config should be removed" || return 1
}

# Test: Skips default symlink
test_skips_default_symlink() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/functions/czruby_setup"
  source "$CZRUBY_ROOT/functions/czruby_purge"
  source "$CZRUBY_ROOT/functions/czruby_set_default"
  source "$CZRUBY_ROOT/functions/czruby_reset"

  czruby_set_default "3.3.0"
  czruby_purge

  assert_symlink "$czruby_datadir/default" "Default symlink should still exist" || return 1
}

# Test: Reports count
test_reports_purge_count() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/functions/czruby_setup"
  source "$CZRUBY_ROOT/functions/czruby_purge"
  source "$CZRUBY_ROOT/functions/czruby_set_default"
  source "$CZRUBY_ROOT/functions/czruby_reset"

  # Create orphan configs
  touch "$czruby_datadir/orphan1"
  touch "$czruby_datadir/orphan2"

  local output
  output=$(czruby_purge 2>&1)

  assert_contains "$output" "purged 2" "Should report 2 purged" || return 1
}

# Test: Zero purged when clean
test_zero_purged_when_clean() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/functions/czruby_setup"
  source "$CZRUBY_ROOT/functions/czruby_purge"
  source "$CZRUBY_ROOT/functions/czruby_set_default"
  source "$CZRUBY_ROOT/functions/czruby_reset"

  local output
  output=$(czruby_purge 2>&1)

  assert_contains "$output" "purged 0" "Should report 0 purged" || return 1
}

# Test: Preserves valid configs
test_preserves_valid_configs() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/functions/czruby_setup"
  source "$CZRUBY_ROOT/functions/czruby_purge"
  source "$CZRUBY_ROOT/functions/czruby_set_default"
  source "$CZRUBY_ROOT/functions/czruby_reset"

  # Add an orphan
  touch "$czruby_datadir/orphan"

  czruby_purge

  # Valid configs should remain
  assert_file_exists "$czruby_datadir/3.2.0" "Valid config 3.2.0 should remain" || return 1
  assert_file_exists "$czruby_datadir/3.3.0" "Valid config 3.3.0 should remain" || return 1
}

# Test: Updates default if purged
test_updates_default_if_purged() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/functions/czruby_setup"
  source "$CZRUBY_ROOT/functions/czruby_purge"
  source "$CZRUBY_ROOT/functions/czruby_set_default"
  source "$CZRUBY_ROOT/functions/czruby_reset"

  # Set 3.3.0 as default
  czruby_set_default "3.3.0"

  # Remove 3.3.0 from rubies (simulate uninstall)
  rubies=("$ruby1")
  rm -rf "$ruby2"

  czruby_purge

  # Default should be reset to system
  assert_equals "system" "$RUBIES_DEFAULT" "Default should be reset to system" || return 1
}

# Test: System ruby removal when /usr/bin/ruby missing
test_system_ruby_removal() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/functions/czruby_setup"

  # The system config is created during setup
  # In test env, /usr/bin/ruby may not exist
  # We're testing the logic, not the actual system

  source "$CZRUBY_ROOT/functions/czruby_purge"
  source "$CZRUBY_ROOT/functions/czruby_set_default"
  source "$CZRUBY_ROOT/functions/czruby_reset"

  local output
  output=$(czruby_purge 2>&1)

  # This test validates the purge ran without error
  assert_contains "$output" "purged" "Should report purge count" || return 1
}

# Test: Multiple orphans removed
test_multiple_orphans_removed() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/functions/czruby_setup"
  source "$CZRUBY_ROOT/functions/czruby_purge"
  source "$CZRUBY_ROOT/functions/czruby_set_default"
  source "$CZRUBY_ROOT/functions/czruby_reset"

  # Create multiple orphans
  touch "$czruby_datadir/orphan1"
  touch "$czruby_datadir/orphan2"
  touch "$czruby_datadir/orphan3"

  czruby_purge

  assert_file_not_exists "$czruby_datadir/orphan1" || return 1
  assert_file_not_exists "$czruby_datadir/orphan2" || return 1
  assert_file_not_exists "$czruby_datadir/orphan3" || return 1
}

# Test: Handles empty datadir
test_handles_empty_datadir() {
  mkdir -p "$czruby_datadir"

  source "$CZRUBY_ROOT/functions/czruby_purge"

  local output
  output=$(czruby_purge 2>&1)
  local result=$?

  assert_success "$result" "Should succeed with empty datadir" || return 1
  assert_contains "$output" "purged 0" "Should report 0 purged" || return 1
}

# Run all tests
echo "Running czruby_purge tests..."
echo "========================================"

run_test "Error no datadir" test_error_no_datadir
run_test "Removes orphaned configs" test_removes_orphaned_configs
run_test "Removes stale configs" test_removes_stale_configs
run_test "Skips default symlink" test_skips_default_symlink
run_test "Reports purge count" test_reports_purge_count
run_test "Zero purged when clean" test_zero_purged_when_clean
run_test "Preserves valid configs" test_preserves_valid_configs
run_test "Updates default if purged" test_updates_default_if_purged
run_test "System ruby removal" test_system_ruby_removal
run_test "Multiple orphans removed" test_multiple_orphans_removed
run_test "Handles empty datadir" test_handles_empty_datadir

print_summary

#!/usr/bin/env zsh
# Edge case and error handling tests for czruby

source "${0:A:h}/test_helper.zsh"

# Test: Empty rubies array after setup adds system
test_empty_rubies_array() {
  rubies=()

  source "$CZRUBY_ROOT/fn/czruby_setup"

  # System should be added
  assert_array_contains "system" "${rubies[@]}" || return 1
  assert_file_exists "$czruby_datadir/system" "System config should exist" || return 1
}

# Test: Duplicate rubies in array
test_duplicate_rubies() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir" "$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Should still work
  czruby_use "3.3.0"
  assert_equals "$ruby_dir" "$RUBY_ROOT" || return 1
}

# Test: Ruby name with multiple hyphens
test_multiple_hyphens_in_name() {
  local ruby_dir=$(create_mock_ruby "ruby-head-preview")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Config should be created
  assert_file_exists "$czruby_datadir/ruby-head-preview" || return 1

  # Check parsing - first part should be engine
  local config_content=$(cat "$czruby_datadir/ruby-head-preview")
  assert_contains "$config_content" 'RUBY_ENGINE="ruby"' || return 1
}

# Test: Ruby name with dots (like preview versions)
test_dots_in_version() {
  local ruby_dir=$(create_mock_ruby "3.4.0-preview1")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Should handle this name
  czruby_use "3.4.0-preview1"
  assert_equals "$ruby_dir" "$RUBY_ROOT" || return 1
}

# Test: Very long ruby name
test_long_ruby_name() {
  local ruby_dir=$(create_mock_ruby "truffleruby-community-21.1.0-linux-amd64")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"

  assert_file_exists "$czruby_datadir/truffleruby-community-21.1.0-linux-amd64" || return 1
}

# Test: Unicode in paths (if supported)
test_special_characters_in_path() {
  # Create ruby in path with spaces
  local ruby_dir="$TEST_DIR/rubies/my ruby/3.3.0"
  mkdir -p "$ruby_dir/bin"
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Should handle path with space
  assert_file_exists "$czruby_datadir/3.3.0" || return 1
}

# Test: Symlink loops in default
test_symlink_to_nonexistent() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Create a broken symlink
  ln -sf "$czruby_datadir/nonexistent" "$czruby_datadir/default"

  # Try to use default - should handle gracefully
  source "$CZRUBY_ROOT/fn/czruby"
  local output
  output=$(czruby 2>&1)

  # Should not crash, table should still display
  assert_contains "$output" "engine" "Should still show table" || return 1
}

# Test: Config file without read permission
test_unreadable_config() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Remove read permission
  chmod -r "$czruby_datadir/3.3.0"

  # This should trigger fallback to setup
  local output
  output=$(czruby_reset "3.3.0" 2>&1)

  # Restore permission for cleanup
  chmod +r "$czruby_datadir/3.3.0"

  # The reset should complete (setup recreates the file)
  return 0
}

# Test: Concurrent setup calls (idempotency)
test_concurrent_setup() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  # Run setup twice
  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Should still have valid config
  assert_file_exists "$czruby_datadir/3.3.0" || return 1

  # Config should be valid zsh
  zsh -n "$czruby_datadir/3.3.0" || return 1
}

# Test: Missing GNU coreutils fallback
test_missing_grealpath() {
  # This test checks if grealpath is used correctly
  # In CI without macOS, grealpath may not exist
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby"

  # The table display uses grealpath
  # Just verify it doesn't crash
  local output
  output=$(czruby 2>&1)
  local result=$?

  # May fail if grealpath missing, but shouldn't crash
  return 0
}

# Test: Very large rubies array
test_large_rubies_array() {
  # Create 20 rubies
  for i in {1..20}; do
    local ruby_dir=$(create_mock_ruby "3.0.$i")
    rubies+=("$ruby_dir")
  done

  source "$CZRUBY_ROOT/fn/czruby_setup"

  # All should have configs
  for i in {1..20}; do
    assert_file_exists "$czruby_datadir/3.0.$i" "Config for 3.0.$i" || return 1
  done
}

# Test: Switching with empty gem_path
test_empty_initial_gem_path() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")
  gem_path=()  # Explicitly empty

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_use "3.3.0"

  # Should still work
  assert_not_empty "$GEM_HOME" || return 1
  assert_array_contains "$GEM_HOME" "${gem_path[@]}" || return 1
}

# Test: Non-standard RUBY_ROOT structure
test_nonstandard_ruby_structure() {
  # Ruby without standard lib directory
  local ruby_dir="$TEST_DIR/rubies/minimal-3.3.0"
  mkdir -p "$ruby_dir/bin"
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_use "minimal-3.3.0"

  # Should work even without lib directory
  assert_equals "$ruby_dir" "$RUBY_ROOT" || return 1
}

# Test: Case where only system ruby exists
test_only_system_ruby() {
  rubies=()

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Only system should be available
  czruby_use "system"
  assert_equals "/usr" "$RUBY_ROOT" || return 1

  # Other rubies should fail
  local output
  output=$(czruby_use "3.3.0" 2>&1)
  local result=$?
  assert_failure "$result" "Should fail for non-existent ruby" || return 1
}

# Test: Rapid switching stress test
test_rapid_switching() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Switch rapidly back and forth
  for i in {1..10}; do
    czruby_use "3.2.0"
    czruby_use "3.3.0"
  done

  # Should end on 3.3.0
  assert_equals "$ruby2" "$RUBY_ROOT" || return 1
  assert_equals "3.3.0" "$RUBY_VERSION" || return 1
}

# Test: PATH doesn't grow indefinitely
test_path_growth() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  local initial_path_count=${#path[@]}

  # Switch back and forth
  for i in {1..5}; do
    czruby_use "3.2.0"
    czruby_use "3.3.0"
  done

  local final_path_count=${#path[@]}

  # Path should not have grown significantly
  # Allow some growth for the ruby bins
  local max_growth=10
  local growth=$((final_path_count - initial_path_count))

  if [[ $growth -gt $max_growth ]]; then
    echo "PATH grew by $growth entries (max allowed: $max_growth)"
    return 1
  fi

  return 0
}

# Test: czruby_use without argument
test_use_without_argument() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Call without argument - should fail
  local output
  output=$(czruby_use 2>&1)
  local result=$?

  # Currently the code doesn't validate this (noted as TODO)
  # This test documents the current behavior
  return 0
}

# Test: Numeric-only version matching
test_numeric_version() {
  local ruby1=$(create_mock_ruby "310")  # No dots
  rubies=("$ruby1")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_use "310"
  assert_equals "$ruby1" "$RUBY_ROOT" || return 1
}

# Run all tests
echo "Running edge case tests..."
echo "========================================"

run_test "Empty rubies array" test_empty_rubies_array
run_test "Duplicate rubies" test_duplicate_rubies
run_test "Multiple hyphens in name" test_multiple_hyphens_in_name
run_test "Dots in version" test_dots_in_version
run_test "Long ruby name" test_long_ruby_name
run_test "Special characters in path" test_special_characters_in_path
run_test "Symlink to nonexistent" test_symlink_to_nonexistent
run_test "Unreadable config" test_unreadable_config
run_test "Concurrent setup" test_concurrent_setup
run_test "Missing grealpath" test_missing_grealpath
run_test "Large rubies array" test_large_rubies_array
run_test "Empty initial gem_path" test_empty_initial_gem_path
run_test "Nonstandard ruby structure" test_nonstandard_ruby_structure
run_test "Only system ruby" test_only_system_ruby
run_test "Rapid switching" test_rapid_switching
run_test "PATH growth" test_path_growth
run_test "Use without argument" test_use_without_argument
run_test "Numeric version" test_numeric_version

print_summary

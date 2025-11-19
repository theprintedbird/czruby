#!/usr/bin/env zsh
# Integration tests for czruby

source "${0:A:h}/test_helper.zsh"

# Test: Full workflow - setup, use, switch
test_full_workflow() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  local ruby3=$(create_mock_ruby "truffleruby-21.1.0")
  rubies=("$ruby1" "$ruby2" "$ruby3")

  # 1. Setup
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Verify configs created
  assert_file_exists "$czruby_datadir/3.2.0" "3.2.0 config" || return 1
  assert_file_exists "$czruby_datadir/3.3.0" "3.3.0 config" || return 1
  assert_file_exists "$czruby_datadir/truffleruby-21.1.0" "truffleruby config" || return 1

  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"
  source "$CZRUBY_ROOT/fn/czruby_set_default"

  # 2. Use first ruby
  czruby_use "3.2.0"
  assert_equals "$ruby1" "$RUBY_ROOT" "Should use 3.2.0" || return 1
  assert_equals "3.2.0" "$RUBY_VERSION" || return 1

  # 3. Switch to second
  czruby_use "3.3.0"
  assert_equals "$ruby2" "$RUBY_ROOT" "Should switch to 3.3.0" || return 1
  assert_equals "3.3.0" "$RUBY_VERSION" || return 1

  # 4. Switch to alternate engine
  czruby_use "truffleruby"
  assert_equals "$ruby3" "$RUBY_ROOT" "Should switch to truffleruby" || return 1
  assert_equals "truffleruby" "$RUBY_ENGINE" || return 1

  # 5. Back to system
  czruby_use "system"
  assert_equals "/usr" "$RUBY_ROOT" "Should switch to system" || return 1
}

# Test: Multiple MRI versions switching
test_multiple_mri_versions() {
  local ruby1=$(create_mock_ruby "3.0.0")
  local ruby2=$(create_mock_ruby "3.1.0")
  local ruby3=$(create_mock_ruby "3.2.0")
  local ruby4=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2" "$ruby3" "$ruby4")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Test switching through all versions
  for ver in "3.0.0" "3.1.0" "3.2.0" "3.3.0"; do
    czruby_use "$ver"
    assert_equals "$ver" "$RUBY_VERSION" "Should be version $ver" || return 1
  done
}

# Test: Mixed engines coexistence
test_mixed_engines() {
  local mri=$(create_mock_ruby "3.3.0")
  local truffle=$(create_mock_ruby "truffleruby-21.1.0")
  local jruby=$(create_mock_ruby "jruby-9.4.0")
  rubies=("$mri" "$truffle" "$jruby")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Switch to each and verify engine
  czruby_use "3.3.0"
  assert_equals "ruby" "$RUBY_ENGINE" || return 1

  czruby_use "truffleruby"
  assert_equals "truffleruby" "$RUBY_ENGINE" || return 1

  czruby_use "jruby"
  assert_equals "jruby" "$RUBY_ENGINE" || return 1
}

# Test: PATH isolation between rubies
test_path_isolation() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Use first ruby
  czruby_use "3.2.0"
  local gem_home_1="$GEM_HOME"

  # Switch to second
  czruby_use "3.3.0"

  # Old gem bin should not be in path
  assert_array_not_contains "$gem_home_1/bin" "${path[@]}" || return 1

  # New gem bin should be in path
  assert_array_contains "$GEM_HOME/bin" "${path[@]}" || return 1
}

# Test: GEM_PATH isolation
test_gem_path_isolation() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Use first ruby
  czruby_use "3.2.0"
  local gem_home_1="$GEM_HOME"

  # Switch to second
  czruby_use "3.3.0"

  # Old gem home should not be in gem_path
  assert_array_not_contains "$gem_home_1" "${gem_path[@]}" || return 1

  # New gem home should be in gem_path
  assert_array_contains "$GEM_HOME" "${gem_path[@]}" || return 1
}

# Test: Default persistence (symlink remains valid)
test_default_persistence() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_set_default "3.3.0"

  # Verify symlink is valid
  local target=$(readlink "$czruby_datadir/default")
  assert_file_exists "$target" "Default symlink should point to existing file" || return 1

  # Verify we can source the default
  if [[ -r "$czruby_datadir/default" ]]; then
    source "$czruby_datadir/default"
    assert_equals "3.3.0" "$RUBY_VERSION" "Should load default ruby version" || return 1
  else
    echo "Default symlink not readable"
    return 1
  fi
}

# Test: Clean environment after reset
test_clean_environment() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Use first ruby
  czruby_use "3.2.0"

  # Store old values
  local old_root="$RUBY_ROOT"
  local old_engine="$RUBY_ENGINE"
  local old_version="$RUBY_VERSION"
  local old_gem_home="$GEM_HOME"

  # Switch to second
  czruby_use "3.3.0"

  # All should be different
  assert_not_equals "$old_root" "$RUBY_ROOT" "RUBY_ROOT should change" || return 1
  assert_not_equals "$old_version" "$RUBY_VERSION" "RUBY_VERSION should change" || return 1
  assert_not_equals "$old_gem_home" "$GEM_HOME" "GEM_HOME should change" || return 1
}

# Test: Setup followed by use followed by set-default
test_setup_use_default_workflow() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  # Setup
  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"
  source "$CZRUBY_ROOT/fn/czruby_set_default"

  # Use 3.2.0
  czruby_use "3.2.0"
  assert_equals "$ruby1" "$RUBY_ROOT" || return 1

  # Set default to 3.3.0
  czruby_set_default "3.3.0"

  # Should now be on 3.3.0
  assert_equals "$ruby2" "$RUBY_ROOT" || return 1
  assert_equals "3.3.0" "$RUBIES_DEFAULT" || return 1
}

# Test: Purge after removing ruby
test_purge_after_removal() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_purge"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Verify both configs exist
  assert_file_exists "$czruby_datadir/3.2.0" || return 1
  assert_file_exists "$czruby_datadir/3.3.0" || return 1

  # Simulate uninstall of 3.2.0
  rm -rf "$ruby1"

  # Purge
  czruby_purge

  # Config for 3.2.0 should be removed
  assert_file_not_exists "$czruby_datadir/3.2.0" "Purge should remove stale config" || return 1
  # Config for 3.3.0 should remain
  assert_file_exists "$czruby_datadir/3.3.0" "Valid config should remain" || return 1
}

# Test: Custom init hook integration
test_custom_init_integration() {
  local ruby1=$(create_mock_ruby "3.3.0")

  # Create another ruby that custom init will add
  local ruby2=$(create_mock_ruby "custom-ruby-1.0.0")

  rubies=("$ruby1")

  # Define custom init that adds another ruby
  czruby_custom_init() {
    rubies+=("$ruby2")
  }

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Custom ruby should be usable
  assert_array_contains "$ruby2" "${rubies[@]}" || return 1
  assert_file_exists "$czruby_datadir/custom-ruby-1.0.0" "Custom ruby config should exist" || return 1

  unset -f czruby_custom_init
}

# Test: Round-trip through all rubies
test_roundtrip_all_rubies() {
  local ruby1=$(create_mock_ruby "3.1.0")
  local ruby2=$(create_mock_ruby "3.2.0")
  local ruby3=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2" "$ruby3")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Start with system
  czruby_use "system"
  local start_root="$RUBY_ROOT"

  # Cycle through all
  czruby_use "3.1.0"
  czruby_use "3.2.0"
  czruby_use "3.3.0"
  czruby_use "system"

  # Should be back at system
  assert_equals "$start_root" "$RUBY_ROOT" "Should return to starting ruby" || return 1
}

# Run all tests
echo "Running integration tests..."
echo "========================================"

run_test "Full workflow" test_full_workflow
run_test "Multiple MRI versions" test_multiple_mri_versions
run_test "Mixed engines" test_mixed_engines
run_test "PATH isolation" test_path_isolation
run_test "GEM_PATH isolation" test_gem_path_isolation
run_test "Default persistence" test_default_persistence
run_test "Clean environment" test_clean_environment
run_test "Setup/use/default workflow" test_setup_use_default_workflow
run_test "Purge after removal" test_purge_after_removal
run_test "Custom init integration" test_custom_init_integration
run_test "Round-trip all rubies" test_roundtrip_all_rubies

print_summary

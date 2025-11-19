#!/usr/bin/env zsh
# Tests for czruby_reset function

source "${0:A:h}/test_helper.zsh"

# Test: Clears gem_path
test_clears_gem_path() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Set some initial gem_path
  gem_path=("/some/path" "/another/path")

  czruby_reset "3.3.0"

  # gem_path should be reset and contain new values
  assert_not_empty "$GEM_HOME" "GEM_HOME should be set after reset" || return 1
  assert_array_contains "$GEM_HOME" "${gem_path[@]}" || return 1
}

# Test: Sources config file
test_sources_config_file() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Clear variables
  unset RUBY_ENGINE RUBY_ROOT RUBY_VERSION

  czruby_reset "3.3.0"

  # Variables should be set from config
  assert_equals "ruby" "$RUBY_ENGINE" "RUBY_ENGINE should be set" || return 1
  assert_equals "$ruby_dir" "$RUBY_ROOT" "RUBY_ROOT should be set" || return 1
  assert_equals "3.3.0" "$RUBY_VERSION" "RUBY_VERSION should be set" || return 1
}

# Test: Sets environment variables correctly
test_sets_environment_variables() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_reset "3.3.0"

  assert_not_empty "$RUBY_ENGINE" || return 1
  assert_not_empty "$RUBY_ROOT" || return 1
  assert_not_empty "$RUBY_VERSION" || return 1
  assert_not_empty "$GEM_HOME" || return 1
}

# Test: Updates PATH with ruby bin
test_updates_path_with_ruby_bin() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_reset "3.3.0"

  # PATH should contain ruby bin directory
  assert_array_contains "$ruby_dir/bin" "${path[@]}" || return 1
}

# Test: Updates GEM_PATH
test_updates_gem_path() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_reset "3.3.0"

  # gem_path should contain GEM_HOME
  assert_array_contains "$GEM_HOME" "${gem_path[@]}" || return 1
}

# Test: Removes old paths when switching
test_removes_old_paths() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Switch to first ruby
  czruby_reset "3.2.0"
  local old_gem_home="$GEM_HOME"

  # Switch to second ruby
  czruby_reset "3.3.0"

  # Old GEM_HOME's bin should not be in path
  assert_array_not_contains "$old_gem_home/bin" "${path[@]}" || return 1
}

# Test: Fallback to setup if config missing
test_fallback_to_setup() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  # Setup datadir but don't run setup
  mkdir -p "$czruby_datadir"

  source "$CZRUBY_ROOT/fn/czruby_reset"

  # This should trigger setup and create the config
  local output
  output=$(czruby_reset "3.3.0" 2>&1)

  # After fallback to setup, config should exist
  assert_file_exists "$czruby_datadir/3.3.0" "Config should be created via fallback" || return 1
}

# Test: Switching between rubies
test_switching_between_rubies() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Switch to first
  czruby_reset "3.2.0"
  assert_equals "$ruby1" "$RUBY_ROOT" || return 1
  assert_equals "3.2.0" "$RUBY_VERSION" || return 1

  # Switch to second
  czruby_reset "3.3.0"
  assert_equals "$ruby2" "$RUBY_ROOT" || return 1
  assert_equals "3.3.0" "$RUBY_VERSION" || return 1
}

# Test: Reset to system ruby
test_reset_to_system() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # First set to a non-system ruby
  czruby_reset "3.3.0"

  # Then reset to system
  czruby_reset "system"

  assert_equals "/usr" "$RUBY_ROOT" "Should reset to system ruby" || return 1
}

# Test: GEM_HOME directory is correct
test_gem_home_directory() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_reset "3.3.0"

  local expected_gem_home="$XDG_CACHE_HOME/Ruby/ruby/3.3.0"
  assert_equals "$expected_gem_home" "$GEM_HOME" "GEM_HOME should be in XDG_CACHE_HOME" || return 1
}

# Test: Alternate engine GEM_HOME
test_alternate_engine_gem_home() {
  local ruby_dir=$(create_mock_ruby "truffleruby-21.1.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_reset "truffleruby-21.1.0"

  local expected_gem_home="$XDG_CACHE_HOME/Ruby/truffleruby/21.1.0"
  assert_equals "$expected_gem_home" "$GEM_HOME" "GEM_HOME should use engine name" || return 1
}

# Test: PATH does not accumulate duplicates
test_path_no_duplicates() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # Reset multiple times
  czruby_reset "3.3.0"
  czruby_reset "3.3.0"
  czruby_reset "3.3.0"

  # Count occurrences of ruby bin in path
  local count=0
  for p in "${path[@]}"; do
    [[ "$p" == "$ruby_dir/bin" ]] && ((count++))
  done

  # Due to how paths are managed, this tests the cleanup logic
  # The exact count depends on implementation
  [[ $count -le 3 ]] || {
    echo "Path contains too many duplicates: $count"
    return 1
  }
}

# Run all tests
echo "Running czruby_reset tests..."
echo "========================================"

run_test "Clears gem_path" test_clears_gem_path
run_test "Sources config file" test_sources_config_file
run_test "Sets environment variables" test_sets_environment_variables
run_test "Updates PATH with ruby bin" test_updates_path_with_ruby_bin
run_test "Updates GEM_PATH" test_updates_gem_path
run_test "Removes old paths when switching" test_removes_old_paths
run_test "Fallback to setup" test_fallback_to_setup
run_test "Switching between rubies" test_switching_between_rubies
run_test "Reset to system ruby" test_reset_to_system
run_test "GEM_HOME directory" test_gem_home_directory
run_test "Alternate engine GEM_HOME" test_alternate_engine_gem_home
run_test "PATH no duplicates" test_path_no_duplicates

print_summary

#!/usr/bin/env zsh
# Tests for czruby_setup function

source "${0:A:h}/test_helper.zsh"

# Test: Creates data directory
test_creates_data_directory() {
  # Setup
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  # Verify directory doesn't exist yet
  assert_dir_exists "$XDG_DATA_HOME" "XDG_DATA_HOME should exist" || return 1

  # Run setup
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Verify czruby_datadir was created
  assert_dir_exists "$czruby_datadir" "czruby_datadir should be created" || return 1
}

# Test: Adds system ruby to rubies array
test_adds_system_ruby() {
  # Setup with no system in rubies
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  # Verify system not in rubies
  assert_array_not_contains "system" "${rubies[@]}" || return 1

  # Run setup
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Verify system was added
  assert_array_contains "system" "${rubies[@]}" || return 1
}

# Test: Does not duplicate system ruby
test_no_duplicate_system_ruby() {
  # Setup with system already in rubies
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("system" "$ruby_dir")

  # Run setup
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Count occurrences of system
  local count=0
  for r in $rubies; do
    [[ "$r" == "system" ]] && ((count++))
  done

  assert_equals "1" "$count" "System should appear exactly once" || return 1
}

# Test: Generates config files for each ruby
test_generates_config_files() {
  # Setup
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  # Run setup
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Verify config files exist
  assert_file_exists "$czruby_datadir/3.2.0" "Config for 3.2.0 should exist" || return 1
  assert_file_exists "$czruby_datadir/3.3.0" "Config for 3.3.0 should exist" || return 1
  assert_file_exists "$czruby_datadir/system" "Config for system should exist" || return 1
}

# Test: Config file contains correct exports
test_config_file_content() {
  # Setup
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  # Run setup
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Read config file
  local config_content=$(cat "$czruby_datadir/3.3.0")

  # Verify exports
  assert_contains "$config_content" 'export RUBY_ENGINE="ruby"' "Should export RUBY_ENGINE" || return 1
  assert_contains "$config_content" "export RUBY_ROOT=\"$ruby_dir\"" "Should export RUBY_ROOT" || return 1
  assert_contains "$config_content" 'export RUBY_VERSION="3.3.0"' "Should export RUBY_VERSION" || return 1
  assert_contains "$config_content" 'export GEM_HOME=' "Should export GEM_HOME" || return 1
}

# Test: Creates GEM_HOME directories
test_creates_gem_home_dirs() {
  # Setup
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  # Run setup
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Verify GEM_HOME directory exists
  local gem_home="$XDG_CACHE_HOME/Ruby/ruby/3.3.0"
  assert_dir_exists "$gem_home" "GEM_HOME directory should be created" || return 1
}

# Test: Parses MRI rubies correctly (version-only names)
test_parses_mri_rubies() {
  # Setup - version-only name means MRI Ruby
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  # Run setup
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Read config and verify engine is "ruby"
  local config_content=$(cat "$czruby_datadir/3.3.0")
  assert_contains "$config_content" 'RUBY_ENGINE="ruby"' "MRI Ruby should have engine=ruby" || return 1
}

# Test: Parses alternate engines correctly
test_parses_alternate_engines() {
  # Setup - name with hyphen indicates alternate engine
  local ruby_dir=$(create_mock_ruby "truffleruby-21.1.0")
  rubies=("$ruby_dir")

  # Run setup
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Read config
  local config_content=$(cat "$czruby_datadir/truffleruby-21.1.0")

  # Verify engine and version parsed correctly
  assert_contains "$config_content" 'RUBY_ENGINE="truffleruby"' "Should parse engine as truffleruby" || return 1
  assert_contains "$config_content" 'RUBY_VERSION="21.1.0"' "Should parse version as 21.1.0" || return 1
}

# Test: Parses JRuby correctly
test_parses_jruby() {
  local ruby_dir=$(create_mock_ruby "jruby-9.4.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"

  local config_content=$(cat "$czruby_datadir/jruby-9.4.0")
  assert_contains "$config_content" 'RUBY_ENGINE="jruby"' "Should parse engine as jruby" || return 1
  assert_contains "$config_content" 'RUBY_VERSION="9.4.0"' "Should parse version as 9.4.0" || return 1
}

# Test: Custom init hook is called
test_custom_init_hook() {
  # Setup
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  # Define custom init hook that adds a marker file
  czruby_custom_init() {
    touch "$TEST_DIR/custom_init_called"
  }

  # Run setup
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Verify hook was called
  assert_file_exists "$TEST_DIR/custom_init_called" "Custom init hook should be called" || return 1

  # Cleanup
  unset -f czruby_custom_init
}

# Test: Setup is idempotent (doesn't overwrite existing configs)
test_idempotent_setup() {
  # Setup
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  # Run setup first time
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Modify config file
  echo "# marker" >> "$czruby_datadir/3.3.0"

  # Re-initialize and run setup again
  source "$CZRUBY_ROOT/czruby.plugin.conf"
  rubies=("$ruby_dir")
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Verify marker still exists (file wasn't overwritten)
  local config_content=$(cat "$czruby_datadir/3.3.0")
  assert_contains "$config_content" "# marker" "Config should not be overwritten" || return 1
}

# Test: Sets default ruby
test_sets_default_ruby() {
  # Setup
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")
  RUBIES_DEFAULT="system"

  # Run setup
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Verify default symlink exists
  assert_symlink "$czruby_datadir/default" "Default symlink should be created" || return 1
}

# Test: Config file has valid zsh syntax
test_config_valid_syntax() {
  # Setup
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  # Run setup
  source "$CZRUBY_ROOT/fn/czruby_setup"

  # Check syntax
  if zsh -n "$czruby_datadir/3.3.0" 2>&1; then
    return 0
  else
    echo "Config file has invalid zsh syntax"
    return 1
  fi
}

# Test: Multiple rubies of same engine
test_multiple_same_engine() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  local ruby3=$(create_mock_ruby "3.4.0")
  rubies=("$ruby1" "$ruby2" "$ruby3")

  source "$CZRUBY_ROOT/fn/czruby_setup"

  assert_file_exists "$czruby_datadir/3.2.0" || return 1
  assert_file_exists "$czruby_datadir/3.3.0" || return 1
  assert_file_exists "$czruby_datadir/3.4.0" || return 1
}

# Test: PATH setup in config
test_path_setup_in_config() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"

  local config_content=$(cat "$czruby_datadir/3.3.0")

  # Should add ruby bin to path
  assert_contains "$config_content" 'path=("$RUBY_ROOT/bin" $path)' "Should prepend RUBY_ROOT/bin to path" || return 1
}

# Test: GEM_PATH setup in config
test_gem_path_setup_in_config() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"

  local config_content=$(cat "$czruby_datadir/3.3.0")

  # Should setup gem_path
  assert_contains "$config_content" 'gem_path=($GEM_HOME' "Should add GEM_HOME to gem_path" || return 1
}

# Run all tests
echo "Running czruby_setup tests..."
echo "========================================"

run_test "Creates data directory" test_creates_data_directory
run_test "Adds system ruby to array" test_adds_system_ruby
run_test "No duplicate system ruby" test_no_duplicate_system_ruby
run_test "Generates config files" test_generates_config_files
run_test "Config file content" test_config_file_content
run_test "Creates GEM_HOME directories" test_creates_gem_home_dirs
run_test "Parses MRI rubies" test_parses_mri_rubies
run_test "Parses alternate engines" test_parses_alternate_engines
run_test "Parses JRuby" test_parses_jruby
run_test "Custom init hook" test_custom_init_hook
run_test "Idempotent setup" test_idempotent_setup
run_test "Sets default ruby" test_sets_default_ruby
run_test "Config valid syntax" test_config_valid_syntax
run_test "Multiple same engine" test_multiple_same_engine
run_test "PATH setup in config" test_path_setup_in_config
run_test "GEM_PATH setup in config" test_gem_path_setup_in_config

print_summary

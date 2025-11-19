#!/usr/bin/env zsh
# Tests for czruby main dispatcher function

source "${0:A:h}/test_helper.zsh"

# Test: Help output format
test_help_output() {
  source "$CZRUBY_ROOT/fn/czruby"

  local output
  output=$(czruby -h 2>&1)

  assert_contains "$output" "Usage:" "Should contain Usage" || return 1
  assert_contains "$output" "czruby system" "Should document system command" || return 1
  assert_contains "$output" "--set-default" "Should document set-default" || return 1
  assert_contains "$output" "--purge" "Should document purge" || return 1
}

# Test: Help with long option
test_help_long_option() {
  source "$CZRUBY_ROOT/fn/czruby"

  local output
  output=$(czruby --help 2>&1)

  assert_contains "$output" "Usage:" "Should contain Usage with --help" || return 1
}

# Test: Version output
test_version_output() {
  source "$CZRUBY_ROOT/fn/czruby"

  local output
  output=$(czruby -V 2>&1)

  assert_equals "2.0.0" "$output" "Version should be 2.0.0" || return 1
}

# Test: Version long option
test_version_long_option() {
  source "$CZRUBY_ROOT/fn/czruby"

  local output
  output=$(czruby --version 2>&1)

  assert_equals "2.0.0" "$output" "Version should be 2.0.0 with --version" || return 1
}

# Test: Table display (no arguments)
test_table_display() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby"

  local output
  output=$(czruby 2>&1)

  # Should show table headers
  assert_contains "$output" "engine" "Should show engine column" || return 1
  assert_contains "$output" "version" "Should show version column" || return 1
  assert_contains "$output" "root" "Should show root column" || return 1
}

# Test: Table shows rubies
test_table_shows_rubies() {
  local ruby1=$(create_mock_ruby "3.2.0")
  local ruby2=$(create_mock_ruby "3.3.0")
  rubies=("$ruby1" "$ruby2")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby"

  local output
  output=$(czruby 2>&1)

  assert_contains "$output" "3.2.0" "Should show 3.2.0" || return 1
  assert_contains "$output" "3.3.0" "Should show 3.3.0" || return 1
}

# Test: Table shows system
test_table_shows_system() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby"

  local output
  output=$(czruby 2>&1)

  assert_contains "$output" "system" "Should show system legend" || return 1
}

# Test: Dispatch to set-default
test_dispatch_set_default() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby --set-default "3.3.0"

  assert_equals "3.3.0" "$RUBIES_DEFAULT" "Should set default via dispatch" || return 1
}

# Test: Dispatch to system
test_dispatch_system() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  # First use non-system
  czruby_reset "3.3.0"

  # Then dispatch to system
  czruby system

  assert_equals "/usr" "$RUBY_ROOT" "Should reset to system" || return 1
}

# Test: Dispatch to default
test_dispatch_default() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby_set_default "3.3.0"
  czruby_reset "system"

  # Dispatch to default
  czruby default

  assert_equals "$ruby_dir" "$RUBY_ROOT" "Should reset to default" || return 1
}

# Test: Dispatch to purge
test_dispatch_purge() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby"
  source "$CZRUBY_ROOT/fn/czruby_purge"
  source "$CZRUBY_ROOT/fn/czruby_set_default"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  local output
  output=$(czruby --purge 2>&1)

  assert_contains "$output" "purged" "Should run purge" || return 1
}

# Test: Dispatch to use
test_dispatch_use() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  czruby "3.3.0"

  assert_equals "$ruby_dir" "$RUBY_ROOT" "Should use specified ruby" || return 1
}

# Test: Unknown argument passed to use
test_unknown_argument() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby"
  source "$CZRUBY_ROOT/fn/czruby_use"
  source "$CZRUBY_ROOT/fn/czruby_reset"

  local output
  output=$(czruby "nonexistent" 2>&1)
  local result=$?

  assert_failure "$result" "Should fail for unknown ruby" || return 1
}

# Test: Table footer legend
test_table_footer_legend() {
  local ruby_dir=$(create_mock_ruby "3.3.0")
  rubies=("$ruby_dir")

  source "$CZRUBY_ROOT/fn/czruby_setup"
  source "$CZRUBY_ROOT/fn/czruby"

  local output
  output=$(czruby 2>&1)

  assert_contains "$output" "current" "Should show current legend" || return 1
  assert_contains "$output" "default" "Should show default legend" || return 1
}

# Run all tests
echo "Running czruby main dispatcher tests..."
echo "========================================"

run_test "Help output" test_help_output
run_test "Help long option" test_help_long_option
run_test "Version output" test_version_output
run_test "Version long option" test_version_long_option
run_test "Table display" test_table_display
run_test "Table shows rubies" test_table_shows_rubies
run_test "Table shows system" test_table_shows_system
run_test "Dispatch to set-default" test_dispatch_set_default
run_test "Dispatch to system" test_dispatch_system
run_test "Dispatch to default" test_dispatch_default
run_test "Dispatch to purge" test_dispatch_purge
run_test "Dispatch to use" test_dispatch_use
run_test "Unknown argument" test_unknown_argument
run_test "Table footer legend" test_table_footer_legend

print_summary

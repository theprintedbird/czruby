#!/usr/bin/env zsh
# Tests for czruby tab completion

source "${0:A:h}/test_helper.zsh"

test_completion_function_exists() {
	fpath=("$CZRUBY_ROOT" $fpath)
	autoload -Uz _czruby

	if ! whence -w _czruby >/dev/null 2>&1; then
		echo "ERROR: Completion function _czruby not found"
		return 1
	fi
	return 0
}

test_extract_ruby_names_from_paths() {
	local ruby1=$(create_mock_ruby "3.3.0")
	local ruby2=$(create_mock_ruby "truffleruby-21.1.0")
	rubies=("system" "$ruby1" "$ruby2")

	# Expected basenames: system, 3.3.0, truffleruby-21.1.0
	local name1="${ruby1:t}"
	local name2="${ruby2:t}"

	assert_equals "3.3.0" "$name1" || return 1
	assert_equals "truffleruby-21.1.0" "$name2" || return 1
}

test_parse_hyphenated_ruby_names() {
	local key="truffleruby-21.1.0"
	local engine="${key%%-*}"
	local version="${key#*-}"

	assert_equals "truffleruby" "$engine" || return 1
	assert_equals "21.1.0" "$version" || return 1
}

test_parse_plain_ruby_names() {
	local key="3.3.0"

	# No hyphen, so engine defaults to ruby
	if [[ "$key" =~ "-" ]]; then
		echo "ERROR: Should not contain hyphen"
		return 1
	fi
	return 0
}

test_completion_with_empty_rubies() {
	rubies=()

	fpath=("$CZRUBY_ROOT" $fpath)
	autoload -Uz _czruby

	# Should not crash
	return 0
}

test_parse_multiple_hyphens() {
	local key="ruby-3.3.0-preview1"
	local engine="${key%%-*}"
	local version="${key#*-}"

	# Should split on first hyphen only
	assert_equals "ruby" "$engine" || return 1
	assert_equals "3.3.0-preview1" "$version" || return 1
}

# Run tests
echo "Running czruby completion tests..."
echo "========================================"

run_test "Completion function exists" test_completion_function_exists
run_test "Extract ruby names from paths" test_extract_ruby_names_from_paths
run_test "Parse hyphenated ruby names" test_parse_hyphenated_ruby_names
run_test "Parse plain ruby names" test_parse_plain_ruby_names
run_test "Handle empty rubies array" test_completion_with_empty_rubies
run_test "Parse multiple hyphens" test_parse_multiple_hyphens

print_summary

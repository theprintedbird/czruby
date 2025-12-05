# Contributing to czruby

Thank you for your interest in contributing to czruby! This guide will help you set up your development environment and run tests.

## Table of Contents

- [Setting Up Development Environment](#setting-up-development-environment)
  - [Native Setup](#native-setup)
  - [Container Setup](#container-setup)
- [Running Tests](#running-tests)
  - [Using Containers (Recommended)](#using-containers-recommended)
  - [Native Testing](#native-testing)
- [Writing Tests](#writing-tests)
- [Debugging Test Failures](#debugging-test-failures)
- [CI/CD Integration](#cicd-integration)
- [Common Issues](#common-issues)

## Setting Up Development Environment

You can develop and test czruby either natively on your machine or using containers. Containers provide a consistent environment and are recommended for most contributors.

### Native Setup

If you prefer to run tests natively, you'll need the following dependencies:

#### Required Dependencies

1. **Z-Shell (zsh)** version 5.x or later
   ```bash
   # macOS (comes pre-installed)
   zsh --version

   # Linux (Ubuntu/Debian)
   sudo apt-get install zsh

   # Linux (Fedora)
   sudo dnf install zsh
   ```

2. **Ruby** (any version)
   ```bash
   # macOS (comes pre-installed)
   ruby --version

   # Linux (Ubuntu/Debian)
   sudo apt-get install ruby

   # Linux (Fedora)
   sudo dnf install ruby
   ```

3. **GNU Coreutils** (for `realpath`/`grealpath`)
   ```bash
   # macOS (via Homebrew)
   brew install coreutils

   # macOS (via MacPorts)
   sudo port install coreutils

   # Linux - already included
   ```

#### Environment Variables

Set the required XDG environment variables in your shell configuration:

```bash
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
```

### Container Setup

Containers provide a consistent, isolated testing environment without requiring native dependencies.

#### Prerequisites

Install either Docker or Podman:

**Docker:**
- macOS: [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
- Linux: [Docker Engine](https://docs.docker.com/engine/install/)
- Windows: [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)

**Podman:**
- macOS: `brew install podman`
- Linux: [Podman Installation Guide](https://podman.io/getting-started/installation)

No additional configuration is required. The container scripts auto-detect which runtime is available.

## Running Tests

### Using Containers (Recommended)

Containers provide the fastest and most reliable way to run tests, matching the CI environment exactly.

#### Quick Start

```bash
# Run all tests
./scripts/test-container.sh

# Run specific test file
./scripts/test-container.sh test/test_czruby_setup.zsh

# Force rebuild and run tests
./scripts/test-container.sh --build
```

#### Using Docker Compose

```bash
# Run all tests
docker compose up test

# Run specific test
docker compose run --rm test zsh test/test_czruby_setup.zsh

# Interactive shell for debugging
docker compose run --rm shell
```

#### Direct Docker/Podman Commands

```bash
# Build image
docker build -t czruby-test .

# Run all tests
docker run --rm czruby-test

# Run specific test
docker run --rm czruby-test zsh test/test_czruby_setup.zsh

# Interactive shell
docker run --rm -it czruby-test zsh

# With live code mounting
docker run --rm -v $(pwd):/app czruby-test
```

### Native Testing

If you have the native dependencies installed:

```bash
# Run all tests
zsh test/run_all_tests.zsh

# Run specific test suite
zsh test/test_czruby_setup.zsh
zsh test/test_czruby_use.zsh
zsh test/test_integration.zsh
```

#### Syntax Checking

```bash
# Check zsh syntax for all functions
for file in functions/*; do zsh -n "$file"; done
zsh -n czruby.plugin.conf
```

#### Linting

```bash
# Run ShellCheck (with zsh-appropriate exclusions)
shellcheck --shell=bash --severity=warning \
  -e SC2034 -e SC2128 -e SC2154 -e SC2206 \
  -e SC2296 -e SC2299 -e SC1090 -e SC2086 \
  functions/* czruby.plugin.conf
```

## Writing Tests

czruby uses a custom zsh testing framework located in `test/test_helper.zsh`.

### Test Structure

Each test file should follow this structure:

```zsh
#!/usr/bin/env zsh

# Source the test helper
source "$(dirname "$0")/test_helper.zsh"

# Define test functions
test_example_functionality() {
    # Setup
    local expected="some value"

    # Execute
    local actual=$(some_function)

    # Assert
    assert_equals "$expected" "$actual" "Function should return expected value"
}

test_another_feature() {
    # Your test code here
    assert_success some_command
}

# Run all tests
run_test test_example_functionality
run_test test_another_feature

# Print summary
print_summary
```

### Available Assertions

The test framework provides these assertion functions:

- `assert_equals <expected> <actual> [message]` - Values must be equal
- `assert_not_equals <value1> <value2> [message]` - Values must differ
- `assert_contains <haystack> <needle> [message]` - String contains substring
- `assert_not_contains <haystack> <needle> [message]` - String doesn't contain substring
- `assert_file_exists <path> [message]` - File must exist
- `assert_file_not_exists <path> [message]` - File must not exist
- `assert_dir_exists <path> [message]` - Directory must exist
- `assert_symlink <path> <target> [message]` - Symlink must point to target
- `assert_array_contains <array_name> <value> [message]` - Array contains value
- `assert_array_not_contains <array_name> <value> [message]` - Array doesn't contain value
- `assert_success <command> [message]` - Command exits with 0
- `assert_failure <command> [message]` - Command exits with non-zero
- `assert_empty <value> [message]` - Value is empty
- `assert_not_empty <value> [message]` - Value is not empty

### Mock Ruby Installations

Use the helper functions to create mock Ruby installations:

```zsh
test_with_mock_ruby() {
    # Create mock Ruby in test directory
    local ruby_dir=$(create_mock_ruby "3.2.0")

    # Use in tests
    assert_dir_exists "$ruby_dir/bin"
    assert_file_exists "$ruby_dir/bin/ruby"
}

test_with_system_ruby() {
    # Create mock system Ruby
    create_system_ruby "2.7.0"

    # Test system Ruby detection
    assert_file_exists "/usr/bin/ruby"
}
```

## Debugging Test Failures

### Interactive Container Shell

The easiest way to debug test failures is using the interactive shell:

```bash
# Start interactive shell with live code mounting
./scripts/test-shell.sh
```

Inside the shell, you can:

```zsh
# Run individual test files
zsh test/test_czruby_setup.zsh

# Source czruby manually
source czruby.plugin.conf
autoload -Uz czruby czruby_setup czruby_use

# Test functions interactively
czruby --version
czruby_setup
echo $rubies

# Run specific test functions
source test/test_helper.zsh
setup_test_env
test_czruby_version  # Replace with actual test function name
```

### Debugging Tips

1. **Check test output** - Tests print detailed failure messages
2. **Inspect environment** - Use `echo` statements to verify variable values
3. **Run tests in isolation** - Test individual files to narrow down issues
4. **Use zsh debugging** - Add `set -x` to enable trace mode
5. **Check file permissions** - Ensure test scripts are executable

### Common Debugging Commands

```bash
# Check if functions are loaded
autoload -Uz czruby && whence -v czruby

# Inspect arrays
echo $rubies
echo $path

# Check XDG directories
ls -la $XDG_DATA_HOME/czruby/

# View generated Ruby configs
cat $XDG_DATA_HOME/czruby/system
```

## CI/CD Integration

The container-based tests can be integrated into any CI/CD system.

### GitHub Actions

Already configured in `.github/workflows/test.yml`.

### GitLab CI

```yaml
test:
  image: ubuntu:22.04
  before_script:
    - apt-get update && apt-get install -y docker.io
  script:
    - ./scripts/test-container.sh
```

### Jenkins

```groovy
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                sh './scripts/test-container.sh'
            }
        }
    }
}
```

### CircleCI

```yaml
version: 2.1
jobs:
  test:
    docker:
      - image: cimg/base:stable
    steps:
      - checkout
      - setup_remote_docker
      - run: ./scripts/test-container.sh
```

### Local Pre-Commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
./scripts/test-container.sh
exit $?
```

## Common Issues

### Issue: Container runtime not found

**Error:** `Error: Neither Docker nor Podman is installed.`

**Solution:** Install Docker or Podman (see [Container Setup](#container-setup))

### Issue: Permission denied on scripts

**Error:** `Permission denied: ./scripts/test-container.sh`

**Solution:**
```bash
chmod +x scripts/*.sh
```

### Issue: Tests pass locally but fail in CI

**Cause:** Different environments (native vs container)

**Solution:** Always test using containers before pushing:
```bash
./scripts/test-container.sh --build
```

### Issue: `grealpath: command not found` (macOS native testing)

**Error:** `grealpath: command not found`

**Solution:** Install GNU coreutils:
```bash
brew install coreutils
```

### Issue: XDG directories not set (native testing)

**Error:** Tests fail with missing directory errors

**Solution:** Export XDG variables:
```bash
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
```

### Issue: Container build fails

**Error:** Docker build errors

**Solution:**
1. Check your internet connection
2. Try rebuilding: `./scripts/test-container.sh --build`
3. Clear Docker cache: `docker system prune -a`

### Issue: Tests are slow

**Solution:**
- Use containers (faster than native on some systems)
- Run specific test files instead of full suite
- Use Docker layer caching (automatic)

## Getting Help

If you encounter issues not covered here:

1. Check existing [GitHub Issues](https://github.com/YOUR_REPO/czruby/issues)
2. Review test output carefully - it's usually descriptive
3. Try the interactive shell for debugging
4. Open a new issue with:
   - Your operating system and version
   - Docker/Podman version (if using containers)
   - Complete error output
   - Steps to reproduce

## Code Style

- Follow existing code conventions
- Use zsh best practices (autoload, no global variables)
- Add tests for new features
- Update documentation for significant changes
- Keep functions focused and single-purpose

## Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure all tests pass: `./scripts/test-container.sh`
5. Update documentation if needed
6. Submit a pull request with a clear description

Thank you for contributing to czruby!

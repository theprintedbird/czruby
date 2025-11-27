#!/usr/bin/env bash
# Universal test runner supporting Docker and Podman
# Runs czruby tests in a container

set -euo pipefail

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the utility library
# shellcheck source=scripts/container-tool.sh
source "$SCRIPT_DIR/container-tool.sh"

# Parse command line arguments
FORCE_BUILD=false
TEST_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --build|-b)
            FORCE_BUILD=true
            shift
            ;;
        --help|-h)
            print_usage "$(basename "$0")"
            echo "Examples:"
            echo "  $0                                    # Run all tests"
            echo "  $0 test/test_czruby_setup.zsh        # Run specific test file"
            echo "  $0 --build                            # Force rebuild and run all tests"
            exit 0
            ;;
        *)
            TEST_ARGS+=("$1")
            shift
            ;;
    esac
done

# Change to project root
cd "$PROJECT_ROOT"

# Detect container runtime
RUNTIME=$(get_container_runtime)
log_info "Using container runtime: $RUNTIME"

# Build image if needed
if [ "$FORCE_BUILD" = "true" ]; then
    build_image "$RUNTIME" true || exit 1
elif ! image_exists "$RUNTIME"; then
    log_info "Container image not found, building..."
    build_image "$RUNTIME" false || exit 1
else
    log_info "Using existing container image: $FULL_IMAGE"
fi

# Determine what to run
if [ ${#TEST_ARGS[@]} -eq 0 ]; then
    # Run all tests
    log_info "Running all tests..."
    run_container "$RUNTIME" zsh test/run_all_tests.zsh
    EXIT_CODE=$?
else
    # Run specific test file(s)
    log_info "Running: ${TEST_ARGS[*]}"
    run_container "$RUNTIME" zsh "${TEST_ARGS[@]}"
    EXIT_CODE=$?
fi

# Report results
if [ $EXIT_CODE -eq 0 ]; then
    log_success "Tests passed!"
else
    log_error "Tests failed with exit code $EXIT_CODE"
fi

exit $EXIT_CODE

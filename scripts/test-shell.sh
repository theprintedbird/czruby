#!/usr/bin/env bash
# Interactive debugging shell for czruby
# Drops into a zsh shell inside the container with live code mounting

set -euo pipefail

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the utility library
# shellcheck source=scripts/container-tool.sh
source "$SCRIPT_DIR/container-tool.sh"

# Parse command line arguments
FORCE_BUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --build|-b)
            FORCE_BUILD=true
            shift
            ;;
        --help|-h)
            echo "Usage: $(basename "$0") [OPTIONS]"
            echo ""
            echo "Opens an interactive zsh shell inside the test container."
            echo "The current directory is mounted as /app for live code editing."
            echo ""
            echo "Options:"
            echo "  --build, -b     Force rebuild of container image"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Inside the shell, you can:"
            echo "  - Run individual tests: zsh test/test_czruby_setup.zsh"
            echo "  - Source functions: source czruby.plugin.conf && autoload -Uz czruby"
            echo "  - Run czruby commands: czruby --version"
            echo "  - Debug test failures: manually execute test functions"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
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

# Launch interactive shell
log_info "Starting interactive shell..."
log_info "Your code is mounted at /app (changes are live)"
echo ""
echo -e "${GREEN}Welcome to the czruby test environment!${NC}"
echo -e "${YELLOW}Useful commands:${NC}"
echo "  - zsh test/run_all_tests.zsh          # Run all tests"
echo "  - zsh test/test_czruby_setup.zsh      # Run specific test"
echo "  - source czruby.plugin.conf           # Load czruby"
echo "  - czruby --version                    # Test czruby command"
echo ""

run_container_interactive "$RUNTIME" zsh

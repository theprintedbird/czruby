#!/usr/bin/env bash
# Shared utility library for container scripts
# Sources this file to access common functions

set -euo pipefail

# Configuration
IMAGE_NAME="czruby-test"
IMAGE_TAG="latest"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

# Colors for output
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Detect available container runtime
detect_container_runtime() {
    if command -v docker &> /dev/null; then
        echo "docker"
    elif command -v podman &> /dev/null; then
        echo "podman"
    else
        echo "none"
    fi
}

# Get the container runtime to use
get_container_runtime() {
    local runtime
    runtime=$(detect_container_runtime)

    if [ "$runtime" = "none" ]; then
        echo -e "${RED}Error: Neither Docker nor Podman is installed.${NC}" >&2
        echo -e "${YELLOW}Please install Docker or Podman to use container-based testing.${NC}" >&2
        exit 1
    fi

    echo "$runtime"
}

# Build the container image
build_image() {
    local runtime="$1"
    local force_rebuild="${2:-false}"

    echo -e "${BLUE}Building container image with ${runtime}...${NC}"

    if [ "$force_rebuild" = "true" ]; then
        $runtime build --no-cache -t "$FULL_IMAGE" .
    else
        $runtime build -t "$FULL_IMAGE" .
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Container image built successfully.${NC}"
        return 0
    else
        echo -e "${RED}Failed to build container image.${NC}" >&2
        return 1
    fi
}

# Check if image exists
image_exists() {
    local runtime="$1"
    $runtime images -q "$FULL_IMAGE" 2>/dev/null | grep -q .
}

# Run container with common options
run_container() {
    local runtime="$1"
    shift
    local args=("$@")

    $runtime run --rm \
        -v "$(pwd):/app" \
        -e XDG_DATA_HOME=/tmp/czruby-data \
        -e XDG_CACHE_HOME=/tmp/czruby-cache \
        -e XDG_CONFIG_HOME=/tmp/czruby-config \
        "$FULL_IMAGE" \
        "${args[@]}"
}

# Run container with volume mount
run_container_with_volume() {
    local runtime="$1"
    shift
    local args=("$@")

    $runtime run --rm \
        -v "$(pwd):/app" \
        -e XDG_DATA_HOME=/tmp/czruby-data \
        -e XDG_CACHE_HOME=/tmp/czruby-cache \
        -e XDG_CONFIG_HOME=/tmp/czruby-config \
        "${args[@]}" \
        "$FULL_IMAGE"
}

# Run container interactively
run_container_interactive() {
    local runtime="$1"
    shift
    local args=("$@")

    $runtime run --rm -it \
        -v "$(pwd):/app" \
        -e XDG_DATA_HOME=/tmp/czruby-data \
        -e XDG_CACHE_HOME=/tmp/czruby-cache \
        -e XDG_CONFIG_HOME=/tmp/czruby-config \
        "${args[@]}" \
        "$FULL_IMAGE"
}

# Print usage message
print_usage() {
    local script_name="$1"
    echo "Usage: $script_name [OPTIONS] [ARGS]"
    echo ""
    echo "Runs czruby tests in a container using Docker or Podman."
    echo ""
    echo "Options:"
    echo "  --build, -b     Force rebuild of container image"
    echo "  --help, -h      Show this help message"
    echo ""
}

# Log message with color
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

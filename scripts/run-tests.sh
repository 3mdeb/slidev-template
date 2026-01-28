#!/bin/bash
# Run Playwright tests for slidev-template
#
# This script handles everything automatically:
# 1. Creates test presentation structure
# 2. Starts dev server
# 3. Runs tests
# 4. Cleans up
#
# Usage:
#   ./scripts/run-tests.sh              # Run all tests
#   ./scripts/run-tests.sh update       # Update screenshot baselines
#   ./scripts/run-tests.sh clean        # Clean up test artifacts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"
PARENT_DIR="$(dirname "$TEMPLATE_DIR")"
TEST_REPO_DIR="$PARENT_DIR/slidev-template-tests"
WORKTREE_DIR="$TEST_REPO_DIR/slidev-template"
SLIDEV_PORT="${SLIDEV_PORT:-8000}"
DEV_SERVER_PID=""
DEV_CONTAINER_NAME="slidev-test-server-$$"

source "${SCRIPT_DIR}/env.sh"

print_error() {
  echo -e "\033[31mERROR: $1\033[0m"
}

print_info() {
  echo -e "\033[34m$1\033[0m"
}

print_success() {
  echo -e "\033[32m$1\033[0m"
}

cleanup() {
  print_info "Cleaning up..."
  # Stop dev server container if running
  docker stop "$DEV_CONTAINER_NAME" 2>/dev/null || true
  docker rm "$DEV_CONTAINER_NAME" 2>/dev/null || true
}

trap cleanup EXIT

usage() {
  cat <<EOF
Usage: $(basename "$0") [test|update|dev|clean]

Commands:
  test    Run Playwright tests (default) - starts server automatically
  update  Update screenshot baselines - starts server automatically
  dev     Start dev server only (for manual testing)
  clean   Remove test repo and worktree

Examples:
  ./scripts/run-tests.sh           # Run all tests
  ./scripts/run-tests.sh update    # Update baselines
  SLIDEV_PORT=8002 ./scripts/run-tests.sh  # Use different port

Environment Variables:
  SLIDEV_PORT  Port for dev server (default: 8000)
EOF
  exit 0
}

setup_test_repo() {
  print_info "Setting up test presentation repo..."

  mkdir -p "$TEST_REPO_DIR"

  # Create git worktree for slidev-template (real directory for Docker)
  if [ ! -d "$WORKTREE_DIR" ]; then
    cd "$TEMPLATE_DIR"
    git worktree add "$WORKTREE_DIR" HEAD --detach 2>/dev/null || true
    cd - > /dev/null
  fi

  # Copy required files
  cp "$TEMPLATE_DIR/slides-template.md" "$TEST_REPO_DIR/"
  cp "$TEMPLATE_DIR/tests/fixtures/test-slides.md" "$TEST_REPO_DIR/"
  cp "$WORKTREE_DIR/vite.config.ts" "$TEST_REPO_DIR/"

  # Create slides.md from template (mimics render-slides.sh)
  # The src path is relative to slidev-template directory
  local input_file_rel="../test-slides.md"
  local escaped_file
  escaped_file=$(printf '%s\n' "$input_file_rel" | sed -e 's/[\/&$]/\\&/g')

  sed -e "s/<SRC>/$escaped_file/g" \
      -e "s/<DAY>/1/g" \
      -e "s/<COPYRIGHT>/3mdeb Sp. z o.o. Licensed under the CC BY-SA 4.0/g" \
      -e "s/<TITLE>/Test Presentation/g" \
      "$TEST_REPO_DIR/slides-template.md" > "$WORKTREE_DIR/slides.md"

  # Create symlink for slides to access parent directory resources
  if [ -L "$WORKTREE_DIR/slides" ]; then
    unlink "$WORKTREE_DIR/slides"
  fi
  ln -sr "$TEST_REPO_DIR" "$WORKTREE_DIR/slides" 2>/dev/null || true

  print_info "Test repo ready"
}

wait_for_server() {
  local max_attempts=60
  local attempt=0

  print_info "Waiting for dev server to be ready..."

  while [ $attempt -lt $max_attempts ]; do
    if curl -s "http://localhost:$SLIDEV_PORT" > /dev/null 2>&1; then
      print_success "Dev server is ready"
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 1
  done

  print_error "Dev server failed to start within ${max_attempts}s"
  return 1
}

start_dev_server() {
  setup_test_repo

  local node_max_old_space=${SLIDEV_NODE_MAX_OLD_SPACE:-4096}

  print_info "Starting dev server on port $SLIDEV_PORT..."

  # Start dev server in background container
  # Note: Cannot use render-slides.sh here because:
  # - render-slides.sh runs interactively (-it) and blocks
  # - We need detached mode (-d) for automated test execution
  # - We need a named container for cleanup via trap handler
  # For interactive use, start_dev_server_interactive() delegates to render-slides.sh
  docker run -d --rm \
    --name "$DEV_CONTAINER_NAME" \
    --user "$(id -u):$(id -g)" \
    -v "$TEST_REPO_DIR:/repo" \
    -p "$SLIDEV_PORT:8000" \
    -e NODE_OPTIONS="--max-old-space-size=$node_max_old_space" \
    "$PLAYWRIGHT_IMAGE" \
    bash -c "cd /repo/slidev-template && npm install --silent && npm run dev slides.md -- -o false -p 8000 --remote --force" \
    > /dev/null

  wait_for_server
}

start_dev_server_interactive() {
  setup_test_repo

  local node_max_old_space=${SLIDEV_NODE_MAX_OLD_SPACE:-4096}

  print_info "Starting dev server on port $SLIDEV_PORT (Ctrl+C to stop)..."
  print_info "Access at http://localhost:$SLIDEV_PORT"

  cd "$TEST_REPO_DIR"
  SLIDEV_PORT="$SLIDEV_PORT" ./slidev-template/scripts/render-slides.sh test-slides.md
}

run_tests() {
  local test_args="${1:-}"

  print_info "Running Playwright tests..."

  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -v "$TEMPLATE_DIR:/repo" \
    --network host \
    -e SLIDEV_BASE_URL="http://localhost:$SLIDEV_PORT" \
    "$PLAYWRIGHT_IMAGE" \
    bash -c "cd /repo && npm install --silent && node node_modules/@playwright/test/cli.js test $test_args"
}

clean_test_repo() {
  print_info "Cleaning up..."

  # Stop any running test containers
  docker ps -q --filter "name=slidev-test-server" | xargs -r docker stop 2>/dev/null || true

  # Remove symlink first (prevents worktree removal issues)
  if [ -L "$WORKTREE_DIR/slides" ]; then
    unlink "$WORKTREE_DIR/slides" 2>/dev/null || true
  fi

  # Remove generated slides.md
  rm -f "$WORKTREE_DIR/slides.md" 2>/dev/null || true

  # Remove git worktree
  if [ -d "$WORKTREE_DIR" ]; then
    cd "$TEMPLATE_DIR"
    git worktree remove "$WORKTREE_DIR" --force 2>/dev/null || rm -rf "$WORKTREE_DIR"
    cd - > /dev/null
  fi

  rm -rf "$TEST_REPO_DIR"
  rm -rf "$TEMPLATE_DIR/test-results"
  rm -rf "$TEMPLATE_DIR/playwright-report"

  print_success "Cleanup complete"
}

# Parse command
CMD="${1:-test}"

case "$CMD" in
  test)
    start_dev_server
    run_tests
    print_success "All tests passed!"
    ;;
  update|update-snapshots)
    start_dev_server
    run_tests "--update-snapshots"
    print_success "Baselines updated!"
    ;;
  dev)
    start_dev_server_interactive
    ;;
  clean)
    clean_test_repo
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    print_error "Unknown command: $CMD"
    usage
    ;;
esac

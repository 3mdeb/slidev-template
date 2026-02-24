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
#   ./scripts/run-tests.sh broken       # Prove all tests detect regressions
#   ./scripts/run-tests.sh broken <test> # Prove specific test detects regressions

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

# Broken fixture mode
BROKEN_FEATURE=""


print_error() {
  echo -e "\033[31mERROR: $1\033[0m"
}

print_info() {
  echo -e "\033[34m$1\033[0m"
}

print_success() {
  echo -e "\033[32m$1\033[0m"
}

print_warning() {
  echo -e "\033[33m$1\033[0m"
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
Usage: $(basename "$0") [test|update|dev|clean|broken [TEST_NAME]]

Commands:
  test         Run Playwright tests (default) - starts server automatically
  update       Update screenshot baselines - starts server automatically
  dev          Start dev server only (for manual testing)
  clean        Remove test repo and worktree
  broken       Prove all fixture-breakable tests detect regressions (11 tests)
  broken NAME  Prove specific test detects regressions

Available broken fixture tests (11):
  src-directive    - "src: directive renders content"
  images           - "images load without errors"
  cover            - "Layouts › cover"
  two-cols         - "Layouts › two-cols"
  two-cols-header  - "Layouts › two-cols-header"
  quote            - "Layouts › quote"
  figure           - "Components › figure with figcaption"
  footnotes        - "Components › Footnotes"
  table            - "Components › table"
  footer-visible   - "Footer › visible on content slides"
  footer-hidden    - "Footer › hidden on cover slides"

Tests not fixture-breakable (6):
  - "responds on configured port" (tests server response)
  - "theme loads without console errors" (Slidev handles gracefully)
  - "all slides load without OOM" (Slidev shows last slide)
  - "presenter mode accessible" (tests routing)
  - "overview mode accessible" (tests routing)
  - "renders with notes panel" (screenshot doesn't verify notes)

Examples:
  ./scripts/run-tests.sh                    # Run all tests
  ./scripts/run-tests.sh update             # Update baselines
  ./scripts/run-tests.sh broken             # Prove ALL tests catch regressions
  ./scripts/run-tests.sh broken footnotes   # Prove Footnotes test catches regressions
  ./scripts/run-tests.sh broken cover       # Prove cover layout test catches regressions
  SLIDEV_PORT=8002 ./scripts/run-tests.sh   # Use different port

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

  # Copy base required files
  cp "$TEMPLATE_DIR/slides-template.md" "$TEST_REPO_DIR/"
  cp "$WORKTREE_DIR/vite.config.ts" "$TEST_REPO_DIR/"

  # Always copy base slides for src: imports (used by minimal fixtures)
  cp "$TEMPLATE_DIR/tests/fixtures/test-slides.md" "$TEST_REPO_DIR/base-slides.md"

  # Apply broken fixture if requested
  # Fixtures use src: imports to minimize duplication (see tests/fixtures/broken/README.md)
  case "$BROKEN_FEATURE" in
    src-directive)
      print_warning "Breaking: Default Layout text (src directive test)"
      cp "$TEMPLATE_DIR/tests/fixtures/broken/test-slides-no-default-text.md" "$TEST_REPO_DIR/test-slides.md"
      ;;
    images)
      print_warning "Breaking: Referencing non-existent images"
      cp "$TEMPLATE_DIR/tests/fixtures/broken/test-slides-broken-images.md" "$TEST_REPO_DIR/test-slides.md"
      ;;
    cover)
      print_warning "Breaking: Removing cover layout"
      cp "$TEMPLATE_DIR/tests/fixtures/broken/test-slides-no-cover.md" "$TEST_REPO_DIR/test-slides.md"
      ;;
    two-cols)
      print_warning "Breaking: Removing two-cols layout"
      cp "$TEMPLATE_DIR/tests/fixtures/broken/test-slides-no-twocols.md" "$TEST_REPO_DIR/test-slides.md"
      ;;
    two-cols-header)
      print_warning "Breaking: Removing two-cols-header layout"
      cp "$TEMPLATE_DIR/tests/fixtures/broken/test-slides-no-twocolsheader.md" "$TEST_REPO_DIR/test-slides.md"
      ;;
    quote)
      print_warning "Breaking: Removing quote layout"
      cp "$TEMPLATE_DIR/tests/fixtures/broken/test-slides-no-quote.md" "$TEST_REPO_DIR/test-slides.md"
      ;;
    figure)
      print_warning "Breaking: Removing figure/figcaption elements"
      cp "$TEMPLATE_DIR/tests/fixtures/broken/test-slides-no-figure.md" "$TEST_REPO_DIR/test-slides.md"
      ;;
    footnotes)
      print_warning "Breaking: Removing Footnotes component"
      cp "$TEMPLATE_DIR/tests/fixtures/broken/test-slides-no-footnotes.md" "$TEST_REPO_DIR/test-slides.md"
      ;;
    table)
      print_warning "Breaking: Removing table element"
      cp "$TEMPLATE_DIR/tests/fixtures/broken/test-slides-no-table.md" "$TEST_REPO_DIR/test-slides.md"
      ;;
    footer-visible)
      print_warning "Breaking: Using cover layout on slide 2 (hides footer)"
      cp "$TEMPLATE_DIR/tests/fixtures/broken/test-slides-no-footer-visible.md" "$TEST_REPO_DIR/test-slides.md"
      ;;
    footer-hidden)
      print_warning "Breaking: Using default layout on cover slide (shows footer)"
      cp "$TEMPLATE_DIR/tests/fixtures/broken/test-slides-footer-on-cover.md" "$TEST_REPO_DIR/test-slides.md"
      ;;
    "")
      cp "$TEMPLATE_DIR/tests/fixtures/test-slides.md" "$TEST_REPO_DIR/"
      ;;
    *)
      print_error "Unknown broken fixture: $BROKEN_FEATURE"
      exit 1
      ;;
  esac

  # Create slides.md from template (mimics render-slides.sh)
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

stop_dev_server() {
  docker stop "$DEV_CONTAINER_NAME" 2>/dev/null || true
  docker rm "$DEV_CONTAINER_NAME" 2>/dev/null || true
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

# Map broken fixture name to test grep pattern
# Note: Use unique substrings that match exactly one test
# Playwright --grep uses JavaScript regex against full test title
get_test_pattern() {
  local fixture="$1"
  case "$fixture" in
    src-directive)    echo "src: directive renders content" ;;
    images)           echo "images load without errors" ;;
    cover)            echo "Layouts.*cover" ;;
    two-cols)         echo "two-cols$" ;;
    two-cols-header)  echo "two-cols-header" ;;
    quote)            echo "Layouts.*quote" ;;
    figure)           echo "figure with figcaption" ;;
    footnotes)        echo "Footnotes" ;;
    table)            echo "Components.*table" ;;
    footer-visible)   echo "visible on content slides" ;;
    footer-hidden)    echo "hidden on cover slides" ;;
    *)                echo "" ;;
  esac
}

# Run single broken test
run_single_broken_test() {
  local fixture="$1"
  local test_pattern
  test_pattern=$(get_test_pattern "$fixture")

  if [ -z "$test_pattern" ]; then
    print_error "Unknown fixture: $fixture"
    return 1
  fi

  echo ""
  print_info "═══════════════════════════════════════════════════════════════"
  print_info "Testing: $fixture → \"$test_pattern\""
  print_info "═══════════════════════════════════════════════════════════════"

  # Clean and setup with broken fixture
  clean_test_repo 2>/dev/null || true
  BROKEN_FEATURE="$fixture"
  start_dev_server

  # Run the specific test
  print_info "Running test with broken fixture..."
  if run_tests "--grep '$test_pattern'" 2>&1; then
    print_error "✗ FAIL: Test PASSED but should have FAILED"
    print_error "  Test does NOT detect regressions!"
    stop_dev_server
    return 1
  else
    print_success "✓ PASS: Test correctly FAILED when $fixture was broken"
    stop_dev_server
  fi

  return 0
}

# All fixture-breakable tests (11 total)
# Fixtures use src: imports to minimize duplication
# Excluded (test logic doesn't detect fixture changes):
#   - console-error: Slidev handles invalid components gracefully
#   - oom: Slidev shows last slide for missing slide numbers
#   - presenter: Screenshot test doesn't verify notes content
BROKEN_FIXTURES=(
  "src-directive"
  "images"
  "cover"
  "two-cols"
  "two-cols-header"
  "quote"
  "figure"
  "footnotes"
  "table"
  "footer-visible"
  "footer-hidden"
)

# Run all broken tests
run_all_broken_tests() {
  local passed=0
  local failed=0
  local failed_tests=()

  echo ""
  print_info "═══════════════════════════════════════════════════════════════"
  print_info "Running ALL broken fixture tests (${#BROKEN_FIXTURES[@]} tests)"
  print_info "═══════════════════════════════════════════════════════════════"

  for fixture in "${BROKEN_FIXTURES[@]}"; do
    if run_single_broken_test "$fixture"; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
      failed_tests+=("$fixture")
    fi
  done

  echo ""
  print_info "═══════════════════════════════════════════════════════════════"
  print_info "SUMMARY"
  print_info "═══════════════════════════════════════════════════════════════"
  print_success "Passed: $passed"
  if [ $failed -gt 0 ]; then
    print_error "Failed: $failed"
    print_error "Failed tests: ${failed_tests[*]}"
    exit 1
  fi
  echo ""
  print_success "PROOF COMPLETE: All $passed tests detect regressions ✓"
}

# Run regression proof tests
run_broken_tests() {
  local specific_test="${1:-}"

  if [ -n "$specific_test" ]; then
    if run_single_broken_test "$specific_test"; then
      echo ""
      print_success "PROOF COMPLETE: $specific_test test detects regressions ✓"
    else
      exit 1
    fi
  else
    run_all_broken_tests
  fi
}

# Parse command
CMD="${1:-test}"
ARG2="${2:-}"

case "$CMD" in
  test)
    start_dev_server
    run_tests
    print_success "All tests passed!"
    ;;
  broken)
    run_broken_tests "$ARG2"
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

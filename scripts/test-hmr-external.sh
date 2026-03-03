#!/bin/bash
# Test HMR for src:-included files outside slidev-template.
#
# Reproduces m-iwanicki's PR #23 review issue:
#   Source .md file lives in parent repo (../pages/), included via src: directive.
#   Editing the source on the HOST must trigger HMR inside Docker dev server.
#
# The test modifies the file on the HOST (not inside Docker) because the bug
# is a chokidar symlink path mismatch between host filesystem events and
# Slidev's internal watchFiles map.
#
# Usage:
#   ./scripts/test-hmr-external.sh
#   SLIDEV_PORT=8003 ./scripts/test-hmr-external.sh
#
# Environment:
#   SLIDEV_PORT - port for dev server (default: 8003)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"
REPRO_DIR="$(mktemp -d)"
SLIDEV_PORT="${SLIDEV_PORT:-8003}"
DEV_CONTAINER="hmr-dev-$$"
TEST_CONTAINER="hmr-test-$$"

source "${SCRIPT_DIR}/env.sh"

print_error() { echo -e "\033[31mERROR: $1\033[0m"; }
print_info()  { echo -e "\033[34m$1\033[0m"; }
print_success() { echo -e "\033[32m$1\033[0m"; }

cleanup() {
  docker stop "$DEV_CONTAINER" >/dev/null 2>&1 || true
  docker stop "$TEST_CONTAINER" >/dev/null 2>&1 || true
  docker compose -f "$REPRO_DIR/slidev-template/docker-compose.yml" down >/dev/null 2>&1 || true
  rm -rf "$REPRO_DIR"
}
trap cleanup EXIT

print_info "HMR external file test (port $SLIDEV_PORT)"
echo ""

# --- Setup: mock presentation repo ---
print_info "Setting up mock presentation repo..."

mkdir -p "$REPRO_DIR/pages"
cat > "$REPRO_DIR/pages/test-content.md" << 'SLIDES'
# Test Slide

This is the ORIGINAL content.

- Bullet point one
- Bullet point two

---

# Second Slide

More content here.
SLIDES

# Copy slidev-template (like a git submodule checkout)
cp -r "$TEMPLATE_DIR" "$REPRO_DIR/slidev-template"
rm -rf "$REPRO_DIR/slidev-template/.git"

# Generate slides.md (same as render-slides.sh)
input_file_rel=$(realpath --relative-to "$REPRO_DIR/slidev-template" "$REPRO_DIR/pages/test-content.md")
escaped_file=$(printf '%s\n' "$input_file_rel" | sed -e 's/[\/&$]/\\&/g')
sed -e "s/<SRC>/$escaped_file/g" -e "s/<DAY>/1/g" \
    -e "s/<COPYRIGHT>/Test/g" -e "s/<TITLE>/Test/g" \
  "$REPRO_DIR/slidev-template/slides-template.md" > "$REPRO_DIR/slidev-template/slides.md"

# Create slides symlink (same as render-slides.sh)
ln -sf .. "$REPRO_DIR/slidev-template/slides"
cp "$REPRO_DIR/slidev-template/vite.config.ts" "$REPRO_DIR/"

# --- Start services ---
print_info "Starting Kroki + dev server..."

docker compose -f "$REPRO_DIR/slidev-template/docker-compose.yml" up -d >/dev/null 2>&1

docker run -d --rm \
  --name "$DEV_CONTAINER" \
  --user "$(id -u):$(id -g)" \
  -v "$REPRO_DIR:/repo" \
  -p "$SLIDEV_PORT:8000" \
  --network slidev \
  -e NODE_OPTIONS="--max-old-space-size=4096 --expose-gc" \
  "$PLAYWRIGHT_IMAGE" \
  bash -c "cd /repo/slidev-template && npm install --silent && npm run dev slides.md -- -o false -p 8000 --remote --force" \
  >/dev/null

# Wait for server
code=""
for i in $(seq 1 30); do
  code=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$SLIDEV_PORT/" 2>/dev/null || true)
  if [ "$code" = "200" ]; then break; fi
  sleep 2
done

if [ "$code" != "200" ]; then
  print_error "Dev server failed to start after 60s"
  exit 1
fi

print_info "Dev server ready"

# --- Coordination ---
# The Playwright test runs in Docker and polls for content changes.
# The HOST modifies the source file after Playwright signals readiness.
# Coordination uses files in the shared $REPRO_DIR volume.
rm -f "$REPRO_DIR/.test-ready" "$REPRO_DIR/.test-result"

# --- Run Playwright HMR test ---
print_info "Running HMR test..."
echo ""

# Start Playwright in background — it will signal readiness, then poll
docker run --rm \
  --name "$TEST_CONTAINER" \
  --user "$(id -u):$(id -g)" \
  -v "$REPRO_DIR:/repo" \
  --network host \
  "$PLAYWRIGHT_IMAGE" \
  bash -c "cd /repo/slidev-template && npm install --silent 2>/dev/null && node -e \"
const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  // Step 1: Navigate and verify initial content on slide 2
  await page.goto('http://localhost:$SLIDEV_PORT/2');
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(1000);
  const initial = await page.textContent('body');
  if (!initial.includes('ORIGINAL')) {
    console.log('ERROR: slide 2 does not contain source content');
    fs.writeFileSync('/repo/.test-result', 'ERROR');
    await browser.close();
    process.exit(1);
  }
  console.log('  Slide 2 has ORIGINAL content: OK');

  // Step 2: Signal host to modify the file
  fs.writeFileSync('/repo/.test-ready', 'ready');
  console.log('  Signaled host to modify source file');

  // Step 3: Wait for host to modify file (up to 10s)
  for (let i = 0; i < 10; i++) {
    await page.waitForTimeout(1000);
    if (fs.existsSync('/repo/.test-modified')) break;
  }

  // Step 4: Wait up to 15s for HMR to deliver the change
  let hmrWorked = false;
  for (let i = 0; i < 15; i++) {
    await page.waitForTimeout(1000);
    const text = await page.textContent('body');
    if (text.includes('LIVE_EDIT')) {
      console.log('  HMR picked up change after ' + (i+1) + 's');
      hmrWorked = true;
      break;
    }
  }
  if (!hmrWorked) console.log('  HMR did NOT pick up change after 15s');

  // Step 5: Full page reload
  await page.reload({ waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);
  const afterReload = await page.textContent('body');
  const reloadWorked = afterReload.includes('LIVE_EDIT');
  console.log('  After reload has LIVE_EDIT: ' + reloadWorked);

  await browser.close();

  // Verdict
  console.log('');
  if (hmrWorked) {
    console.log('PASS: HMR works for src:-included external files');
    fs.writeFileSync('/repo/.test-result', 'PASS');
    process.exit(0);
  } else if (reloadWorked) {
    console.log('PARTIAL: HMR broken but reload works (file watcher issue)');
    fs.writeFileSync('/repo/.test-result', 'PARTIAL');
    process.exit(1);
  } else {
    console.log('FAIL: Neither HMR nor reload picks up external file changes');
    fs.writeFileSync('/repo/.test-result', 'FAIL');
    process.exit(1);
  }
})();
\"" &
PLAYWRIGHT_PID=$!

# --- Host-side: wait for readiness signal, then modify file ---
for i in $(seq 1 30); do
  if [ -f "$REPRO_DIR/.test-ready" ]; then break; fi
  sleep 1
done

if [ ! -f "$REPRO_DIR/.test-ready" ]; then
  print_error "Playwright did not signal readiness after 30s"
  exit 1
fi

# Modify the source file ON THE HOST (this is the critical part)
sed -i 's/ORIGINAL/LIVE_EDIT/' "$REPRO_DIR/pages/test-content.md"
touch "$REPRO_DIR/.test-modified"
print_info "Source file modified on HOST"

# Wait for Playwright to finish
wait $PLAYWRIGHT_PID
exit_code=$?

echo ""
if [ $exit_code -eq 0 ]; then
  print_success "Test passed"
else
  print_error "Test failed"
  echo ""
  echo "Debug info:"
  echo "  Docker: $(docker --version)"
  echo "  Kernel: $(uname -r)"
  echo "  Filesystem: $(df --output=fstype "$REPRO_DIR" | tail -1)"
  echo "  inotify max_user_watches: $(cat /proc/sys/fs/inotify/max_user_watches)"
fi

exit $exit_code

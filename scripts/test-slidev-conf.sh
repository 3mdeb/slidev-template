#!/bin/bash
# Tests for the .slidev.conf configuration feature.
#
# Covers two levels:
#   * unit        - scripts/env.sh loading rules and precedence
#   * integration - render-slides.sh / ci/gen_slides.sh actually use the values
#                   (Docker, npm, yq and the port probe are stubbed, so this
#                   runs offline in a couple of seconds)
#
# The `broken` mode is the regression proof: each broken env.sh fixture in
# tests/fixtures/broken/ is expected to make specific tests fail. If a broken
# fixture still passes, the corresponding test is not actually testing anything.
#
# Usage:
#   ./scripts/test-slidev-conf.sh              # run the test suite
#   ./scripts/test-slidev-conf.sh broken       # prove all tests detect regressions
#   ./scripts/test-slidev-conf.sh broken NAME  # prove one fixture is detected
#   ./scripts/test-slidev-conf.sh all          # suite + regression proof

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"
FIXTURE_DIR="$TEMPLATE_DIR/tests/fixtures/broken"

# env.sh under test; overridden by broken mode
ENV_SH="${ENV_SH:-$SCRIPT_DIR/env.sh}"

DEFAULT_COPYRIGHT="3mdeb Sp. z o.o. Licensed under the CC BY-SA 4.0"
DEFAULT_TITLE="3mdeb Presentation"

PASSED=0
FAILED=0
FAILED_TESTS=()
ONLY_TEST="${ONLY_TEST:-}"

# Nothing inherited from the caller may leak into a test case, otherwise
# "environment wins over config" would pass for the wrong reason.
CLEAN_ENV=(
  -u COPYRIGHT
  -u SLIDES_TITLE
  -u SLIDEV_PORT
  -u SLIDEV_NODE_MAX_OLD_SPACE
  -u SLIDEV_CONF
  -u PLAYWRIGHT_IMAGE
)

print_error()   { echo -e "\033[31mERROR: $1\033[0m"; }
print_info()    { echo -e "\033[34m$1\033[0m"; }
print_success() { echo -e "\033[32m$1\033[0m"; }
print_warning() { echo -e "\033[33m$1\033[0m"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [test|broken [FIXTURE]|all]

Commands:
  test           Run the .slidev.conf test suite (default)
  broken         Prove every broken env.sh fixture is detected
  broken NAME    Prove one fixture is detected
  all            Run the suite, then the regression proof

Broken fixtures:
  no-conf              .slidev.conf never read
  no-precedence        .slidev.conf clobbers environment variables
  no-slidev-conf-var   SLIDEV_CONF path override ignored
  set-e-abort          sourcing env.sh returns non-zero under 'set -e'

Environment:
  ENV_SH     Path to the env.sh under test (default: scripts/env.sh)
  ONLY_TEST  Substring filter, run only matching test names
EOF
  exit 0
}

# --- assertions -------------------------------------------------------------

check() {
  local name="$1" expected="$2" actual="$3"

  if [ -n "$ONLY_TEST" ] && [[ "$name" != *"$ONLY_TEST"* ]]; then
    return 0
  fi

  if [ "$expected" = "$actual" ]; then
    PASSED=$((PASSED + 1))
    print_success "✓ $name"
  else
    FAILED=$((FAILED + 1))
    FAILED_TESTS+=("$name")
    print_error "✗ $name"
    echo "    expected: [$expected]"
    echo "    actual:   [$actual]"
  fi
}

check_contains() {
  local name="$1" needle="$2" haystack="$3"

  if [ -n "$ONLY_TEST" ] && [[ "$name" != *"$ONLY_TEST"* ]]; then
    return 0
  fi

  if [[ "$haystack" == *"$needle"* ]]; then
    PASSED=$((PASSED + 1))
    print_success "✓ $name"
  else
    FAILED=$((FAILED + 1))
    FAILED_TESTS+=("$name")
    print_error "✗ $name"
    echo "    expected to contain: [$needle]"
    echo "    actual:              [$haystack]"
  fi
}

# --- helpers ----------------------------------------------------------------

# Run a snippet in a clean bash with env.sh sourced from a scratch directory.
# $1 = .slidev.conf contents ("" for no config file)
# $2 = snippet evaluated after sourcing env.sh
# remaining args = VAR=VALUE pairs exported before sourcing
# Extra shell options come from SHELL_OPTS.
run_env() {
  local conf_body="$1" snippet="$2"; shift 2
  local dir
  dir="$(mktemp -d)"

  if [ -n "$conf_body" ]; then
    printf '%s\n' "$conf_body" > "$dir/.slidev.conf"
  fi

  ( cd "$dir" && env "${CLEAN_ENV[@]}" \
      ENV_SH="$ENV_SH" SNIPPET="$snippet" SHELL_OPTS="${SHELL_OPTS:-}" \
      "$@" \
      bash -c 'if [ -n "$SHELL_OPTS" ]; then set "$SHELL_OPTS"; fi
               source "$ENV_SH"
               eval "$SNIPPET"' )
  local rc=$?

  rm -rf "$dir"
  return $rc
}

# Build a throwaway presentation repo laid out the way the scripts expect:
#   <repo>/slides-template.md, <repo>/slidev-template/{scripts,vite.config.ts,...}
# Echoes the repo path.
make_presentation_repo() {
  local repo
  repo="$(mktemp -d)"

  mkdir -p "$repo/slidev-template/scripts/ci" "$repo/stubs" "$repo/capture"
  cp "$TEMPLATE_DIR/slides-template.md" "$repo/"
  cp "$TEMPLATE_DIR/vite.config.ts" "$repo/slidev-template/"
  cp "$TEMPLATE_DIR/docker-compose.yml" "$repo/slidev-template/"
  cp "$SCRIPT_DIR/render-slides.sh" "$repo/slidev-template/scripts/"
  cp "$SCRIPT_DIR/ci/gen_slides.sh" "$repo/slidev-template/scripts/ci/"
  cp "$ENV_SH" "$repo/slidev-template/scripts/env.sh"
  chmod +x "$repo/slidev-template/scripts/render-slides.sh" \
           "$repo/slidev-template/scripts/ci/gen_slides.sh"

  printf '# Slide\n\nbody\n' > "$repo/test-slides.md"

  # docker stub: logs its arguments and snapshots the generated slides.md
  # before the caller deletes it.
  cat > "$repo/stubs/docker" <<'STUB'
#!/bin/bash
echo "$@" >> "$CAPTURE_DIR/docker-args.log"
if [ "$1" = "run" ] && [ -f slidev-template/slides.md ]; then
  cp slidev-template/slides.md "$CAPTURE_DIR/slides.md"
fi
exit 0
STUB

  # npm / python3 (port probe) / yq stubs
  cat > "$repo/stubs/npm" <<'STUB'
#!/bin/bash
exit 0
STUB
  cat > "$repo/stubs/python3" <<'STUB'
#!/bin/bash
cat > /dev/null
exit 0
STUB
  cat > "$repo/stubs/yq" <<'STUB'
#!/bin/bash
echo "test-slides.md|1|out.pdf"
STUB
  chmod +x "$repo"/stubs/*

  echo "$repo"
}

# --- unit tests: env.sh -----------------------------------------------------

test_env_sh() {
  print_info "== unit: scripts/env.sh =="

  check "no config file leaves COPYRIGHT unset" \
    "unset" \
    "$(run_env "" 'echo "${COPYRIGHT-unset}"')"

  check "config file sets COPYRIGHT" \
    "From conf" \
    "$(run_env 'COPYRIGHT="From conf"' 'echo "$COPYRIGHT"')"

  check "config file sets SLIDES_TITLE" \
    "Conf Title" \
    "$(run_env 'SLIDES_TITLE="Conf Title"' 'echo "$SLIDES_TITLE"')"

  check "config file sets SLIDEV_PORT" \
    "8123" \
    "$(run_env 'SLIDEV_PORT=8123' 'echo "$SLIDEV_PORT"')"

  check "config file sets SLIDEV_NODE_MAX_OLD_SPACE" \
    "8192" \
    "$(run_env 'SLIDEV_NODE_MAX_OLD_SPACE=8192' 'echo "$SLIDEV_NODE_MAX_OLD_SPACE"')"

  check "config file sets several variables at once" \
    "Conf Title|From conf|8123" \
    "$(run_env 'SLIDES_TITLE="Conf Title"
COPYRIGHT="From conf"
SLIDEV_PORT=8123' 'echo "$SLIDES_TITLE|$COPYRIGHT|$SLIDEV_PORT"')"

  print_info "== unit: environment wins over config =="

  check "env COPYRIGHT overrides config" \
    "From env" \
    "$(run_env 'COPYRIGHT="From conf"' 'echo "$COPYRIGHT"' COPYRIGHT="From env")"

  check "env SLIDES_TITLE overrides config" \
    "From env" \
    "$(run_env 'SLIDES_TITLE="From conf"' 'echo "$SLIDES_TITLE"' SLIDES_TITLE="From env")"

  check "env SLIDEV_PORT overrides config" \
    "9999" \
    "$(run_env 'SLIDEV_PORT=8123' 'echo "$SLIDEV_PORT"' SLIDEV_PORT=9999)"

  check "env SLIDEV_NODE_MAX_OLD_SPACE overrides config" \
    "2048" \
    "$(run_env 'SLIDEV_NODE_MAX_OLD_SPACE=8192' 'echo "$SLIDEV_NODE_MAX_OLD_SPACE"' SLIDEV_NODE_MAX_OLD_SPACE=2048)"

  check "env PLAYWRIGHT_IMAGE overrides config" \
    "env/image:1" \
    "$(run_env 'PLAYWRIGHT_IMAGE="conf/image:1"' 'echo "$PLAYWRIGHT_IMAGE"' PLAYWRIGHT_IMAGE="env/image:1")"

  check "config PLAYWRIGHT_IMAGE overrides the built-in default" \
    "conf/image:1" \
    "$(run_env 'PLAYWRIGHT_IMAGE="conf/image:1"' 'echo "$PLAYWRIGHT_IMAGE"')"

  # An explicitly empty env var is still an explicit choice, not "unset".
  check "empty env COPYRIGHT still overrides config" \
    "[]" \
    "$(run_env 'COPYRIGHT="From conf"' 'echo "[$COPYRIGHT]"' COPYRIGHT=)"

  check "config value only applies to variables it sets" \
    "From conf|unset" \
    "$(run_env 'COPYRIGHT="From conf"' 'echo "$COPYRIGHT|${SLIDES_TITLE-unset}"')"

  print_info "== unit: SLIDEV_CONF path override =="

  local alt_dir alt_out
  alt_dir="$(mktemp -d)"
  printf 'COPYRIGHT="From alt conf"\n' > "$alt_dir/custom.conf"
  alt_out="$(run_env 'COPYRIGHT="From default conf"' 'echo "$COPYRIGHT"' SLIDEV_CONF="$alt_dir/custom.conf")"
  check "SLIDEV_CONF selects a different config file" "From alt conf" "$alt_out"

  alt_out="$(run_env "" 'echo "${COPYRIGHT-unset}"' SLIDEV_CONF="$alt_dir/does-not-exist.conf")"
  check "missing SLIDEV_CONF file is not an error" "unset" "$alt_out"

  alt_out="$(SHELL_OPTS="-e" run_env "" 'echo ok' SLIDEV_CONF="$alt_dir/does-not-exist.conf")"
  check "missing SLIDEV_CONF file does not abort under 'set -e'" "ok" "$alt_out"
  rm -rf "$alt_dir"

  print_info "== unit: shell safety (regression: PR #24 review) =="

  # scripts/ci/gen_slides.sh runs under `set -e`; a loader returning non-zero
  # killed it the moment a .slidev.conf existed.
  check "sourcing env.sh with a config file does not abort under 'set -e'" \
    "reached" \
    "$(SHELL_OPTS="-e" run_env 'COPYRIGHT="From conf"' 'echo reached')"

  check "sourcing env.sh with a config file returns 0 under 'set -e'" \
    "0" \
    "$(SHELL_OPTS="-e" run_env 'COPYRIGHT="From conf"' 'true'; echo $?)"

  check "sourcing env.sh without a config file returns 0 under 'set -e'" \
    "0" \
    "$(SHELL_OPTS="-e" run_env "" 'true'; echo $?)"

  check "config file is loaded under 'set -u'" \
    "From conf" \
    "$(SHELL_OPTS="-u" run_env 'COPYRIGHT="From conf"' 'echo "$COPYRIGHT"')"

  check "values with spaces and punctuation survive" \
    "ACME & Co. (2026) — all rights reserved" \
    "$(run_env 'COPYRIGHT="ACME & Co. (2026) — all rights reserved"' 'echo "$COPYRIGHT"')"

  check "PLAYWRIGHT_IMAGE default still applies with a config file present" \
    "mcr.microsoft.com/playwright:v1.57.0-noble" \
    "$(run_env 'COPYRIGHT="From conf"' 'echo "$PLAYWRIGHT_IMAGE"')"

  check "PLAYWRIGHT_IMAGE is exported" \
    "mcr.microsoft.com/playwright:v1.57.0-noble" \
    "$(run_env 'COPYRIGHT="From conf"' 'bash -c "echo \$PLAYWRIGHT_IMAGE"')"
}

# --- integration tests: render-slides.sh ------------------------------------

test_render_slides() {
  print_info "== integration: render-slides.sh =="

  local repo slides args

  # 1. config file drives the rendered slides.md
  repo="$(make_presentation_repo)"
  cat > "$repo/.slidev.conf" <<'CONF'
COPYRIGHT="Conf Copyright 2026"
SLIDES_TITLE="Conf Title"
SLIDEV_PORT=8123
SLIDEV_NODE_MAX_OLD_SPACE=8192
CONF
  ( cd "$repo" && PATH="$repo/stubs:$PATH" CAPTURE_DIR="$repo/capture" \
      ./slidev-template/scripts/render-slides.sh test-slides.md ) >/dev/null 2>&1
  slides="$(cat "$repo/capture/slides.md" 2>/dev/null || echo MISSING)"
  args="$(cat "$repo/capture/docker-args.log" 2>/dev/null || echo MISSING)"

  check_contains "render-slides.sh: COPYRIGHT from config reaches slides.md" \
    "Conf Copyright 2026" "$slides"
  check_contains "render-slides.sh: SLIDES_TITLE from config reaches slides.md" \
    "Conf Title" "$slides"
  check_contains "render-slides.sh: SLIDEV_PORT from config is published" \
    "-p 8123:8000" "$args"
  check_contains "render-slides.sh: SLIDEV_NODE_MAX_OLD_SPACE from config is used" \
    "--max-old-space-size=8192" "$args"
  rm -rf "$repo"

  # 2. environment still wins over the config file
  repo="$(make_presentation_repo)"
  cat > "$repo/.slidev.conf" <<'CONF'
COPYRIGHT="Conf Copyright"
SLIDES_TITLE="Conf Title"
SLIDEV_PORT=8123
CONF
  ( cd "$repo" && PATH="$repo/stubs:$PATH" CAPTURE_DIR="$repo/capture" \
      COPYRIGHT="Env Copyright" SLIDES_TITLE="Env Title" SLIDEV_PORT=9123 \
      ./slidev-template/scripts/render-slides.sh test-slides.md ) >/dev/null 2>&1
  slides="$(cat "$repo/capture/slides.md" 2>/dev/null || echo MISSING)"
  args="$(cat "$repo/capture/docker-args.log" 2>/dev/null || echo MISSING)"

  check_contains "render-slides.sh: env COPYRIGHT beats config" "Env Copyright" "$slides"
  check_contains "render-slides.sh: env SLIDES_TITLE beats config" "Env Title" "$slides"
  check_contains "render-slides.sh: env SLIDEV_PORT beats config" "-p 9123:8000" "$args"
  check "render-slides.sh: config COPYRIGHT is not also emitted" \
    "0" "$(grep -c 'Conf Copyright' <<<"$slides")"
  rm -rf "$repo"

  # 3. no config file -> documented defaults
  repo="$(make_presentation_repo)"
  ( cd "$repo" && PATH="$repo/stubs:$PATH" CAPTURE_DIR="$repo/capture" \
      ./slidev-template/scripts/render-slides.sh test-slides.md ) >/dev/null 2>&1
  slides="$(cat "$repo/capture/slides.md" 2>/dev/null || echo MISSING)"
  args="$(cat "$repo/capture/docker-args.log" 2>/dev/null || echo MISSING)"

  check_contains "render-slides.sh: default COPYRIGHT without a config file" \
    "$DEFAULT_COPYRIGHT" "$slides"
  check_contains "render-slides.sh: default title without a config file" \
    "$DEFAULT_TITLE" "$slides"
  check_contains "render-slides.sh: default port without a config file" \
    "-p 8000:8000" "$args"
  check_contains "render-slides.sh: default node heap without a config file" \
    "--max-old-space-size=4096" "$args"
  rm -rf "$repo"

  # 4. SLIDEV_CONF selects an out-of-tree config file
  repo="$(make_presentation_repo)"
  printf 'COPYRIGHT="Alternate Conf"\n' > "$repo/other.conf"
  ( cd "$repo" && PATH="$repo/stubs:$PATH" CAPTURE_DIR="$repo/capture" \
      SLIDEV_CONF="$repo/other.conf" \
      ./slidev-template/scripts/render-slides.sh test-slides.md ) >/dev/null 2>&1
  slides="$(cat "$repo/capture/slides.md" 2>/dev/null || echo MISSING)"
  check_contains "render-slides.sh: SLIDEV_CONF path is honoured" "Alternate Conf" "$slides"
  rm -rf "$repo"

  # 5. help text documents the feature
  repo="$(make_presentation_repo)"
  local help
  help="$( cd "$repo" && PATH="$repo/stubs:$PATH" CAPTURE_DIR="$repo/capture" \
      ./slidev-template/scripts/render-slides.sh --help 2>&1 )"
  check_contains "render-slides.sh: --help documents .slidev.conf" ".slidev.conf" "$help"
  check_contains "render-slides.sh: --help documents SLIDEV_CONF" "SLIDEV_CONF" "$help"
  rm -rf "$repo"
}

# --- integration tests: ci/gen_slides.sh ------------------------------------

test_gen_slides() {
  print_info "== integration: ci/gen_slides.sh =="

  local repo out args

  # gen_slides.sh runs under `set -e` and cats the generated slides.md.
  repo="$(make_presentation_repo)"
  printf 'slides: []\n' > "$repo/slides.metadata"
  cat > "$repo/.slidev.conf" <<'CONF'
COPYRIGHT="CI Conf Copyright"
SLIDES_TITLE="CI Conf Title"
SLIDEV_NODE_MAX_OLD_SPACE=6144
CONF
  out="$( cd "$repo" && PATH="$repo/stubs:$PATH" CAPTURE_DIR="$repo/capture" \
      ./slidev-template/scripts/ci/gen_slides.sh slides.metadata 2>&1 )"
  args="$(cat "$repo/capture/docker-args.log" 2>/dev/null || echo MISSING)"

  # Regression guard: with the original loader this produced no output at all,
  # because sourcing env.sh returned non-zero and `set -e` killed the script.
  check_contains "gen_slides.sh: survives a .slidev.conf under 'set -e'" \
    "CI Conf Copyright" "$out"
  check_contains "gen_slides.sh: SLIDES_TITLE from config reaches slides.md" \
    "CI Conf Title" "$out"
  check_contains "gen_slides.sh: SLIDEV_NODE_MAX_OLD_SPACE from config is used" \
    "--max-old-space-size=6144" "$args"
  rm -rf "$repo"

  # env still wins
  repo="$(make_presentation_repo)"
  printf 'slides: []\n' > "$repo/slides.metadata"
  printf 'COPYRIGHT="CI Conf Copyright"\n' > "$repo/.slidev.conf"
  out="$( cd "$repo" && PATH="$repo/stubs:$PATH" CAPTURE_DIR="$repo/capture" \
      COPYRIGHT="CI Env Copyright" \
      ./slidev-template/scripts/ci/gen_slides.sh slides.metadata 2>&1 )"
  check_contains "gen_slides.sh: env COPYRIGHT beats config" "CI Env Copyright" "$out"
  check "gen_slides.sh: config COPYRIGHT is not also emitted" \
    "0" "$(grep -c 'CI Conf Copyright' <<<"$out")"
  rm -rf "$repo"

  # defaults without a config file
  repo="$(make_presentation_repo)"
  printf 'slides: []\n' > "$repo/slides.metadata"
  out="$( cd "$repo" && PATH="$repo/stubs:$PATH" CAPTURE_DIR="$repo/capture" \
      ./slidev-template/scripts/ci/gen_slides.sh slides.metadata 2>&1 )"
  check_contains "gen_slides.sh: default COPYRIGHT without a config file" \
    "$DEFAULT_COPYRIGHT" "$out"
  rm -rf "$repo"

  repo="$(make_presentation_repo)"
  local help
  help="$( cd "$repo" && PATH="$repo/stubs:$PATH" \
      ./slidev-template/scripts/ci/gen_slides.sh --help 2>&1 )"
  check_contains "gen_slides.sh: --help documents .slidev.conf" ".slidev.conf" "$help"
  rm -rf "$repo"
}

run_suite() {
  PASSED=0
  FAILED=0
  FAILED_TESTS=()

  test_env_sh
  test_render_slides
  test_gen_slides

  echo ""
  if [ "$FAILED" -gt 0 ]; then
    print_error "$PASSED passed, $FAILED failed:"
    printf '    - %s\n' "${FAILED_TESTS[@]}"
    return 1
  fi
  print_success "All $PASSED tests passed ✓"
  return 0
}

# --- regression proof -------------------------------------------------------
#
# Each broken env.sh fixture must make the listed tests fail. Format:
#   fixture:ONLY_TEST filter that must fail
BROKEN_FIXTURES=(
  "no-conf:config file sets COPYRIGHT"
  "no-conf:COPYRIGHT from config reaches slides.md"
  "no-precedence:env COPYRIGHT overrides config"
  "no-precedence:env COPYRIGHT beats config"
  "no-slidev-conf-var:SLIDEV_CONF selects a different config file"
  "no-slidev-conf-var:SLIDEV_CONF path is honoured"
  "set-e-abort:does not abort under 'set -e'"
  "set-e-abort:survives a .slidev.conf under 'set -e'"
)

run_single_broken_test() {
  local fixture="$1" filter="$2"
  local fixture_file="$FIXTURE_DIR/env-${fixture}.sh"

  if [ ! -f "$fixture_file" ]; then
    print_error "Unknown broken fixture: $fixture ($fixture_file missing)"
    return 1
  fi

  local output
  output="$(ENV_SH="$fixture_file" ONLY_TEST="$filter" run_suite 2>&1)"
  if [ $? -eq 0 ]; then
    print_error "✗ $fixture / '$filter' — tests PASSED but should have FAILED"
    echo "$output" | sed 's/^/    /'
    return 1
  fi

  # Guard against the filter matching nothing: a run with zero assertions
  # would "fail" for the wrong reason.
  if ! grep -q '✗' <<<"$output"; then
    print_error "✗ $fixture / '$filter' — no test matched the filter"
    echo "$output" | sed 's/^/    /'
    return 1
  fi

  print_success "✓ $fixture detected by '$filter'"
  return 0
}

run_broken_tests() {
  local only="${1:-}"
  local passed=0 failed=0
  local -a failures=()
  local entry fixture filter

  print_info "Proving broken env.sh fixtures are detected..."
  echo ""

  for entry in "${BROKEN_FIXTURES[@]}"; do
    fixture="${entry%%:*}"
    filter="${entry#*:}"
    [ -n "$only" ] && [ "$only" != "$fixture" ] && continue

    if run_single_broken_test "$fixture" "$filter"; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
      failures+=("$fixture / $filter")
    fi
  done

  echo ""
  if [ "$passed" -eq 0 ] && [ "$failed" -eq 0 ]; then
    print_error "No broken fixture matched '$only'"
    return 1
  fi
  if [ "$failed" -gt 0 ]; then
    print_error "$passed passed, $failed failed:"
    printf '    - %s\n' "${failures[@]}"
    return 1
  fi
  print_success "All $passed regression proofs passed ✓"
  return 0
}

case "${1:-test}" in
  test)
    run_suite
    ;;
  broken)
    run_broken_tests "${2:-}"
    ;;
  all)
    run_suite && { echo ""; run_broken_tests; }
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    print_error "Unknown command: $1"
    usage
    ;;
esac

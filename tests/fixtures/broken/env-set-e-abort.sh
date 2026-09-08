#!/bin/false
# BROKEN FIXTURE: the loader ends with a failing test, so sourcing it returns
# non-zero. Any caller running under `set -e` (scripts/ci/gen_slides.sh) dies
# silently the moment a .slidev.conf exists.
# Proves the "safe under set -e" test actually detects a regression.

_slidev_load_conf() {
    local conf="${SLIDEV_CONF:-.slidev.conf}"
    [ -f "$conf" ] || return 0

    local _had_copyright="" _had_nodemem=""
    local _val_copyright="" _val_nodemem=""
    [ -n "${COPYRIGHT+set}" ]                 && _had_copyright=1 _val_copyright="$COPYRIGHT"
    [ -n "${SLIDEV_NODE_MAX_OLD_SPACE+set}" ] && _had_nodemem=1   _val_nodemem="$SLIDEV_NODE_MAX_OLD_SPACE"

    # shellcheck source=/dev/null
    source "$conf"

    [ -n "$_had_copyright" ] && COPYRIGHT="$_val_copyright"
    [ -n "$_had_nodemem" ]   && SLIDEV_NODE_MAX_OLD_SPACE="$_val_nodemem"
}
_slidev_load_conf

export PLAYWRIGHT_IMAGE="${PLAYWRIGHT_IMAGE:-mcr.microsoft.com/playwright:v1.57.0-noble}"

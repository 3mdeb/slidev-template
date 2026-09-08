#!/bin/false
# BROKEN FIXTURE: .slidev.conf clobbers environment variables.
# Proves the precedence tests actually detect a regression.

SLIDEV_CONF_VARS="COPYRIGHT SLIDES_TITLE SLIDEV_PORT SLIDEV_NODE_MAX_OLD_SPACE PLAYWRIGHT_IMAGE"

_slidev_load_conf() {
    local conf="${SLIDEV_CONF:-.slidev.conf}"
    [ -f "$conf" ] || return 0

    # shellcheck source=/dev/null
    source "$conf"

    return 0
}
_slidev_load_conf

export PLAYWRIGHT_IMAGE="${PLAYWRIGHT_IMAGE:-mcr.microsoft.com/playwright:v1.57.0-noble}"

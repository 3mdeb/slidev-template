#!/bin/false
# BROKEN FIXTURE: config path is hardcoded, SLIDEV_CONF is ignored.
# Proves the SLIDEV_CONF override test actually detects a regression.

SLIDEV_CONF_VARS="COPYRIGHT SLIDES_TITLE SLIDEV_PORT SLIDEV_NODE_MAX_OLD_SPACE PLAYWRIGHT_IMAGE"

_slidev_load_conf() {
    local conf=".slidev.conf"
    [ -f "$conf" ] || return 0

    local var
    local -a saved=()
    for var in $SLIDEV_CONF_VARS; do
        if [ -n "${!var+set}" ]; then
            saved+=( "$var=${!var}" )
        fi
    done

    # shellcheck source=/dev/null
    source "$conf"

    local entry
    for entry in "${saved[@]}"; do
        printf -v "${entry%%=*}" '%s' "${entry#*=}"
    done

    return 0
}
_slidev_load_conf

export PLAYWRIGHT_IMAGE="${PLAYWRIGHT_IMAGE:-mcr.microsoft.com/playwright:v1.57.0-noble}"

#!/bin/false
# Shared environment for slidev-template scripts.
#
# Configuration precedence (highest first):
#   1. environment variables
#   2. .slidev.conf in the current directory (override path with SLIDEV_CONF)
#   3. defaults below
#
# NOTE: this file is sourced by scripts running under `set -e`, so every code
# path must end with a zero exit status.

# Variables .slidev.conf may set, and that the environment may override.
SLIDEV_CONF_VARS="COPYRIGHT SLIDES_TITLE SLIDEV_PORT SLIDEV_NODE_MAX_OLD_SPACE PLAYWRIGHT_IMAGE"

# Source local project config if available (env vars take precedence)
_slidev_load_conf() {
    local conf="${SLIDEV_CONF:-.slidev.conf}"
    [ -f "$conf" ] || return 0

    # Remember which variables came from the environment, so that sourcing the
    # config file cannot clobber them.
    local var
    local -a saved=()
    for var in $SLIDEV_CONF_VARS; do
        if [ -n "${!var+set}" ]; then
            saved+=( "$var=${!var}" )
        fi
    done

    # shellcheck source=/dev/null
    source "$conf"

    # Restore the environment-provided values. Plain assignment keeps the
    # export attribute the variable already had.
    local entry
    for entry in "${saved[@]}"; do
        printf -v "${entry%%=*}" '%s' "${entry#*=}"
    done

    return 0
}
_slidev_load_conf

export PLAYWRIGHT_IMAGE="${PLAYWRIGHT_IMAGE:-mcr.microsoft.com/playwright:v1.57.0-noble}"

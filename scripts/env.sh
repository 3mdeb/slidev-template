#!/bin/false

export PLAYWRIGHT_IMAGE="${PLAYWRIGHT_IMAGE:-mcr.microsoft.com/playwright:v1.57.0-noble}"

# Source local project config if available (env vars take precedence)
_slidev_load_conf() {
    local conf="${SLIDEV_CONF:-.slidev.conf}"
    [ -f "$conf" ] || return 0

    # Save pre-existing env vars so they take precedence over config
    local _had_copyright="" _had_title="" _had_port="" _had_nodemem=""
    local _val_copyright="" _val_title="" _val_port="" _val_nodemem=""
    [ -n "${COPYRIGHT+set}" ]                 && _had_copyright=1 _val_copyright="$COPYRIGHT"
    [ -n "${SLIDES_TITLE+set}" ]              && _had_title=1     _val_title="$SLIDES_TITLE"
    [ -n "${SLIDEV_PORT+set}" ]               && _had_port=1      _val_port="$SLIDEV_PORT"
    [ -n "${SLIDEV_NODE_MAX_OLD_SPACE+set}" ] && _had_nodemem=1   _val_nodemem="$SLIDEV_NODE_MAX_OLD_SPACE"

    # shellcheck source=/dev/null
    source "$conf"

    # Restore env vars that were set before sourcing
    [ -n "$_had_copyright" ] && COPYRIGHT="$_val_copyright"
    [ -n "$_had_title" ]     && SLIDES_TITLE="$_val_title"
    [ -n "$_had_port" ]      && SLIDEV_PORT="$_val_port"
    [ -n "$_had_nodemem" ]   && SLIDEV_NODE_MAX_OLD_SPACE="$_val_nodemem"
}
_slidev_load_conf

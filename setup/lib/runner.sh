#!/usr/bin/env bash
set -euo pipefail

function setup_should_run_local_packages() {
    [[ "${SETUP_PROFILE:-full}" = "full" ]]
}

function setup_print_dry_run_plan() {
    local os="$1"

    log_info "Dry-run mode enabled"
    log_info "Profile: ${SETUP_PROFILE:-full}"
    log_info "Detected OS: ${os}"
    log_info "Would run: common setup"
    log_info "Would run: platform setup"
    if setup_should_run_local_packages; then
        log_info "Would run: local package setup"
    fi
}

function setup_execute_plan() {
    local os="$1"

    if [[ "${SETUP_DRY_RUN:-0}" = "1" ]]; then
        setup_print_dry_run_plan "$os"
        return 0
    fi

    case "$os" in
        Darwin)
            log_action "SETUP for Mac"
            common
            for_mac
            if setup_should_run_local_packages; then
                for_local
            fi
            ;;
        Linux)
            log_action "SETUP for Linux"
            common
            for_linux
            if setup_should_run_local_packages; then
                for_local
            fi
            ;;
        *)
            handle_error "$os is unsupported" 1
            ;;
    esac
}

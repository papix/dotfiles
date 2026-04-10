#!/usr/bin/env bash
set -euo pipefail

function setup_init_defaults() {
    ALLOW_HOMEBREW_INSTALL="${ALLOW_HOMEBREW_INSTALL:-0}"
    WITH_HACKGEN="${WITH_HACKGEN:-0}"
    SETUP_DRY_RUN="${SETUP_DRY_RUN:-0}"
    SETUP_PROFILE="${SETUP_PROFILE:-full}"
    SETUP_DOCTOR="${SETUP_DOCTOR:-0}"
    SETUP_JSON="${SETUP_JSON:-0}"
}

function setup_print_help() {
    local script_name="$1"

    echo "Usage: ${script_name} [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --allow-homebrew-install  Allow automatic Homebrew installation"
    echo "  --with-hackgen            Install HackGen Nerd Font"
    echo "  --dry-run                 Show planned actions without applying changes"
    echo "  --profile <name>          Setup profile (minimal|full)"
    echo "  --profile=<name>          Setup profile (minimal|full)"
    echo "  --doctor                  Run diagnostics and exit"
    echo "  --json                    Output as JSON (available with --doctor)"
    echo "  --help, -h                Show this help message"
    echo ""
}

function setup_validate_profile() {
    local profile="$1"
    case "$profile" in
        minimal|full)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function setup_parse_options() {
    local script_name="$1"
    shift

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --allow-homebrew-install)
                ALLOW_HOMEBREW_INSTALL=1
                shift
                ;;
            --with-hackgen)
                WITH_HACKGEN=1
                shift
                ;;
            --dry-run)
                SETUP_DRY_RUN=1
                shift
                ;;
            --doctor)
                SETUP_DOCTOR=1
                shift
                ;;
            --json)
                SETUP_JSON=1
                shift
                ;;
            --profile)
                if [[ $# -lt 2 ]]; then
                    echo "[ERROR] Missing value for --profile. Use minimal or full." >&2
                    return 1
                fi
                SETUP_PROFILE="$2"
                shift 2
                ;;
            --profile=*)
                SETUP_PROFILE="${1#*=}"
                shift
                ;;
            --help|-h)
                setup_print_help "$script_name"
                return 2
                ;;
            *)
                echo "[ERROR] Unknown option: $1" >&2
                echo "[INFO] Use --help for usage information" >&2
                return 1
                ;;
        esac
    done

    if ! setup_validate_profile "$SETUP_PROFILE"; then
        echo "[ERROR] Invalid profile: $SETUP_PROFILE (expected: minimal or full)" >&2
        return 1
    fi

    if [[ "${SETUP_JSON:-0}" = "1" && "${SETUP_DOCTOR:-0}" != "1" ]]; then
        echo "[ERROR] --json can only be used with --doctor" >&2
        return 1
    fi

    return 0
}

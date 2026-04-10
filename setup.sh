#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_LIB_DIR="$SCRIPT_DIR/setup/lib"
# shellcheck disable=SC1091
source "$SETUP_LIB_DIR/options.sh"
# shellcheck disable=SC1091
source "$SETUP_LIB_DIR/runner.sh"
# shellcheck disable=SC1091
source "$SETUP_LIB_DIR/packages.sh"
# shellcheck disable=SC1091
source "$SETUP_LIB_DIR/doctor.sh"
# shellcheck disable=SC1091
source "$SETUP_LIB_DIR/common.sh"
# shellcheck disable=SC1091
source "$SETUP_LIB_DIR/platform.sh"
# shellcheck disable=SC1091
source "$SETUP_LIB_DIR/local.sh"

# ログ色設定（TTYのみ/NO_COLORで無効化）
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    COLOR_RESET=$'\033[0m'
    COLOR_RED=$'\033[0;31m'
    COLOR_YELLOW=$'\033[0;33m'
    COLOR_BLUE=$'\033[0;34m'
    COLOR_GREEN=$'\033[0;32m'
    COLOR_MAGENTA=$'\033[0;35m'
else
    COLOR_RESET=""
    COLOR_RED=""
    COLOR_YELLOW=""
    COLOR_BLUE=""
    COLOR_GREEN=""
    COLOR_MAGENTA=""
fi

function log_info() {
    printf "%b\n" "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

function log_action() {
    printf "%b\n" "${COLOR_GREEN}[ACTION]${COLOR_RESET} $*"
}

function log_warn() {
    printf "%b\n" "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $*" >&2
}

function log_error() {
    printf "%b\n" "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

function log_skip() {
    printf "%b\n" "${COLOR_MAGENTA}[SKIP]${COLOR_RESET} $*"
}

# エラーハンドリング関数
function handle_error() {
    local message="$1"
    local exit_code="${2:-1}"
    log_error "$message"
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        # スクリプトが直接実行された場合
        exit "$exit_code"
    else
        # ソースされた場合（関数内）
        return "$exit_code"
    fi
}

function verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual=""

    if command -v shasum >/dev/null 2>&1; then
        actual=$(shasum -a 256 "$file" | awk '{print $1}')
    elif command -v sha256sum >/dev/null 2>&1; then
        actual=$(sha256sum "$file" | awk '{print $1}')
    else
        log_warn "sha256 utility not found. Unable to verify: $file"
        return 2
    fi

    if [ "$actual" != "$expected" ]; then
        log_error "SHA256 mismatch for $file"
        return 1
    fi

    return 0
}

# sudo が使えない場合は失敗として扱う
function run_with_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
        return $?
    fi

    if command -v sudo >/dev/null 2>&1; then
        if sudo -n true >/dev/null 2>&1; then
            sudo "$@"
            return $?
        fi
        if [ -t 0 ]; then
            log_info "sudo password is required. Please enter your password."
            sudo "$@"
            return $?
        fi
        log_error "sudo is required but not available without a password: $*"
        return 1
    fi

    log_error "sudo not found: $*"
    return 1
}

function main() {
    setup_init_defaults
    local parse_exit_code=0
    setup_parse_options "$0" "$@" || parse_exit_code=$?
    if [[ "$parse_exit_code" -eq 2 ]]; then
        return 0
    elif [[ "$parse_exit_code" -ne 0 ]]; then
        return 1
    fi

    # 廃止フラグの検出と警告
    if [ "${ALLOW_UNVERIFIED_DOWNLOAD:-}" = "1" ]; then
        log_warn "ALLOW_UNVERIFIED_DOWNLOAD is deprecated and ignored."
        log_warn "HackGen now uses a pinned version with an embedded checksum."
        log_warn "Use --with-hackgen to install HackGen font."
    fi

    PWD=$(pwd)
    local os
    os=$(uname)

    if [[ "${SETUP_DOCTOR:-0}" = "1" ]]; then
        setup_run_doctor "$os"
        return 0
    fi

    setup_execute_plan "$os"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

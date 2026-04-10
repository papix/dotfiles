#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
LOCAL_LIB="$ROOT_DIR/setup/lib/local.sh"

assert_text_contains() {
    local needle="$1"
    local text="$2"
    if ! printf '%s\n' "$text" | grep -F -- "$needle" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected output to contain '$needle'" >&2
        echo "actual output: $text" >&2
        exit 1
    fi
}

assert_text_not_contains() {
    local needle="$1"
    local text="$2"
    if printf '%s\n' "$text" | grep -F -- "$needle" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected output not to contain '$needle'" >&2
        echo "actual output: $text" >&2
        exit 1
    fi
}

run_for_local_scenario() {
    local mocked_os_name="$1"
    local mocked_machine_arch="$2"
    local mocked_arm64_capable="$3"
    local mocked_packages="git"

    if [[ "$#" -ge 4 ]]; then
        mocked_packages="$4"
    fi

    MOCKED_OS_NAME="$mocked_os_name" \
        MOCKED_MACHINE_ARCH="$mocked_machine_arch" \
        MOCKED_ARM64_CAPABLE="$mocked_arm64_capable" \
        MOCKED_PACKAGES="$mocked_packages" \
        LOCAL_LIB="$LOCAL_LIB" \
        bash <<'BASH' 2>&1
set -euo pipefail

source "$LOCAL_LIB"

setup_load_packages() {
    if [[ -n "$MOCKED_PACKAGES" ]]; then
        printf '%s\n' "$MOCKED_PACKAGES"
    fi
}

handle_error() {
    echo "ERROR:$*" >&2
    return 1
}

log_action() {
    echo "ACTION:$*"
}

log_warn() {
    echo "WARN:$*" >&2
}

log_info() {
    :
}

setup_mise() {
    :
}

brew() {
    echo "BREW:$*"
}

sysctl() {
    if [[ "${1:-}" = "-in" && "${2:-}" = "hw.optional.arm64" ]]; then
        printf '%s\n' "$MOCKED_ARM64_CAPABLE"
        return 0
    fi

    return 1
}

uname() {
    case "${1:-}" in
    -s)
        printf '%s\n' "$MOCKED_OS_NAME"
        ;;
    -m)
        printf '%s\n' "$MOCKED_MACHINE_ARCH"
        ;;
    *)
        printf '%s\n' "$MOCKED_OS_NAME"
        ;;
    esac
}

for_local
BASH
}

darwin_arm_output="$(run_for_local_scenario Darwin arm64 1)"
assert_text_contains 'BREW:install git' "$darwin_arm_output"
assert_text_contains 'BREW:install --cask altair-graphql-client' "$darwin_arm_output"

darwin_rosetta_output="$(run_for_local_scenario Darwin x86_64 1)"
assert_text_contains 'BREW:install --cask altair-graphql-client' "$darwin_rosetta_output"

darwin_intel_output="$(run_for_local_scenario Darwin x86_64 0)"
assert_text_not_contains 'BREW:install --cask altair-graphql-client' "$darwin_intel_output"

linux_output="$(run_for_local_scenario Linux x86_64 0)"
assert_text_not_contains 'BREW:install --cask altair-graphql-client' "$linux_output"

darwin_arm_empty_packages_output="$(run_for_local_scenario Darwin arm64 1 '')"
assert_text_contains 'WARN:No packages configured for profile full. Skipping brew install.' "$darwin_arm_empty_packages_output"
assert_text_contains 'BREW:install --cask altair-graphql-client' "$darwin_arm_empty_packages_output"
assert_text_not_contains 'BREW:install git' "$darwin_arm_empty_packages_output"

echo "apple_silicon_cask_test: ok"

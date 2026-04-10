#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SETUP_SH="$ROOT_DIR/setup.sh"
SETUP_LIB_DIR="$ROOT_DIR/setup/lib"

assert_file_exists() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "ASSERTION FAILED: expected file $path" >&2
        return 1
    fi
}

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_file_exists "$SETUP_LIB_DIR/options.sh"
assert_file_exists "$SETUP_LIB_DIR/runner.sh"
assert_file_exists "$SETUP_LIB_DIR/common.sh"
assert_file_exists "$SETUP_LIB_DIR/platform.sh"
assert_file_exists "$SETUP_LIB_DIR/local.sh"

# shellcheck disable=SC2016
assert_contains 'source "$SETUP_LIB_DIR/options.sh"' "$SETUP_SH"
# shellcheck disable=SC2016
assert_contains 'source "$SETUP_LIB_DIR/runner.sh"' "$SETUP_SH"
# shellcheck disable=SC2016
assert_contains 'source "$SETUP_LIB_DIR/common.sh"' "$SETUP_SH"
# shellcheck disable=SC2016
assert_contains 'source "$SETUP_LIB_DIR/platform.sh"' "$SETUP_SH"
# shellcheck disable=SC2016
assert_contains 'source "$SETUP_LIB_DIR/local.sh"' "$SETUP_SH"
assert_contains 'main "$@"' "$SETUP_SH"

echo "setup_modularization_test: ok"

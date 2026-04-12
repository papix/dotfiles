#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SETUP_SH="$ROOT_DIR/setup.sh"
PACKAGES_LIB="$ROOT_DIR/setup/lib/packages.sh"
LOCAL_LIB="$ROOT_DIR/setup/lib/local.sh"

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

assert_file_exists "$ROOT_DIR/Brewfile"
assert_file_exists "$ROOT_DIR/Brewfile.darwin"
assert_file_exists "$ROOT_DIR/Brewfile.linux"
assert_file_exists "$ROOT_DIR/Brewfile.minimal"
assert_file_exists "$ROOT_DIR/Brewfile.minimal.darwin"
assert_file_exists "$ROOT_DIR/Brewfile.minimal.linux"
assert_file_exists "$PACKAGES_LIB"
assert_file_exists "$LOCAL_LIB"

# shellcheck disable=SC2016
assert_contains 'source "$SETUP_LIB_DIR/packages.sh"' "$SETUP_SH"
assert_contains 'setup_load_packages' "$PACKAGES_LIB"
assert_contains 'Brewfile' "$PACKAGES_LIB"
assert_contains 'setup_list_package_files' "$PACKAGES_LIB"
assert_contains 'brew bundle --file="$package_file" --no-upgrade' "$LOCAL_LIB"

echo "packages_profile_external_test: ok"

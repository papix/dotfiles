#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SETUP_SH="$ROOT_DIR/setup.sh"
PACKAGES_LIB="$ROOT_DIR/setup/lib/packages.sh"
DARWIN_FULL="$ROOT_DIR/Brewfile"
DARWIN_OS="$ROOT_DIR/Brewfile.darwin"
LINUX_FULL="$ROOT_DIR/Brewfile"
LINUX_OS="$ROOT_DIR/Brewfile.linux"

assert_file_exists() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "ASSERTION FAILED: expected file $path" >&2
        exit 1
    fi
}

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        exit 1
    fi
}

assert_file_exists "$PACKAGES_LIB"
assert_file_exists "$DARWIN_FULL"
assert_file_exists "$DARWIN_OS"
assert_file_exists "$LINUX_FULL"
assert_file_exists "$LINUX_OS"

# shellcheck disable=SC2016
assert_contains 'source "$SETUP_LIB_DIR/packages.sh"' "$SETUP_SH"
assert_contains 'setup_load_packages' "$PACKAGES_LIB"
assert_contains 'brew "jq"' "$DARWIN_FULL"
assert_contains 'brew "shfmt"' "$LINUX_FULL"
assert_contains 'cask "1password-cli"' "$DARWIN_OS"
assert_contains 'cask "1password-cli"' "$LINUX_OS"

echo "prerequisites_packages_test: ok"

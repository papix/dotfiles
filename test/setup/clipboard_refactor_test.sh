#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PLATFORM_LIB="$ROOT_DIR/setup/lib/platform.sh"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_contains 'set -euo pipefail' "$PLATFORM_LIB"
assert_contains 'function install_clipboard_tools_linux() {' "$PLATFORM_LIB"
assert_contains 'install_clipboard_tools_linux' "$PLATFORM_LIB"

echo "clipboard_refactor_test: ok"

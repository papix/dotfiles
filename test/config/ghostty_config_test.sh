#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
GHOSTTY_CONFIG="$ROOT_DIR/config/ghostty/config"
COMMON_LIB="$ROOT_DIR/setup/lib/common.sh"

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

assert_file_exists "$GHOSTTY_CONFIG"
assert_contains 'font-family = "HackGen Console NF"' "$GHOSTTY_CONFIG"
assert_contains 'font-size = 14' "$GHOSTTY_CONFIG"
assert_contains 'theme = "iTerm2 Solarized Dark"' "$GHOSTTY_CONFIG"
assert_contains 'minimum-contrast = 3' "$GHOSTTY_CONFIG"
assert_contains 'term = xterm-256color' "$GHOSTTY_CONFIG"

assert_contains 'set_config_file_target "/config/ghostty/config" "${config_home}/ghostty/config"' "$COMMON_LIB"

echo "ghostty_config_test: ok"

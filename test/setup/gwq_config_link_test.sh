#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
COMMON_LIB="$ROOT_DIR/setup/lib/common.sh"
CONFIG_FILE="$ROOT_DIR/config/gwq/config.toml"

assert_file_missing() {
    local path="$1"
    if [[ -e "$path" ]]; then
        echo "ASSERTION FAILED: expected path to be absent: $path" >&2
        return 1
    fi
}

assert_file_missing "$CONFIG_FILE"
if grep -F -- 'setup_gwq_config' "$COMMON_LIB" >/dev/null 2>&1; then
    echo "ASSERTION FAILED: expected setup_gwq_config to be removed from $COMMON_LIB" >&2
    exit 1
fi
if grep -F -- '/config/gwq/config.toml' "$COMMON_LIB" >/dev/null 2>&1; then
    echo "ASSERTION FAILED: expected gwq config link setup to be removed from $COMMON_LIB" >&2
    exit 1
fi

echo "gwq_config_link_test: ok"

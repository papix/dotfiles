#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
COMMON_LIB="$ROOT_DIR/setup/lib/common.sh"
CONFIG_FILE="$ROOT_DIR/config/gwq/config.toml"

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

assert_file_exists "$CONFIG_FILE"
assert_contains 'function setup_gwq_config() {' "$COMMON_LIB"
assert_contains 'config_home="$(setup_config_home)"' "$COMMON_LIB"
assert_contains 'if [[ -e "${config_home}/gwq/config.toml" && ! -L "${config_home}/gwq/config.toml" ]]; then' "$COMMON_LIB"
assert_contains 'mv "${config_home}/gwq/config.toml" "${config_home}/gwq/config.toml.backup.$(date +%Y%m%d%H%M%S)"' "$COMMON_LIB"
assert_contains 'log_info "gwq config: Backed up existing config"' "$COMMON_LIB"
assert_contains 'mkdir -p "${config_home}/gwq"' "$COMMON_LIB"
assert_contains 'set_config_file_target "/config/gwq/config.toml" "${config_home}/gwq/config.toml"' "$COMMON_LIB"
assert_contains 'setup_gwq_config' "$COMMON_LIB"
assert_contains '[worktree]' "$CONFIG_FILE"
assert_contains 'basedir = "~/.worktrees"' "$CONFIG_FILE"
assert_contains 'auto_mkdir = true' "$CONFIG_FILE"
assert_contains '[cd]' "$CONFIG_FILE"
assert_contains 'launch_shell = false' "$CONFIG_FILE"

echo "gwq_config_link_test: ok"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
COMMON_LIB="$ROOT_DIR/setup/lib/common.sh"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

# 期待: common() は主要処理をサブ関数に分割して呼び出す
assert_contains 'function setup_tmux_config() {' "$COMMON_LIB"
assert_contains 'function setup_git_config() {' "$COMMON_LIB"
assert_contains 'function setup_vim_config() {' "$COMMON_LIB"
assert_contains 'function setup_neovim_config() {' "$COMMON_LIB"
assert_contains 'function setup_zsh_config() {' "$COMMON_LIB"

assert_contains 'setup_tmux_config' "$COMMON_LIB"
assert_contains 'setup_git_config' "$COMMON_LIB"
assert_contains 'setup_vim_config' "$COMMON_LIB"
assert_contains 'setup_neovim_config' "$COMMON_LIB"
assert_contains 'setup_zsh_config' "$COMMON_LIB"

echo "common_refactor_test: ok"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
VIMRC="$ROOT_DIR/config/vim/vimrc"
PROVIDERS_LUA="$ROOT_DIR/config/nvim/lua/core/providers.lua"

assert_contains() {
    local needle="$1"
    local file="$2"

    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_not_contains() {
    local needle="$1"
    local file="$2"

    if grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected not to contain '$needle' in $file" >&2
        return 1
    fi
}

# 期待: Neovim provider の無効化変数はinit.luaで管理する
assert_contains 'vim.g.loaded_python3_provider = 0' "$PROVIDERS_LUA"
assert_not_contains 'let g:loaded_python_provider = 0' "$VIMRC"
assert_contains 'vim.g.loaded_ruby_provider = 0' "$PROVIDERS_LUA"
assert_contains 'vim.g.loaded_perl_provider = 0' "$PROVIDERS_LUA"
assert_contains 'vim.g.loaded_node_provider = 0' "$PROVIDERS_LUA"

# 期待: True Color が利用可能な環境では termguicolors を有効化する
assert_contains "if has('termguicolors')" "$VIMRC"
assert_contains 'set termguicolors' "$VIMRC"

echo "provider_policy_test: ok"

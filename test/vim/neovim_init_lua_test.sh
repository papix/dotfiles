#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
INIT_LUA="$ROOT_DIR/config/nvim/init.lua"
BOOTSTRAP_LUA="$ROOT_DIR/config/nvim/lua/core/bootstrap.lua"
CLIPBOARD_LUA="$ROOT_DIR/config/nvim/lua/core/clipboard.lua"
VIMRC="$ROOT_DIR/config/vim/vimrc"

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

if [[ ! -f "$INIT_LUA" ]]; then
    echo "ASSERTION FAILED: expected file $INIT_LUA" >&2
    exit 1
fi

# 期待: init.luaで既存vimrcを読み込む
assert_contains 'vim.cmd([[source ~/.vimrc]])' "$INIT_LUA"
assert_contains 'require("core.bootstrap")' "$INIT_LUA"

# 期待: lazy.nvimをブートストラップする
assert_contains 'local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"' "$BOOTSTRAP_LUA"
assert_contains 'pcall(require, "lazy")' "$BOOTSTRAP_LUA"
assert_contains 'lazy.setup("plugins",' "$BOOTSTRAP_LUA"

# 期待: SSH + tmux環境ではOSC52をフォールバックとして使う
assert_contains 'if vim.env.SSH_CONNECTION and vim.env.TMUX then' "$CLIPBOARD_LUA"
assert_contains 'vim.g.clipboard = "osc52"' "$CLIPBOARD_LUA"

# 期待: Neovim固有設定はvimrcから移管する
assert_not_contains 'set inccommand=nosplit' "$VIMRC"
assert_not_contains 'let g:loaded_python3_provider = 0' "$VIMRC"

echo "neovim_init_lua_test: ok"

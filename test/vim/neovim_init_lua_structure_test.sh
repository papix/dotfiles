#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
INIT_LUA="$ROOT_DIR/config/nvim/init.lua"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "ASSERTION FAILED: expected file $file" >&2
        return 1
    fi
}

# 期待: init.lua は責務分割したモジュールを読み込む
assert_contains 'require("core.bootstrap")' "$INIT_LUA"
assert_contains 'require("core.options")' "$INIT_LUA"
assert_contains 'require("core.providers")' "$INIT_LUA"
assert_contains 'require("core.clipboard")' "$INIT_LUA"

# 期待: 各モジュールファイルが存在する
assert_file_exists "$ROOT_DIR/config/nvim/lua/core/bootstrap.lua"
assert_file_exists "$ROOT_DIR/config/nvim/lua/core/options.lua"
assert_file_exists "$ROOT_DIR/config/nvim/lua/core/providers.lua"
assert_file_exists "$ROOT_DIR/config/nvim/lua/core/clipboard.lua"

echo "neovim_init_lua_structure_test: ok"

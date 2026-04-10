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

# 期待: Neovimはinit.luaを配置する
assert_contains 'set_config_file "/config/nvim/init.lua" "/.config/nvim/init.lua"' "$COMMON_LIB"
assert_contains 'set_config_file "/config/nvim/lua" "/.config/nvim/lua"' "$COMMON_LIB"

echo "neovim_init_lua_link_test: ok"

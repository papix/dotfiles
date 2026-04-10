#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMUX_CONF="$ROOT_DIR/config/tmux.conf"
ZSH_TMUX_FILE="$ROOT_DIR/config/zsh/82-tmux.zsh"

assert_contains() {
    local needle="$1"
    local file="$2"

    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

# 期待: tmux サーバーは client の PATH を更新対象に含める
assert_contains 'set -ga update-environment "PATH"' "$TMUX_CONF"

# 期待: tmux 内で起動した zsh は解決済み PATH をサーバー側へ同期する
assert_contains 'command tmux set-environment -g PATH "$PATH"' "$ZSH_TMUX_FILE"

echo "path_sync_policy_test: ok"

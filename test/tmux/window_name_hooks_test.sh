#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMUX_CONF="$ROOT_DIR/config/tmux.conf"
REFRESH_SCRIPT="$ROOT_DIR/config/zsh/functions/tmux-git-window-name-refresh"
WINDOW_NAME_FUNC="$ROOT_DIR/config/zsh/functions/tmux-git-window-name"

assert_contains() {
    local needle="$1"
    local file="$2"

    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_executable() {
    local file="$1"

    if [[ ! -x "$file" ]]; then
        echo "ASSERTION FAILED: expected executable file $file" >&2
        return 1
    fi
}

# 期待: pane close時にwindow名を再計算するhookがある
assert_contains "set-hook -g after-kill-pane 'run-shell \"~/.config/zsh/functions/tmux-git-window-name-refresh \\\"#{window_id}\\\"\"'" "$TMUX_CONF"
assert_contains "set-hook -g pane-exited 'run-shell \"~/.config/zsh/functions/tmux-git-window-name-refresh \\\"#{window_id}\\\"\"'" "$TMUX_CONF"

# 期待: hook先スクリプトが存在し、refresh関数を呼ぶ
assert_executable "$REFRESH_SCRIPT"
assert_contains 'source "${HOME}/.config/zsh/functions/tmux-git-window-name"' "$REFRESH_SCRIPT"
assert_contains 'tmux_git_window_name_refresh_window "$window_target"' "$REFRESH_SCRIPT"

# 期待: 関数本体にwindow指定更新用の関数がある
assert_contains "function tmux_git_window_name_refresh_window()" "$WINDOW_NAME_FUNC"
assert_contains 'tmux rename-window -t "$window_target" "$window_title"' "$WINDOW_NAME_FUNC"

# 期待: 無効なwindow targetでもhookスクリプトは非0終了しない（tmuxエラーを表に出さない）
if ! "$REFRESH_SCRIPT" "@999999" >/dev/null 2>&1; then
    echo "ASSERTION FAILED: expected refresh script to ignore invalid window target" >&2
    exit 1
fi

echo "window_name_hooks_test: ok"

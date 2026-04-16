#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMUX_CONF="$ROOT_DIR/config/tmux.conf"
REFRESH_SCRIPT="$ROOT_DIR/config/zsh/functions/tmux-git-window-name-refresh"
AFTER_SELECT_WINDOW_SCRIPT="$ROOT_DIR/config/zsh/functions/tmux-after-select-window"
STATUS_REFRESH_SCRIPT="$ROOT_DIR/config/zsh/functions/tmux-status-line-refresh"
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
assert_contains "set-hook -g after-select-window 'run-shell \"#{?XDG_CONFIG_HOME,#{q:XDG_CONFIG_HOME},#{q:HOME}/.config}/zsh/functions/tmux-after-select-window \\\"#{@last_active_pane}\\\" \\\"#{hook_session}\\\" \\\"#{hook_client}\\\"\"'" "$TMUX_CONF"
assert_contains "set-hook -g after-kill-pane 'run-shell \"#{?XDG_CONFIG_HOME,#{q:XDG_CONFIG_HOME},#{q:HOME}/.config}/zsh/functions/tmux-git-window-name-refresh \\\"#{window_id}\\\" \\\"#{hook_session}\\\" \\\"#{hook_client}\\\"\"'" "$TMUX_CONF"
assert_contains "set-hook -g pane-exited 'run-shell \"#{?XDG_CONFIG_HOME,#{q:XDG_CONFIG_HOME},#{q:HOME}/.config}/zsh/functions/tmux-git-window-name-refresh \\\"#{window_id}\\\" \\\"#{hook_session}\\\" \\\"#{hook_client}\\\"\"'" "$TMUX_CONF"

# 期待: hook先スクリプトが存在し、refresh関数を呼ぶ
assert_executable "$REFRESH_SCRIPT"
assert_executable "$AFTER_SELECT_WINDOW_SCRIPT"
assert_executable "$STATUS_REFRESH_SCRIPT"
assert_contains 'config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"' "$REFRESH_SCRIPT"
assert_contains 'source "${config_home}/zsh/functions/tmux-git-window-name"' "$REFRESH_SCRIPT"
assert_contains 'tmux_git_window_name_refresh_window "$window_target"' "$REFRESH_SCRIPT"
assert_contains '"${config_home}/zsh/functions/tmux-status-line-refresh"' "$REFRESH_SCRIPT"
assert_contains 'last_active_pane="${1:-}"' "$AFTER_SELECT_WINDOW_SCRIPT"
assert_contains 'session_target="${2:-}"' "$AFTER_SELECT_WINDOW_SCRIPT"
assert_contains 'client_target="${3:-}"' "$AFTER_SELECT_WINDOW_SCRIPT"
assert_contains 'tmux select-pane -t "$last_active_pane"' "$AFTER_SELECT_WINDOW_SCRIPT"
assert_contains '"${config_home}/zsh/functions/tmux-status-line-refresh" "$session_target" "$client_target"' "$AFTER_SELECT_WINDOW_SCRIPT"
assert_contains 'session_target="${2:-}"' "$REFRESH_SCRIPT"
assert_contains 'client_target="${3:-}"' "$REFRESH_SCRIPT"
assert_contains '"${config_home}/zsh/functions/tmux-status-line-refresh" "$session_target" "$client_target"' "$REFRESH_SCRIPT"
assert_contains 'session_target="${1:-}"' "$STATUS_REFRESH_SCRIPT"
assert_contains 'client_target="${2:-}"' "$STATUS_REFRESH_SCRIPT"
assert_contains "tmux list-clients -t \"\$session_target\" -F '#{client_tty}'" "$STATUS_REFRESH_SCRIPT"
assert_contains "tmux list-clients -F '#{client_tty}'" "$STATUS_REFRESH_SCRIPT"
assert_contains 'tmux refresh-client -S -t "$client_target"' "$STATUS_REFRESH_SCRIPT"
assert_contains 'if typeset -f tmux-git-window-name >/dev/null 2>&1; then' "$ROOT_DIR/config/zsh/82-tmux.zsh"

# 期待: 関数本体にwindow指定更新用の関数がある
assert_contains "function tmux_git_window_name_refresh_window()" "$WINDOW_NAME_FUNC"
assert_contains 'tmux rename-window -t "$window_target" "$window_title"' "$WINDOW_NAME_FUNC"

# 期待: 無効なwindow targetでもhookスクリプトは非0終了しない（tmuxエラーを表に出さない）
if ! "$REFRESH_SCRIPT" "@999999" >/dev/null 2>&1; then
    echo "ASSERTION FAILED: expected refresh script to ignore invalid window target" >&2
    exit 1
fi

# 期待: tmux設定を実際に読み込めて、hookが登録される
tmp_config="$(mktemp)"
socket_name="dotfiles-window-hooks-$$"
trap 'rm -f "$tmp_config"; tmux -L "$socket_name" kill-server >/dev/null 2>&1 || true' EXIT

grep -Fv "run '~/.tmux/plugins/tpm/tpm'" "$TMUX_CONF" >"$tmp_config"

tmux -L "$socket_name" -f "$tmp_config" new-session -d -s hooks-test

runtime_after_select_window="$(tmux -L "$socket_name" show-hooks -g after-select-window 2>/dev/null || true)"
runtime_after_kill_pane="$(tmux -L "$socket_name" show-hooks -g after-kill-pane 2>/dev/null || true)"
runtime_pane_exited="$(tmux -L "$socket_name" show-hooks -g pane-exited 2>/dev/null || true)"

if [[ "$runtime_after_select_window" != *'tmux-after-select-window'* ]]; then
    echo "ASSERTION FAILED: expected after-select-window hook to be registered" >&2
    exit 1
fi

if [[ "$runtime_after_kill_pane" != *'tmux-git-window-name-refresh'* ]]; then
    echo "ASSERTION FAILED: expected after-kill-pane hook to be registered" >&2
    exit 1
fi

if [[ "$runtime_pane_exited" != *'tmux-git-window-name-refresh'* ]]; then
    echo "ASSERTION FAILED: expected pane-exited hook to be registered" >&2
    exit 1
fi

# 期待: custom XDG_CONFIG_HOME 環境でも hook が custom config 配下のスクリプトを実行する
tmp_root="$(mktemp -d)"
tmp_home="$tmp_root/home"
custom_config_home="$tmp_root/custom-config"
hook_log="$tmp_root/hook.log"
mkdir -p "$tmp_home" "$custom_config_home/zsh/functions"

cat >"$custom_config_home/zsh/functions/tmux-after-select-window" <<EOF
#!/usr/bin/env bash
printf 'after-select-window:%s\n' "\$*" >>"$hook_log"
EOF

cat >"$custom_config_home/zsh/functions/tmux-git-window-name-refresh" <<EOF
#!/usr/bin/env bash
printf 'git-window-name-refresh:%s\n' "\$*" >>"$hook_log"
EOF

chmod +x \
    "$custom_config_home/zsh/functions/tmux-after-select-window" \
    "$custom_config_home/zsh/functions/tmux-git-window-name-refresh"

custom_socket_name="dotfiles-window-hooks-custom-$$"
trap 'rm -f "$tmp_config"; rm -rf "$tmp_root"; tmux -L "$socket_name" kill-server >/dev/null 2>&1 || true; tmux -L "$custom_socket_name" kill-server >/dev/null 2>&1 || true' EXIT
HOME="$tmp_home" tmux -L "$custom_socket_name" -f "$tmp_config" new-session -d -s hooks-custom -n one
HOME="$tmp_home" tmux -L "$custom_socket_name" set-environment -g XDG_CONFIG_HOME "$custom_config_home"
HOME="$tmp_home" tmux -L "$custom_socket_name" new-window -t hooks-custom -n two >/dev/null
HOME="$tmp_home" tmux -L "$custom_socket_name" select-window -t hooks-custom:two >/dev/null
custom_pane_id="$(HOME="$tmp_home" tmux -L "$custom_socket_name" split-window -t hooks-custom:two -h -P -F '#{pane_id}')"
HOME="$tmp_home" tmux -L "$custom_socket_name" kill-pane -t "$custom_pane_id" >/dev/null
sleep 1

custom_hook_output="$(cat "$hook_log" 2>/dev/null || true)"
if [[ "$custom_hook_output" != *'after-select-window:'* ]]; then
    echo "ASSERTION FAILED: expected after-select-window hook to use custom XDG_CONFIG_HOME" >&2
    exit 1
fi

if [[ "$custom_hook_output" != *'git-window-name-refresh:'* ]]; then
    echo "ASSERTION FAILED: expected pane close hook to use custom XDG_CONFIG_HOME" >&2
    exit 1
fi

tmux -L "$custom_socket_name" kill-server >/dev/null 2>&1 || true
rm -rf "$tmp_root"

echo "window_name_hooks_test: ok"

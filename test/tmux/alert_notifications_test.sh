#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMUX_CONF="$ROOT_DIR/config/tmux.conf"

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

# 期待: bell通知は current/other を問わず扱い、activity/silenceは通知しない
assert_contains "set -g bell-action any" "$TMUX_CONF"
assert_contains "set -gq activity-action none" "$TMUX_CONF"
assert_contains "set -gq silence-action none" "$TMUX_CONF"
assert_contains "setw -g monitor-bell on" "$TMUX_CONF"

# 期待: 視覚通知は抑制してOS通知へ集約する
assert_contains "set -g visual-bell off" "$TMUX_CONF"
assert_contains "set -g visual-activity off" "$TMUX_CONF"
assert_contains "set -gq visual-silence off" "$TMUX_CONF"

# 期待: activity/silence の監視は無効化する
assert_contains "setw -g monitor-activity off" "$TMUX_CONF"
assert_contains "setw -g monitor-silence 0" "$TMUX_CONF"

# 期待: bell hook のみ詳細通知スクリプトを呼び出す
assert_contains "set-hook -g alert-bell 'run-shell \"command -v tmux-alert-notify" "$TMUX_CONF"
assert_contains "tmux-alert-notify bell" "$TMUX_CONF"
assert_not_contains "tmux-alert-notify activity" "$TMUX_CONF"
assert_not_contains "tmux-alert-notify silence" "$TMUX_CONF"
assert_contains "#{q:session_name}" "$TMUX_CONF"
assert_contains "#{q:window_name}" "$TMUX_CONF"
assert_contains "#{q:pane_title}" "$TMUX_CONF"
assert_contains "#{q:pane_current_path}" "$TMUX_CONF"

echo "alert_notifications_test: ok"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bin/tmux-alert-notify"

assert_contains() {
    local needle="$1"
    local text="$2"
    local message="$3"

    if ! printf '%s\n' "$text" | grep -F -- "$needle" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: $message" >&2
        echo "  expected to contain: $needle" >&2
        echo "  actual            : $text" >&2
        exit 1
    fi
}

assert_empty() {
    local text="$1"
    local message="$2"

    if [[ -n "$text" ]]; then
        echo "ASSERTION FAILED: $message" >&2
        echo "  expected empty output" >&2
        echo "  actual         : $text" >&2
        exit 1
    fi
}

assert_executable() {
    local file="$1"

    if [[ ! -x "$file" ]]; then
        echo "ASSERTION FAILED: expected executable file $file" >&2
        exit 1
    fi
}

assert_executable "$SCRIPT"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

default_disabled_output="$(
    env \
        -u TMUX_ALERT_NOTIFY_DISABLE \
        TMUX_ALERT_NOTIFY_DRY_RUN=1 \
        TMUX_ALERT_NOTIFY_STATE_DIR="$tmp_dir" \
        "$SCRIPT" \
        bell \
        work \
        2 \
        editor \
        1 \
        "nvim /tmp/app" \
        /tmp/app \
        nvim \
        '-'
)"

assert_empty "$default_disabled_output" "default mode should be disabled"

first_output="$(
    TMUX_ALERT_NOTIFY_DRY_RUN=1 \
        TMUX_ALERT_NOTIFY_DISABLE=0 \
        TMUX_ALERT_NOTIFY_STATE_DIR="$tmp_dir" \
        TMUX_ALERT_NOTIFY_MIN_INTERVAL=120 \
        "$SCRIPT" \
        bell \
        work \
        2 \
        editor \
        1 \
        "nvim /tmp/app" \
        /tmp/app \
        nvim \
        '-'
)"

assert_contains "event=bell" "$first_output" "first output should include event"
assert_contains "session=work" "$first_output" "first output should include session"
assert_contains "window=2:editor" "$first_output" "first output should include window index/name"
assert_contains "pane=1 (nvim)" "$first_output" "first output should include pane metadata"
assert_contains "path=/tmp/app" "$first_output" "first output should include pane path"

second_output="$(
    TMUX_ALERT_NOTIFY_DRY_RUN=1 \
        TMUX_ALERT_NOTIFY_DISABLE=0 \
        TMUX_ALERT_NOTIFY_STATE_DIR="$tmp_dir" \
        TMUX_ALERT_NOTIFY_MIN_INTERVAL=120 \
        "$SCRIPT" \
        bell \
        work \
        2 \
        editor \
        1 \
        "nvim /tmp/app" \
        /tmp/app \
        nvim \
        '-'
)"

assert_empty "$second_output" "second output should be rate-limited"

third_output="$(
    TMUX_ALERT_NOTIFY_DRY_RUN=1 \
        TMUX_ALERT_NOTIFY_DISABLE=0 \
        TMUX_ALERT_NOTIFY_STATE_DIR="$tmp_dir" \
        TMUX_ALERT_NOTIFY_MIN_INTERVAL=120 \
        "$SCRIPT" \
        activity \
        work \
        2 \
        editor \
        1 \
        "nvim /tmp/app" \
        /tmp/app \
        nvim \
        '-'
)"

assert_contains "event=activity" "$third_output" "different event should bypass rate-limit key"

focused_output="$(
    TMUX_ALERT_NOTIFY_DRY_RUN=1 \
        TMUX_ALERT_NOTIFY_DISABLE=0 \
        TMUX_ALERT_NOTIFY_STATE_DIR="$tmp_dir" \
        TMUX_ALERT_NOTIFY_MIN_INTERVAL=0 \
        "$SCRIPT" \
        bell \
        work \
        3 \
        logs \
        0 \
        "tail -f /tmp/app.log" \
        /tmp \
        tail \
        '*'
)"

assert_empty "$focused_output" "focused window should be skipped by default"

focused_override_output="$(
    TMUX_ALERT_NOTIFY_DRY_RUN=1 \
        TMUX_ALERT_NOTIFY_DISABLE=0 \
        TMUX_ALERT_NOTIFY_SKIP_FOCUSED=0 \
        TMUX_ALERT_NOTIFY_STATE_DIR="$tmp_dir" \
        TMUX_ALERT_NOTIFY_MIN_INTERVAL=0 \
        "$SCRIPT" \
        bell \
        work \
        3 \
        logs \
        0 \
        "tail -f /tmp/app.log" \
        /tmp \
        tail \
        '*'
)"

assert_contains "window=3:logs" "$focused_override_output" "skip focused should be configurable"

disabled_output="$(
    TMUX_ALERT_NOTIFY_DRY_RUN=1 \
        TMUX_ALERT_NOTIFY_DISABLE=1 \
        TMUX_ALERT_NOTIFY_STATE_DIR="$tmp_dir" \
        "$SCRIPT" \
        bell \
        work \
        2 \
        editor \
        1 \
        "nvim /tmp/app" \
        /tmp/app \
        nvim \
        '*'
)"

assert_empty "$disabled_output" "disabled mode should render nothing"

echo "tmux_alert_notify_test: ok"

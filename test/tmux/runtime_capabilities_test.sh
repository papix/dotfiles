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

# 期待: クリップボード連携は external モードを利用する
assert_contains 'set -s set-clipboard external' "$TMUX_CONF"
assert_not_contains 'set -g set-clipboard on' "$TMUX_CONF"

# 期待: フォーカスイベントと拡張キー入力を有効化する
assert_contains 'set -g focus-events on' "$TMUX_CONF"
assert_contains 'set -g extended-keys on' "$TMUX_CONF"

# 期待: modern terminal の RGB feature を有効化する
assert_contains 'terminal-features' "$TMUX_CONF"

echo "runtime_capabilities_test: ok"

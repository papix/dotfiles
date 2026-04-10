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

# 期待: tmuxのモダン機能はバージョンガード付きで有効化する
assert_contains "if -F '#{>=:#{version},3.2}' 'set -as terminal-features \",*:RGB\"' 'set -ga terminal-overrides \",xterm-256color:Tc\"'" "$TMUX_CONF"
assert_contains "if -F '#{>=:#{version},3.2}' 'set -g extended-keys on'" "$TMUX_CONF"

# 期待: セッション復元系プラグインを有効化する
assert_contains "set -g @plugin 'tmux-plugins/tmux-resurrect'" "$TMUX_CONF"
assert_contains "set -g @plugin 'tmux-plugins/tmux-continuum'" "$TMUX_CONF"
assert_contains "set -g @continuum-restore 'on'" "$TMUX_CONF"

echo "plugin_and_compatibility_test: ok"

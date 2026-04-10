#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SEGMENT="$ROOT_DIR/config/tmux-powerline/segments/claude_usage.sh"

assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    if [[ "$expected" != "$actual" ]]; then
        echo "ASSERTION FAILED: $message" >&2
        echo "  expected: $expected" >&2
        echo "  actual  : $actual" >&2
        exit 1
    fi
}

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

export TMUX_POWERLINE_SEG_CLAUDE_USAGE_CURL_TIMEOUT=9
export TMUX_POWERLINE_SEG_CLAUDE_USAGE_STALE_CACHE_MAX=120
source "$SEGMENT"

assert_eq "9" "$CURL_TIMEOUT" "CURL_TIMEOUT should be configurable by env"
assert_eq "120" "$STALE_CACHE_MAX" "STALE_CACHE_MAX should be configurable by env"

# disabled時は空出力
export TMUX_POWERLINE_SEG_CLAUDE_USAGE_DISABLE=1
disabled_output="$(run_segment)"
assert_eq "" "$disabled_output" "run_segment should render nothing when disabled"

# invalid値はデフォルトへフォールバック
export TMUX_POWERLINE_SEG_CLAUDE_USAGE_DISABLE=0
export TMUX_POWERLINE_SEG_CLAUDE_USAGE_CURL_TIMEOUT=invalid
export TMUX_POWERLINE_SEG_CLAUDE_USAGE_STALE_CACHE_MAX=-1
__claude_usage_apply_env_config
assert_eq "5" "$CURL_TIMEOUT" "invalid timeout should fallback to default"
assert_eq "86400" "$STALE_CACHE_MAX" "invalid stale max should fallback to default"

assert_contains 'TMUX_POWERLINE_SEG_CLAUDE_USAGE_DISABLE' "$(sed -n '1,220p' "$SEGMENT")" "segment should expose disable env variable"

echo "claude_usage_env_config_test: ok"

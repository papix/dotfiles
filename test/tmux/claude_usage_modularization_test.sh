#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SEGMENT="$ROOT_DIR/config/tmux-powerline/segments/claude_usage.sh"
MODULE_DIR="$ROOT_DIR/config/tmux-powerline/segments/claude_usage"
API_MODULE="$MODULE_DIR/api.sh"
CACHE_MODULE="$MODULE_DIR/cache.sh"
RENDER_MODULE="$MODULE_DIR/render.sh"

assert_file_exists() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "ASSERTION FAILED: expected file $path" >&2
        return 1
    fi
}

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_file_exists "$API_MODULE"
assert_file_exists "$CACHE_MODULE"
assert_file_exists "$RENDER_MODULE"

assert_contains 'source "${__claude_usage_module_dir}/api.sh"' "$SEGMENT"
assert_contains 'source "${__claude_usage_module_dir}/cache.sh"' "$SEGMENT"
assert_contains 'source "${__claude_usage_module_dir}/render.sh"' "$SEGMENT"

assert_contains 'function __call_usage_api()' "$API_MODULE"
assert_contains 'function __use_stale_cache()' "$CACHE_MODULE"
assert_contains 'function __append_rate_limited_suffix()' "$RENDER_MODULE"

echo "claude_usage_modularization_test: ok"

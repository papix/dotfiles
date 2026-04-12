#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SEGMENT="$ROOT_DIR/config/tmux-powerline/segments/battery.sh"

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

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cache_file="$tmp_dir/battery.cache"
printf 'cached-battery\n' >"$cache_file"

output="$(
    SEGMENT="$SEGMENT" CACHE_FILE_PATH="$cache_file" bash <<'EOF'
set -euo pipefail
source "$SEGMENT"
CACHE_FILE="$CACHE_FILE_PATH"
CACHE_DURATION=60
run_segment
EOF
)"

assert_eq "cached-battery" "$output" "battery segment should return fresh cached output on GNU stat systems"

echo "battery_segment_test: ok"

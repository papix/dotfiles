#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
INIT_FILE="$ROOT_DIR/config/zsh/00-init.zsh"
GWQ_FILE="$ROOT_DIR/config/zsh/83-gwq.zsh"

assert_file_missing() {
    local path="$1"
    if [[ -e "$path" ]]; then
        echo "ASSERTION FAILED: expected path to be absent: $path" >&2
        return 1
    fi
}

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_contains 'tmux peco ag gh op' "$INIT_FILE"
if grep -Fq -- 'gwq' "$INIT_FILE"; then
    echo "ASSERTION FAILED: expected gwq to be removed from $INIT_FILE" >&2
    exit 1
fi
assert_file_missing "$GWQ_FILE"

echo "gwq_integration_test: ok"

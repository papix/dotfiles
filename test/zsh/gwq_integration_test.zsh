#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
INIT_FILE="$ROOT_DIR/config/zsh/00-init.zsh"
GWQ_FILE="$ROOT_DIR/config/zsh/83-gwq.zsh"

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
    if ! grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_contains 'tmux peco ag gwq' "$INIT_FILE"
assert_file_exists "$GWQ_FILE"
assert_contains '# 依存: 40-completion.zsh (compinitのため)' "$GWQ_FILE"
assert_contains 'if [[ -n "$COMMAND_CACHE[gwq]" ]]; then' "$GWQ_FILE"
assert_contains 'source <(gwq completion zsh)' "$GWQ_FILE"

echo "gwq_integration_test: ok"

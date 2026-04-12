#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
PECO_FILE="$ROOT_DIR/config/zsh/80-peco.zsh"

function assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    if [[ "$expected" != "$actual" ]]; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  expected: ${expected}" >&2
        echo "  actual  : ${actual}" >&2
        return 1
    fi
}

output="$(PECO_FILE="$PECO_FILE" zsh -fc 'source "$PECO_FILE"' 2>&1)"
assert_eq "" "$output" "80-peco.zsh should not emit tty errors when sourced without a terminal"

echo "peco_non_tty_test: ok"

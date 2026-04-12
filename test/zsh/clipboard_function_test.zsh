#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
FUNCTIONS_FILE="$ROOT_DIR/config/zsh/70-functions.zsh"

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

function assert_file_eq() {
    local expected_file="$1"
    local actual_file="$2"
    local message="$3"
    if ! cmp -s "$expected_file" "$actual_file"; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  expected bytes: $(od -An -tx1 -v "$expected_file" | tr -d '\n' | sed 's/^ *//')" >&2
        echo "  actual bytes  : $(od -An -tx1 -v "$actual_file" | tr -d '\n' | sed 's/^ *//')" >&2
        return 1
    fi
}

function decode_base64() {
    local encoded="$1"
    if print -rn -- "$encoded" | base64 -d >/dev/null 2>&1; then
        print -rn -- "$encoded" | base64 -d
        return 0
    fi

    print -rn -- "$encoded" | base64 -D
}

function zle() { return 0 }
function bindkey() { return 0 }

PATH="/usr/bin:/bin"
unset TMUX
source "$FUNCTIONS_FILE"

raw_output="$(copy-to-clipboard '\c')"
encoded="${raw_output#$'\e]52;c;'}"
encoded="${encoded%$'\a'}"
decoded="$(decode_base64 "$encoded")"

assert_eq '\c' "$decoded" "copy-to-clipboard fallback should preserve backslashes literally"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
expected_file="$tmp_dir/expected.txt"
actual_file="$tmp_dir/actual.txt"

printf 'line\n' >"$expected_file"
raw_output="$(printf 'line\n' | copy-to-clipboard)"
encoded="${raw_output#$'\e]52;c;'}"
encoded="${encoded%$'\a'}"
decode_base64 "$encoded" >"$actual_file"

assert_file_eq "$expected_file" "$actual_file" "copy-to-clipboard fallback should preserve trailing newline from stdin"

echo "clipboard_function_test: ok"

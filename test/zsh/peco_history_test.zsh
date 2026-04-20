#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"

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

function stty() { :; }
function zle() { :; }
function bindkey() { :; }
function fc() {
    printf '%s\n' "git status" "git commit -m test"
}
function peco() {
    cat >/dev/null || true
    printf '%s\n' "git commit -m test"
}

BUFFER=""
CURSOR=0

source "$ROOT_DIR/config/zsh/80-peco.zsh"
peco-history

assert_eq "git commit -m test" "$BUFFER" "peco-history should restore the selected command into BUFFER"
assert_eq "${#BUFFER}" "$CURSOR" "peco-history should move the cursor to the end of BUFFER"

echo "peco_history_test: ok"

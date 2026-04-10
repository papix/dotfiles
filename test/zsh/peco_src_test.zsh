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
function bindkey() { :; }
function zle() {
    if [[ "$1" == "accept-line" ]]; then
        ZLE_ACCEPTED=1
    fi
}
function roots() { cat; }
function ghq() {
    if [[ "$1" == "list" && "$2" == "--full-path" ]]; then
        printf '%s\n' "/tmp/plain-repo" "/tmp/a repo"
        return 0
    fi
    return 1
}
function peco() {
    cat >/dev/null || true
    printf '%s\n' "${PECO_OUTPUT}"
}

source "$ROOT_DIR/config/zsh/80-peco.zsh"

BUFFER=""
ZLE_ACCEPTED=0
PECO_OUTPUT="/tmp/a repo"
peco-src

assert_eq 'cd /tmp/a\ repo' "$BUFFER" "peco-src should quote spaces in selected repo path"
assert_eq "1" "${ZLE_ACCEPTED}" "peco-src should accept the command line after selection"

echo "peco_src_test: ok"

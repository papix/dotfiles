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

function assert_contains() {
    local needle="$1"
    local haystack="$2"
    local message="$3"
    if ! print -r -- "$haystack" | grep -F -- "$needle" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  expected to contain: ${needle}" >&2
        echo "  actual            : ${haystack}" >&2
        return 1
    fi
}

# 非対話テスト用の最小スタブ
function zle() { return 0 }
function bindkey() { return 0 }
function peco() { cat }

source "$ROOT_DIR/config/zsh/81-git.zsh"

set +e
missing_arg_output="$(git-switch-branch 2>&1)"
missing_arg_exit_code=$?
set -e

assert_eq "1" "$missing_arg_exit_code" "git-switch-branch should return 1 when branch arg is missing"
assert_contains "Usage: git-switch-branch <branch-name>" "$missing_arg_output" "git-switch-branch should print usage when branch arg is missing"

echo "git_functions_refactor_test: ok"

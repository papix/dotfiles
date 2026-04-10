#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
INIT_FILE="$ROOT_DIR/config/zsh/00-init.zsh"
LINUX_FILE="$ROOT_DIR/config/zsh/15-platform-linux.zsh"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_not_contains() {
    local needle="$1"
    local file="$2"
    if grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected not to contain '$needle' in $file" >&2
        return 1
    fi
}

# /home/linuxbrew のみを初期化対象にする
assert_contains '"/home/linuxbrew/.linuxbrew/bin"' "$INIT_FILE"
assert_not_contains '"$HOME/.linuxbrew/bin"' "$INIT_FILE"

# brew 実体の実行可能判定を使う
assert_contains '[[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]' "$LINUX_FILE"

# ~/.linuxbrew は廃止方針のため分岐を持たない
assert_not_contains 'elif [[ -d "$HOME/.linuxbrew" ]]' "$LINUX_FILE"
assert_not_contains 'eval "$($HOME/.linuxbrew/bin/brew shellenv)"' "$LINUX_FILE"

echo "linuxbrew_init_policy_test: ok"

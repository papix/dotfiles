#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
ANYENV_FILE="$ROOT_DIR/config/zsh/16-anyenv.zsh"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

init_line="$(grep -nF 'eval "$(anyenv init -)"' "$ANYENV_FILE" | cut -d: -f1)"
mise_line="$(grep -nF 'path=("${HOME}/.local/share/mise/shims" ${path})' "$ANYENV_FILE" | cut -d: -f1)"

if [[ -z "$init_line" || -z "$mise_line" ]]; then
    echo "ASSERTION FAILED: expected anyenv init and mise path reset lines" >&2
    exit 1
fi

if (( mise_line <= init_line )); then
    echo "ASSERTION FAILED: expected mise shims reset after anyenv init" >&2
    exit 1
fi

assert_contains 'mise shims を最優先に戻す' "$ANYENV_FILE"
assert_contains '${HOME}/.local/share/mise/shims' "$ANYENV_FILE"

echo "anyenv_path_priority_test: ok"

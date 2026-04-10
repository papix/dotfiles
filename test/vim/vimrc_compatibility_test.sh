#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
VIMRC="$ROOT_DIR/config/vim/vimrc"

assert_contains() {
    local needle="$1"
    local file="$2"

    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

if [[ ! -f "$VIMRC" ]]; then
    echo "ASSERTION FAILED: expected file $VIMRC" >&2
    exit 1
fi

# 期待: Neovimではviminfo設定を適用しない
assert_contains "if !has('nvim')" "$VIMRC"
assert_contains 'set viminfo+=n~/.vim/viminfo' "$VIMRC"

# 期待: Markdownでは保存時の行末空白削除を抑止する
assert_contains "autocmd BufWritePre * if &filetype !=# 'markdown' | silent! %s/\\s\\+$//e | endif" "$VIMRC"

echo "vimrc_compatibility_test: ok"

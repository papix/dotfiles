#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DOC="$ROOT_DIR/docs/how-to/manage-neovim-config.md"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

if [[ ! -f "$DOC" ]]; then
    echo "ASSERTION FAILED: expected file $DOC" >&2
    exit 1
fi

# 期待: Neovim運用ドキュメントに構成説明と切り戻し手順がある
assert_contains '## 現在の構成（init.lua + core）' "$DOC"
assert_contains '## 切り戻し手順（トラブル時）' "$DOC"
assert_contains 'cp ~/.config/nvim/init.lua ~/.config/nvim/init.lua.backup.' "$DOC"
assert_contains 'vim --clean' "$DOC"

echo "neovim_operations_doc_test: ok"

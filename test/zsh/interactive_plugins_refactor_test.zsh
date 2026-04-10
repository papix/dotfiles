#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
PLUGINS_FILE="$ROOT_DIR/config/zsh/91-interactive-plugins.zsh"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

# 期待: プラグイン読み込み処理を共通関数化する
assert_contains 'function zsh_source_first_existing()' "$PLUGINS_FILE"
assert_contains 'zsh_source_first_existing "${autosuggest_candidates[@]}" || true' "$PLUGINS_FILE"
assert_contains 'zsh_source_first_existing "${syntax_highlight_candidates[@]}" || true' "$PLUGINS_FILE"

echo "interactive_plugins_refactor_test: ok"

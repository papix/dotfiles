#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
PLUGINS_FILE="$ROOT_DIR/config/zsh/91-interactive-plugins.zsh"
FUNCTIONS_FILE="$ROOT_DIR/config/zsh/70-functions.zsh"

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

assert_line_order() {
    local first="$1"
    local second="$2"
    local file="$3"

    local first_line second_line
    first_line="$(grep -nF -- "$first" "$file" | head -n 1 | cut -d: -f1 || true)"
    second_line="$(grep -nF -- "$second" "$file" | head -n 1 | cut -d: -f1 || true)"

    if [[ -z "$first_line" || -z "$second_line" ]]; then
        echo "ASSERTION FAILED: expected both '$first' and '$second' in $file" >&2
        return 1
    fi
    if (( first_line >= second_line )); then
        echo "ASSERTION FAILED: expected '$first' to appear before '$second' in $file" >&2
        return 1
    fi
}

# 期待: 補助プラグイン読み込みモジュールが存在する
if [[ ! -f "$PLUGINS_FILE" ]]; then
    echo "ASSERTION FAILED: expected file $PLUGINS_FILE" >&2
    exit 1
fi

assert_contains 'zsh-autosuggestions' "$PLUGINS_FILE"
assert_contains 'zsh-syntax-highlighting' "$PLUGINS_FILE"
assert_contains 'ZSH_AUTOSUGGEST_STRATEGY=' "$PLUGINS_FILE"
assert_not_contains 'local brew_prefix=' "$PLUGINS_FILE"
assert_line_order 'zsh-autosuggestions' 'zsh-syntax-highlighting' "$PLUGINS_FILE"

# 期待: compauditチェック関数を追加する
assert_contains 'function zsh-compaudit-check()' "$FUNCTIONS_FILE"
assert_contains 'autoload -Uz compaudit' "$FUNCTIONS_FILE"

echo "interactive_plugins_test: ok"

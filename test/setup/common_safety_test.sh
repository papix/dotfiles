#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SETUP_SH="$ROOT_DIR/setup.sh"
COMMON_LIB="$ROOT_DIR/setup/lib/common.sh"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_not_contains() {
    local needle="$1"
    local file="$2"
    if grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected not to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_text_contains() {
    local needle="$1"
    local text="$2"
    if ! printf '%s' "$text" | grep -F -- "$needle" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle'" >&2
        echo "actual: $text" >&2
        return 1
    fi
}

# 期待: 組み込みの PWD を上書きせず、共有用のディレクトリ変数を使う
assert_contains 'DOTFILES_DIR="$SCRIPT_DIR"' "$SETUP_SH"
assert_not_contains 'PWD=$(pwd)' "$SETUP_SH"

# 期待: setup.sh を source した経路でも set_config_file が DOTFILES_DIR を解決できる
source_path_output="$(
    SETUP_SH="$SETUP_SH" bash <<'EOF'
set -euo pipefail
source "$SETUP_SH"
set +e
set_config_file "/config/does-not-exist" "/.zshrc" 2>&1
exit_code=$?
set -e
printf 'EXIT_CODE=%s\n' "$exit_code"
EOF
)"
assert_text_contains "Source file not found: ${ROOT_DIR}/config/does-not-exist" "$source_path_output"
assert_text_contains "EXIT_CODE=1" "$source_path_output"

# 期待: common.sh はローカル変数を使い、DOTFILES_DIR を参照する
assert_contains 'local SOURCE DEST DEST_DIR READLINK' "$COMMON_LIB"
assert_contains 'SOURCE="${DOTFILES_DIR}$1"' "$COMMON_LIB"
assert_contains 'for segment in "${DOTFILES_DIR}"/config/tmux-powerline/segments/*.sh; do' "$COMMON_LIB"
assert_contains 'if [[ -d "${DOTFILES_DIR}/config/vim/vim/colors" ]]; then' "$COMMON_LIB"
assert_contains 'if [[ -d "${DOTFILES_DIR}/config/zsh" ]]; then' "$COMMON_LIB"
assert_contains 'ln -s "${DOTFILES_DIR}/config/zsh" "${HOME}/.config/zsh"' "$COMMON_LIB"
assert_contains 'log_info "zsh modules: ${DOTFILES_DIR}/config/zsh => ${HOME}/.config/zsh (symlink)"' "$COMMON_LIB"

# 期待: init.lua がある場合は init.vim フォールバックを作らない
assert_contains 'if [[ ! -e "${HOME}/.config/nvim/init.vim" && ! -e "${HOME}/.config/nvim/init.lua" ]]; then' "$COMMON_LIB"

# 期待: PATH の説明は config/zshenv を参照する
assert_contains '# Setup bin directory - PATH is now configured in config/zshenv' "$COMMON_LIB"
assert_contains 'log_info "bin directory: PATH will be configured via config/zshenv"' "$COMMON_LIB"

echo "common_safety_test: ok"

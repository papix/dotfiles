#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SETUP_SH="$ROOT_DIR/setup.sh"
COMMON_LIB="$ROOT_DIR/setup/lib/common.sh"
PLATFORM_LIB="$ROOT_DIR/setup/lib/platform.sh"

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
assert_contains 'function setup_config_home() {' "$COMMON_LIB"
assert_contains 'function setup_cache_home() {' "$COMMON_LIB"
assert_contains 'function setup_state_home() {' "$COMMON_LIB"
assert_contains 'local SOURCE DEST DEST_DIR READLINK' "$COMMON_LIB"
assert_contains 'SOURCE="${DOTFILES_DIR}$1"' "$COMMON_LIB"
assert_contains 'config_home="$(setup_config_home)"' "$COMMON_LIB"
assert_contains 'for segment in "${DOTFILES_DIR}"/config/tmux-powerline/segments/*.sh; do' "$COMMON_LIB"
assert_contains 'if [[ -d "${DOTFILES_DIR}/config/vim/vim/colors" ]]; then' "$COMMON_LIB"
assert_contains 'if [[ -d "${DOTFILES_DIR}/config/zsh" ]]; then' "$COMMON_LIB"
assert_contains 'ln -s "${DOTFILES_DIR}/config/zsh" "${config_home}/zsh"' "$COMMON_LIB"
assert_contains 'log_info "zsh modules: ${DOTFILES_DIR}/config/zsh => ${config_home}/zsh (symlink)"' "$COMMON_LIB"

# 期待: init.lua がある場合は init.vim フォールバックを作らない
assert_contains 'if [[ ! -e "${config_home}/nvim/init.vim" && ! -e "${config_home}/nvim/init.lua" ]]; then' "$COMMON_LIB"

# 期待: local state/cache と ~/.local/bin をセットアップする
assert_contains 'cache_home="$(setup_cache_home)"' "$COMMON_LIB"
assert_contains 'state_home="$(setup_state_home)"' "$COMMON_LIB"
assert_contains 'mkdir -p "${state_home}/zsh"' "$COMMON_LIB"
assert_contains 'mkdir -p "${cache_home}/dotfiles"' "$COMMON_LIB"
assert_contains 'function setup_bin_links() {' "$COMMON_LIB"
assert_contains 'mkdir -p "${HOME}/.local/bin"' "$COMMON_LIB"
assert_contains 'backup_path="${link_target}.backup.$(date +%Y%m%d%H%M%S)"' "$COMMON_LIB"
assert_contains 'mv "$link_target" "$backup_path"' "$COMMON_LIB"
assert_contains 'ln -s "$source_file" "$link_target"' "$COMMON_LIB"

# 期待: custom XDG cache/state がある場合は setup でもそれを使う
tmp_home="$(mktemp -d)"
xdg_setup_output="$(
    HOME="$tmp_home" \
        XDG_CONFIG_HOME="$tmp_home/custom-config" \
        XDG_CACHE_HOME="$tmp_home/custom-cache" \
        XDG_STATE_HOME="$tmp_home/custom-state" \
        SETUP_SH="$SETUP_SH" \
        bash <<'EOF'
set -euo pipefail
source "$SETUP_SH"
set_config_file() { :; }
set_config_file_target() { :; }
setup_tmux_config() { :; }
setup_gwq_config() { :; }
setup_git_config() { :; }
setup_vim_config() { :; }
setup_neovim_config() { :; }
setup_zsh_config() { :; }
setup_bin_links() { :; }
common
printf 'HAS_STATE=%s\n' "$([[ -d "$XDG_STATE_HOME/zsh" ]] && echo 1 || echo 0)"
printf 'HAS_CACHE=%s\n' "$([[ -d "$XDG_CACHE_HOME/dotfiles" ]] && echo 1 || echo 0)"
printf 'HAS_DEFAULT_STATE=%s\n' "$([[ -d "$HOME/.local/state/zsh" ]] && echo 1 || echo 0)"
printf 'HAS_DEFAULT_CACHE=%s\n' "$([[ -d "$HOME/.cache/dotfiles" ]] && echo 1 || echo 0)"
EOF
)"
trap 'rm -rf "$tmp_home"' EXIT
assert_text_contains 'HAS_STATE=1' "$xdg_setup_output"
assert_text_contains 'HAS_CACHE=1' "$xdg_setup_output"
assert_text_contains 'HAS_DEFAULT_STATE=0' "$xdg_setup_output"
assert_text_contains 'HAS_DEFAULT_CACHE=0' "$xdg_setup_output"

# 期待: フォント更新は eval ではなく直接コマンド実行する
assert_not_contains 'eval "$font_update_cmd"' "$PLATFORM_LIB"
assert_contains 'fc-cache -fv "$font_dir"' "$PLATFORM_LIB"

echo "common_safety_test: ok"

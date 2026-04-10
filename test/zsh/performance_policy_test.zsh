#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
ENV_FILE="$ROOT_DIR/config/zsh/10-env.zsh"
DARWIN_FILE="$ROOT_DIR/config/zsh/15-platform-darwin.zsh"
LINUX_FILE="$ROOT_DIR/config/zsh/15-platform-linux.zsh"
TMUX_FILE="$ROOT_DIR/config/zsh/82-tmux.zsh"
PROMPT_FILE="$ROOT_DIR/config/zsh/50-prompt.zsh"
INIT_FILE="$ROOT_DIR/config/zsh/00-init.zsh"
FUNCTIONS_FILE="$ROOT_DIR/config/zsh/70-functions.zsh"
PECO_FILE="$ROOT_DIR/config/zsh/80-peco.zsh"
ZSHENV_FILE="$ROOT_DIR/config/zshenv"

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

assert_line_count() {
    local expected="$1"
    local needle="$2"
    local file="$3"
    local actual

    actual=$(grep -F -c -- "$needle" "$file" || true)
    if [[ "$actual" != "$expected" ]]; then
        echo "ASSERTION FAILED: expected '$needle' to appear $expected times in $file (actual: $actual)" >&2
        return 1
    fi
}

# Homebrew の prefix は 1 回だけ解決する
assert_contains 'local brew_prefix' "$ENV_FILE"
assert_line_count "1" 'brew --prefix' "$ENV_FILE"

# プラットフォーム判定は OSTYPE を使う
assert_not_contains '$(uname)' "$DARWIN_FILE"
assert_not_contains '$(uname)' "$LINUX_FILE"
assert_contains 'darwin*' "$DARWIN_FILE"
assert_contains 'linux*' "$LINUX_FILE"

# tmux の window 名更新 hook は chpwd / precmd のみ
assert_contains 'add-zsh-hook chpwd tmux-git-window-name' "$TMUX_FILE"
assert_contains 'add-zsh-hook precmd tmux-git-window-name' "$TMUX_FILE"
assert_not_contains 'add-zsh-hook preexec tmux-git-window-name' "$TMUX_FILE"

# vcs_info は git のみを有効化する
assert_contains "zstyle ':vcs_info:*' enable git" "$PROMPT_FILE"
assert_not_contains "zstyle ':vcs_info:*' enable git svn hg bzr" "$PROMPT_FILE"
assert_not_contains ":vcs_info:(svn|hg|bzr)" "$PROMPT_FILE"
assert_not_contains ":vcs_info:(svn|bzr):*" "$PROMPT_FILE"
assert_not_contains ":vcs_info:bzr:*" "$PROMPT_FILE"

# 不要な subshell test パターンを使わない
assert_contains 'if [[ -f "${HOME}/.zshrc.alias" ]]; then' "$INIT_FILE"
assert_contains 'if [[ $# -gt 0 ]]; then' "$FUNCTIONS_FILE"
assert_contains 'if [[ $# -eq 0 ]]; then' "$FUNCTIONS_FILE"
assert_contains 'if [[ -n "${BUFFER}" ]]; then' "$PECO_FILE"
assert_contains 'if [[ -n "${selected}" ]]; then' "$PECO_FILE"
assert_contains 'if [[ -n "$selected_repos" ]]; then' "$PECO_FILE"
assert_contains 'if [[ "$CODESPACES" = "true" ]]; then' "$ZSHENV_FILE"
assert_not_contains '( test' "$INIT_FILE"
assert_not_contains '( test' "$FUNCTIONS_FILE"
assert_not_contains '( test' "$PECO_FILE"
assert_not_contains '( test' "$ZSHENV_FILE"
assert_not_contains 'if [[ -n "$1" ]]; then' "$FUNCTIONS_FILE"

# epoch は引数なしでも nounset で壊れない
set +e
epoch_output="$(zsh -fc 'set -euo pipefail; function zle(){ :; }; function bindkey(){ :; }; source "$1"; epoch' _ "$FUNCTIONS_FILE" 2>&1)"
epoch_exit_code=$?
set -e
if [[ "$epoch_exit_code" != "0" ]]; then
    echo "ASSERTION FAILED: epoch should succeed without args under nounset" >&2
    echo "  output: $epoch_output" >&2
    exit 1
fi
if print -r -- "$epoch_output" | grep -F -- 'parameter not set' >/dev/null 2>&1; then
    echo "ASSERTION FAILED: epoch should not emit nounset errors" >&2
    echo "  output: $epoch_output" >&2
    exit 1
fi

echo "performance_policy_test: ok"

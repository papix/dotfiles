#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if [[ "$haystack" != *"$needle"* ]]; then
        echo "ASSERTION FAILED: $message" >&2
        echo "expected to contain: $needle" >&2
        return 1
    fi
}

zsh_output="$(env -i HOME="$TMP_HOME" PATH="/usr/bin:/bin" zsh -df -c '
    source "$1"
    printf "XDG_CACHE_HOME=%s\n" "${XDG_CACHE_HOME:-}"
    printf "XDG_STATE_HOME=%s\n" "${XDG_STATE_HOME:-}"
    printf "HISTFILE=%s\n" "${HISTFILE:-}"
    printf "HISTDIR=%s\n" "$([[ -d "${HISTFILE:h}" ]] && echo 1 || echo 0)"
    printf "DOTFILES_1PASSWORD_VAULT=%s\n" "${DOTFILES_1PASSWORD_VAULT:-}"
    printf "DOTFILES_1PASSWORD_ITEM=%s\n" "${DOTFILES_1PASSWORD_ITEM:-}"
    printf "PATH=%s\n" "$PATH"
' zsh "$ROOT_DIR/config/zshenv")"

assert_contains "$zsh_output" "XDG_CACHE_HOME=$TMP_HOME/.cache" "zshenv should set XDG_CACHE_HOME"
assert_contains "$zsh_output" "XDG_STATE_HOME=$TMP_HOME/.local/state" "zshenv should set XDG_STATE_HOME"
assert_contains "$zsh_output" "HISTFILE=$TMP_HOME/.local/state/zsh/history" "zshenv should move HISTFILE under XDG_STATE_HOME"
assert_contains "$zsh_output" "HISTDIR=1" "zshenv should create the zsh history directory"
assert_contains "$zsh_output" 'DOTFILES_1PASSWORD_VAULT=dotfiles' 'zshenv should set default 1Password vault'
assert_contains "$zsh_output" 'DOTFILES_1PASSWORD_ITEM=shared-env' 'zshenv should set default 1Password item'
assert_contains "$zsh_output" "$TMP_HOME/.local/bin" "zshenv should add local bin"

TMP_HOME_WITH_CONFIG="$(mktemp -d)"
CUSTOM_CONFIG_HOME="$TMP_HOME_WITH_CONFIG/custom-config"
mkdir -p "$CUSTOM_CONFIG_HOME"
: >"$CUSTOM_CONFIG_HOME/bash_env.sh"
trap 'rm -rf "$TMP_HOME" "$TMP_HOME_WITH_LOCAL" "$TMP_HOME_WITH_CONFIG"' EXIT

zsh_config_output="$(env -i HOME="$TMP_HOME_WITH_CONFIG" XDG_CONFIG_HOME="$CUSTOM_CONFIG_HOME" PATH="/usr/bin:/bin" zsh -df -c '
    source "$1/config/zshenv"
    typeset -gA COMMAND_CACHE
    source "$1/config/zsh/10-env.zsh"
    printf "CLAUDE_ENV_FILE=%s\n" "${CLAUDE_ENV_FILE:-}"
    printf "BASH_ENV=%s\n" "${BASH_ENV:-}"
' zsh "$ROOT_DIR")"

assert_contains "$zsh_config_output" "CLAUDE_ENV_FILE=$CUSTOM_CONFIG_HOME/claude_env.sh" "zshenv should point CLAUDE_ENV_FILE at XDG_CONFIG_HOME"
assert_contains "$zsh_config_output" "BASH_ENV=$CUSTOM_CONFIG_HOME/bash_env.sh" "10-env.zsh should point BASH_ENV at XDG_CONFIG_HOME"

TMP_HOME_WITH_LOCAL="$(mktemp -d)"
printf 'export XDG_STATE_HOME=%s\n' "$TMP_HOME_WITH_LOCAL/custom-state" >"$TMP_HOME_WITH_LOCAL/.zshenv.local"

zsh_local_output="$(env -i HOME="$TMP_HOME_WITH_LOCAL" PATH="/usr/bin:/bin" zsh -df -c '
    source "$1"
    printf "XDG_STATE_HOME=%s\n" "${XDG_STATE_HOME:-}"
    printf "HISTFILE=%s\n" "${HISTFILE:-}"
    printf "HISTDIR=%s\n" "$([[ -d "${HISTFILE:h}" ]] && echo 1 || echo 0)"
' zsh "$ROOT_DIR/config/zshenv")"

assert_contains "$zsh_local_output" "XDG_STATE_HOME=$TMP_HOME_WITH_LOCAL/custom-state" "zshenv should honor XDG_STATE_HOME from .zshenv.local"
assert_contains "$zsh_local_output" "HISTFILE=$TMP_HOME_WITH_LOCAL/custom-state/zsh/history" "zshenv should recompute HISTFILE after loading .zshenv.local"
assert_contains "$zsh_local_output" "HISTDIR=1" "zshenv should create the overridden history directory"

echo "xdg_paths_test: ok"

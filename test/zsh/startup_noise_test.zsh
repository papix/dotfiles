#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
AI_MODULE_FILE="$ROOT_DIR/config/zsh/84-ai-cli.zsh"
TMUX_MODULE_FILE="$ROOT_DIR/config/zsh/82-tmux.zsh"
ENV_MODULE_FILE="$ROOT_DIR/config/zsh/10-env.zsh"

function assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    if [[ "$expected" != "$actual" ]]; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  expected: ${expected}" >&2
        echo "  actual  : ${actual}" >&2
        return 1
    fi
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

ai_output="$(env -i HOME="$HOME" PATH="$PATH" XDG_CONFIG_HOME="$tmp_dir" AI_MODULE_FILE="$AI_MODULE_FILE" zsh -dfi -c '
    config_home=/tmp/existing
    source "$AI_MODULE_FILE"
' 2>&1)"
assert_eq "" "$ai_output" "84-ai-cli.zsh should not emit variable declarations when config_home already exists"

tmux_output="$(env -i HOME="$HOME" PATH="$PATH" XDG_CONFIG_HOME="$tmp_dir" TMUX=1 TMUX_MODULE_FILE="$TMUX_MODULE_FILE" zsh -dfi -c '
    config_home=/tmp/existing
    source "$TMUX_MODULE_FILE"
' 2>&1)"
assert_eq "" "$tmux_output" "82-tmux.zsh should not emit variable declarations when config_home already exists"

env_output="$(env -i HOME="$HOME" PATH="/usr/bin:/bin" ENV_MODULE_FILE="$ENV_MODULE_FILE" zsh -df -c '
    typeset -gA COMMAND_CACHE
    zsh_completion_dir=/tmp/existing
    brew_prefix=/tmp/existing
    source "$ENV_MODULE_FILE"
' 2>&1)"
assert_eq "" "$env_output" "10-env.zsh should not emit variable declarations when temporary globals already exist"

echo "startup_noise_test: ok"

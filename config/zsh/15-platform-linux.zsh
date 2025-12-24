#!/usr/bin/env zsh
########################################
# Linux固有設定
########################################

# Linuxでのみ読み込み
[[ "$(uname)" != "Linux" ]] && return

# Linux固有エイリアス
alias ls='ls --color'

# Linux Homebrew設定（存在する場合）
if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -d "$HOME/.linuxbrew" ]]; then
    eval "$($HOME/.linuxbrew/bin/brew shellenv)"
fi
if (( $+functions[ensure_nodenv_shims_first] )); then
    ensure_nodenv_shims_first
fi

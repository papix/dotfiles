#!/usr/bin/env zsh
########################################
# Linux固有設定
########################################

# Linuxでのみ読み込み
[[ "$OSTYPE" != linux* ]] && return

# Linux固有エイリアス
alias ls='ls --color'

# Linux Homebrew設定（存在する場合）
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# brew shellenv がPATH先頭にHomebrewを追加するため、mise shimsを再先頭に配置
# （mise activate / mise shims がHomebrewより優先されるようにする）
if [[ -d "${HOME}/.local/share/mise/shims" ]]; then
    typeset -gx -U path
    path=("${HOME}/.local/share/mise/shims" ${path})
fi

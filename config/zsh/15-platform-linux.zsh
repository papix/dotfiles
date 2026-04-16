#!/usr/bin/env zsh
########################################
# Linux固有設定
########################################

# Linuxでのみ読み込み
[[ "$OSTYPE" != linux* ]] && return

# Linux固有エイリアス
alias ls='ls --color'

# Linux Homebrew設定（存在する場合）
# brew shellenv の出力は静的なため、brew バイナリより新しいキャッシュがあればスキップ
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    _dotfiles_brew_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/brew-shellenv-linux"
    _dotfiles_brew_cache_tmp="${_dotfiles_brew_cache}.tmp.$$"
    if [[ ! -f "$_dotfiles_brew_cache" || "/home/linuxbrew/.linuxbrew/bin/brew" -nt "$_dotfiles_brew_cache" ]]; then
        mkdir -p "${_dotfiles_brew_cache:h}"
        if /home/linuxbrew/.linuxbrew/bin/brew shellenv >"$_dotfiles_brew_cache_tmp"; then
            mv "$_dotfiles_brew_cache_tmp" "$_dotfiles_brew_cache"
        else
            rm -f "$_dotfiles_brew_cache_tmp"
        fi
    fi
    [[ -f "$_dotfiles_brew_cache" ]] && source "$_dotfiles_brew_cache"
    unset _dotfiles_brew_cache
    unset _dotfiles_brew_cache_tmp
fi

# brew shellenv がPATH先頭にHomebrewを追加するため、mise shimsを再先頭に配置
# （mise activate / mise shims がHomebrewより優先されるようにする）
if [[ -d "${HOME}/.local/share/mise/shims" ]]; then
    typeset -gx -U path
    path=("${HOME}/.local/share/mise/shims" ${path})
fi

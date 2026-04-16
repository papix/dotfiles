#!/usr/bin/env zsh
########################################
# Darwin (macOS) 固有設定
########################################
# 依存: 00-init.zsh (COMMAND_CACHEのため)

# macOSでのみ読み込み
[[ "$OSTYPE" != darwin* ]] && return

# Homebrew設定（Apple Silicon / Intel Mac対応）
# brew shellenv の出力はインストールパスが変わらない限り静的なため、
# brew バイナリより新しいキャッシュがある場合はサブプロセスをスキップする
_dotfiles_brew_bin=""
_dotfiles_brew_cache_key=""
if [[ -x /opt/homebrew/bin/brew ]]; then
    _dotfiles_brew_bin=/opt/homebrew/bin/brew
    _dotfiles_brew_cache_key=opt-homebrew
elif [[ -x /usr/local/bin/brew ]]; then
    _dotfiles_brew_bin=/usr/local/bin/brew
    _dotfiles_brew_cache_key=usr-local
fi
if [[ -n "$_dotfiles_brew_bin" ]]; then
    _dotfiles_brew_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/brew-shellenv-darwin-${_dotfiles_brew_cache_key}"
    _dotfiles_brew_cache_tmp="${_dotfiles_brew_cache}.tmp.$$"
    if [[ ! -f "$_dotfiles_brew_cache" || "$_dotfiles_brew_bin" -nt "$_dotfiles_brew_cache" ]]; then
        mkdir -p "${_dotfiles_brew_cache:h}"
        if "$_dotfiles_brew_bin" shellenv >"$_dotfiles_brew_cache_tmp"; then
            mv "$_dotfiles_brew_cache_tmp" "$_dotfiles_brew_cache"
        else
            rm -f "$_dotfiles_brew_cache_tmp"
        fi
    fi
    [[ -f "$_dotfiles_brew_cache" ]] && source "$_dotfiles_brew_cache"
    unset _dotfiles_brew_cache
    unset _dotfiles_brew_cache_tmp
fi
unset _dotfiles_brew_bin
unset _dotfiles_brew_cache_key

# macOS specific aliases
alias bell='afplay /System/Library/Sounds/Hero.aiff'

# Use GNU ls if available
if [[ -n "$COMMAND_CACHE[gls]" ]]; then
    alias ls='gls --color'
else
    alias ls='ls -G'
fi

# Use GNU sed if available
if [[ -n "$COMMAND_CACHE[gsed]" ]]; then
    alias sed='gsed'
fi

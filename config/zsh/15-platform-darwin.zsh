#!/usr/bin/env zsh
########################################
# Darwin (macOS) 固有設定
########################################
# 依存: 00-init.zsh (COMMAND_CACHEのため)

# macOSでのみ読み込み
[[ "$OSTYPE" != darwin* ]] && return

# Homebrew設定（Apple Silicon / Intel Mac対応）
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

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

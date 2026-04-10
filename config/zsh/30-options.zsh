#!/usr/bin/env zsh
########################################
# シェルオプション
########################################

# ビープ音を無効化
setopt nobeep
setopt nolistbeep
setopt ignoreeof

# Viモード
bindkey -v

# 履歴用のキーバインディング
bindkey '^k' up-line-or-history
bindkey '^j' down-line-or-history

# 履歴オプション
setopt extended_history
setopt hist_expand
setopt hist_ignore_all_dups
setopt hist_expire_dups_first
setopt hist_ignore_space
setopt hist_no_store
setopt hist_verify
setopt share_history
setopt hist_reduce_blanks

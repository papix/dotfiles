#!/usr/bin/env zsh
########################################
# シェルオプション
########################################

# ref: http://karur4n.hatenablog.com/entry/2016/01/18/100000
setopt no_global_rcs

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
setopt hist_no_store
setopt share_history
setopt hist_reduce_blanks
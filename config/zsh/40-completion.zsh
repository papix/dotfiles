#!/usr/bin/env zsh
########################################
# 補完設定
########################################

zmodload zsh/complist
autoload -Uz compinit

typeset -g ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
typeset -g ZSH_COMPLETION_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompcache"
if [[ ! -d "${ZSH_COMPDUMP:h}" ]]; then
    mkdir -p "${ZSH_COMPDUMP:h}" 2>/dev/null
fi
if [[ ! -d "${ZSH_COMPLETION_CACHE_DIR}" ]]; then
    mkdir -p "${ZSH_COMPLETION_CACHE_DIR}" 2>/dev/null
fi
# compinit 自身が dump を再利用しつつ、completion ファイル数の変化は検知して再生成する。
compinit -d "${ZSH_COMPDUMP}"

# 補完オプション
setopt auto_list
setopt auto_menu
setopt auto_param_slash
setopt auto_pushd
setopt correct
setopt list_packed
setopt list_types
setopt magic_equal_subst
setopt pushd_ignore_dups

# 補完スタイル
zstyle ':completion:*:default' menu select
zstyle ':completion:*' list-separator '=>'
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${ZSH_COMPLETION_CACHE_DIR}"
zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*' list-colors 'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'

# 詳細な補完
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _match _prefix _list _approximate
zstyle ':completion:*:messages' format '%F{yellow}%d'${DEFAULT}
zstyle ':completion:*:warnings' format '%F{red}No matches for:''%F{yellow} %d'${DEFAULT}
zstyle ':completion:*:corrections' format '%F{yellow}%d ''%F{red}(errors: %e)%b'${DEFAULT}
zstyle ':completion:*:descriptions' format '%F{yellow}completing %B%d%b'${DEFAULT}
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*' group-name ''

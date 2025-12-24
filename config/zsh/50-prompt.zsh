#!/usr/bin/env zsh
########################################
# プロンプト設定
########################################
# 依存: 20-colors.zsh (カラー定義のため)

setopt prompt_subst

autoload -Uz add-zsh-hook
autoload -Uz vcs_info
autoload -Uz is-at-least

# プロンプト定義
PROMPT="${SOLARIZED_BLUE}[%1v]${RESET} ${SOLARIZED_GREEN}%~${RESET}
$ "
PROMPT2='> '
SPROMPT='"%r" is correct? ([y]es, [N]o, [a]bort, [e]dit):'

# コマンド実行前のフック
precmd() {
  psvar=()
  
  psvar[1]='papix'
  vcs_info
  [[ -n "${vcs_info_msg_0_}" ]] && psvar[2]="${vcs_info_msg_0_}"
}

# 右プロンプト
RPROMPT="%2(v|${SOLARIZED_YELLOW}%2v${RESET}|)"

# VCS情報設定
# ref: http://mollifier.hatenablog.com/entry/20100906/p1
zstyle ':vcs_info:*' enable git svn hg bzr

# Git固有設定
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' formats '[%b%c%u]'
zstyle ':vcs_info:git:*' actionformats '[%b|%a%c%u]'
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' unstagedstr '-'

# その他のVCS
zstyle ':vcs_info:(svn|hg|bzr)' formats '(%s)[%b]'
zstyle ':vcs_info:(svn|hg|bzr)' actionformats '(%s)[%b|%a]'
zstyle ':vcs_info:(svn|bzr):*' branchformat '%b:r%r'
zstyle ':vcs_info:bzr:*' use-simple true
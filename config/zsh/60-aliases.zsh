#!/usr/bin/env zsh
########################################
# エイリアス
########################################
# 依存: 15-platform-*.zsh (lsエイリアスのため)

alias ll='ls -l'
alias la='ls -al'

# エディタ
# vim/viのエイリアスは80-editor.zshで関数として実装

# git
alias g='git'
alias gi='git init'

alias gaa='git add -A'
alias gcl='git reset HEAD'
alias gco='git commit'
alias gcoa='git commit --amend'
alias gcoe='git commit --allow-empty'

alias grs='git restore --staged .'

alias gb='git branch'
alias gbd='git branch -d'
alias gbc='git checkout -b'

alias gc='git checkout'
alias gcm='git-checkout-main'

alias gme='git merge'
alias gre='git rebase'

alias gs='git status'
alias gst='git status'

alias gd='git diff'
alias gdh='git diff HEAD~ HEAD'
alias gbl='git blame'

alias gps='git push'
alias gpso='git push --set-upstream origin HEAD'
alias gpsf='git push --force-with-lease'

alias gf='git fetch'
alias gpl='git pull'
alias gplr='git pull --rebase'

alias grau='git remote add upstream'

# upstreamのデフォルトブランチを動的に取得してpull
# ローカルのsymbolic-refを優先（高速）、なければmainにフォールバック
gplu() {
  local branch
  branch=$(git symbolic-ref refs/remotes/upstream/HEAD 2>/dev/null | sed 's@^refs/remotes/upstream/@@')
  git pull upstream "${branch:-main}"
}

# Perl
alias cpan='cpanm'

alias cm='cpanm'
alias cmu='cpanm -U'
alias cmi='cpanm --installdeps .'

alias pr='prove'
alias ci='carton install'
alias ce='carton exec -- '
alias cep='carton exec -- perl -Ilib'
alias cepr='carton exec -- prove'

if [[ -n "$COMMAND_CACHE[cpandoc]" ]]; then
  alias perldoc='cpandoc'
fi

# その他
alias cl='clear'
alias pd='popd'

alias ag='ag -S'
alias tree='tree -N'

if [[ -n "$COMMAND_CACHE[tldr]" ]]; then
  alias man='tldr'
fi

if [[ -n "$COMMAND_CACHE[colordiff]" ]]; then
  alias diff='colordiff -u'
fi

if [[ -n "$COMMAND_CACHE[gsed]" ]]; then
  alias sed='gsed'
fi

alias gip='curl -s ifconfig.me'
alias lo='exit 0'

# nodenv優先設定
# HomebrewのNodeよりもnodenvのNodeを優先させる
if [[ -d "${HOME}/.anyenv/envs/nodenv/shims" ]]; then
  alias node="${HOME}/.anyenv/envs/nodenv/shims/node"
  alias npm="${HOME}/.anyenv/envs/nodenv/shims/npm"
  alias npx="${HOME}/.anyenv/envs/nodenv/shims/npx"
  alias yarn="${HOME}/.anyenv/envs/nodenv/shims/yarn"
  alias pnpm="${HOME}/.anyenv/envs/nodenv/shims/pnpm"
fi

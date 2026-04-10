#!/usr/bin/env zsh
########################################
# anyenv
########################################

# anyenv の公式初期化を通して各 **env の shims を有効化する
if command -v anyenv >/dev/null 2>&1; then
    eval "$(anyenv init -)"
fi

# anyenv init は各 **env の shims を PATH 先頭へ追加するため、
# 既存方針どおり mise shims を最優先に戻す
if [[ -d "${HOME}/.local/share/mise/shims" ]]; then
    typeset -gx -U path
    path=("${HOME}/.local/share/mise/shims" ${path})
fi

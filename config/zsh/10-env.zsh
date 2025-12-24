#!/usr/bin/env zsh
########################################
# 環境と外部ツール
########################################
# 依存: 00-init.zsh (COMMAND_CACHEのため)

# nodenvのshimsをPATH先頭に固定する
ensure_nodenv_shims_first() {
    local nodenv_shims

    # anyenv経由、直接インストール、Homebrewインストールを検出
    if [[ -d "${HOME}/.anyenv/envs/nodenv/shims" ]]; then
        nodenv_shims="${HOME}/.anyenv/envs/nodenv/shims"
    elif [[ -d "${HOME}/.nodenv/shims" ]]; then
        nodenv_shims="${HOME}/.nodenv/shims"
    elif [[ -d "/opt/homebrew/opt/nodenv/shims" ]]; then
        nodenv_shims="/opt/homebrew/opt/nodenv/shims"
    else
        return
    fi

    # 既に先頭にある場合はスキップ
    [[ "${path[1]}" == "${nodenv_shims}" ]] && return

    # 既存のエントリを除去してから先頭に配置
    path=(${path:#${nodenv_shims}})
    path=(${nodenv_shims} ${path})
}

# anyenv
if [[ -n "$COMMAND_CACHE[anyenv]" ]]; then
    # anyenvの初期化
    # --no-rehashオプションでrehashをスキップ（高速化）
    eval "$(anyenv init - --no-rehash)"
    # anyenv initがnodenvも初期化するため、重複呼び出しは不要
    # PATH順序のみ調整
    ensure_nodenv_shims_first
fi

# direnv
if [[ -n "$COMMAND_CACHE[direnv]" ]]; then
    eval "$(direnv hook zsh)"
fi

# Homebrew補完
if [[ -n "$COMMAND_CACHE[brew]" ]]; then
    typeset -gx -U fpath
    fpath=(
        $(brew --prefix)/share/zsh/site-functions(N-/)
        $(brew --prefix)/share/zsh-completions(N-/)
        ${fpath}
    )
fi

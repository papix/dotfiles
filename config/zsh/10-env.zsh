#!/usr/bin/env zsh
########################################
# 環境と外部ツール
########################################
# 依存: 00-init.zsh (COMMAND_CACHEのため)

# mise (ツールバージョン管理)
if [[ -n "$COMMAND_CACHE[mise]" ]]; then
    eval "$(mise activate zsh)"
fi

# direnv
if [[ -n "$COMMAND_CACHE[direnv]" ]]; then
    eval "$(direnv hook zsh)"
fi

# Homebrew補完
if [[ -n "$COMMAND_CACHE[brew]" ]]; then
    local brew_prefix
    brew_prefix="$(brew --prefix 2>/dev/null || true)"
    if [[ -n "$brew_prefix" ]]; then
        typeset -gx -U fpath
        fpath=(
            ${brew_prefix}/share/zsh/site-functions(N-/)
            ${brew_prefix}/share/zsh-completions(N-/)
            ${fpath}
        )
    fi
fi

# BASH_ENV 設定（非インタラクティブ bash 用）
if [[ -z "$BASH_ENV" && -f "$HOME/.config/bash_env.sh" ]]; then
    export BASH_ENV="$HOME/.config/bash_env.sh"
fi

# NPM_TOKEN キャッシュ（gh auth token の結果を ~/.cache/npm-token に保存）
if [[ -z "$NPM_TOKEN" ]]; then
    local npm_token_cache="$HOME/.cache/npm-token"
    # キャッシュ更新: gh コマンドがある場合のみ
    if [[ -n "$COMMAND_CACHE[gh]" ]]; then
        local need_refresh=0
        if [[ ! -f "$npm_token_cache" ]]; then
            need_refresh=1
        elif [[ -n "$(find "$npm_token_cache" -mmin +1440 2>/dev/null)" ]]; then
            need_refresh=1
        fi
        if (( need_refresh )); then
            local token
            token="$(gh auth token 2>/dev/null)"
            if [[ -n "$token" ]]; then
                mkdir -p "${npm_token_cache:h}"
                local old_umask
                old_umask="$(umask)"
                umask 077
                print -n "$token" > "$npm_token_cache"
                umask "$old_umask"
            fi
        fi
    fi
    # キャッシュから読み込み
    if [[ -f "$npm_token_cache" ]]; then
        export NPM_TOKEN="$(< "$npm_token_cache")"
    fi
fi

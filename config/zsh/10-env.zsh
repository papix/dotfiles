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
local zsh_completion_dir
zsh_completion_dir="${${(%):-%x}:A:h}/completions"
typeset -gx -U fpath
fpath=(
    ${zsh_completion_dir}(N-/)
    ${fpath}
)

if [[ -n "$COMMAND_CACHE[brew]" ]]; then
    local brew_prefix
    brew_prefix="$(brew --prefix 2>/dev/null || true)"
    if [[ -n "$brew_prefix" ]]; then
        fpath=(
            ${brew_prefix}/share/zsh/site-functions(N-/)
            ${brew_prefix}/share/zsh-completions(N-/)
            ${fpath}
        )
    fi
fi

# BASH_ENV 設定（非インタラクティブ bash 用）
if [[ -z "$BASH_ENV" && -f "${XDG_CONFIG_HOME:-$HOME/.config}/bash_env.sh" ]]; then
    export BASH_ENV="${XDG_CONFIG_HOME:-$HOME/.config}/bash_env.sh"
fi

function __dotfiles_npm_token_cache_path() {
    print -r -- "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/npm-token"
}

function __dotfiles_file_age_seconds() {
    local target_file="$1"
    local now_epoch mtime

    now_epoch="$(date +%s)"
    mtime="$(stat -c %Y "$target_file" 2>/dev/null || stat -f %m "$target_file" 2>/dev/null || print -r -- 0)"
    [[ "$mtime" -gt 0 ]] 2>/dev/null || return 1
    print -r -- "$((now_epoch - mtime))"
}

function __dotfiles_write_secret_cache() {
    local cache_file="$1"
    local secret_value="$2"
    local old_umask

    mkdir -p "${cache_file:h}"
    old_umask="$(umask)"
    umask 077
    print -n -- "$secret_value" >"$cache_file"
    umask "$old_umask"
}

function __dotfiles_load_npm_token_from_1password() {
    local token=""
    local token_cache=""

    [[ -n "$COMMAND_CACHE[op]" ]] || return 1

    token="$(op read "op://${DOTFILES_1PASSWORD_VAULT:-dotfiles}/${DOTFILES_1PASSWORD_ITEM:-shared-env}/NPM_TOKEN" 2>/dev/null)" || return 1
    [[ -n "$token" ]] || return 1

    export NPM_TOKEN="$token"
    token_cache="$(__dotfiles_npm_token_cache_path)"
    __dotfiles_write_secret_cache "$token_cache" "$token"
    return 0
}

function __dotfiles_load_npm_token_from_cache() {
    local token_cache=""

    token_cache="$(__dotfiles_npm_token_cache_path)"
    [[ -f "$token_cache" ]] || return 1

    export NPM_TOKEN="$(<"$token_cache")"
}

function __dotfiles_refresh_npm_token_cache_from_gh() {
    local token_cache=""
    local need_refresh=0
    local token=""
    local cache_age_seconds=""

    [[ -n "$COMMAND_CACHE[gh]" ]] || return 1

    token_cache="$(__dotfiles_npm_token_cache_path)"
    if [[ ! -f "$token_cache" ]]; then
        need_refresh=1
    else
        cache_age_seconds="$(__dotfiles_file_age_seconds "$token_cache" 2>/dev/null || print -r -- 999999999)"
        if [[ "$cache_age_seconds" -gt 86400 ]]; then
            need_refresh=1
        fi
    fi

    ((need_refresh)) || return 1

    token="$(gh auth token 2>/dev/null)" || return 1
    [[ -n "$token" ]] || return 1

    __dotfiles_write_secret_cache "$token_cache" "$token"
    return 0
}

# 対話シェル起動時に 1Password 認証プロンプトを出さないよう、
# zsh 起動では既存キャッシュ/gh auth token のみを使う
if [[ -z "$NPM_TOKEN" ]]; then
    __dotfiles_refresh_npm_token_cache_from_gh ||
        __dotfiles_load_npm_token_from_cache ||
        true
    [[ -n "$NPM_TOKEN" ]] || __dotfiles_load_npm_token_from_cache || true
fi

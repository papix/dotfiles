#!/usr/bin/env bash
########################################
# 非インタラクティブ bash 用の環境設定
########################################
# Claude Code (Codex) などで Node.js コマンドを利用可能にする
# 使用例: export BASH_ENV="$HOME/.config/bash_env.sh"

dotfiles_env_common="${XDG_CONFIG_HOME:-$HOME/.config}/env-common.sh"
dotfiles_env_file="${BASH_ENV:-}"

# 既存の ~/.config/bash_env.sh シンボリックリンク利用者向けに、
# env-common.sh が未配置でもリンク先の隣から共有ロジックを解決する
if [ ! -f "$dotfiles_env_common" ] && [ -n "$dotfiles_env_file" ]; then
    if [ -L "$dotfiles_env_file" ]; then
        dotfiles_env_link_target="$(readlink "$dotfiles_env_file" 2>/dev/null || printf '')"
        if [ -n "$dotfiles_env_link_target" ]; then
            case "$dotfiles_env_link_target" in
            /*) dotfiles_env_file="$dotfiles_env_link_target" ;;
            *) dotfiles_env_file="$(dirname "$dotfiles_env_file")/$dotfiles_env_link_target" ;;
            esac
        fi
    fi
    dotfiles_env_common="$(dirname "$dotfiles_env_file")/env-common.sh"
fi

# env-common.sh が未配置でも非対話 shell 自体は継続させる
if [ -r "$dotfiles_env_common" ]; then
    # shellcheck disable=SC1090
    . "$dotfiles_env_common"
fi

unset dotfiles_env_common
unset dotfiles_env_file
unset dotfiles_env_link_target

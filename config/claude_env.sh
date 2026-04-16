#!/bin/sh
# Claude Code 用の環境変数設定
#
# このファイルは Claude Code の各コマンド実行前に source される。
# CLAUDE_ENV_FILE 環境変数で指定する。
#
# 参考: https://code.claude.com/docs/en/settings
#
# 注意: POSIX sh 互換で記述（Claude Code が /bin/sh 経由で source する可能性があるため）

dotfiles_env_common="${XDG_CONFIG_HOME:-$HOME/.config}/env-common.sh"
dotfiles_env_file="${CLAUDE_ENV_FILE:-}"

# 既存の ~/.config/claude_env.sh シンボリックリンク利用者向けに、
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

# env-common.sh が未配置でも Claude 実行自体は継続させる
if [ -r "$dotfiles_env_common" ]; then
    # shellcheck disable=SC1090
    . "$dotfiles_env_common"
fi

unset dotfiles_env_common
unset dotfiles_env_file
unset dotfiles_env_link_target

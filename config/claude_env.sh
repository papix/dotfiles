#!/bin/sh
# Claude Code 用の環境変数設定
#
# このファイルは Claude Code の各コマンド実行前に source される。
# CLAUDE_ENV_FILE 環境変数で指定する。
#
# 参考: https://code.claude.com/docs/en/settings
#
# 注意: POSIX sh 互換で記述（Claude Code が /bin/sh 経由で source する可能性があるため）

# anyenv の実行ファイルと shims を利用可能にする
if [ -z "${ANYENV_ROOT:-}" ]; then
    export ANYENV_ROOT="$HOME/.anyenv"
fi
anyenv_bin_dir=""
for anyenv_cmd in "$ANYENV_ROOT/bin/anyenv" /opt/homebrew/bin/anyenv /usr/local/bin/anyenv /home/linuxbrew/.linuxbrew/bin/anyenv; do
    if [ -x "$anyenv_cmd" ]; then
        anyenv_bin_dir=${anyenv_cmd%/anyenv}
        break
    fi
done
if [ -n "$anyenv_bin_dir" ]; then
    case "$PATH" in
    "$anyenv_bin_dir":*) ;;
    *) export PATH="$anyenv_bin_dir:$PATH" ;;
    esac
fi
if [ -d "$ANYENV_ROOT/shims" ]; then
    case "$PATH" in
    "$ANYENV_ROOT/shims":*) ;;
    *) export PATH="$ANYENV_ROOT/shims:$PATH" ;;
    esac
fi
if [ -d "$ANYENV_ROOT/envs" ]; then
    # anyenv 配下の各 env に対応する *_ROOT と bin/shims を追加する
    for anyenv_env_root in "$ANYENV_ROOT"/envs/*; do
        [ -d "$anyenv_env_root" ] || continue
        anyenv_env_name="${anyenv_env_root##*/}"
        anyenv_env_var="$(printf '%s_ROOT' "$anyenv_env_name" | tr '[:lower:]-' '[:upper:]_')"
        export "$anyenv_env_var=$anyenv_env_root"
    done

    for anyenv_env_bin in "$ANYENV_ROOT"/envs/*/bin; do
        [ -d "$anyenv_env_bin" ] || continue
        case "$PATH" in
        "$anyenv_env_bin":*) ;;
        *) export PATH="$anyenv_env_bin:$PATH" ;;
        esac
    done

    for anyenv_env_shims in "$ANYENV_ROOT"/envs/*/shims; do
        [ -d "$anyenv_env_shims" ] || continue
        case "$PATH" in
        "$anyenv_env_shims":*) ;;
        *) export PATH="$anyenv_env_shims:$PATH" ;;
        esac
    done
fi

# mise shims を PATH の先頭に追加
if [ -d "$HOME/.local/share/mise/shims" ]; then
    case "$PATH" in
    "$HOME/.local/share/mise/shims":*) ;;
    *) export PATH="$HOME/.local/share/mise/shims:$PATH" ;;
    esac
fi

# Git worktree base directory
if [ -z "$WORKTREE_BASE_DIR" ]; then
    export WORKTREE_BASE_DIR="$HOME/.worktrees"
fi

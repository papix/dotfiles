#!/usr/bin/env sh
# Husky Git hooks 用の初期化スクリプト
# mise の shims を Git hooks から利用可能にする
#
# 注意: このファイルは Husky によって source されるため、
# set -eu は使用しない（他のフックに影響を与えるため）

dotfiles_prepend_path() {
    case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1${PATH:+:$PATH}" ;;
    esac
}

if [ -z "${XDG_CONFIG_HOME:-}" ]; then
    export XDG_CONFIG_HOME="$HOME/.config"
fi
if [ -z "${XDG_DATA_HOME:-}" ]; then
    export XDG_DATA_HOME="$HOME/.local/share"
fi
if [ -z "${XDG_CACHE_HOME:-}" ]; then
    export XDG_CACHE_HOME="$HOME/.cache"
fi
if [ -z "${XDG_STATE_HOME:-}" ]; then
    export XDG_STATE_HOME="$HOME/.local/state"
fi

# anyenv の実行ファイルと shims を Git hooks から利用可能にする
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
    dotfiles_prepend_path "$anyenv_bin_dir"
fi
if [ -d "$ANYENV_ROOT/shims" ]; then
    dotfiles_prepend_path "$ANYENV_ROOT/shims"
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
        dotfiles_prepend_path "$anyenv_env_bin"
    done

    for anyenv_env_shims in "$ANYENV_ROOT"/envs/*/shims; do
        [ -d "$anyenv_env_shims" ] || continue
        dotfiles_prepend_path "$anyenv_env_shims"
    done
fi

# mise の shims を Git hooks から利用可能にする
if [ -d "$HOME/.local/share/mise/shims" ]; then
    dotfiles_prepend_path "$HOME/.local/share/mise/shims"
fi

# dotfiles 管理の実行ファイルを最優先にする
dotfiles_prepend_path "$HOME/.local/bin"

export PATH

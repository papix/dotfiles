#!/bin/sh
# Claude Code 用の環境変数設定
#
# このファイルは Claude Code の各コマンド実行前に source される。
# CLAUDE_ENV_FILE 環境変数で指定する。
#
# 参考: https://code.claude.com/docs/en/settings
#
# 注意: POSIX sh 互換で記述（Claude Code が /bin/sh 経由で source する可能性があるため）

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
if [ -z "${DOTFILES_1PASSWORD_VAULT:-}" ]; then
    export DOTFILES_1PASSWORD_VAULT="dotfiles"
fi
if [ -z "${DOTFILES_1PASSWORD_ITEM:-}" ]; then
    export DOTFILES_1PASSWORD_ITEM="shared-env"
fi
if [ -z "${DOTFILES_1PASSWORD_AUTOLOAD:-}" ]; then
    export DOTFILES_1PASSWORD_AUTOLOAD="0"
fi

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

# mise shims を PATH の先頭に追加
if [ -d "$HOME/.local/share/mise/shims" ]; then
    dotfiles_prepend_path "$HOME/.local/share/mise/shims"
fi

# dotfiles 管理の実行ファイルを最優先にする
dotfiles_prepend_path "$HOME/.local/bin"

# Git worktree base directory
if [ -z "$WORKTREE_BASE_DIR" ]; then
    export WORKTREE_BASE_DIR="$HOME/.worktrees"
fi

dotfiles_npm_token_cache_path() {
    printf '%s\n' "${XDG_CACHE_HOME}/dotfiles/npm-token"
}

dotfiles_file_age_seconds() {
    target_file="$1"
    now_epoch="$(date +%s)"
    mtime="$(stat -c %Y "$target_file" 2>/dev/null || stat -f %m "$target_file" 2>/dev/null || printf '0')"

    [ "$mtime" -gt 0 ] 2>/dev/null || return 1
    printf '%s\n' "$((now_epoch - mtime))"
}

dotfiles_write_secret_cache() {
    cache_file="$1"
    secret_value="$2"
    old_umask="$(umask)"

    mkdir -p "$(dirname "$cache_file")"
    umask 077
    printf '%s' "$secret_value" >"$cache_file"
    umask "$old_umask"
}

dotfiles_load_npm_token_from_1password() {
    if ! command -v op >/dev/null 2>&1; then
        return 1
    fi

    token="$(op read "op://${DOTFILES_1PASSWORD_VAULT}/${DOTFILES_1PASSWORD_ITEM}/NPM_TOKEN" 2>/dev/null)" || return 1
    [ -n "$token" ] || return 1

    export NPM_TOKEN="$token"
    dotfiles_write_secret_cache "$(dotfiles_npm_token_cache_path)" "$token"
}

dotfiles_should_autoload_1password() {
    [ "${DOTFILES_1PASSWORD_AUTOLOAD:-0}" = "1" ]
}

dotfiles_load_npm_token_from_cache() {
    cache_file="$(dotfiles_npm_token_cache_path)"
    [ -f "$cache_file" ] || return 1
    NPM_TOKEN="$(cat "$cache_file")"
    export NPM_TOKEN
}

dotfiles_refresh_npm_token_cache_from_gh() {
    cache_age_seconds=""

    if ! command -v gh >/dev/null 2>&1; then
        return 1
    fi

    cache_file="$(dotfiles_npm_token_cache_path)"
    need_refresh=0
    if [ ! -f "$cache_file" ]; then
        need_refresh=1
    else
        cache_age_seconds="$(dotfiles_file_age_seconds "$cache_file" 2>/dev/null || printf '999999999')"
        if [ "$cache_age_seconds" -gt 86400 ]; then
            need_refresh=1
        fi
    fi
    if [ "$need_refresh" -ne 1 ]; then
        return 1
    fi

    token="$(gh auth token 2>/dev/null)" || return 1
    [ -n "$token" ] || return 1
    dotfiles_write_secret_cache "$cache_file" "$token"
}

# Claude Code の各コマンドで認証プロンプトを出さないよう、1Password 自動読込は opt-in にする
if [ -z "${NPM_TOKEN:-}" ]; then
    if dotfiles_should_autoload_1password; then
        dotfiles_load_npm_token_from_1password ||
            dotfiles_refresh_npm_token_cache_from_gh ||
            dotfiles_load_npm_token_from_cache ||
            true
    else
        dotfiles_refresh_npm_token_cache_from_gh ||
            dotfiles_load_npm_token_from_cache ||
            true
    fi
    [ -n "${NPM_TOKEN:-}" ] || dotfiles_load_npm_token_from_cache || true
fi

export PATH

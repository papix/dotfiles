#!/usr/bin/env zsh
########################################
# Tmux関数
########################################
# 依存: 00-init.zsh (COMMAND_CACHEのため)

# tmux内での追加設定
function __dotfiles_setup_tmux_hooks() {
    local config_home
    config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"

    # 新しい pane / window でも同じ PATH を引き継げるよう tmux サーバーに同期する
    command tmux set-environment -g PATH "$PATH" >/dev/null 2>&1 || true

    # tmux-git-window-name関数の読み込み
    if [[ -f "${config_home}/zsh/functions/tmux-git-window-name" ]]; then
        source "${config_home}/zsh/functions/tmux-git-window-name"
    fi

    if typeset -f tmux-git-window-name >/dev/null 2>&1; then
        # ディレクトリ変更時にwindow名を更新
        autoload -Uz add-zsh-hook
        add-zsh-hook chpwd tmux-git-window-name

        # プロンプト表示前にもwindow名を更新
        add-zsh-hook precmd tmux-git-window-name

        # 初回読み込み時に実行
        tmux-git-window-name
    fi
}

if [[ -n "${TMUX:-}" ]]; then
    __dotfiles_setup_tmux_hooks
fi
unfunction __dotfiles_setup_tmux_hooks

function current-workspace() {
    local pwd=$(pwd)
    local root=""
    if command -v ghq >/dev/null 2>&1; then
        root=$(ghq root 2>/dev/null || true)
    fi
    if [[ -z "$root" ]]; then
        echo "default"
        return
    fi

    if [[ "${pwd}" != "${root}" && "${pwd}" == "${root}"* ]]; then
        local workspace="${pwd#$root/}"
        local arr=(${(s:/:)workspace})

        local service=${arr[1]}
        local user=${arr[2]}
        local repo=${arr[3]}

        if [[ $service && $user && $repo ]]; then
            if [[ $service == "github.com" ]]; then
                echo "${user}/${repo}"
            else
                echo "${service}/${user}/${repo}"
            fi
            return
        fi
    fi
    echo "default"
}

function sanitize_tmux_session_name() {
    local name="$1"

    # tmuxのターゲット解釈で問題にならないよう安全な文字に変換
    name="${name//[^A-Za-z0-9_-]/-}"
    while [[ "$name" == *--* ]]; do
        name="${name//--/-}"
    done
    while [[ "$name" == -* ]]; do
        name="${name#-}"
    done
    while [[ "$name" == *- ]]; do
        name="${name%-}"
    done

    if [[ -z "$name" ]]; then
        name="default"
    fi
    if ((${#name} > 80)); then
        name="${name[1,80]}"
    fi

    echo "$name"
}

function resolve_tmux_session_name() {
    local workspace="$1"
    local tmux_session_name="default"
    local raw_tmux_session_name=""

    if [[ -n "${workspace}" ]]; then
        raw_tmux_session_name="$workspace"
        tmux_session_name="$(sanitize_tmux_session_name "$workspace")"
    fi

    # 旧セッション互換: 生の名前が存在すれば優先して使用
    if [[ -n "$raw_tmux_session_name" ]]; then
        if [[ "$raw_tmux_session_name" != *.* && "$raw_tmux_session_name" != *:* ]]; then
            if command tmux has-session -t "$raw_tmux_session_name" 2>/dev/null; then
                tmux_session_name="$raw_tmux_session_name"
            fi
        fi
    fi

    echo "$tmux_session_name"
}

function should_auto_start_tmux() {
    [[ -z "${DISABLE_AUTO_TMUX:-}" ]] || return 1
    [[ -z "${TMUX:-}" ]] || return 1
    [[ -z "${SSH_CONNECTION:-}" ]] || return 1
    [[ "${TERM_PROGRAM:-}" == "iTerm.app" ]] || return 1
    [[ -z "${VSCODE_INJECTION:-}" ]] || return 1
    [[ -n "${COMMAND_CACHE[tmux]:-}" ]] || return 1
    return 0
}

function auto_start_tmux_session() {
    local workspace
    workspace="$(current-workspace)"

    local tmux_session_name
    tmux_session_name="$(resolve_tmux_session_name "$workspace")"

    echo "tmux session name: $tmux_session_name"

    if command tmux has-session -t "$tmux_session_name" 2>/dev/null; then
        echo "Attaching to existing tmux session"
        command tmux attach -t "$tmux_session_name" && exit
    else
        echo "Creating new tmux session"
        command tmux new -s "$tmux_session_name" && exit
    fi
}

# tmuxの自動起動（iTerm2限定、SSH経由では無効、環境変数で無効化可能）
# 条件: iTerm2 && !SSH && !VSCode && !Cursor && !tmux内 && !DISABLE_AUTO_TMUX && tmuxコマンド存在
if should_auto_start_tmux; then
    auto_start_tmux_session
fi

# tmuxコマンドのラッパー関数
# 引数なしで実行時、既存セッションがあれば自動attach
# 参考: https://qiita.com/kawaz/items/0cd28a955205c79ec7e3
# 条件: インタラクティブシェル && tmux外 && tmuxコマンド存在
if [[ -n "${PS1:-}" ]] && [[ -z "${TMUX:-}" ]] && type tmux >/dev/null 2>&1; then
    function tmux() {
        if [[ $# == 0 ]] && command tmux has-session 2>/dev/null; then
            command tmux attach-session
        else
            command tmux "$@"
        fi
    }
fi

#!/usr/bin/env zsh
########################################
# Tmux関数
########################################
# 依存: 00-init.zsh (COMMAND_CACHEのため)

# tmux内での追加設定
if [[ -n "$TMUX" ]]; then
    # tmux-git-window-name関数の読み込み
    if [[ -f "${HOME}/.config/zsh/functions/tmux-git-window-name" ]]; then
        source "${HOME}/.config/zsh/functions/tmux-git-window-name"
    fi

    if (( $+functions[tmux-git-window-name] )); then
        # ディレクトリ変更時にwindow名を更新
        autoload -Uz add-zsh-hook
        add-zsh-hook chpwd tmux-git-window-name
        
        # プロンプト表示前にもwindow名を更新
        add-zsh-hook precmd tmux-git-window-name
        
        # 初回読み込み時に実行
        tmux-git-window-name
    fi
fi

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
    if (( ${#name} > 80 )); then
        name="${name[1,80]}"
    fi

    echo "$name"
}

# tmuxの自動起動（iTerm2限定、SSH経由では無効、環境変数で無効化可能）
# 条件: iTerm2 && !SSH && !VSCode && !Cursor && !tmux内 && !DISABLE_AUTO_TMUX && tmuxコマンド存在
if [[ -z "$DISABLE_AUTO_TMUX" ]] && \
   [[ -z "$TMUX" ]] && \
   [[ -z "$SSH_CONNECTION" ]] && \
   [[ "$TERM_PROGRAM" == "iTerm.app" ]] && \
   [[ -z "$VSCODE_INJECTION" ]] && \
   [[ -n "$COMMAND_CACHE[tmux]" ]]; then
    
    workspace=$(current-workspace)

    tmux_session_name="default"
    raw_tmux_session_name=""
    if ( test -n "${workspace}" ); then
        raw_tmux_session_name="$workspace"
        tmux_session_name=$(sanitize_tmux_session_name "$workspace")
    fi

    # 旧セッション互換: 生の名前が存在すれば優先して使用
    if [[ -n "$raw_tmux_session_name" ]]; then
        if [[ "$raw_tmux_session_name" != *.* && "$raw_tmux_session_name" != *:* ]]; then
            if command tmux has-session -t "$raw_tmux_session_name" 2>/dev/null; then
                tmux_session_name="$raw_tmux_session_name"
            fi
        fi
    fi

    echo "tmux session name: $tmux_session_name"

    if command tmux has-session -t "$tmux_session_name" 2>/dev/null; then
        echo "Attaching to existing tmux session"
        tmux attach -t "$tmux_session_name" && exit
    else
        echo "Creating new tmux session"
        tmux new -s "$tmux_session_name" && exit
    fi
fi

# tmuxコマンドのラッパー関数
# 引数なしで実行時、既存セッションがあれば自動attach
# 参考: https://qiita.com/kawaz/items/0cd28a955205c79ec7e3
# 条件: インタラクティブシェル && tmux外 && tmuxコマンド存在
if [[ -n "$PS1" ]] && [[ -z "$TMUX" ]] && type tmux > /dev/null 2>&1; then
    function tmux() {
        if [[ $# == 0 ]] && command tmux has-session 2>/dev/null; then
            command tmux attach-session
        else
            command tmux "$@"
        fi
    }
fi

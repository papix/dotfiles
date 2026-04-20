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

# AIツール用ワークスペースを一発構築するコマンド
# `work` 単体: peco + ghq でリポジトリを選択し、3分割ウィンドウで claude / codex を起動する
# `work new <branch>`: 現在のリポジトリから worktree を作成し、その worktree を tmux で開く
# `work prune`: 不要になった worktree を対話的に削除する
function work-open-window() {
    local target_dir="$1"
    if [[ -z "${TMUX:-}" ]]; then
        echo "Error: work must be run inside tmux" >&2
        return 1
    fi
    if [[ -z "$target_dir" || ! -d "$target_dir" ]]; then
        echo "Error: target directory not found" >&2
        return 1
    fi

    local left_pane
    left_pane=$(tmux new-window -c "$target_dir" -P -F '#{pane_id}')

    local right_top_pane
    right_top_pane=$(tmux split-window -t "$left_pane" -hc "$target_dir" -P -F '#{pane_id}')

    tmux split-window -t "$right_top_pane" -vc "$target_dir" >/dev/null
    tmux resize-pane -t "$left_pane" -x '60%'

    # コマンド起動（send-keys で実行すると終了後もシェルに戻れる）
    tmux send-keys -t "$left_pane" 'claude --allow-dangerously-skip-permissions' Enter
    tmux send-keys -t "$right_top_pane" 'codex --dangerously-bypass-approvals-and-sandbox' Enter

    tmux select-pane -t "$left_pane"
}

function work-select-repo() {
    for cmd in ghq peco roots; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Error: $cmd command not found" >&2
            return 1
        fi
    done

    ghq list --full-path | roots | grep -v "/.next" | peco --prompt 'AI WORKSPACE >' | head -n 1
}

function work-default-start-point() {
    local default_branch
    default_branch="$(git-default-branch)"

    if git show-ref --verify --quiet "refs/remotes/origin/${default_branch}"; then
        echo "refs/remotes/origin/${default_branch}"
        return 0
    fi
    if git show-ref --verify --quiet "refs/heads/${default_branch}"; then
        echo "${default_branch}"
        return 0
    fi

    echo "HEAD"
}

function work-remote-relative-path() {
    local remote_url="$1"
    local normalized="${remote_url%.git}"

    case "$normalized" in
        git@*:*/*)
            local host_and_path="${normalized#git@}"
            local host="${host_and_path%%:*}"
            local path="${host_and_path#*:}"
            echo "${host}/${path}"
            return 0
            ;;
        ssh://git@*/*)
            local without_scheme="${normalized#ssh://}"
            local host_and_path="${without_scheme#git@}"
            local host="${host_and_path%%/*}"
            local path="${host_and_path#*/}"
            echo "${host}/${path}"
            return 0
            ;;
        http://*/*/*|https://*/*/*)
            local without_scheme="${normalized#*://}"
            local host="${without_scheme%%/*}"
            local path="${without_scheme#*/}"
            echo "${host}/${path}"
            return 0
            ;;
    esac

    return 1
}

function work-repository-relative-path() {
    local repo_root
    repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1

    local ghq_root=""
    if command -v ghq >/dev/null 2>&1; then
        ghq_root="$(ghq root 2>/dev/null || true)"
    fi
    if [[ -n "$ghq_root" && "$repo_root" == "${ghq_root}"/* ]]; then
        echo "${repo_root#${ghq_root}/}"
        return 0
    fi

    local remote_url=""
    remote_url="$(git remote get-url origin 2>/dev/null || true)"
    if [[ -n "$remote_url" ]]; then
        local remote_path=""
        remote_path="$(work-remote-relative-path "$remote_url" 2>/dev/null || true)"
        if [[ -n "$remote_path" ]]; then
            echo "$remote_path"
            return 0
        fi
    fi

    local repo_hash=""
    repo_hash="$(printf '%s' "$repo_root" | git hash-object --stdin 2>/dev/null || true)"
    if [[ -n "$repo_hash" ]]; then
        echo "local/$(basename "$repo_root")-${repo_hash[1,12]}"
        return 0
    fi

    echo "local/$(basename "$repo_root")"
}

function work-worktree-root-path() {
    local branch="$1"
    local worktree_base="${WORKTREE_BASE_DIR:-${HOME}/.worktrees}"
    local relative_path
    relative_path="$(work-repository-relative-path)" || return 1
    echo "${worktree_base}/${relative_path}/${branch}"
}

function work-ensure-worktree() {
    local branch="$1"
    if [[ -z "$branch" ]]; then
        echo "Usage: work new <branch>" >&2
        return 1
    fi
    if ! inside-git-repository; then
        echo "Error: work new must be run inside a git repository" >&2
        return 1
    fi

    local existing_target=""
    existing_target="$(__git_branch_target_path "$branch")"
    if [[ -n "$existing_target" && -d "$existing_target" ]]; then
        echo "$existing_target"
        return 0
    fi

    local worktree_root=""
    worktree_root="$(work-worktree-root-path "$branch")" || return 1
    mkdir -p -- "$(dirname "$worktree_root")" || return 1

    if git show-ref --verify --quiet "refs/heads/${branch}"; then
        git worktree add "$worktree_root" "$branch" >&2 || return 1
    elif git show-ref --verify --quiet "refs/remotes/origin/${branch}"; then
        git worktree add --track -b "$branch" "$worktree_root" "origin/${branch}" >&2 || return 1
    else
        local start_point=""
        start_point="$(work-default-start-point)"
        git worktree add -b "$branch" "$worktree_root" "$start_point" >&2 || return 1
    fi

    __git_target_path_for_worktree "$worktree_root"
}

function __work_managed_worktree_paths() {
    local worktree_base="${WORKTREE_BASE_DIR:-${HOME}/.worktrees}"

    [[ -d "$worktree_base" ]] || return 1

    find "$worktree_base" -type f -name .git -print 2>/dev/null \
        | while IFS= read -r git_file; do
            dirname "$git_file"
        done \
        | sort -u
}

function __work_candidate_main_repos() {
    local repo_root=""
    local -A seen_repos

    if inside-git-repository; then
        repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
        if [[ -n "$repo_root" ]]; then
            seen_repos["$repo_root"]=1
            print -r -- "$repo_root"
        fi
    fi

    if command -v ghq >/dev/null 2>&1; then
        while IFS= read -r repo_root; do
            [[ -n "$repo_root" ]] || continue
            [[ -z "${seen_repos[$repo_root]:-}" ]] || continue
            seen_repos["$repo_root"]=1
            print -r -- "$repo_root"
        done < <(ghq list --full-path 2>/dev/null || true)
    fi
}

function __work_main_worktree_for_path() {
    local worktree_path="$1"
    local common_dir=""

    common_dir="$(git -C "$worktree_path" rev-parse --git-common-dir 2>/dev/null)" || return 1
    (
        builtin cd -- "${common_dir}/.." >/dev/null 2>&1 && pwd -P
    )
}

function __work_prune_metadata_for_repo() {
    local repo_root="$1"
    shift

    [[ -n "$repo_root" && -d "$repo_root" ]] || return 1
    git -C "$repo_root" worktree prune "$@"
}

function work-new() {
    local branch="$1"
    local target_dir=""
    target_dir="$(work-ensure-worktree "$branch")" || return 1

    if [[ -n "${TMUX:-}" ]]; then
        work-open-window "$target_dir"
        return $?
    fi

    builtin cd -- "$target_dir"
}

function work-prune() {
    case "${1:-}" in
        stale)
            shift
            local repo_root=""

            while IFS= read -r repo_root; do
                [[ -n "$repo_root" ]] || continue
                __work_prune_metadata_for_repo "$repo_root" --verbose "$@" || return 1
            done < <(__work_candidate_main_repos)
            ;;
        expired)
            shift
            local repo_root=""

            while IFS= read -r repo_root; do
                [[ -n "$repo_root" ]] || continue
                __work_prune_metadata_for_repo "$repo_root" --expire now --verbose "$@" || return 1
            done < <(__work_candidate_main_repos)
            ;;
        *)
            if ! command -v peco >/dev/null 2>&1; then
                echo "Error: peco command not found" >&2
                return 1
            fi

            local selected_worktree=""
            selected_worktree="$(__work_managed_worktree_paths | peco --prompt 'WORKTREE REMOVE >' | head -n 1)"
            if [[ -z "$selected_worktree" ]]; then
                return 0
            fi

            local main_worktree=""
            main_worktree="$(__work_main_worktree_for_path "$selected_worktree")" || return 1
            git -C "$main_worktree" worktree remove "$@" "$selected_worktree"
            ;;
    esac
}

function work-help() {
    echo "Usage:"
    echo "  work                Open a repo picker and launch the AI workspace in tmux"
    echo "  work new <branch>   Create or reuse a worktree and open it"
    echo "  work prune          Remove managed worktrees interactively"
    echo "  work prune stale    Clean stale worktree metadata"
    echo "  work prune expired  Expire stale worktree metadata immediately"
}

function work() {
    case "${1:-}" in
        "")
            local selected_repo=""
            selected_repo="$(work-select-repo)" || return 1
            if [[ -z "$selected_repo" ]]; then
                return 0
            fi
            work-open-window "$selected_repo"
            ;;
        new)
            shift
            work-new "$@"
            ;;
        prune)
            shift
            work-prune "$@"
            ;;
        help|-h|--help)
            work-help
            ;;
        *)
            echo "Error: unknown subcommand: $1" >&2
            work-help >&2
            return 1
            ;;
    esac
}

#!/usr/bin/env zsh
########################################
# Git関数
########################################
# 依存: 80-peco.zsh (peco関数のため)

# Gitリポジトリ内か確認
function inside-git-repository() {
    if ( git rev-parse --is-inside-work-tree > /dev/null 2>&1 ); then
        return 0
    else
        return 1
    fi
}

# デフォルトブランチ名を取得
function git-default-branch() {
    local default=""
    # origin/HEAD が設定されていれば最優先
    default=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
    default=${default#origin/}
    if [[ -n "${default}" ]]; then
        echo "${default}"
        return
    fi

    # ローカルに存在するブランチを優先
    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
        return
    fi
    if git show-ref --verify --quiet refs/heads/master; then
        echo "master"
        return
    fi

    echo "main"
}

# ブランチに切り替え（worktree対応・サブディレクトリ維持）
# 使用法: git-switch-branch <branch-name>
# 戻り値: 成功時0、失敗時1
# 出力: worktree移動時は移動先パスを出力
function __git_branch_worktree_path() {
    local branch="$1"
    local wt_info
    wt_info=$(git worktree list --porcelain 2>/dev/null)
    local wt_path=""
    local line=""
    while IFS= read -r line; do
        case "${line}" in
            "worktree "*)
                wt_path="${line#worktree }"
                ;;
            "branch refs/heads/${branch}")
                echo "${wt_path}"
                return 0
                ;;
            "")
                wt_path=""
                ;;
        esac
    done <<< "${wt_info}"
}

function __git_target_path_for_worktree() {
    local worktree_path="$1"
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)

    local rel_path="${PWD#${repo_root}}"
    if [[ -n "${rel_path}" && -d "${worktree_path}${rel_path}" ]]; then
        echo "${worktree_path}${rel_path}"
        return 0
    fi

    echo "${worktree_path}"
}

function __git_branch_target_path() {
    local branch="$1"
    local worktree_path
    worktree_path=$(__git_branch_worktree_path "${branch}")

    if [[ -n "${worktree_path}" && -d "${worktree_path}" ]]; then
        __git_target_path_for_worktree "${worktree_path}"
    fi
}

function git-switch-branch() {
    local branch="${1:-}"
    if [[ -z "${branch}" ]]; then
        echo "Usage: git-switch-branch <branch-name>" >&2
        return 1
    fi

    local target_path
    target_path=$(__git_branch_target_path "${branch}")

    if [[ -n "${target_path}" ]]; then
        # 別のworktreeでチェックアウト済み → そのディレクトリに移動
        # 現在のサブディレクトリを維持する
        echo "${target_path}"
        builtin cd -- "${target_path}"
    else
        # 通常のチェックアウト
        git checkout "${branch}"
    fi
}

# main/masterブランチにチェックアウト
function git-checkout-main() {
    git-switch-branch "$(git-default-branch)"
}

# マージ済みブランチを削除
function git-delete-branch() {
    (
        local default=$(git-default-branch)
        local current=$(git symbolic-ref --short HEAD 2>/dev/null)
        local -a force_deletable=()
        # \t を実際のタブとして扱うため $'...' でクォートする
        local merged_info
        local -a deletable=()

        # 1. prune前にステールworktreeのブランチを収集
        local worktree_info
        worktree_info=$(git worktree list --porcelain 2>/dev/null)
        local wt_path="" wt_branch=""
        local line=""
        while IFS= read -r line; do
            case "${line}" in
                "worktree "*)
                    wt_path="${line#worktree }"
                    ;;
                "branch "*)
                    wt_branch="${line#branch refs/heads/}"
                    if [[ -n "${wt_path}" && -n "${wt_branch}" && ! -d "${wt_path}" ]]; then
                        if [[ "${wt_branch}" != "${default}" && "${wt_branch}" != "${current}" ]]; then
                            if (( ! ${force_deletable[(Ie)${wt_branch}]} )); then
                                force_deletable+=("${wt_branch}")
                            fi
                        fi
                    fi
                    wt_path=""
                    wt_branch=""
                    ;;
                "")
                    wt_path=""
                    wt_branch=""
                    ;;
            esac
        done <<< "${worktree_info}"

        # 2. ステールworktreeメタデータを掃除
        git worktree prune 2>/dev/null

        # 3. マージ済みブランチを収集
        merged_info="$(git for-each-ref --format='%(refname:short)' --merged "${default}" refs/heads 2>/dev/null)"
        local -a merged_branches=("${(f)merged_info}")
        local branch_info
        branch_info="$(git for-each-ref --format=$'%(refname:short)\t%(worktreepath)' refs/heads 2>/dev/null)"

        while IFS=$'\t' read -r branch worktree; do
            if [[ -z "${branch}" ]]; then
                continue
            fi
            if [[ "${branch}" == "${default}" || "${branch}" == "${current}" ]]; then
                continue
            fi
            if (( ${force_deletable[(Ie)${branch}]} )); then
                continue
            fi
            if [[ -z "${worktree}" ]]; then
                if (( ${merged_branches[(Ie)${branch}]} )); then
                    deletable+=("${branch}")
                fi
            fi
        done <<< "${branch_info}"

        if (( ${#deletable[@]} == 0 && ${#force_deletable[@]} == 0 )); then
            echo "No branches to delete."
            return 0
        fi

        if (( ${#deletable[@]} > 0 )); then
            echo "Merged branches to delete (-d):"
            printf "  %s\n" "${deletable[@]}"
        fi
        if (( ${#force_deletable[@]} > 0 )); then
            echo "Stale worktree branches to delete (-D):"
            printf "  %s\n" "${force_deletable[@]}"
        fi

        echo ""
        echo -n "Delete these branches? [y/N]: "
        local confirm
        read -r confirm
        if [[ "${confirm}" != [yY] ]]; then
            echo "Aborted."
            return 1
        fi

        if (( ${#deletable[@]} > 0 )); then
            git branch -d "${deletable[@]}"
        fi

        if (( ${#force_deletable[@]} > 0 )); then
            git branch -D "${force_deletable[@]}"
        fi
    )
}

# Gitルートディレクトリへ移動
function git-root() {
    if ( inside-git-repository ); then
        local root
        root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
        cd -- "$root"
    else
        echo "Not a git repository"
        return 1
    fi
}
zle -N git-root
bindkey '^p' git-root

# pecoでGitブランチを選択
function peco-branch() {
    # git for-each-ref を使用（color.branch=always のANSIコード混入を回避）
    local selected_branch=$(git for-each-ref --format='%(refname:short)' refs/heads \
        | peco --prompt "BRANCH >" | head -n 1)
    if [[ -n "${selected_branch}" ]]; then
        if [[ -n "${BUFFER}" ]]; then
            local cmd="${BUFFER%% }"
            BUFFER="${cmd} ${selected_branch}"
            CURSOR="${#BUFFER}"
        else
            local target_path
            target_path=$(__git_branch_target_path "${selected_branch}")

            if [[ -n "${target_path}" ]]; then
                if builtin cd -- "${target_path}"; then
                    zle reset-prompt
                else
                    zle -M "Failed to change directory: ${target_path}"
                    zle reset-prompt
                fi
            else
                local checkout_output
                checkout_output=$(git checkout "${selected_branch}" 2>&1)
                local exit_code=$?

                if [[ ${exit_code} -eq 0 ]]; then
                    zle reset-prompt
                else
                    # 失敗時はステータスラインにエラーを表示
                    zle -M "${checkout_output}"
                    zle reset-prompt
                fi
            fi
        fi
    fi
}
zle -N peco-branch
bindkey '^b' peco-branch

# pecoでgit add（空白・特殊文字、rename行に対応）
function peco-git-add() {
    (
        git-root
        # rename行（old -> new）は末尾のファイル名のみ抽出
        git status -uall --porcelain | sed 's/^.. //' | sed 's/.* -> //' | peco --prompt 'GIT ADD >' | while IFS= read -r f; do
            echo "Added: $f"
            git add -- "$f"
        done
    )
}
alias ga='peco-git-add'

# pecoでGit diffビューア
function peco-difit() {
    local log
    log=$(git log --oneline --decorate)
    if [ -n "$(git status --porcelain)" ]; then
        log=$'.       Uncommitted changes\n'"$log"
    fi

    local selected
    selected=$(printf "%s\n" "$log" | peco --prompt 'COMMIT >')
    local selected_commit
    selected_commit=$(printf "%s\n" "$selected" | head -n 2 | awk '{print $1}')
    local difit_args=($(printf "%s\n" "$selected_commit" | tr '\n' ' '))
    if [[ -n "${selected_commit}" ]]; then
        printf "%s\n" "$selected"
        npx difit --port 1111 $difit_args
    fi
}
alias pifit='peco-difit'

function __worktree_sync_entry_is_safe() {
    local entry="$1"
    case "$entry" in
        ..|../*|*/..|*/../*)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# worktree-sync に記載されたファイルをメインworktreeからコピー
function worktree-sync() {
    inside-git-repository || return 1

    local common_dir
    common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1
    local main_worktree
    main_worktree="$(cd "$common_dir/.." && pwd)"
    local current_worktree
    current_worktree="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1

    if [[ "$main_worktree" == "$current_worktree" ]]; then
        echo "Already in main worktree" >&2
        return 1
    fi

    local setup_file="$main_worktree/.worktree-sync"
    if [[ ! -f "$setup_file" ]]; then
        echo "No .worktree-sync found in $main_worktree" >&2
        return 1
    fi

    local copied=0
    while IFS= read -r entry || [[ -n "$entry" ]]; do
        [[ -z "$entry" || "$entry" == \#* ]] && continue
        if ! __worktree_sync_entry_is_safe "$entry"; then
            echo "Skipped unsafe path: $entry" >&2
            continue
        fi
        [[ -f "$main_worktree/$entry" ]] || continue
        if [[ ! -e "$current_worktree/$entry" ]]; then
            local entry_dir
            entry_dir="$(dirname "$entry")"
            [[ "$entry_dir" != "." ]] && mkdir -p "$current_worktree/$entry_dir"
            cp "$main_worktree/$entry" "$current_worktree/$entry"
            echo "Copied $entry"
            copied=$((copied + 1))
        else
            echo "Skipped $entry (already exists)"
        fi
    done < "$setup_file"

    echo "$copied file(s) copied"
}

# pecoでブランチを選択して削除
function peco-delete-branch() {
    inside-git-repository || return

    # * と + がついていないブランチをフィルタリング
    # git branch の出力形式: "  branch-name" or "* current" or "+ worktree"
    local -a branches=($(git branch | grep -v '^[*+]' | sed 's/^  //' | peco --prompt 'DELETE BRANCH >'))

    if [[ ${#branches[@]} -eq 0 ]]; then
        return
    fi

    # 確認プロンプト
    echo "The following branches will be deleted:"
    for branch in "${branches[@]}"; do
        echo "  - ${branch}"
    done
    echo -n "Are you sure? [y/N] "
    read -r confirm
    if [[ "${confirm}" != [yY] ]]; then
        echo "Cancelled" >&2
        return
    fi

    # 削除実行
    for branch in "${branches[@]}"; do
        git branch -D "${branch}"
    done
}

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

# main/masterブランチにチェックアウト
function git-checkout-main() {
    git checkout $(git-default-branch)
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
    local selected_branch=$(git branch | peco --prompt "BRANCH >" | head -n 1 | sed -e "s/^\*//g" | sed -e "s/ //g")
    if ( test -n "${selected_branch}" ); then
        if ( test -n "${BUFFER}" ); then
            local cmd=$(echo ${BUFFER} | sed -e "s/ $//g")
            BUFFER="${cmd} ${selected_branch}"
            CURSOR="${#BUFFER}"
        else
            BUFFER="git checkout ${selected_branch}"
            zle accept-line
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
    if ( test -n "${difit_args}" ); then
        printf "%s\n" "$selected"
        npx difit --port 1111 $difit_args
    fi
}
alias pifit='peco-difit'

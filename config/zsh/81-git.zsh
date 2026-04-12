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

# ブランチに切り替え
# 使用法: git-switch-branch <branch-name>
# 戻り値: 成功時0、失敗時1
function git-switch-branch() {
    local branch="${1:-}"
    if [[ -z "${branch}" ]]; then
        echo "Usage: git-switch-branch <branch-name>" >&2
        return 1
    fi

    git checkout "${branch}"
}

# main/masterブランチにチェックアウト
function git-checkout-main() {
    git-switch-branch "$(git-default-branch)"
}

# マージ済みブランチを削除
function git-delete-branch() {
    (
        local default
        default=$(git-default-branch)
        local current
        current=$(git symbolic-ref --short HEAD 2>/dev/null)
        local confirm
        local branch
        local merged_info
        local -a deletable=()
        local -a merged_branches=()

        merged_info="$(git for-each-ref --format='%(refname:short)' --merged "${default}" refs/heads 2>/dev/null)"
        merged_branches=("${(@f)merged_info}")

        for branch in "${merged_branches[@]}"; do
            if [[ -z "${branch}" || "${branch}" == "${default}" || "${branch}" == "${current}" ]]; then
                continue
            fi
            deletable+=("${branch}")
        done

        if (( ${#deletable[@]} == 0 )); then
            echo "No branches to delete."
            return 0
        fi

        echo "Merged branches to delete (-d):"
        printf "  %s
" "${deletable[@]}"

        echo ""
        echo -n "Delete these branches? [y/N]: "
        read -r confirm
        if [[ "${confirm}" != [yY] ]]; then
            echo "Aborted."
            return 1
        fi

        git branch -d "${deletable[@]}"
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

#!/usr/bin/env bash
# shellcheck shell=bash

tmux_git_repo_trim_trailing_slash() {
    local target_path="$1"

    if [[ "$target_path" == "/" ]]; then
        printf '/\n'
        return 0
    fi

    printf '%s\n' "${target_path%/}"
}

tmux_git_repo_github_label() {
    local owner="$1"
    local repo_name="$2"

    printf '%s %s/%s\n' "$(printf '\uf408')" "$owner" "$repo_name"
}

tmux_git_repo_label_from_root() {
    local repo_path="$1"
    local worktree_base="${WORKTREE_BASE_DIR:-${HOME}/.worktrees}"
    local trimmed_repo_path
    local trimmed_worktree_base
    local relative_path
    local owner
    local repo_name
    local worktree_name
    local host_name

    trimmed_repo_path="$(tmux_git_repo_trim_trailing_slash "$repo_path")"
    trimmed_worktree_base="$(tmux_git_repo_trim_trailing_slash "$worktree_base")"

    if [[ "$trimmed_worktree_base" != "/" && "$trimmed_repo_path" == "$trimmed_worktree_base"/github.com/* ]]; then
        relative_path="${trimmed_repo_path#"$trimmed_worktree_base"/github.com/}"
        owner="${relative_path%%/*}"

        if [[ "$relative_path" != "$owner" ]]; then
            relative_path="${relative_path#*/}"
            repo_name="${relative_path%%/*}"

            if [[ -n "$owner" && -n "$repo_name" && "$relative_path" != "$repo_name" ]]; then
                printf '%s %s\n' "$(printf '\ue727')" "$repo_name"
                return 0
            fi
        fi
    fi

    if [[ "$trimmed_repo_path" == /var/tmp/vibe-kanban/worktrees/* ]]; then
        relative_path="${trimmed_repo_path#/var/tmp/vibe-kanban/worktrees/}"
        worktree_name="${relative_path%%/*}"

        if [[ "$relative_path" != "$worktree_name" ]]; then
            relative_path="${relative_path#*/}"
            repo_name="${relative_path%%/*}"

            if [[ -n "$worktree_name" && -n "$repo_name" ]]; then
                printf '%s %s\n' "$(printf '\ue727')" "$repo_name"
                return 0
            fi
        fi
    fi

    if [[ "$trimmed_repo_path" == "$HOME"/.ghq/github.com/* ]]; then
        relative_path="${trimmed_repo_path#"$HOME"/.ghq/github.com/}"
        owner="${relative_path%%/*}"

        if [[ "$relative_path" != "$owner" ]]; then
            relative_path="${relative_path#*/}"
            repo_name="${relative_path%%/*}"

            if [[ -n "$owner" && -n "$repo_name" ]]; then
                tmux_git_repo_github_label "$owner" "$repo_name"
                return 0
            fi
        fi
    fi

    if [[ "$trimmed_repo_path" == "$HOME"/.ghq/* ]]; then
        relative_path="${trimmed_repo_path#"$HOME"/.ghq/}"
        host_name="${relative_path%%/*}"

        if [[ "$relative_path" != "$host_name" ]]; then
            relative_path="${relative_path#*/}"

            if [[ -n "$host_name" && -n "$relative_path" ]]; then
                printf '%s\n' "$relative_path"
                return 0
            fi
        fi
    fi

    return 1
}

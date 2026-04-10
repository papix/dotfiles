#!/usr/bin/env bash
# shellcheck shell=bash
# Git repository name segment - shows ghq repos and supported worktrees

# Source lib to get the function get_tmux_pwd
# shellcheck disable=SC1091
# shellcheck source=lib/tmux_adapter.sh
source "${TMUX_POWERLINE_DIR_LIB}/tmux_adapter.sh"
# shellcheck disable=SC1091
# shellcheck source=lib/vcs_helper.sh
source "${TMUX_POWERLINE_DIR_LIB}/vcs_helper.sh"
# shellcheck disable=SC1091
# shellcheck source=git_repository_helper.sh
source "$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/git_repository_helper.sh"

# Default configuration
TMUX_POWERLINE_SEG_GIT_REPO_SYMBOL="${TMUX_POWERLINE_SEG_GIT_REPO_SYMBOL:-}"

generate_segmentrc() {
    read -r -d '' rccontents <<EORC
# Repository symbol (GitHub repos will show nf-cod-github automatically)
# export TMUX_POWERLINE_SEG_GIT_REPO_SYMBOL="${TMUX_POWERLINE_SEG_GIT_REPO_SYMBOL}"
EORC
    echo "$rccontents"
}

run_segment() {
    {
        read -r vcs_type
        read -r _unused
    } < <(tp_get_vcs_type_and_root_path)

    if [[ "$vcs_type" != "git" ]]; then
        return
    fi

    tmux_path=$(tp_get_tmux_cwd)
    cd "$tmux_path" || return

    # Check if git repository
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null)
    [[ -z "$git_dir" ]] && return

    local repo_path
    repo_path=$(git rev-parse --show-toplevel 2>/dev/null)

    if [[ -n "$repo_path" ]]; then
        local output=""
        output="$(tmux_git_repo_label_from_root "$repo_path" 2>/dev/null)" || output=""
        [[ -n "$output" ]] && echo "$output"
    fi
}
